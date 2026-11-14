import '../../support/images/image_fixtures.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/features/admin/presentation/pages/owner_verification_page.dart';
import 'package:papikost_mobile/features/admin/presentation/providers/admin_provider.dart';
import '../../support/fixtures/verification_fixtures.dart';
import '../../support/fixtures/kost_fixtures.dart';
import '../../support/helpers/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockVerificationRepository repository;
  late StreamController<List<OwnerSubmission>> updates;
  late AdminProvider provider;
  setUp(() async {
    configureTestFonts();
    configureTestImages();
    await initializeDateFormatting('id_ID');
    repository = MockVerificationRepository();
    updates = StreamController<List<OwnerSubmission>>.broadcast();
    when(() => repository.watchAll()).thenAnswer((_) => updates.stream);
    provider = AdminProvider(repository: repository)
      ..bindUser(verificationAdmin);
  });
  tearDown(() async {
    provider.dispose();
    await updates.close();
  });

  Future<void> openDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: OwnerVerificationPage()),
      ),
    );
    await tester.pump();
    updates.add([submissionFixture()]);
    await tester.pump();
    await tester.tap(find.text('Owner A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'a new room appears in Proses and can be approved from its details',
    (tester) async {
      final room = OwnerSubmission.fromKost(testKost.id, {
        ...testKost.toJson(),
        'verificationStatus': 'PROSES',
      });
      when(() => repository.review(room.id, approve: true)).thenAnswer((
        _,
      ) async {
        updates.add([OwnerSubmission.fromKost(testKost.id, testKost.toJson())]);
      });
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: OwnerVerificationPage()),
        ),
      );
      await tester.pump();
      updates.add([room]);
      await tester.pump();
      expect(find.text('Pengajuan Kamar'), findsOneWidget);
      await tester.tap(find.text(testKost.name));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Jumlah kamar'), findsOneWidget);
      expect(find.text('No. KTP'), findsNothing);
      expect(find.text('Foto kamar belum ditambahkan.'), findsOneWidget);
      await tester.ensureVisible(find.text('ACC'));
      await tester.tap(find.text('ACC'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACC Sekarang'));
      await tester.pumpAndSettle();
      verify(
        () => repository.review('kost/${testKost.id}', approve: true),
      ).called(1);
      expect(provider.submissions.single.status, VerificationStatus.acc);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed approval displays the server message and keeps the detail open',
    (tester) async {
      when(
        () => repository.review('owner-a', approve: true),
      ).thenThrow(const AuthFailure('Pengajuan sudah diproses admin lain.'));
      await openDetail(tester);
      await tester.ensureVisible(find.text('ACC'));
      await tester.tap(find.text('ACC'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('ACC Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pengajuan sudah diproses admin lain.'), findsOneWidget);
      expect(find.text('Detail Verifikasi'), findsOneWidget);
      updates.add([submissionFixture(status: VerificationStatus.acc)]);
      await tester.pump();
      expect(find.text('Pengajuan Disetujui (ACC)'), findsOneWidget);
      expect(find.text('Tolak'), findsNothing);
    },
  );
  testWidgets(
    'admin must give a reason before rejection and sees saved result in the list',
    (tester) async {
      when(
        () => repository.review(
          'owner-a',
          approve: false,
          reason: 'Foto KTP tidak terbaca.',
        ),
      ).thenAnswer((_) async {
        updates.add([submissionFixture(status: VerificationStatus.tolak)]);
      });
      await openDetail(tester);
      await tester.ensureVisible(find.text('Tolak'));
      await tester.tap(find.text('Tolak'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Tolak Sekarang'));
      await tester.pump();
      expect(find.text('Alasan penolakan wajib diisi.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Foto KTP tidak terbaca.',
      );
      await tester.tap(find.text('Tolak Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Detail Verifikasi'), findsNothing);
      expect(provider.submissions.single.status, VerificationStatus.tolak);
      expect(tester.takeException(), isNull);
    },
  );
}
