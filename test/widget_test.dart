import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/app/app.dart';
import 'package:splitlens/app/navigation/app_routes.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';

void main() {
  testWidgets('configures the SplitLens application shell', (tester) async {
    await _pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'SplitLens');
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
    expect(app.initialRoute, AppRoutes.home);
    expect(app.routes?.containsKey(AppRoutes.home), isTrue);
    expect(app.routes?.containsKey(AppRoutes.expenseSplit), isTrue);
    expect(app.routes?.containsKey(AppRoutes.receiptCapture), isTrue);
  });

  testWidgets('opens receipt capture from home', (tester) async {
    await _pumpApp(tester);

    expect(find.text('SplitLens'), findsOneWidget);
    expect(find.text('Split receipts with confidence'), findsOneWidget);
    expect(find.text('Add a receipt image'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

    final startButton = find.text('Add a receipt');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Add a receipt'), findsOneWidget);
    expect(find.text('Choose a receipt image'), findsOneWidget);
  });

  testWidgets('keeps the manual split workflow available from home', (
    tester,
  ) async {
    await _pumpApp(tester);

    final startButton = find.text('Start a manual split');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Split an expense'), findsOneWidget);
    expect(find.text('Enter the receipt total'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        receiptImagePickerProvider.overrideWithValue(
          const _NoopReceiptImagePicker(),
        ),
      ],
      child: const SplitLensApp(),
    ),
  );
}

final class _NoopReceiptImagePicker implements ReceiptImagePicker {
  const _NoopReceiptImagePicker();

  @override
  Future<ReceiptImagePickResult> pickImage(ReceiptImageSource source) async {
    return const ReceiptImageCancelled();
  }

  @override
  Future<ReceiptImagePickResult?> recoverLostImage() async => null;
}
