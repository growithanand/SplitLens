import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognizer.dart';

typedef ImagePathExists = Future<bool> Function(String path);

final class MlKitReceiptTextRecognizer implements ReceiptTextRecognizer {
  MlKitReceiptTextRecognizer({
    TextRecognizer? textRecognizer,
    ImagePathExists? imagePathExists,
  }) : _textRecognizer =
           textRecognizer ??
           TextRecognizer(script: TextRecognitionScript.latin),
       _imagePathExists = imagePathExists ?? _fileExists;

  final TextRecognizer _textRecognizer;
  final ImagePathExists _imagePathExists;
  bool _isClosed = false;

  @override
  Future<ReceiptTextRecognitionResult> recognize(ReceiptImage image) async {
    if (_isClosed) {
      return const ReceiptTextRecognitionFailed(
        ReceiptTextRecognitionFailure(
          code: ReceiptTextRecognitionFailureCode.processingFailed,
          message: 'Text recognition is unavailable. Reopen this screen.',
        ),
      );
    }

    try {
      if (!await _imagePathExists(image.path)) {
        return const ReceiptTextRecognitionFailed(
          ReceiptTextRecognitionFailure(
            code: ReceiptTextRecognitionFailureCode.imageUnavailable,
            message:
                'The selected receipt image is no longer available. Select '
                'it again.',
          ),
        );
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      if (recognizedText.text.trim().isEmpty) {
        return const ReceiptTextRecognitionFailed(
          ReceiptTextRecognitionFailure(
            code: ReceiptTextRecognitionFailureCode.noTextDetected,
            message:
                'No printed text was detected. Try a clearer receipt image.',
          ),
        );
      }

      return ReceiptTextRecognized(rawText: recognizedText.text);
    } on Object {
      return const ReceiptTextRecognitionFailed(
        ReceiptTextRecognitionFailure(
          code: ReceiptTextRecognitionFailureCode.processingFailed,
          message:
              'The receipt text could not be recognized. Try again or choose '
              'another image.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    await _textRecognizer.close();
  }
}

Future<bool> _fileExists(String path) => File(path).exists();
