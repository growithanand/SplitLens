enum ReceiptTextRecognitionFailureCode {
  imageUnavailable,
  noTextDetected,
  processingFailed,
}

sealed class ReceiptTextRecognitionResult {
  const ReceiptTextRecognitionResult();
}

final class ReceiptTextRecognized extends ReceiptTextRecognitionResult {
  const ReceiptTextRecognized({required this.rawText});

  final String rawText;
}

final class ReceiptTextRecognitionFailed extends ReceiptTextRecognitionResult {
  const ReceiptTextRecognitionFailed(this.failure);

  final ReceiptTextRecognitionFailure failure;
}

final class ReceiptTextRecognitionFailure {
  const ReceiptTextRecognitionFailure({
    required this.code,
    required this.message,
  });

  final ReceiptTextRecognitionFailureCode code;
  final String message;
}
