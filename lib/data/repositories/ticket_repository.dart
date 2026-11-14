import '../../core/utils/image_url.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ticket_model.dart';
import '../models/reservation_model.dart';
import 'auth_repository.dart';

class TicketRepository {
  TicketRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;
  static final instance = TicketRepository();
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 20);
  static const categoryLabels = {
    'AIR': 'Air & Plumbing',
    'LISTRIK': 'Listrik',
    'MEBEL': 'Mebel & Perabot',
    'STRUKTUR': 'Struktur Bangunan',
    'LAINNYA': 'Lainnya',
  };

  String _uid() {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    return user.uid;
  }

  List<TicketModel> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .map((doc) => TicketModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Query<Map<String, dynamic>> _query(String field, String uid) =>
      _firestore.collection('tickets').where(field, isEqualTo: uid);
  Stream<List<TicketModel>> watchForRenter(String uid) =>
      _query('renterId', uid).snapshots().map(_decode);
  Stream<List<TicketModel>> watchForOwner(String uid) =>
      _query('ownerId', uid).snapshots().map(_decode);
  Future<List<TicketModel>> fetchForRenter(String uid) async => _decode(
    await _query(
      'renterId',
      uid,
    ).get(const GetOptions(source: Source.server)).timeout(_timeout),
  );
  Future<List<TicketModel>> fetchForOwner(String uid) async => _decode(
    await _query(
      'ownerId',
      uid,
    ).get(const GetOptions(source: Source.server)).timeout(_timeout),
  );
  Stream<TicketModel?> watchById(String id) => _firestore
      .collection('tickets')
      .doc(id)
      .snapshots()
      .map(
        (doc) => doc.exists && doc.data() != null
            ? TicketModel.fromJson({...doc.data()!, 'id': doc.id})
            : null,
      );

  Future<List<ReservationModel>> eligibleReservations(String uid) async {
    final snapshot = await _firestore
        .collection('reservations')
        .where('renterId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final items = snapshot.docs
        .map((doc) => ReservationModel.fromJson({...doc.data(), 'id': doc.id}))
        .where((item) => item.status == 'APPROVED')
        .toList();
    items.sort((a, b) => a.kostName.compareTo(b.kostName));
    return items;
  }

  Map<String, dynamic> _editable({
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    required List<String> imageUrls,
  }) {
    final name = title.trim(), details = description.trim();
    if (name.length < 5 || name.length > 100) {
      throw const AuthFailure('Judul laporan harus 5–100 karakter.');
    }
    if (details.length < 15 || details.length > 500) {
      throw const AuthFailure('Deskripsi laporan harus 15–500 karakter.');
    }
    if (!categoryLabels.containsKey(category)) {
      throw const AuthFailure('Pilih kategori kerusakan yang tersedia.');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      incidentDate.year,
      incidentDate.month,
      incidentDate.day,
    );
    if (date.isAfter(today) ||
        date.isBefore(today.subtract(const Duration(days: 365)))) {
      throw const AuthFailure(
        'Pilih tanggal kejadian dalam satu tahun terakhir hingga hari ini.',
      );
    }
    final photos = imageUrls.map(ImageUrl.normalizeInput).toList();
    if (photos.length > 3 || photos.any((url) => !ImageUrl.isValid(url))) {
      throw const AuthFailure(
        'Gunakan maksimal 3 tautan foto HTTPS yang valid.',
      );
    }
    return {
      'title': name,
      'description': details,
      'category': category,
      'incidentDate': Timestamp.fromDate(date),
      'imageUrls': photos,
    };
  }

  Future<TicketModel> createTicket({
    required String reservationId,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String> imageUrls = const [],
  }) async {
    final uid = _uid();
    final data = _editable(
      title: title,
      description: description,
      category: category,
      incidentDate: incidentDate,
      imageUrls: imageUrls,
    );
    final ref = _firestore.collection('tickets').doc();
    return _firestore.runTransaction<TicketModel>(
      (transaction) async {
        final profile = (await transaction.get(
          _firestore.collection('users').doc(uid),
        )).data();
        final reservation = (await transaction.get(
          _firestore.collection('reservations').doc(reservationId),
        )).data();
        if (profile?['role'] != 'RENTER') {
          throw const AuthFailure('Hanya penyewa yang dapat mengirim laporan.');
        }
        if (reservation == null ||
            reservation['renterId'] != uid ||
            reservation['status'] != 'APPROVED') {
          throw const AuthFailure(
            'Pilih reservasi milikmu yang sudah disetujui pemilik kost.',
          );
        }
        final values = <String, dynamic>{
          ...data,
          'reservationId': reservationId,
          'ownerId': reservation['ownerId'],
          'kostId': reservation['kostId'],
          'kostName': reservation['kostName'],
          'renterId': uid,
          'renterName': profile!['name'],
          'status': 'PENDING',
          'ownerNote': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        transaction.set(ref, values);
        final now = DateTime.now();
        return TicketModel.fromJson({
          ...values,
          'id': ref.id,
          'createdAt': now,
          'updatedAt': now,
        });
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  Future<TicketModel> updateTicket({
    required String id,
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    List<String>? imageUrls,
  }) async {
    final uid = _uid();
    final ref = _firestore.collection('tickets').doc(id);
    return _firestore.runTransaction<TicketModel>(
      (transaction) async {
        final old = (await transaction.get(ref)).data();
        if (old == null || old['renterId'] != uid) {
          throw const AuthFailure(
            'Laporan tidak ditemukan atau bukan milik akun ini.',
          );
        }
        if (old['status'] != 'PENDING') {
          throw const AuthFailure(
            'Laporan yang sudah diproses tidak dapat diedit.',
          );
        }
        final changes = {
          ..._editable(
            title: title,
            description: description,
            category: category,
            incidentDate: incidentDate,
            imageUrls: imageUrls ?? List<String>.from(old['imageUrls'] as List),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        transaction.update(ref, changes);
        return TicketModel.fromJson({
          ...old,
          ...changes,
          'id': id,
          'updatedAt': DateTime.now(),
        });
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  Future<void> deleteTicket(String id) async {
    final uid = _uid();
    final ref = _firestore.collection('tickets').doc(id);
    await _firestore.runTransaction<void>(
      (transaction) async {
        final old = (await transaction.get(ref)).data();
        if (old == null || old['renterId'] != uid) {
          throw const AuthFailure(
            'Laporan tidak ditemukan atau bukan milik akun ini.',
          );
        }
        if (old['status'] != 'PENDING') {
          throw const AuthFailure(
            'Laporan yang sudah diproses tidak dapat dihapus.',
          );
        }
        transaction.delete(ref);
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  Future<TicketModel> updateStatus(
    String id,
    String status, {
    String? ownerNote,
  }) async {
    final uid = _uid();
    if (ownerNote != null && ownerNote.trim().length > 2000) {
      throw const AuthFailure('Catatan maksimal 2000 karakter.');
    }
    final ref = _firestore.collection('tickets').doc(id);
    return _firestore.runTransaction<TicketModel>(
      (transaction) async {
        final old = (await transaction.get(ref)).data();
        if (old == null || old['ownerId'] != uid) {
          throw const AuthFailure(
            'Laporan tidak ditemukan atau bukan milik akun ini.',
          );
        }
        if (old['status'] == status) {
          return TicketModel.fromJson({...old, 'id': id});
        }
        if (!((old['status'] == 'PENDING' && status == 'IN_PROGRESS') ||
            (old['status'] == 'IN_PROGRESS' && status == 'DONE'))) {
          throw const AuthFailure(
            'Proses laporan dari Menunggu ke Diproses, lalu Selesai.',
          );
        }
        final changes = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          if (ownerNote != null) 'ownerNote': ownerNote.trim(),
        };
        transaction.update(ref, changes);
        return TicketModel.fromJson({
          ...old,
          ...changes,
          'id': id,
          'updatedAt': DateTime.now(),
        });
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  static String errorMessage(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is TimeoutException) {
      return 'Koneksi lambat. Periksa daftar laporan sebelum mencoba lagi.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Akses laporan ditolak. Silakan login kembali atau hubungi pengelola.',
        'unavailable' =>
          'Tidak dapat terhubung. Periksa koneksi internet kamu.',
        'aborted' => 'Laporan berubah saat diproses. Silakan muat ulang.',
        _ => 'Laporan gagal diproses. Silakan coba kembali.',
      };
    }
    return 'Laporan gagal diproses. Silakan coba kembali.';
  }
}
