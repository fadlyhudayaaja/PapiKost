import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reservation_model.dart';
import 'auth_repository.dart';

class ReservationRepository {
  ReservationRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  static final instance = ReservationRepository();
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 20);

  List<ReservationModel> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .map((doc) => ReservationModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Stream<List<ReservationModel>> watchForRenter(String uid) => _firestore
      .collection('reservations')
      .where('renterId', isEqualTo: uid)
      .snapshots()
      .map(_decode);

  Stream<List<ReservationModel>> watchForOwner(String uid) => _firestore
      .collection('reservations')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map(_decode);

  Future<List<ReservationModel>> fetchForOwner(String uid) async => _decode(
    await _firestore
        .collection('reservations')
        .where('ownerId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout),
  );

  Future<ReservationModel> createReservation({
    required String kostId,
    required bool isSplitBill,
    int? splitMemberCount,
    required DateTime checkInDate,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    final now = DateTime.now();
    final date = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today) ||
        date.isAfter(today.add(const Duration(days: 90)))) {
      throw const AuthFailure(
        'Pilih tanggal masuk hari ini hingga 90 hari ke depan.',
      );
    }
    if ((isSplitBill &&
            (splitMemberCount == null ||
                splitMemberCount < 2 ||
                splitMemberCount > 4)) ||
        (!isSplitBill && splitMemberCount != null)) {
      throw const AuthFailure('Jumlah anggota patungan harus 2–4 orang.');
    }
    if ((notes?.trim().length ?? 0) > 2000) {
      throw const AuthFailure('Catatan maksimal 2000 karakter.');
    }

    // A stable document per invocation also makes automatic transaction retries idempotent.
    final reservationRef = _firestore.collection('reservations').doc();
    final kostRef = _firestore.collection('kost').doc(kostId);
    final userRef = _firestore.collection('users').doc(user.uid);
    final lockRef = userRef.collection('reservationLocks').doc(kostId);
    return _firestore.runTransaction<ReservationModel>(
      (transaction) async {
        final profile = (await transaction.get(userRef)).data();
        final kost = (await transaction.get(kostRef)).data();
        final lock = (await transaction.get(lockRef)).data();
        if (profile?['role'] != 'RENTER') {
          throw const AuthFailure(
            'Hanya akun penyewa yang dapat membuat reservasi.',
          );
        }
        if (kost == null) throw const AuthFailure('Kost sudah tidak tersedia.');
        if (kost['verificationStatus'] != 'ACC') {
          throw const AuthFailure('Kamar belum disetujui admin.');
        }
        if ((kost['availableRooms'] as int) < 1) {
          throw const AuthFailure('Kamar di kost ini sudah penuh.');
        }
        if (isSplitBill && kost['isSplitBillAvailable'] != true) {
          throw const AuthFailure('Kost ini tidak menyediakan sewa patungan.');
        }
        if (lock != null) {
          final previous = await transaction.get(
            _firestore
                .collection('reservations')
                .doc(lock['reservationId'] as String),
          );
          if (previous.data()?['status'] != 'REJECTED') {
            throw const AuthFailure(
              'Kamu sudah memiliki reservasi aktif di kost ini. Periksa riwayat reservasi.',
            );
          }
        }
        final price = (kost['pricePerMonth'] as num).toDouble();
        final photos = List<String>.from(kost['imageUrls'] as List? ?? []);
        final data = <String, dynamic>{
          'ownerId': kost['ownerId'],
          'kostId': kostId,
          'kostName': kost['name'],
          'kostAddress': kost['address'],
          'kostImageUrl': photos.isEmpty ? null : photos.first,
          'renterId': user.uid,
          'renterName': profile!['name'],
          'renterEmail': profile['email'],
          'renterPhone': profile['phone'],
          'status': 'PENDING',
          'isSplitBill': isSplitBill,
          'splitMemberCount': splitMemberCount,
          'totalPrice': price,
          'pricePerPerson': isSplitBill ? price / splitMemberCount! : null,
          'checkInDate': Timestamp.fromDate(date),
          'checkOutDate': null,
          'notes': notes?.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        transaction.set(reservationRef, data);
        transaction.set(lockRef, {
          'renterId': user.uid,
          'kostId': kostId,
          'reservationId': reservationRef.id,
        });
        return ReservationModel.fromJson({
          ...data,
          'id': reservationRef.id,
          'createdAt': now,
        });
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  Future<void> respond(String id, {required bool approve}) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    final ref = _firestore.collection('reservations').doc(id);
    await _firestore.runTransaction<void>(
      (transaction) async {
        final reservation = (await transaction.get(ref)).data();
        if (reservation == null || reservation['ownerId'] != user.uid) {
          throw const AuthFailure(
            'Reservasi tidak ditemukan atau bukan milik akun ini.',
          );
        }
        final target = approve ? 'APPROVED' : 'REJECTED';
        // A repeated approval must never consume another room.
        if (reservation['status'] == target) return;
        if (reservation['status'] != 'PENDING') {
          throw const AuthFailure('Reservasi ini sudah diproses.');
        }
        if (approve) {
          final kostRef = _firestore
              .collection('kost')
              .doc(reservation['kostId'] as String);
          final kost = (await transaction.get(kostRef)).data();
          if (kost == null || kost['ownerId'] != user.uid) {
            throw const AuthFailure(
              'Kost sudah tidak tersedia. Reservasi dapat ditolak.',
            );
          }
          final available = kost['availableRooms'] as int;
          if (available < 1) {
            throw const AuthFailure(
              'Kamar sudah penuh. Reservasi tidak dapat disetujui.',
            );
          }
          transaction.update(kostRef, {
            'availableRooms': available - 1,
            'lastReservationId': id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.update(ref, {
          'status': target,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  static String errorMessage(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is TimeoutException) {
      return 'Koneksi lambat. Periksa riwayat reservasi sebelum mencoba lagi.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Akses reservasi ditolak. Silakan login kembali atau hubungi pengelola.',
        'unavailable' =>
          'Tidak dapat terhubung. Periksa koneksi internet kamu.',
        'aborted' => 'Data berubah saat diproses. Silakan coba kembali.',
        _ => 'Reservasi gagal diproses. Silakan coba kembali.',
      };
    }
    return 'Reservasi gagal diproses. Silakan coba kembali.';
  }
}
