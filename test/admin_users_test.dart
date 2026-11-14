import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/core/router/app_router.dart';
import 'package:papikost_mobile/data/models/user_model.dart';
import 'package:papikost_mobile/data/repositories/admin_user_repository.dart';
import 'package:papikost_mobile/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:papikost_mobile/features/admin/presentation/pages/admin_users_page.dart';
import 'package:papikost_mobile/features/admin/presentation/pages/owner_verification_page.dart';
import 'package:papikost_mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:papikost_mobile/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'support/auth_fixtures.dart';
import 'support/test_fonts.dart';
import 'support/verification_fixtures.dart';

class _Repository extends Mock implements AdminUserRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late StreamController<List<UserModel>> updates;
  late AdminUsersProvider provider;
  setUp(() async {
    configureTestFonts();
    await initializeDateFormatting('id_ID');
    repository = _Repository();
    updates = StreamController<List<UserModel>>.broadcast();
    when(() => repository.watchUsers()).thenAnswer((_) => updates.stream);
    provider = AdminUsersProvider(repository: repository)
      ..bindUser(verificationAdmin);
  });
  tearDown(() async {
    provider.dispose();
    await updates.close();
  });

  testWidgets(
    'dashboard menu opens real user route, searches, filters and displays details',
    (tester) async {
      final accounts = MockAuthRepository();
      when(
        () => accounts.getCurrentUser(),
      ).thenAnswer((_) async => verificationAdmin);
      final auth = AuthProvider(repository: accounts);
      await auth.checkAuthStatus();
      final verifications = MockVerificationRepository();
      when(() => verifications.watchAll()).thenAnswer((_) => Stream.value([]));
      final admin = AdminProvider(repository: verifications)
        ..bindUser(verificationAdmin);
      final router = createRouter(auth);
      router.go(AppRoutes.adminDashboard);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AdminUsersProvider>.value(value: provider),
            ChangeNotifierProvider<AdminProvider>.value(value: admin),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardPage), findsOneWidget);
      await tester.tap(find.text('Manajemen Pengguna'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AdminUsersPage), findsOneWidget);
      updates.add([verificationOwner, verificationAdmin, testUser]);
      await tester.pumpAndSettle();
      expect(find.text('3 dari 3 pengguna'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'OWNER@EXAMPLE');
      await tester.pumpAndSettle();
      expect(find.text('1 dari 3 pengguna'), findsOneWidget);
      await tester.tap(find.text('Owner A'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Pengguna'), findsOneWidget);
      expect(find.text('owner-a'), findsOneWidget);
      expect(find.text('Belum terverifikasi'), findsOneWidget);
      // Route, bukan hanya callback menu, dipakai juga dari detail pemilik.
      await tester.tap(find.text('Buka Verifikasi Pemilik'));
      await tester.pumpAndSettle();
      expect(find.byType(OwnerVerificationPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      auth.dispose();
      admin.dispose();
    },
  );

  testWidgets('permission failures offer a retry and recover with live data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: AdminUsersPage()),
      ),
    );
    await tester.pump();
    updates.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('aturan Firestore terbaru'), findsOneWidget);
    expect(find.text('Belum ada pengguna terdaftar.'), findsNothing);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(updates.hasListener, true);
    updates.add([verificationOwner]);
    await tester.pumpAndSettle();
    expect(find.text('Owner A'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Penyewa'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada pengguna yang cocok.'), findsOneWidget);
  });

  test(
    'sign out clears users, role filter and the previous subscription',
    () async {
      await provider.load();
      updates.add([verificationOwner, testUser]);
      await Future<void>.delayed(Duration.zero);
      provider.filterRole('OWNER');
      expect(provider.users.single.id, 'owner-a');
      provider.bindUser(null);
      updates.add([verificationOwner]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.users, isEmpty);
      expect(provider.total, 0);
      expect(provider.role, isNull);
      expect(provider.state, UsersLoadState.initial);
    },
  );

  test(
    'owner and renter accounts cannot start a user list subscription',
    () async {
      provider.bindUser(verificationOwner);
      await provider.load();
      provider.bindUser(testUser);
      await provider.load();
      verifyNever(() => repository.watchUsers());
    },
  );
}
