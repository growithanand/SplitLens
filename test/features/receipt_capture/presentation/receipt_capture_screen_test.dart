import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_text_recognition_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/presentation/receipt_capture_screen.dart';

import '../../../support/fakes/fake_receipt_text_recognizer.dart';

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
      find.text(
        'Receipt image selected. It is ready for on-device text recognition.',
      ),
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

  testWidgets('shows raw OCR text returned for the selected image', (
    tester,
  ) async {
    final picker = FakeReceiptImagePicker(
      result: const ReceiptImageSelected(
        ReceiptImage(
          path: 'synthetic-receipt.png',
          source: ReceiptImageSource.gallery,
        ),
      ),
    );
    final recognizer = FakeReceiptTextRecognizer(
      result: const ReceiptTextRecognized(
        rawText: 'SYNTHETIC MARKET\nTOTAL 12.99 EUR',
      ),
    );
    await _pumpScreen(tester, picker, recognizer: recognizer);
    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();
    await _tapRecognizeText(tester);

    expect(find.text('Raw OCR text'), findsOneWidget);
    expect(find.text('SYNTHETIC MARKET\nTOTAL 12.99 EUR'), findsOneWidget);
    expect(find.byKey(const ValueKey('raw-ocr-text-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('review-receipt-button')), findsOneWidget);
    expect(recognizer.receivedImages, hasLength(1));
  });

  testWidgets('opens editable review after successful recognition', (
    tester,
  ) async {
    final picker = FakeReceiptImagePicker(
      result: const ReceiptImageSelected(
        ReceiptImage(
          path: 'synthetic-receipt.png',
          source: ReceiptImageSource.gallery,
        ),
      ),
    );
    final recognizer = FakeReceiptTextRecognizer(
      result: const ReceiptTextRecognized(
        rawText: 'SYNTHETIC MARKET LTD\nDATE 04.09.2026\nTOTAL 12.99 EUR',
      ),
    );
    await _pumpScreen(tester, picker, recognizer: recognizer);
    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();
    await _tapRecognizeText(tester);

    final reviewButton = find.byKey(const ValueKey('review-receipt-button'));
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Review receipt'), findsOneWidget);
    expect(find.text('Review receipt details'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('receipt-review-merchant-field')),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading state and disables image actions', (
    tester,
  ) async {
    final pendingResult = Completer<ReceiptTextRecognitionResult>();
    final picker = FakeReceiptImagePicker(
      result: const ReceiptImageSelected(
        ReceiptImage(
          path: 'synthetic-receipt.png',
          source: ReceiptImageSource.gallery,
        ),
      ),
    );
    final recognizer = FakeReceiptTextRecognizer(
      result: const ReceiptTextRecognized(rawText: 'unused'),
      onRecognize: (_) => pendingResult.future,
    );
    await _pumpScreen(tester, picker, recognizer: recognizer);
    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();

    final recognizeButton = find.byKey(const ValueKey('recognize-text-button'));
    await tester.ensureVisible(recognizeButton);
    await tester.tap(recognizeButton);
    await tester.pump();

    expect(
      find.text('Recognizing printed text on this device…'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(recognizeButton).onPressed, isNull);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('take-photo-button')))
          .onPressed,
      isNull,
    );

    pendingResult.complete(
      const ReceiptTextRecognized(rawText: 'SYNTHETIC RECEIPT'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows a recognition error and allows retrying', (tester) async {
    const message = 'No printed text was detected. Try a clearer image.';
    final picker = FakeReceiptImagePicker(
      result: const ReceiptImageSelected(
        ReceiptImage(
          path: 'synthetic-receipt.png',
          source: ReceiptImageSource.gallery,
        ),
      ),
    );
    final recognizer = FakeReceiptTextRecognizer(
      result: const ReceiptTextRecognitionFailed(
        ReceiptTextRecognitionFailure(
          code: ReceiptTextRecognitionFailureCode.noTextDetected,
          message: message,
        ),
      ),
    );
    await _pumpScreen(tester, picker, recognizer: recognizer);
    await tester.tap(find.byKey(const ValueKey('select-gallery-button')));
    await tester.pumpAndSettle();
    await _tapRecognizeText(tester);

    expect(find.text(message), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('recognize-text-button')),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ReceiptImagePicker picker, {
  FakeReceiptTextRecognizer? recognizer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        receiptImagePickerProvider.overrideWithValue(picker),
        receiptTextRecognizerProvider.overrideWithValue(
          recognizer ??
              FakeReceiptTextRecognizer(
                result: const ReceiptTextRecognized(
                  rawText: 'SYNTHETIC RECEIPT',
                ),
              ),
        ),
      ],
      child: const MaterialApp(home: ReceiptCaptureScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapRecognizeText(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('recognize-text-button'));
  await tester.ensureVisible(button);
  await tester.tap(button);
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
