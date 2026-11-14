import 'dart:async';

import '../../core/utils/image_url.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/kost_model.dart';
import 'auth_repository.dart';

class KostRepository {
  KostRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;
  static final instance = KostRepository();
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 20);
  static const facilities = [
    'WiFi',
    'AC',
    'TV',
    'Lemari',
    'Meja Belajar',
    'Kamar Mandi Dalam',
    'Dapur Bersama',
    'Parkir Motor',
    'Parkir Mobil',
    'Keamanan 24 Jam',
    'Laundry',
    'Kulkas',
  ];

  List<KostModel> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => KostModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Stream<List<KostModel>> watchAll() => _firestore
      .collection('kost')
      .snapshots()
      .map(
        (snapshot) => _decode(
          snapshot,
        ).where((kost) => kost.verificationStatus == 'ACC').toList(),
      );

  Future<List<KostModel>> fetchAll({
    String? search,
    String? type,
    double? maxPrice,
    int page = 0,
    int size = 200,
  }) async {
    final snapshot = await _firestore
        .collection('kost')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final query = search?.trim().toLowerCase() ?? '';
    return _decode(snapshot)
        .where((kost) {
          return kost.verificationStatus == 'ACC' &&
              (query.isEmpty ||
                  [
                    kost.name,
                    kost.address,
                    kost.city,
                  ].any((value) => value.toLowerCase().contains(query))) &&
              (type == null || type == 'ALL' || kost.type == type) &&
              (maxPrice == null || kost.pricePerMonth <= maxPrice);
        })
        .skip(page < 0 ? 0 : page * size)
        .take(size)
        .toList();
  }

  Future<List<KostModel>> fetchForOwner(String ownerId) async => _decode(
    await _firestore
        .collection('kost')
        .where('ownerId', isEqualTo: ownerId)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout),
  );

  Future<KostModel> fetchById(String id) async {
    final doc = await _firestore
        .collection('kost')
        .doc(id)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    if (!doc.exists || doc.data() == null) {
      throw const AuthFailure('Kost tidak ditemukan atau sudah dihapus.');
    }
    return KostModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<({String uid, String name})> _owner() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    if (doc.data()?['role'] != 'OWNER') {
      throw const AuthFailure(
        'Hanya pemilik kost yang dapat mengelola properti.',
      );
    }
    return (uid: user.uid, name: doc.data()!['name'] as String);
  }

  Map<String, dynamic> _editable({
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) {
    if (name.trim().isEmpty ||
        name.trim().length > 150 ||
        address.trim().isEmpty ||
        address.trim().length > 500 ||
        city.trim().isEmpty ||
        city.trim().length > 100) {
      throw const AuthFailure('Isi nama, alamat, dan kota kost dengan benar.');
    }
    if (!pricePerMonth.isFinite ||
        pricePerMonth <= 0 ||
        pricePerMonth > 1000000000000) {
      throw const AuthFailure('Harga sewa harus lebih dari nol.');
    }
    if (totalRooms < 1 ||
        totalRooms > 10000 ||
        !['PUTRA', 'PUTRI', 'CAMPUR'].contains(type)) {
      throw const AuthFailure('Periksa tipe kost dan jumlah kamar.');
    }
    if (facilities.isEmpty ||
        facilities.length > 12 ||
        facilities.any((value) => !KostRepository.facilities.contains(value))) {
      throw const AuthFailure('Pilih fasilitas kost yang tersedia.');
    }
    final url = photoUrl == null ? null : ImageUrl.normalizeInput(photoUrl);
    if (url != null && url.isNotEmpty && !ImageUrl.isValid(url)) {
      throw const AuthFailure('Gunakan URL foto HTTPS yang valid.');
    }
    if (description != null && description.trim().length > 5000) {
      throw const AuthFailure('Deskripsi maksimal 5000 karakter.');
    }
    return {
      'name': name.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'pricePerMonth': pricePerMonth,
      'type': type,
      'totalRooms': totalRooms,
      'isSplitBillAvailable': isSplitBillAvailable,
      'facilities': facilities.toSet().toList(),
      'description': description?.trim(),
      'imageUrls': url == null || url.isEmpty ? <String>[] : [url],
    };
  }

  Future<KostModel> createKost({
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) async {
    final data = _editable(
      name: name,
      address: address,
      city: city,
      pricePerMonth: pricePerMonth,
      type: type,
      totalRooms: totalRooms,
      isSplitBillAvailable: isSplitBillAvailable,
      facilities: facilities,
      description: description,
      photoUrl: photoUrl,
    );
    final owner = await _owner();
    data.addAll({
      'ownerId': owner.uid,
      'ownerName': owner.name,
      'availableRooms': totalRooms,
      'latitude': null,
      'longitude': null,
      'rating': null,
      'reviewCount': 0,
      'verificationStatus': 'PROSES',
      'rejectionReason': null,
      'reviewedBy': null,
      'reviewedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final doc = _firestore.collection('kost').doc();
    await doc.set(data).timeout(_timeout);
    return KostModel.fromJson({...data, 'id': doc.id});
  }

  Future<KostModel> updateKost({
    required String id,
    required String name,
    required String address,
    required String city,
    required double pricePerMonth,
    required String type,
    required int totalRooms,
    required bool isSplitBillAvailable,
    required List<String> facilities,
    String? description,
    String? photoUrl,
  }) async {
    final data = _editable(
      name: name,
      address: address,
      city: city,
      pricePerMonth: pricePerMonth,
      type: type,
      totalRooms: totalRooms,
      isSplitBillAvailable: isSplitBillAvailable,
      facilities: facilities,
      description: description,
      photoUrl: photoUrl,
    );
    final owner = await _owner();
    final ref = _firestore.collection('kost').doc(id);
    return _firestore.runTransaction<KostModel>(
      (transaction) async {
        final doc = await transaction.get(ref);
        final old = doc.data();
        if (old == null || old['ownerId'] != owner.uid) {
          throw const AuthFailure(
            'Kost tidak ditemukan atau bukan milik akun ini.',
          );
        }
        final occupied =
            (old['totalRooms'] as int) - (old['availableRooms'] as int);
        if (totalRooms < occupied) {
          throw const AuthFailure(
            'Jumlah kamar tidak boleh kurang dari kamar yang terisi.',
          );
        }
        final changes = {
          ...data,
          'ownerName': owner.name,
          'availableRooms': totalRooms - occupied,
          'verificationStatus': 'PROSES',
          'rejectionReason': null,
          'reviewedBy': null,
          'reviewedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        transaction.update(ref, changes);
        return KostModel.fromJson({...old, ...changes, 'id': id});
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  Future<void> deleteKost(String id) async {
    final owner = await _owner();
    final ref = _firestore.collection('kost').doc(id);
    await _firestore.runTransaction<void>(
      (transaction) async {
        final doc = await transaction.get(ref);
        final data = doc.data();
        if (data == null || data['ownerId'] != owner.uid) {
          throw const AuthFailure(
            'Kost tidak ditemukan atau bukan milik akun ini.',
          );
        }
        if (data['totalRooms'] != data['availableRooms']) {
          throw const AuthFailure(
            'Kost yang masih dihuni tidak dapat dihapus.',
          );
        }
        transaction.delete(ref);
      },
      timeout: _timeout,
      maxAttempts: 3,
    );
  }

  static String errorMessage(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is TimeoutException)
      return 'Koneksi terlalu lama. Periksa internet lalu coba lagi.';
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Akses data kost ditolak. Hubungi pengelola untuk memeriksa izin akses.';
    }
    if (error is FirebaseException && error.code == 'unavailable') {
      return 'Data kost belum dapat dimuat. Periksa koneksi internet.';
    }
    return 'Data kost belum dapat diproses. Silakan coba lagi.';
  }
}
