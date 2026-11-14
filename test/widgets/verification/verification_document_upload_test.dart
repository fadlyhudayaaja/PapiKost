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
    ).thenAnswer((_) async {});
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
    updates.add(submissionFixture(status: VerificationStatus.tolak));
    await tester.pumpAndSettle();
  }

  Future<void> enterUrl(WidgetTester tester, String key, String url) async {
    final field = find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, url);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('Kirim Ulang Pengajuan');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'three document URLs are saved without an uploader or Storage dependency',
    (tester) async {
      await open(tester);
      await enterUrl(tester, 'url-ktp', '  https://example.com/new-ktp.jpg  ');
      await submit(tester);
      verify(
        () => repository.submit(
          ktpNumber: any(named: 'ktpNumber'),
          propertyName: any(named: 'propertyName'),
          propertyAddress: any(named: 'propertyAddress'),
          propertyType: any(named: 'propertyType'),
          ktpImageUrl: 'https://example.com/new-ktp.jpg',
          sertifikatImageUrl: 'https://example.com/sertifikat.jpg',
          fotoRumahImageUrl: 'https://example.com/kost.jpg',
        ),
      ).called(1);
      expect(find.text('Pengajuan berhasil dikirim.'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsNothing);
    },
  );

  testWidgets('invalid document URL blocks submission and can be corrected', (
    tester,
  ) async {
    await open(tester);
    await enterUrl(
      tester,
      'url-ktp',
      'verificationDocuments/owner-a/old/ktp.jpg',
    );
    await submit(tester);
    expect(find.textContaining('Masukkan URL foto HTTPS'), findsOneWidget);
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
    await enterUrl(tester, 'url-ktp', 'https://example.com/correct.jpg');
    await submit(tester);
    expect(find.text('Pengajuan berhasil dikirim.'), findsOneWidget);
  });

  testWidgets('server failure retains entered document URLs for retry', (
    tester,
  ) async {
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
    ).thenThrow(const AuthFailure('Koneksi terputus.'));
    await open(tester);
    await enterUrl(tester, 'url-ktp', 'https://example.com/retry.jpg');
    await submit(tester);
    expect(find.text('Koneksi terputus.'), findsOneWidget);
    expect(find.text('https://example.com/retry.jpg'), findsOneWidget);
  });
}
