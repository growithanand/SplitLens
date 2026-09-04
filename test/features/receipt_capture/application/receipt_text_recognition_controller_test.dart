import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_text_recognition_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';

import '../../../support/fakes/fake_receipt_text_recognizer.dart';

void main() {
  const image = ReceiptImage(
    path: 'synthetic-receipt.jpg',
    source: ReceiptImageSource.gallery,
  );

  group('ReceiptTextRecognitionController', () {
    test('starts idle without text or an error', () {
      final container = _createContainer(
        FakeReceiptTextRecognizer(
          result: const ReceiptTextRecognized(rawText: 'unused'),
        ),
      );
      addTearDown(container.dispose);

      final state = container.read(receiptTextRecognitionControllerProvider);

      expect(state.status, ReceiptTextRecognitionStatus.idle);
      expect(state.rawText, isNull);
      expect(state.errorMessage, isNull);
    });

    test('exposes recognizing and successful raw-text states', () async {
      final pendingResult = Completer<ReceiptTextRecognitionResult>();
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognized(rawText: 'unused'),
        onRecognize: (_) => pendingResult.future,
      );
      final container = _createContainer(recognizer);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptTextRecognitionControllerProvider.notifier,
      );

      final recognition = controller.recognize(image);

      final loadingState = container.read(
        receiptTextRecognitionControllerProvider,
      );
      expect(loadingState.status, ReceiptTextRecognitionStatus.recognizing);
      expect(loadingState.imagePath, image.path);

      pendingResult.complete(
        const ReceiptTextRecognized(rawText: 'SYNTHETIC RECEIPT'),
      );
      await recognition;

      final successState = container.read(
        receiptTextRecognitionControllerProvider,
      );
      expect(successState.status, ReceiptTextRecognitionStatus.success);
      expect(successState.rawText, 'SYNTHETIC RECEIPT');
      expect(successState.imagePath, image.path);
    });

    test('exposes a safe recognition failure', () async {
      const message = 'No printed text was detected.';
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognitionFailed(
          ReceiptTextRecognitionFailure(
            code: ReceiptTextRecognitionFailureCode.noTextDetected,
            message: message,
          ),
        ),
      );
      final container = _createContainer(recognizer);
      addTearDown(container.dispose);

      await container
          .read(receiptTextRecognitionControllerProvider.notifier)
          .recognize(image);

      final state = container.read(receiptTextRecognitionControllerProvider);
      expect(state.status, ReceiptTextRecognitionStatus.failure);
      expect(state.errorMessage, message);
      expect(state.rawText, isNull);
    });

    test('ignores another request while recognition is running', () async {
      final pendingResult = Completer<ReceiptTextRecognitionResult>();
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognized(rawText: 'unused'),
        onRecognize: (_) => pendingResult.future,
      );
      final container = _createContainer(recognizer);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptTextRecognitionControllerProvider.notifier,
      );

      final firstRecognition = controller.recognize(image);
      await controller.recognize(image);

      expect(recognizer.receivedImages, hasLength(1));
      pendingResult.complete(
        const ReceiptTextRecognized(rawText: 'SYNTHETIC RECEIPT'),
      );
      await firstRecognition;
    });

    test('clears a completed result when the selected image changes', () async {
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognized(rawText: 'SYNTHETIC RECEIPT'),
      );
      final container = _createContainer(recognizer);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptTextRecognitionControllerProvider.notifier,
      );
      await controller.recognize(image);

      controller.clear();

      final state = container.read(receiptTextRecognitionControllerProvider);
      expect(state.status, ReceiptTextRecognitionStatus.idle);
      expect(state.rawText, isNull);
      expect(state.imagePath, isNull);
    });
  });
}

ProviderContainer _createContainer(FakeReceiptTextRecognizer recognizer) {
  return ProviderContainer(
    overrides: [receiptTextRecognizerProvider.overrideWithValue(recognizer)],
  );
}
