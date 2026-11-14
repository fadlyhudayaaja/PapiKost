import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class AdminUserRepository {
  AdminUserRepository({FirebaseFirestore? firestore}) : _override = firestore;
  static final instance = AdminUserRepository();
  final FirebaseFirestore? _override;
  FirebaseFirestore get _firestore => _override ?? FirebaseFirestore.instance;

  List<UserModel> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
        .toList();
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Stream<List<UserModel>> watchUsers() async* {
    final users = _firestore.collection('users');
    yield _decode(
      await users
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20)),
    );
    yield* users.snapshots().map(_decode);
  }

  static String errorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Belum mendapat respons server. Periksa koneksi lalu coba lagi.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Daftar pengguna belum dapat diakses. Pastikan akun memiliki peran ADMIN dan aturan Firestore terbaru sudah dipublikasikan.',
        'unauthenticated' => 'Sesi berakhir. Silakan masuk kembali.',
        'unavailable' =>
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        'no-app' => 'Koneksi Firebase belum disiapkan untuk perangkat ini.',
        _ => 'Gagal memuat pengguna. Silakan coba lagi.',
      };
    }
    if (error is FormatException || error is TypeError) {
      return 'Ada profil pengguna yang belum lengkap. Periksa field profil di Firestore.';
    }
    if (error is AuthFailure) return error.message;
    return 'Gagal memuat pengguna. Silakan coba lagi.';
  }
}
