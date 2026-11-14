import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/owner_submission.dart';
import '../../core/utils/image_url.dart';
import 'auth_repository.dart';

class OwnerVerificationRepository {
  OwnerVerificationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _authOverride = auth,
       _firestoreOverride = firestore;

  static final instance = OwnerVerificationRepository();
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 20);

  List<OwnerSubmission> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .map((doc) => OwnerSubmission.fromFirestore(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return items;
  }

  Stream<List<OwnerSubmission>> watchAll() => Stream.multi((controller) {
    List<OwnerSubmission>? owners;
    List<OwnerSubmission>? rooms;
    var failed = false;
    void fail(Object error, StackTrace stack) {
      failed = true;
      controller.addError(error, stack);
    }

    void emit() {
      if (failed || owners == null || rooms == null) return;
      final items = [...owners!, ...rooms!];
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      controller.add(items);
    }

    Stream<List<OwnerSubmission>> watch(
      String path,
      List<OwnerSubmission> Function(QuerySnapshot<Map<String, dynamic>>)
      decode,
    ) async* {
      final collection = _firestore.collection(path);
      // Jangan tampilkan cache kosong sebagai hasil dari server.
      yield decode(
        await collection
            .get(const GetOptions(source: Source.server))
            .timeout(_timeout),
      );
      yield* collection.snapshots().map(decode);
    }

    final ownerSubscription = watch('ownerVerifications', _decode).listen((
      items,
    ) {
      owners = items;
      emit();
    }, onError: fail);
    final roomSubscription =
        watch(
          'kost',
          (snapshot) => snapshot.docs
              .map((doc) => OwnerSubmission.fromKost(doc.id, doc.data()))
              .toList(),
        ).listen((items) {
          rooms = items;
          emit();
        }, onError: fail);
    controller.onCancel = () async {
      await Future.wait([
        ownerSubscription.cancel(),
        roomSubscription.cancel(),
      ]);
    };
  });

  Stream<OwnerSubmission?> watchForOwner(String uid) async* {
    final ref = _firestore.collection('ownerVerifications').doc(uid);
    OwnerSubmission? decode(DocumentSnapshot<Map<String, dynamic>> doc) =>
        doc.exists ? OwnerSubmission.fromFirestore(doc.id, doc.data()!) : null;
    yield decode(
      await ref.get(const GetOptions(source: Source.server)).timeout(_timeout),
    );
    yield* ref.snapshots().map(decode);
  }

  static bool validDocumentUrl(String value) => ImageUrl.isValid(value);

  Future<void> submit({
    required String ktpNumber,
    required String propertyName,
    required String propertyAddress,
    required String propertyType,
    required String ktpImageUrl,
    required String sertifikatImageUrl,
    required String fotoRumahImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    if (!RegExp(r'^\d{16}$').hasMatch(ktpNumber.trim())) {
      throw const AuthFailure('Nomor KTP harus terdiri dari 16 angka.');
    }
    if (propertyName.trim().isEmpty ||
        propertyName.trim().length > 150 ||
        propertyAddress.trim().isEmpty ||
        propertyAddress.trim().length > 500 ||
        !['PUTRA', 'PUTRI', 'CAMPUR'].contains(propertyType)) {
      throw const AuthFailure('Lengkapi data properti dengan benar.');
    }
    if (![
      ktpImageUrl,
      sertifikatImageUrl,
      fotoRumahImageUrl,
    ].every(validDocumentUrl)) {
      throw const AuthFailure(
        'Lengkapi ketiga dokumen dengan URL gambar HTTPS yang valid.',
      );
    }
    final userRef = _firestore.collection('users').doc(user.uid);
    final ref = _firestore.collection('ownerVerifications').doc(user.uid);
    await _firestore.runTransaction<void>((transaction) async {
      final profile = (await transaction.get(userRef)).data();
      final previous = (await transaction.get(ref)).data();
      if (profile?['role'] != 'OWNER' || profile?['isVerified'] != false) {
        throw const AuthFailure(
          'Pengajuan hanya untuk pemilik yang belum terverifikasi.',
        );
      }
      if (previous != null && previous['status'] != 'TOLAK') {
        throw const AuthFailure(
          'Pengajuan sudah dikirim. Tunggu keputusan admin.',
        );
      }
      transaction.set(ref, {
        'ownerId': user.uid,
        'name': profile!['name'],
        'email': profile['email'],
        'phone': profile['phone'],
        'ktpNumber': ktpNumber.trim(),
        'propertyName': propertyName.trim(),
        'propertyAddress': propertyAddress.trim(),
        'propertyType': propertyType,
        'ktpImageUrl': ImageUrl.normalizeInput(ktpImageUrl),
        'sertifikatImageUrl': ImageUrl.normalizeInput(sertifikatImageUrl),
        'fotoRumahImageUrl': ImageUrl.normalizeInput(fotoRumahImageUrl),
        'status': 'PROSES',
        'rejectionReason': null,
        'reviewedBy': null,
        'reviewedAt': null,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, timeout: _timeout);
  }

  Future<void> review(
    String ownerId, {
    required bool approve,
    String? reason,
  }) async {
    if (ownerId.startsWith('kost/')) {
      return _reviewKost(
        ownerId.substring(5),
        approve: approve,
        reason: reason,
      );
    }
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    final rejection = reason?.trim();
    if (!approve &&
        (rejection == null ||
            rejection.length < 10 ||
            rejection.length > 300)) {
      throw const AuthFailure('Alasan penolakan harus 10–300 karakter.');
    }
    final adminRef = _firestore.collection('users').doc(user.uid);
    final ownerRef = _firestore.collection('users').doc(ownerId);
    final ref = _firestore.collection('ownerVerifications').doc(ownerId);
    await _firestore.runTransaction<void>((transaction) async {
      final admin = (await transaction.get(adminRef)).data();
      if (admin?['role'] != 'ADMIN') {
        throw const AuthFailure('Hanya admin yang dapat memproses pengajuan.');
      }
      final owner = (await transaction.get(ownerRef)).data();
      final submission = (await transaction.get(ref)).data();
      if (owner?['role'] != 'OWNER' ||
          owner?['isVerified'] != false ||
          submission?['ownerId'] != ownerId ||
          submission?['status'] != 'PROSES') {
        throw const AuthFailure(
          'Pengajuan tidak tersedia atau sudah diproses admin lain.',
        );
      }
      transaction.update(ref, {
        'status': approve ? 'ACC' : 'TOLAK',
        'rejectionReason': approve ? null : rejection,
        'reviewedBy': user.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(ownerRef, {'isVerified': approve});
    }, timeout: _timeout);
  }

  Future<void> _reviewKost(
    String kostId, {
    required bool approve,
    String? reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    final rejection = reason?.trim();
    if (!approve &&
        (rejection == null ||
            rejection.length < 10 ||
            rejection.length > 300)) {
      throw const AuthFailure('Alasan penolakan harus 10–300 karakter.');
    }
    final adminRef = _firestore.collection('users').doc(user.uid);
    final ref = _firestore.collection('kost').doc(kostId);
    await _firestore.runTransaction<void>((transaction) async {
      final admin = (await transaction.get(adminRef)).data();
      final kost = (await transaction.get(ref)).data();
      if (admin?['role'] != 'ADMIN') {
        throw const AuthFailure('Hanya admin yang dapat memproses pengajuan.');
      }
      if (kost == null ||
          (kost['verificationStatus'] ?? 'PROSES') != 'PROSES') {
        throw const AuthFailure(
          'Pengajuan kamar tidak tersedia atau sudah diproses admin lain.',
        );
      }
      transaction.update(ref, {
        'verificationStatus': approve ? 'ACC' : 'TOLAK',
        'rejectionReason': approve ? null : rejection,
        'reviewedBy': user.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, timeout: _timeout);
  }

  static String errorMessage(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is TimeoutException) {
      return 'Koneksi terlalu lama. Muat ulang untuk memeriksa status pengajuan.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Akses verifikasi ditolak. Pastikan peran akun benar dan aturan Firestore terbaru sudah dipublikasikan pada proyek aplikasi.',
        'unauthenticated' => 'Sesi berakhir. Silakan masuk kembali.',
        'no-app' =>
          'Koneksi Firebase belum disiapkan untuk perangkat ini. Gunakan aplikasi Android yang sudah dikonfigurasi.',
        'unavailable' => 'Tidak dapat terhubung. Periksa koneksi internet.',
        'aborted' => 'Pengajuan sedang diproses. Muat ulang lalu coba lagi.',
        _ => 'Gagal memproses verifikasi. Silakan coba lagi.',
      };
    }
    return 'Gagal memproses verifikasi. Silakan coba lagi.';
  }
}
