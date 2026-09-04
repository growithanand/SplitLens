import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/features/receipt_capture/data/ml_kit_receipt_text_recognizer.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognition.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_text_recognizer.dart';

enum ReceiptTextRecognitionStatus { idle, recognizing, success, failure }

final receiptTextRecognizerProvider = Provider<ReceiptTextRecognizer>((ref) {
  final recognizer = MlKitReceiptTextRecognizer();
  ref.onDispose(() => unawaited(recognizer.close()));
  return recognizer;
});

final receiptTextRecognitionControllerProvider =
    NotifierProvider<
      ReceiptTextRecognitionController,
      ReceiptTextRecognitionState
    >(ReceiptTextRecognitionController.new);

final class ReceiptTextRecognitionState {
  const ReceiptTextRecognitionState({
    this.status = ReceiptTextRecognitionStatus.idle,
    this.imagePath,
    this.rawText,
    this.errorMessage,
  });

  final ReceiptTextRecognitionStatus status;
  final String? imagePath;
  final String? rawText;
  final String? errorMessage;

  bool get isRecognizing => status == ReceiptTextRecognitionStatus.recognizing;
}

final class ReceiptTextRecognitionController
    extends Notifier<ReceiptTextRecognitionState> {
  @override
  ReceiptTextRecognitionState build() => const ReceiptTextRecognitionState();

  Future<void> recognize(ReceiptImage image) async {
    if (state.isRecognizing) {
      return;
    }

    state = ReceiptTextRecognitionState(
      status: ReceiptTextRecognitionStatus.recognizing,
      imagePath: image.path,
    );

    final result = await ref
        .read(receiptTextRecognizerProvider)
        .recognize(image);
    state = switch (result) {
      ReceiptTextRecognized(:final rawText) => ReceiptTextRecognitionState(
        status: ReceiptTextRecognitionStatus.success,
        imagePath: image.path,
        rawText: rawText,
      ),
      ReceiptTextRecognitionFailed(:final failure) =>
        ReceiptTextRecognitionState(
          status: ReceiptTextRecognitionStatus.failure,
          imagePath: image.path,
          errorMessage: failure.message,
        ),
    };
  }

  void clear() {
    if (!state.isRecognizing) {
      state = const ReceiptTextRecognitionState();
    }
  }
}
