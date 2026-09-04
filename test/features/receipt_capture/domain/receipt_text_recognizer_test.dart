import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';

import '../../../support/fakes/fake_receipt_text_recognizer.dart';

void main() {
  group('receipt text recognition models', () {
    test('preserve raw recognized text exactly', () {
      const result = ReceiptTextRecognized(
        rawText: 'SYNTHETIC MARKET\nTOTAL 12,99 EUR\n',
      );

      expect(result.rawText, 'SYNTHETIC MARKET\nTOTAL 12,99 EUR\n');
    });

    test('expose a stable failure code and safe message', () {
      const failure = ReceiptTextRecognitionFailure(
        code: ReceiptTextRecognitionFailureCode.noTextDetected,
        message: 'No printed text was detected. Try a clearer image.',
      );
      const result = ReceiptTextRecognitionFailed(failure);

      expect(
        result.failure.code,
        ReceiptTextRecognitionFailureCode.noTextDetected,
      );
      expect(
        result.failure.message,
        'No printed text was detected. Try a clearer image.',
      );
    });
  });

  group('FakeReceiptTextRecognizer', () {
    const image = ReceiptImage(
      path: 'synthetic-receipt.jpg',
      source: ReceiptImageSource.gallery,
    );

    test('returns its configured result and records the image', () async {
      const configuredResult = ReceiptTextRecognized(
        rawText: 'SYNTHETIC RECEIPT',
      );
      final recognizer = FakeReceiptTextRecognizer(result: configuredResult);

      final result = await recognizer.recognize(image);

      expect(result, same(configuredResult));
      expect(recognizer.receivedImages, [same(image)]);
    });

    test('supports asynchronous recognition behavior', () async {
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognized(rawText: ''),
        onRecognize: (receivedImage) async {
          expect(receivedImage, same(image));
          return const ReceiptTextRecognitionFailed(
            ReceiptTextRecognitionFailure(
              code: ReceiptTextRecognitionFailureCode.processingFailed,
              message: 'The image could not be processed.',
            ),
          );
        },
      );

      final result = await recognizer.recognize(image);

      expect(result, isA<ReceiptTextRecognitionFailed>());
    });

    test('records when its resources are closed', () async {
      final recognizer = FakeReceiptTextRecognizer(
        result: const ReceiptTextRecognized(rawText: 'SYNTHETIC RECEIPT'),
      );

      await recognizer.close();

      expect(recognizer.isClosed, isTrue);
    });
  });
}
