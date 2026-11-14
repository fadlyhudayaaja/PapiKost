import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository.instance;
  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isUpdatingProfile = false;
  int _sessionVersion = 0;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isUpdatingProfile => _isUpdatingProfile;
  String get userRole => _currentUser?.role ?? '';
  bool get isRenter => userRole == AppConstants.roleRenter;
  bool get isOwner => userRole == AppConstants.roleOwner;
  bool get isAdmin => userRole == AppConstants.roleAdmin;

  Future<void> checkAuthStatus() async {
    if (isLoading) return;
    _sessionVersion++;
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await _repository.getCurrentUser();
      _setStatus(
        _currentUser == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
      );
    } catch (error) {
      _errorMessage = AuthRepository.errorMessage(error);
      _setStatus(AuthStatus.error);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    if (isLoading) return false;
    _sessionVersion++;
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await _repository.login(email: email, password: password);
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (error) {
      _errorMessage = AuthRepository.errorMessage(error);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    if (isLoading) return false;
    _sessionVersion++;
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.loading);
    try {
      await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } catch (error) {
      _errorMessage = AuthRepository.errorMessage(error);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> logout() async {
    _sessionVersion++;
    await _repository.logout();
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() async {
    final version = _sessionVersion;
    final user = await _repository.getCurrentUser();
    if (version != _sessionVersion) return;
    if (user == null) throw const AuthFailure('Silakan login kembali.');
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? bio,
  }) async {
    if (_isUpdatingProfile || !isAuthenticated) return false;
    _isUpdatingProfile = true;
    final version = _sessionVersion;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _repository.updateProfile(
        name: name,
        phone: phone,
        bio: bio,
      );
      if (version != _sessionVersion) return false;
      _currentUser = user;
      return true;
    } catch (error) {
      _errorMessage = AuthRepository.errorMessage(error);
      return false;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
