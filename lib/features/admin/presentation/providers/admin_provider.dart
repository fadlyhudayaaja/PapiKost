import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/owner_submission.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/owner_verification_repository.dart';

export '../../../../data/models/owner_submission.dart';

enum AdminLoadState { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  AdminProvider({OwnerVerificationRepository? repository})
    : _repository = repository ?? OwnerVerificationRepository.instance;
  final OwnerVerificationRepository _repository;
  StreamSubscription<List<OwnerSubmission>>? _subscription;
  UserModel? _user;
  int _session = 0;
  int _loadVersion = 0;
  AdminLoadState _state = AdminLoadState.initial;
  List<OwnerSubmission> _submissions = [];
  String _error = '';
  bool _isSubmitting = false;

  AdminLoadState get state => _state;
  List<OwnerSubmission> get submissions => List.unmodifiable(_submissions);
  String get error => _error;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _state == AdminLoadState.loading;
  List<OwnerSubmission> get pendingSubmissions =>
      _submissions.where((s) => s.status == VerificationStatus.proses).toList();

  void bindUser(UserModel? user) {
    if (_user?.id == user?.id && _user?.role == user?.role) return;
    _session++;
    _loadVersion++;
    _user = user;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _submissions = [];
    _state = AdminLoadState.initial;
    _error = '';
    _isSubmitting = false;
  }

  Future<void> loadSubmissions() async {
    if (_user?.role != 'ADMIN') return;
    final version = ++_loadVersion;
    _state = AdminLoadState.loading;
    _error = '';
    notifyListeners();
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _subscription = _repository.watchAll().listen(
        (items) {
          if (version != _loadVersion) return;
          _submissions = items;
          _state = AdminLoadState.loaded;
          _error = '';
          notifyListeners();
        },
        onError: (Object error) {
          if (version != _loadVersion) return;
          _submissions = [];
          _state = AdminLoadState.error;
          _error = OwnerVerificationRepository.errorMessage(error);
          notifyListeners();
        },
      );
    } catch (error) {
      if (version != _loadVersion) return;
      _submissions = [];
      _state = AdminLoadState.error;
      _error = OwnerVerificationRepository.errorMessage(error);
      notifyListeners();
    }
  }

  Future<bool> approveSubmission(String id) => _review(id, approve: true);
  Future<bool> rejectSubmission(String id, String reason) =>
      _review(id, approve: false, reason: reason);

  Future<bool> _review(
    String id, {
    required bool approve,
    String? reason,
  }) async {
    if (_isSubmitting || _user?.role != 'ADMIN') return false;
    final session = _session;
    _isSubmitting = true;
    _error = '';
    notifyListeners();
    try {
      await _repository.review(id, approve: approve, reason: reason);
      return session == _session;
    } catch (error) {
      if (session == _session) {
        _error = OwnerVerificationRepository.errorMessage(error);
      }
      return false;
    } finally {
      if (session == _session) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _session++;
    _loadVersion++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
