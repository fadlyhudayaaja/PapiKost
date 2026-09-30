import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  static const _storage = FlutterSecureStorage();

  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    final resp = await DioClient.instance.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = resp.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;

    await _storage.write(key: AppConstants.tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      );
    }
    await _storage.write(key: AppConstants.userRoleKey, value: user.role);
    await _storage.write(
      key: AppConstants.userIdKey,
      value: user.id.toString(),
    );

    return (user: user, token: token);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    await DioClient.instance.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return null;
    final resp = await DioClient.instance.get('/auth/me');
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
