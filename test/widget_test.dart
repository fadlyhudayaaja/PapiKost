import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/core/router/app_router.dart';
import 'package:papikost_mobile/core/constants/app_constants.dart';
import 'package:papikost_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:papikost_mobile/features/renter/ticket/pages/ticket_list_page.dart';
import 'package:papikost_mobile/main.dart' as app;
import 'support/auth_fixtures.dart';
import 'support/test_fonts.dart';
import 'support/kost_fixtures.dart';
import 'support/ticket_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  testWidgets('main initializes Indonesian dates before showing tickets', (
    WidgetTester tester,
  ) async {
    // Sesi mock lama tidak boleh memberi akses admin.
    FlutterSecureStorage.setMockInitialValues({
      AppConstants.tokenKey: 'mock_jwt_token',
      AppConstants.userRoleKey: 'ADMIN',
    });
    final repository = MockAuthRepository();
    final kostRepository = MockKostRepository();
    when(
      () => kostRepository.watchAll(),
    ).thenAnswer((_) => Stream.value([testKost]));
    configureTestFonts();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
    when(
      () => repository.login(email: testUser.email, password: 'test-pass'),
    ).thenAnswer((_) async => testUser);
    await tester.runAsync(
      () => app.runPapiKost(
        authRepository: repository,
        kostRepository: kostRepository,
        ticketRepository: emptyTicketRepository(),
      ),
    );
    await tester.pump();
    expect(Firebase.app().name, '[DEFAULT]');
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(Intl.defaultLocale, 'id_ID');
    expect(
      DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime(2026, 8, 17)),
      '17 Agustus 2026',
    );

    // runApp dapat memulai timer splash di zona runAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3100)),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LoginPage), findsOneWidget);
    final loginContext = tester.element(find.byType(LoginPage));
    final auth = loginContext.read<AuthProvider>();
    await auth.login(email: testUser.email, password: 'test-pass');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(AppRoutes.renterTickets);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(RenterTicketListPage), findsOneWidget);
    expect(find.text('Laporan Kerusakan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Selesaikan inisialisasi splash yang sempat dimulai oleh main().
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}
