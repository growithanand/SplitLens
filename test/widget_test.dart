import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/app/app.dart';
import 'package:splitlens/app/navigation/app_routes.dart';

void main() {
  testWidgets('configures the SplitLens application shell', (tester) async {
    await tester.pumpWidget(const SplitLensApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'SplitLens');
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
    expect(app.initialRoute, AppRoutes.home);
    expect(app.routes?.containsKey(AppRoutes.home), isTrue);
  });

  testWidgets('displays the temporary home screen', (tester) async {
    await tester.pumpWidget(const SplitLensApp());

    expect(find.text('SplitLens'), findsOneWidget);
    expect(find.text('Split receipts with confidence'), findsOneWidget);
    expect(find.text('Receipt workflow coming next'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
