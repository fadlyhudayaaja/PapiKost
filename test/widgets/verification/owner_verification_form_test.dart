import '../../support/images/image_fixtures.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/data/models/owner_submission.dart';
import 'package:papikost_mobile/data/repositories/auth_repository.dart';
import 'package:papikost_mobile/data/repositories/owner_verification_repository.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:papikost_mobile/features/owner/presentation/pages/owner_verification_form_page.dart';
import '../../support/fixtures/auth_fixtures.dart';
import '../../support/fixtures/verification_fixtures.dart';
import '../../support/helpers/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockVerificationRepository repository;
  late AuthProvider auth;
  late StreamController<OwnerSubmission?> updates;
  setUp(() async {
    configureTestFonts();
    configureTestImages();
    repository = MockVerificationRepository();
    updates = StreamController<OwnerSubmission?>.broadcast();
    when(
      () => repository.watchForOwner('owner-a'),
    ).thenAnswer((_) => updates.stream);
    final accounts = MockAuthRepository();
    when(
      () => accounts.getCurrentUser(),
    ).thenAnswer((_) async => verificationOwner);
    auth = AuthProvider(repository: accounts);
    await auth.checkAuthStatus();
  });
  tearDown(() async {
    auth.dispose();
    await updates.close();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OwnerVerificationRepository>.value(value: repository),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(home: OwnerVerificationFormPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'pending submission changes to approved when admin stream updates',
    (tester) async {
      await open(tester);
      updates.add(submissionFixture());
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan sedang diperiksa admin'), findsOneWidget);
      expect(find.text('Kirim Pengajuan'), findsNothing);
      updates.add(submissionFixture(status: VerificationStatus.acc));
      await tester.pumpAndSettle();
      expect(find.text('Pemilik sudah terverifikasi'), findsOneWidget);
    },
  );
  testWidgets(
    'rejected owner can correct and resubmit documents, with server errors visible',
    (tester) async {
      when(
        () => repository.submit(
          ktpNumber: any(named: 'ktpNumber'),
          propertyName: any(named: 'propertyName'),
          propertyAddress: any(named: 'propertyAddress'),
          propertyType: any(named: 'propertyType'),
          ktpImageUrl: any(named: 'ktpImageUrl'),
          sertifikatImageUrl: any(named: 'sertifikatImageUrl'),
          fotoRumahImageUrl: any(named: 'fotoRumahImageUrl'),
        ),
      ).thenThrow(const AuthFailure('Pengajuan sudah dikirim.'));
      await open(tester);
      updates.add(submissionFixture(status: VerificationStatus.tolak));
      await tester.pumpAndSettle();
      expect(find.textContaining('Foto KTP tidak terbaca.'), findsOneWidget);
      final button = find.text('Kirim Ulang Pengajuan');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan sudah dikirim.'), findsOneWidget);
    },
  );
  testWidgets('empty form validates before sending', (tester) async {
    await open(tester);
    updates.add(null);
    await tester.pumpAndSettle();
    final button = find.text('Kirim Pengajuan');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Nomor KTP harus 16 angka.'), findsOneWidget);
    verifyNever(
      () => repository.submit(
        ktpNumber: any(named: 'ktpNumber'),
        propertyName: any(named: 'propertyName'),
        propertyAddress: any(named: 'propertyAddress'),
        propertyType: any(named: 'propertyType'),
        ktpImageUrl: any(named: 'ktpImageUrl'),
        sertifikatImageUrl: any(named: 'sertifikatImageUrl'),
        fotoRumahImageUrl: any(named: 'fotoRumahImageUrl'),
      ),
    );
  });
}
