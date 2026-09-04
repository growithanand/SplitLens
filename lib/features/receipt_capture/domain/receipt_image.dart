enum ReceiptImageSource { camera, gallery, recovered }

final class ReceiptImage {
  const ReceiptImage({required this.path, required this.source});

  final String path;
  final ReceiptImageSource source;
}

sealed class ReceiptImagePickResult {
  const ReceiptImagePickResult();
}

final class ReceiptImageSelected extends ReceiptImagePickResult {
  const ReceiptImageSelected(this.image);

  final ReceiptImage image;
}

final class ReceiptImageCancelled extends ReceiptImagePickResult {
  const ReceiptImageCancelled();
}

final class ReceiptImageFailure extends ReceiptImagePickResult {
  const ReceiptImageFailure(this.message);

  final String message;
}
