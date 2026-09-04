import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';

abstract interface class ReceiptTextRecognizer {
  Future<ReceiptTextRecognitionResult> recognize(ReceiptImage image);

  Future<void> close();
}
