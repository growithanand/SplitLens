import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/features/receipt_capture/data/image_picker_receipt_image_picker.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';

enum ReceiptCaptureStatus { idle, selecting, ready, cancelled, failure }

final receiptImagePickerProvider = Provider<ReceiptImagePicker>(
  (ref) => ImagePickerReceiptImagePicker(),
);

final receiptCaptureControllerProvider =
    NotifierProvider<ReceiptCaptureController, ReceiptCaptureState>(
      ReceiptCaptureController.new,
    );

final class ReceiptCaptureState {
  const ReceiptCaptureState({
    this.status = ReceiptCaptureStatus.idle,
    this.image,
    this.requestedSource,
    this.errorMessage,
  });

  final ReceiptCaptureStatus status;
  final ReceiptImage? image;
  final ReceiptImageSource? requestedSource;
  final String? errorMessage;

  bool get isSelecting => status == ReceiptCaptureStatus.selecting;
}

final class ReceiptCaptureController extends Notifier<ReceiptCaptureState> {
  @override
  ReceiptCaptureState build() => const ReceiptCaptureState();

  Future<void> selectImage(ReceiptImageSource source) async {
    if (state.isSelecting || source == ReceiptImageSource.recovered) {
      return;
    }

    final previousImage = state.image;
    state = ReceiptCaptureState(
      status: ReceiptCaptureStatus.selecting,
      image: previousImage,
      requestedSource: source,
    );

    final result = await ref.read(receiptImagePickerProvider).pickImage(source);
    _applyResult(result, previousImage: previousImage, requestedSource: source);
  }

  Future<void> recoverLostImage() async {
    if (state.status != ReceiptCaptureStatus.idle) {
      return;
    }

    state = const ReceiptCaptureState(
      status: ReceiptCaptureStatus.selecting,
      requestedSource: ReceiptImageSource.recovered,
    );

    final result = await ref
        .read(receiptImagePickerProvider)
        .recoverLostImage();
    if (result == null) {
      state = const ReceiptCaptureState();
      return;
    }

    _applyResult(
      result,
      previousImage: null,
      requestedSource: ReceiptImageSource.recovered,
    );
  }

  void _applyResult(
    ReceiptImagePickResult result, {
    required ReceiptImage? previousImage,
    required ReceiptImageSource requestedSource,
  }) {
    state = switch (result) {
      ReceiptImageSelected(:final image) => ReceiptCaptureState(
        status: ReceiptCaptureStatus.ready,
        image: image,
      ),
      ReceiptImageCancelled() => ReceiptCaptureState(
        status: ReceiptCaptureStatus.cancelled,
        image: previousImage,
        requestedSource: requestedSource,
      ),
      ReceiptImageFailure(:final message) => ReceiptCaptureState(
        status: ReceiptCaptureStatus.failure,
        image: previousImage,
        requestedSource: requestedSource,
        errorMessage: message,
      ),
    };
  }
}
