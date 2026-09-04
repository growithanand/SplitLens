import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';
import 'package:splitlens/features/receipt_capture/presentation/receipt_capture_screen.dart';

void main() {
  testWidgets('shows an empty receipt-selection interface', (tester) async {
    await _pumpScreen(tester, FakeReceiptImagePicker());

    expect(find.text('Choose a receipt image'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-receipt-preview')), findsOneWidget);
    expect(find.text('No receipt image selected'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Select from gallery'), findsOneWidget);
  });

  testWidgets('shows a preview after selecting a camera image', (tester) async {
    final picker = FakeReceiptImagePicker(
      result: const ReceiptImageSelected(
        ReceiptImage(
          path: 'synthetic-receipt.png',
          source: ReceiptImageSource.camera,
        ),
      ),
    );
    await _pumpScreen(tester, picker);

    await tester.tap(find.byKey(const ValueKey('take-photo-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-receipt-preview')),
      findsOneWidget,
    );
    expect(
      find.text('Receipt image selected. OCR has not been run yet.'),
      findsOneWidget,
    );
    expect(picker.lastSource, ReceiptImageSource.camera);
  });

  testWidgets('shows cancellation without fabricating an error', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      FakeReceiptImagePicker(result: const ReceiptImageCancelled()),
    );

    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Image selection was cancelled. Nothing changed.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('shows a visible picker error and allows another attempt', (
    tester,
  ) async {
    const message = 'The gallery could not provide an image.';
    await _pumpScreen(
      tester,
      FakeReceiptImagePicker(result: const ReceiptImageFailure(message)),
    );

    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Select from gallery'),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpScreen(WidgetTester tester, ReceiptImagePicker picker) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [receiptImagePickerProvider.overrideWithValue(picker)],
      child: const MaterialApp(home: ReceiptCaptureScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

final class FakeReceiptImagePicker implements ReceiptImagePicker {
  FakeReceiptImagePicker({
    this.result = const ReceiptImageCancelled(),
    this.recoveredResult,
  });

  final ReceiptImagePickResult result;
  final ReceiptImagePickResult? recoveredResult;
  ReceiptImageSource? lastSource;

  @override
  Future<ReceiptImagePickResult> pickImage(ReceiptImageSource source) async {
    lastSource = source;
    return result;
  }

  @override
  Future<ReceiptImagePickResult?> recoverLostImage() async => recoveredResult;
}
