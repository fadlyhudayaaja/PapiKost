import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:papikost_mobile/data/models/kost_model.dart';
import 'package:papikost_mobile/data/repositories/kost_repository.dart';
import 'package:papikost_mobile/features/renter/catalog/pages/catalog_page.dart';
import '../../support/fixtures/kost_fixtures.dart';
import '../../support/helpers/test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'catalogue reflects Firestore changes and filters without refetching',
    (tester) async {
      configureTestFonts();
      await tester.runAsync(() async {
        GoogleFonts.poppinsTextTheme();
        GoogleFonts.poppins(fontWeight: FontWeight.w600);
        await GoogleFonts.pendingFonts();
      });
      final repository = MockKostRepository();
      final updates = StreamController<List<KostModel>>();
      addTearDown(updates.close);
      when(() => repository.watchAll()).thenAnswer((_) => updates.stream);
      await tester.pumpWidget(
        Provider<KostRepository>.value(
          value: repository,
          child: const MaterialApp(home: CatalogPage()),
        ),
      );
      await tester.pump();
      updates.add([testKost]);
      await tester.pump();
      expect(find.text('Kost Melati'), findsOneWidget);
      final second = KostModel.fromJson({
        ...testKost.toJson(),
        'id': 'listing-b',
        'name': 'Kost Baru',
      });
      updates.add([testKost, second]);
      await tester.pump();
      expect(find.text('Kost Baru'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Baru');
      await tester.pump();
      expect(find.text('Kost Baru'), findsOneWidget);
      expect(find.text('Kost Melati'), findsNothing);
      verify(() => repository.watchAll()).called(1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
