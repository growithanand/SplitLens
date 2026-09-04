import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/data/ml_kit_receipt_text_recognizer.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';

void main() {
  const image = ReceiptImage(
    path: 'synthetic-receipt.jpg',
    source: ReceiptImageSource.gallery,
  );

  group('MlKitReceiptTextRecognizer', () {
    test('returns the raw Latin recognition result unchanged', () async {
      final mlKitRecognizer = _FakeMlKitTextRecognizer(
        recognizedText: 'SYNTHETIC MARKT\nGESAMT 12,99 €\n',
      );
      final recognizer = MlKitReceiptTextRecognizer(
        textRecognizer: mlKitRecognizer,
        imagePathExists: (_) async => true,
      );

      final result = await recognizer.recognize(image);

      expect(result, isA<ReceiptTextRecognized>());
      expect(
        (result as ReceiptTextRecognized).rawText,
        'SYNTHETIC MARKT\nGESAMT 12,99 €\n',
      );
      expect(mlKitRecognizer.receivedImage?.filePath, image.path);
    });

    test('reports when the selected image no longer exists', () async {
      final mlKitRecognizer = _FakeMlKitTextRecognizer(
        recognizedText: 'unused',
      );
      final recognizer = MlKitReceiptTextRecognizer(
        textRecognizer: mlKitRecognizer,
        imagePathExists: (_) async => false,
      );

      final result = await recognizer.recognize(image);

      expect(
        (result as ReceiptTextRecognitionFailed).failure.code,
        ReceiptTextRecognitionFailureCode.imageUnavailable,
      );
      expect(mlKitRecognizer.receivedImage, isNull);
    });

    test('reports an empty recognition result as no text detected', () async {
      final recognizer = MlKitReceiptTextRecognizer(
        textRecognizer: _FakeMlKitTextRecognizer(recognizedText: '  \n  '),
        imagePathExists: (_) async => true,
      );

      final result = await recognizer.recognize(image);

      expect(
        (result as ReceiptTextRecognitionFailed).failure.code,
        ReceiptTextRecognitionFailureCode.noTextDetected,
      );
    });

    test('converts native recognition errors to a safe failure', () async {
      final recognizer = MlKitReceiptTextRecognizer(
        textRecognizer: _FakeMlKitTextRecognizer(
          error: StateError('private native detail'),
        ),
        imagePathExists: (_) async => true,
      );

      final result = await recognizer.recognize(image);

      final failure = (result as ReceiptTextRecognitionFailed).failure;
      expect(failure.code, ReceiptTextRecognitionFailureCode.processingFailed);
      expect(failure.message, isNot(contains('private native detail')));
    });

    test('closes the native recognizer only once', () async {
      final mlKitRecognizer = _FakeMlKitTextRecognizer(
        recognizedText: 'SYNTHETIC RECEIPT',
      );
      final recognizer = MlKitReceiptTextRecognizer(
        textRecognizer: mlKitRecognizer,
        imagePathExists: (_) async => true,
      );

      await recognizer.close();
      await recognizer.close();

      expect(mlKitRecognizer.closeCallCount, 1);
    });
  });
}

final class _FakeMlKitTextRecognizer extends TextRecognizer {
  _FakeMlKitTextRecognizer({this.recognizedText = '', this.error});

  final String recognizedText;
  final Object? error;
  InputImage? receivedImage;
  int closeCallCount = 0;

  @override
  Future<RecognizedText> processImage(InputImage inputImage) async {
    receivedImage = inputImage;
    if (error case final error?) {
      throw error;
    }

    return RecognizedText(text: recognizedText, blocks: []);
  }

  @override
  Future<void> close() async {
    closeCallCount += 1;
  }
}
