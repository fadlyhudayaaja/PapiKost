import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/data/repositories/ticket_repository.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:papikost_mobile/features/renter/ticket/providers/renter_ticket_provider.dart';
import 'package:papikost_mobile/features/renter/ticket/pages/ticket_form_page.dart';
import 'support/auth_fixtures.dart';
import 'support/reservation_fixtures.dart';
import 'support/ticket_fixtures.dart';
import 'support/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'report form submits the selected real reservation and hides creation without one',
    (tester) async {
      configureTestFonts();
      await tester.runAsync(() async {
        await initializeDateFormatting('id_ID');
        GoogleFonts.poppinsTextTheme();
        GoogleFonts.poppins(fontWeight: FontWeight.w600);
        await GoogleFonts.pendingFonts();
      });
      registerFallbackValue(DateTime(2026));
      final authRepository = MockAuthRepository();
      when(
        () => authRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testUser);
      final auth = AuthProvider(repository: authRepository);
      await auth.login(email: testUser.email, password: 'password');
      addTearDown(auth.dispose);
      final repository = emptyTicketRepository();
      when(
        () => repository.eligibleReservations(testUser.id),
      ).thenAnswer((_) async => [testReservation]);
      when(
        () => repository.createTicket(
          reservationId: any(named: 'reservationId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          incidentDate: any(named: 'incidentDate'),
          imageUrls: any(named: 'imageUrls'),
        ),
      ).thenAnswer((_) async => testTicket);
      final tickets = RenterTicketProvider(repository: repository)
        ..bindUser(testUser);
      addTearDown(tickets.dispose);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/form'),
                child: const Text('Buka Formulir'),
              ),
            ),
          ),
          GoRoute(path: '/form', builder: (_, _) => const TicketFormPage()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<RenterTicketProvider>.value(value: tickets),
            Provider<TicketRepository>.value(value: repository),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.tap(find.text('Buka Formulir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Kost Melati').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        testTicket.title,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        testTicket.description,
      );
      await tester.ensureVisible(find.text('Kirim Laporan'));
      await tester.tap(find.text('Kirim Laporan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Buka Formulir'), findsOneWidget);
      verify(
        () => repository.createTicket(
          reservationId: testReservation.id,
          title: testTicket.title,
          description: testTicket.description,
          category: 'LISTRIK',
          incidentDate: any(named: 'incidentDate'),
          imageUrls: const [],
        ),
      ).called(1);

      when(
        () => repository.eligibleReservations(testUser.id),
      ).thenAnswer((_) async => []);
      await tester.tap(find.text('Buka Formulir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Belum ada reservasi yang disetujui'), findsOneWidget);
      expect(find.text('Kirim Laporan'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
