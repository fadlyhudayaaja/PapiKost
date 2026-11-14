import 'support/image_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/data/models/kost_model.dart';
import 'package:papikost_mobile/features/owner/presentation/pages/kost_management_page.dart';
import 'package:papikost_mobile/features/owner/presentation/providers/owner_provider.dart';
import 'package:papikost_mobile/core/widgets/url_image.dart';
import 'support/kost_fixtures.dart';
import 'support/test_fonts.dart';

class _Owner extends Mock implements OwnerProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Owner owner;
  setUp(() {
    configureTestFonts();
    configureTestImages();
    owner = _Owner();
    when(() => owner.isSubmitting).thenReturn(false);
    when(() => owner.errorMessage).thenReturn('Gagal menyimpan kamar.');
    when(
      () => owner.updateKost(
        id: any(named: 'id'),
        name: any(named: 'name'),
        address: any(named: 'address'),
        city: any(named: 'city'),
        pricePerMonth: any(named: 'pricePerMonth'),
        type: any(named: 'type'),
        totalRooms: any(named: 'totalRooms'),
        isSplitBillAvailable: any(named: 'isSplitBillAvailable'),
        facilities: any(named: 'facilities'),
        description: any(named: 'description'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => owner.addKost(
        name: any(named: 'name'),
        address: any(named: 'address'),
        city: any(named: 'city'),
        pricePerMonth: any(named: 'pricePerMonth'),
        type: any(named: 'type'),
        totalRooms: any(named: 'totalRooms'),
        isSplitBillAvailable: any(named: 'isSplitBillAvailable'),
        facilities: any(named: 'facilities'),
        description: any(named: 'description'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenAnswer((_) async => true);
  });

  Future<void> open(
    WidgetTester tester, {
    KostModel? listing = testKost,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<OwnerProvider>.value(
        value: owner,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => KostFormPage(existingKost: listing),
                  ),
                ),
                child: const Text('Buka Form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka Form'));
    await tester.pumpAndSettle();
  }

  Future<void> enterPhoto(WidgetTester tester, String url) async {
    final field = find.descendant(
      of: find.byKey(const Key('kost-photo-url')),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, url);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {bool create = false}) async {
    final button = find.widgetWithText(
      ElevatedButton,
      create ? 'Tambah Kamar' : 'Simpan Perubahan',
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  void verifySavedPhoto(String? value) {
    verify(
      () => owner.updateKost(
        id: testKost.id,
        name: testKost.name,
        address: testKost.address,
        city: testKost.city,
        pricePerMonth: testKost.pricePerMonth,
        type: testKost.type,
        totalRooms: testKost.totalRooms,
        isSplitBillAvailable: testKost.isSplitBillAvailable,
        facilities: testKost.facilities,
        description: null,
        photoUrl: value,
      ),
    ).called(1);
  }

  testWidgets(
    'saving an edited room stores the trimmed URL without Storage providers',
    (tester) async {
      await open(tester);
      await enterPhoto(tester, '  https://example.com/kamar.jpg?token=abc  ');
      await save(tester);
      verifySavedPhoto('https://example.com/kamar.jpg?token=abc');
      expect(find.byType(KostFormPage), findsNothing);
    },
  );

  testWidgets(
    'existing Drive share links preview and save without changing the stored URL',
    (tester) async {
      const share =
          'https://drive.google.com/file/d/room_123456/view?usp=drive_link';
      final listing = KostModel.fromJson({
        ...testKost.toJson(),
        'imageUrls': [share],
      });
      await open(tester, listing: listing);
      expect(tester.widget<UrlImage>(find.byType(UrlImage)).imageUrl, share);
      expect(find.textContaining('Periksa izin akses file'), findsOneWidget);
      await save(tester);
      verifySavedPhoto(share);
    },
  );

  testWidgets('invalid and local photo references prevent saving', (
    tester,
  ) async {
    await open(tester);
    for (final url in [
      'file:///foto.jpg',
      'http://example.com/foto.jpg',
      'https://user:pass@example.com/foto.jpg',
    ]) {
      await enterPhoto(tester, url);
      await save(tester);
      expect(find.textContaining('Masukkan URL foto HTTPS'), findsOneWidget);
      expect(find.byType(KostFormPage), findsOneWidget);
    }
    verifyNever(
      () => owner.updateKost(
        id: any(named: 'id'),
        name: any(named: 'name'),
        address: any(named: 'address'),
        city: any(named: 'city'),
        pricePerMonth: any(named: 'pricePerMonth'),
        type: any(named: 'type'),
        totalRooms: any(named: 'totalRooms'),
        isSplitBillAvailable: any(named: 'isSplitBillAvailable'),
        facilities: any(named: 'facilities'),
        description: any(named: 'description'),
        photoUrl: any(named: 'photoUrl'),
      ),
    );
  });

  testWidgets(
    'editing retains an existing URL and clearing it removes the photo',
    (tester) async {
      final listing = KostModel.fromJson({
        ...testKost.toJson(),
        'imageUrls': ['https://example.com/old.jpg'],
      });
      await open(tester, listing: listing);
      expect(find.text('https://example.com/old.jpg'), findsOneWidget);
      await enterPhoto(tester, '');
      await save(tester);
      verifySavedPhoto(null);
    },
  );

  testWidgets('new room saves its external photo URL', (tester) async {
    await open(tester, listing: null);
    await enterPhoto(tester, 'https://example.com/new.jpg');
    for (final entry in {
      'Nama Kost *': testKost.name,
      'Alamat Lengkap *': testKost.address,
      'Harga/Bulan (Rp) *': '1000000',
      'Total Kamar *': '5',
    }.entries) {
      final field = find.widgetWithText(TextFormField, entry.key);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    final wifi = find.widgetWithText(FilterChip, 'WiFi');
    await tester.ensureVisible(wifi);
    await tester.tap(wifi);
    await save(tester, create: true);
    verify(
      () => owner.addKost(
        name: testKost.name,
        address: testKost.address,
        city: 'Medan',
        pricePerMonth: 1000000,
        type: 'CAMPUR',
        totalRooms: 5,
        isSplitBillAvailable: false,
        facilities: ['WiFi'],
        description: null,
        photoUrl: 'https://example.com/new.jpg',
      ),
    ).called(1);
  });
}
