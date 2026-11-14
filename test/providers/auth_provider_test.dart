import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';

import '../support/fixtures/auth_fixtures.dart';

void main() {
  late MockAuthRepository repository;
  late AuthProvider provider;

  setUp(() {
    repository = MockAuthRepository();
    provider = AuthProvider(repository: repository);
    when(() => repository.logout()).thenAnswer((_) async {});
  });
  tearDown(() => provider.dispose());

  test(
    'successful login retains Firebase UID, profile and pending verification',
    () async {
      when(
        () =>
            repository.login(email: 'siti@example.com', password: 'test-pass'),
      ).thenAnswer((_) async => testUser);
      expect(
        await provider.login(email: 'siti@example.com', password: 'test-pass'),
        true,
      );
      expect(provider.currentUser, testUser);
      expect(provider.isRenter, true);
      expect(provider.currentUser!.isVerified, false);
      await provider.logout();
      expect(provider.currentUser, isNull);
      expect(provider.status, AuthStatus.unauthenticated);
    },
  );

  test('invalid credentials leave no authenticated user', () async {
    when(
      () => repository.login(email: 'siti@example.com', password: 'wrong'),
    ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    expect(
      await provider.login(email: 'siti@example.com', password: 'wrong'),
      false,
    );
    expect(provider.isAuthenticated, false);
    expect(provider.currentUser, isNull);
    expect(provider.errorMessage, 'Email atau password tidak sesuai.');
  });

  test('registration returns to login without authenticating the UI', () async {
    when(
      () => repository.register(
        name: 'Siti',
        email: 'siti@example.com',
        password: 'test-pass',
        phone: '081234567890',
        role: 'RENTER',
      ),
    ).thenAnswer((_) async {});
    expect(
      await provider.register(
        name: 'Siti',
        email: 'siti@example.com',
        password: 'test-pass',
        phone: '081234567890',
        role: 'RENTER',
      ),
      true,
    );
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.currentUser, isNull);
  });

  test('a missing Firebase session remains unauthenticated', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
    await provider.checkAuthStatus();
    expect(provider.status, AuthStatus.unauthenticated);
  });

  test('a late profile refresh cannot restore a logged-out user', () async {
    final pending = Completer<UserModel?>();
    when(() => repository.getCurrentUser()).thenAnswer((_) => pending.future);
    final refresh = provider.refreshProfile();
    await provider.logout();
    pending.complete(testUser);
    await refresh;
    expect(provider.currentUser, isNull);
    expect(provider.isAuthenticated, false);
  });
}
