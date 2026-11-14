import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;
  static final instance = AuthRepository();
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 20);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      return await _readProfile(credential.user!.uid);
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    _validateProfile(name: name, phone: phone);
    if (role != AppConstants.roleRenter && role != AppConstants.roleOwner) {
      throw const AuthFailure('Pilih peran pencari kost atau pemilik kost.');
    }
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      // Pulihkan pendaftaran terputus setelah memeriksa password akun.
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }
    try {
      final user = credential.user!;
      final document = _firestore.collection('users').doc(user.uid);
      final existing = await document
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      if (existing.exists) {
        throw const AuthFailure('Email sudah terdaftar. Silakan login.');
      }
      await document
          .set({
            'name': name.trim(),
            'email': user.email!,
            'phone': phone.trim(),
            'role': role,
            'isVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
            'avatarUrl': null,
            'bio': null,
          })
          .timeout(_timeout);
    } catch (error) {
      if (error is AuthFailure) rethrow;
      // Jangan hapus akun: penulisan dapat selesai setelah timeout.
      throw const AuthFailure(
        'Akun sudah dibuat, tetapi profil belum tersimpan. Periksa koneksi '
        'lalu ulangi pendaftaran dengan email dan password yang sama.',
      );
    } finally {
      // Pertahankan alur registrasi yang kembali ke halaman login.
      await _auth.signOut();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = await _auth.authStateChanges().first.timeout(_timeout);
    return user == null ? null : _readProfile(user.uid);
  }

  Future<UserModel> _readProfile(String uid) async {
    final document = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final data = document.data();
    if (data == null) {
      throw const AuthFailure(
        'Profil akun belum lengkap. Ulangi pendaftaran dengan email dan password yang sama.',
      );
    }
    if (![
      AppConstants.roleRenter,
      AppConstants.roleOwner,
      AppConstants.roleAdmin,
    ].contains(data['role'])) {
      throw const AuthFailure('Peran akun tidak valid. Hubungi pengelola.');
    }
    if (data['name'] is! String || data['email'] is! String) {
      throw const AuthFailure(
        'Profil akun belum lengkap. Lengkapi nama dan email di Firestore.',
      );
    }
    return UserModel.fromFirestore(uid, data);
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String? bio,
  }) async {
    _validateProfile(name: name, phone: phone, bio: bio);
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({
          'name': name.trim(),
          'phone': phone.trim(),
          'bio': bio?.trim(),
        })
        .timeout(_timeout);
    return _readProfile(user.uid);
  }

  void _validateProfile({
    required String name,
    required String phone,
    String? bio,
  }) {
    if (name.trim().isEmpty || name.trim().length > 100) {
      throw const AuthFailure('Nama wajib diisi, maksimal 100 karakter.');
    }
    if (phone.trim().isEmpty || phone.trim().length > 30) {
      throw const AuthFailure('Nomor HP wajib diisi, maksimal 30 karakter.');
    }
    if (bio != null && bio.trim().length > 500) {
      throw const AuthFailure('Bio maksimal 500 karakter.');
    }
  }

  Future<void> logout() => _auth.signOut();

  static String errorMessage(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is TimeoutException) {
      return 'Koneksi terlalu lama. Periksa internet lalu coba lagi.';
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'invalid-email' => 'Format email tidak valid.',
        'email-already-in-use' => 'Email sudah terdaftar. Silakan login.',
        'weak-password' =>
          'Password terlalu lemah. Gunakan minimal 6 karakter.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email atau password tidak sesuai.',
        'user-disabled' => 'Akun dinonaktifkan. Hubungi pengelola.',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
        'network-request-failed' ||
        'unavailable' => 'Tidak dapat terhubung. Periksa koneksi internet.',
        'operation-not-allowed' =>
          'Login email belum diaktifkan oleh pengelola.',
        'permission-denied' =>
          'Akses profil ditolak. Pastikan aturan Firestore terbaru sudah dipublikasikan pada proyek aplikasi.',
        'unauthenticated' => 'Sesi berakhir. Silakan masuk kembali.',
        'no-app' =>
          'Koneksi Firebase belum disiapkan untuk perangkat ini. Gunakan aplikasi Android yang sudah dikonfigurasi.',
        _ => 'Proses akun gagal. Silakan coba lagi.',
      };
    }
    return 'Proses akun gagal. Silakan coba lagi.';
  }
}
