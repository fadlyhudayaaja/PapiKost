import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/admin_user_repository.dart';

enum UsersLoadState { initial, loading, loaded, error }

class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider({AdminUserRepository? repository})
    : _repository = repository ?? AdminUserRepository.instance;
  final AdminUserRepository _repository;
  StreamSubscription<List<UserModel>>? _subscription;
  UserModel? _admin;
  int _version = 0;
  List<UserModel> _users = [];
  UsersLoadState _state = UsersLoadState.initial;
  String? _error;
  String _search = '';
  String? _role;

  UsersLoadState get state => _state;
  String? get error => _error;
  String? get role => _role;
  int get total => _users.length;
  List<UserModel> get users => List.unmodifiable(
    _users.where(
      (user) =>
          (_role == null || user.role == _role) &&
          [
            user.name,
            user.email,
            user.phone,
            user.id,
          ].any((value) => value.toLowerCase().contains(_search)),
    ),
  );
  UserModel? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  void bindUser(UserModel? admin) {
    if (_admin?.id == admin?.id && _admin?.role == admin?.role) return;
    _version++;
    _admin = admin;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _users = [];
    _state = UsersLoadState.initial;
    _error = null;
    _search = '';
    _role = null;
  }

  void search(String value) {
    _search = value.trim().toLowerCase();
    notifyListeners();
  }

  void filterRole(String? role) {
    _role = role;
    notifyListeners();
  }

  Future<void> load() async {
    if (_admin?.role != 'ADMIN') return;
    final version = ++_version;
    _state = UsersLoadState.loading;
    _error = null;
    notifyListeners();
    // Versi menolak event lama; retry tidak perlu menunggu penutupan stream lama.
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _subscription = _repository.watchUsers().listen(
        (users) {
          if (version != _version) return;
          _users = users;
          _state = UsersLoadState.loaded;
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          if (version != _version) return;
          _users = [];
          _state = UsersLoadState.error;
          _error = AdminUserRepository.errorMessage(error);
          notifyListeners();
        },
      );
    } catch (error) {
      if (version != _version) return;
      _users = [];
      _state = UsersLoadState.error;
      _error = AdminUserRepository.errorMessage(error);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _version++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
