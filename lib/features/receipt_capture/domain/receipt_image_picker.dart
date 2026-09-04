import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';

abstract interface class ReceiptImagePicker {
  Future<ReceiptImagePickResult> pickImage(ReceiptImageSource source);

  Future<ReceiptImagePickResult?> recoverLostImage();
}
