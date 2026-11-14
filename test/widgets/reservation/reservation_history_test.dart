import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:papikost_mobile/data/models/reservation_model.dart';
import 'package:papikost_mobile/data/repositories/reservation_repository.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:papikost_mobile/features/kost/presentation/pages/reservation_history_page.dart';
import '../../support/fixtures/auth_fixtures.dart';
import '../../support/fixtures/reservation_fixtures.dart';
import '../../support/helpers/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'history shows live status, real errors and clears when accounts change',
    (tester) async {
      configureTestFonts();
      await tester.runAsync(() async {
        await initializeDateFormatting('id_ID');
        GoogleFonts.poppinsTextTheme();
        GoogleFonts.poppins(fontWeight: FontWeight.w600);
        await GoogleFonts.pendingFonts();
      });
      final authRepository = MockAuthRepository();
      when(
        () => authRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testUser);
      when(() => authRepository.logout()).thenAnswer((_) async {});
      final auth = AuthProvider(repository: authRepository);
      addTearDown(auth.dispose);
      await auth.login(email: testUser.email, password: 'password');
      final repository = MockReservationRepository();
      final updates = StreamController<List<ReservationModel>>();
      final otherUpdates = StreamController<List<ReservationModel>>();
      addTearDown(updates.close);
      addTearDown(otherUpdates.close);
      when(
        () => repository.watchForRenter(testUser.id),
      ).thenAnswer((_) => updates.stream);
      when(
        () => repository.watchForRenter('other-renter'),
      ).thenAnswer((_) => otherUpdates.stream);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            Provider<ReservationRepository>.value(value: repository),
          ],
          child: const MaterialApp(home: ReservationHistoryPage()),
        ),
      );
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pump();
      updates.add([testReservation]);
      await tester.pump();
      expect(find.text('Kost Melati'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      updates.add([
        ReservationModel.fromJson({
          ...testReservation.toJson(),
          'status': 'APPROVED',
        }),
      ]);
      await tester.pump();
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Menunggu'), findsNothing);
      updates.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Akses reservasi ditolak'), findsOneWidget);
      expect(find.text('Kost Mawar Indah'), findsNothing);
      await auth.logout();
      await tester.pump();
      expect(find.text('Kost Melati'), findsNothing);
      when(
        () => authRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testUser.copyWith(id: 'other-renter'));
      await auth.login(email: 'other@example.com', password: 'password');
      await tester.pump();
      updates.add([testReservation]);
      otherUpdates.add([]);
      await tester.pump();
      expect(find.text('Kost Melati'), findsNothing);
      expect(find.text('Belum ada riwayat reservasi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
