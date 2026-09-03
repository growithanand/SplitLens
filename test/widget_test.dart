import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/app/app.dart';
import 'package:splitlens/app/navigation/app_routes.dart';

void main() {
  testWidgets('configures the SplitLens application shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SplitLensApp()));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'SplitLens');
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
    expect(app.initialRoute, AppRoutes.home);
    expect(app.routes?.containsKey(AppRoutes.home), isTrue);
    expect(app.routes?.containsKey(AppRoutes.expenseSplit), isTrue);
  });

  testWidgets('opens the manual split workflow from home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SplitLensApp()));

    expect(find.text('SplitLens'), findsOneWidget);
    expect(find.text('Split receipts with confidence'), findsOneWidget);
    expect(find.text('Manual splitting is ready'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

    final startButton = find.text('Start a manual split');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Split an expense'), findsOneWidget);
    expect(find.text('Enter the receipt total'), findsOneWidget);
  });
}
