import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  String get userRole => _currentUser?.role ?? '';
  bool get isRenter => userRole == AppConstants.roleRenter;
  bool get isOwner => userRole == AppConstants.roleOwner;
  bool get isAdmin => userRole == AppConstants.roleAdmin;

  // ── Cek session lokal saat splash ─────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final role = await _storage.read(key: AppConstants.userRoleKey);
      final name = await _storage.read(key: AppConstants.userNameKey);
      final idStr = await _storage.read(key: AppConstants.userIdKey);

      if (token == null || role == null) {
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      // Restore user dari storage lokal (tidak perlu hit network)
      _currentUser = UserModel(
        id: int.tryParse(idStr ?? '0') ?? 0,
        name: name ?? 'Pengguna',
        email: '',
        phone: '',
        role: role,
        isVerified: true,
      );
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      await _storage.deleteAll();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ── Login via Mock ─────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await MockService.login(email, password);
      _currentUser = result['user'] as UserModel;
      final token = result['token'] as String;

      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(
        key: AppConstants.userRoleKey,
        value: _currentUser!.role,
      );
      await _storage.write(
        key: AppConstants.userIdKey,
        value: _currentUser!.id.toString(),
      );
      await _storage.write(
        key: AppConstants.userNameKey,
        value: _currentUser!.name,
      );

      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Register via Mock ──────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      await MockService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteAll();
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _setStatus(AuthStatus.unauthenticated);
    } else {
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
