import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papikost_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:papikost_mobile/main.dart';

void main() {
  testWidgets('PapiKost app starts without crashing', (
    WidgetTester tester,
  ) async {
    final auth = AuthProvider();
    await tester.pumpWidget(PapiKostApp(authProvider: auth));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
