import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognizer.dart';

typedef RecognitionCallback = Future<ReceiptTextRecognitionResult> Function(
  ReceiptImage image,
);

final class FakeReceiptTextRecognizer implements ReceiptTextRecognizer {
  FakeReceiptTextRecognizer({required this.result, this.onRecognize});

  ReceiptTextRecognitionResult result;
  final RecognitionCallback? onRecognize;
  final List<ReceiptImage> receivedImages = [];
  bool isClosed = false;

  @override
  Future<ReceiptTextRecognitionResult> recognize(ReceiptImage image) {
    receivedImages.add(image);
    return onRecognize?.call(image) ?? Future.value(result);
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}
