import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';

void main() {
  group('ReceiptCaptureController', () {
    test('starts with an empty idle state', () {
      final container = _createContainer(FakeReceiptImagePicker());
      addTearDown(container.dispose);

      final state = container.read(receiptCaptureControllerProvider);

      expect(state.status, ReceiptCaptureStatus.idle);
      expect(state.image, isNull);
      expect(state.errorMessage, isNull);
    });

    test('exposes loading and selected states for a camera image', () async {
      final pendingResult = Completer<ReceiptImagePickResult>();
      final picker = FakeReceiptImagePicker(
        onPick: (_) => pendingResult.future,
      );
      final container = _createContainer(picker);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptCaptureControllerProvider.notifier,
      );

      final selection = controller.selectImage(ReceiptImageSource.camera);

      expect(
        container.read(receiptCaptureControllerProvider).status,
        ReceiptCaptureStatus.selecting,
      );
      expect(
        container.read(receiptCaptureControllerProvider).requestedSource,
        ReceiptImageSource.camera,
      );

      pendingResult.complete(
        const ReceiptImageSelected(
          ReceiptImage(
            path: 'camera-receipt.jpg',
            source: ReceiptImageSource.camera,
          ),
        ),
      );
      await selection;

      final state = container.read(receiptCaptureControllerProvider);
      expect(state.status, ReceiptCaptureStatus.ready);
      expect(state.image?.path, 'camera-receipt.jpg');
      expect(state.image?.source, ReceiptImageSource.camera);
    });

    test('cancellation preserves an already selected image', () async {
      final picker = FakeReceiptImagePicker();
      final container = _createContainer(picker);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptCaptureControllerProvider.notifier,
      );
      const originalImage = ReceiptImage(
        path: 'original.jpg',
        source: ReceiptImageSource.camera,
      );
      picker.result = const ReceiptImageSelected(originalImage);
      await controller.selectImage(ReceiptImageSource.camera);

      picker.result = const ReceiptImageCancelled();
      await controller.selectImage(ReceiptImageSource.gallery);

      final state = container.read(receiptCaptureControllerProvider);
      expect(state.status, ReceiptCaptureStatus.cancelled);
      expect(state.image, same(originalImage));
      expect(state.requestedSource, ReceiptImageSource.gallery);
    });

    test('failure preserves the image and exposes a safe message', () async {
      final picker = FakeReceiptImagePicker();
      final container = _createContainer(picker);
      addTearDown(container.dispose);
      final controller = container.read(
        receiptCaptureControllerProvider.notifier,
      );
      const originalImage = ReceiptImage(
        path: 'original.jpg',
        source: ReceiptImageSource.gallery,
      );
      picker.result = const ReceiptImageSelected(originalImage);
      await controller.selectImage(ReceiptImageSource.gallery);

      picker.result = const ReceiptImageFailure('Camera unavailable.');
      await controller.selectImage(ReceiptImageSource.camera);

      final state = container.read(receiptCaptureControllerProvider);
      expect(state.status, ReceiptCaptureStatus.failure);
      expect(state.image, same(originalImage));
      expect(state.errorMessage, 'Camera unavailable.');
    });

    test('restores an image returned by Android lost-data recovery', () async {
      const recoveredImage = ReceiptImage(
        path: 'recovered.jpg',
        source: ReceiptImageSource.recovered,
      );
      final picker = FakeReceiptImagePicker(
        recoveredResult: const ReceiptImageSelected(recoveredImage),
      );
      final container = _createContainer(picker);
      addTearDown(container.dispose);

      await container
          .read(receiptCaptureControllerProvider.notifier)
          .recoverLostImage();

      final state = container.read(receiptCaptureControllerProvider);
      expect(state.status, ReceiptCaptureStatus.ready);
      expect(state.image, same(recoveredImage));
    });
  });
}

ProviderContainer _createContainer(ReceiptImagePicker picker) {
  return ProviderContainer(
    overrides: [receiptImagePickerProvider.overrideWithValue(picker)],
  );
}

final class FakeReceiptImagePicker implements ReceiptImagePicker {
  FakeReceiptImagePicker({this.onPick, this.recoveredResult});

  final Future<ReceiptImagePickResult> Function(ReceiptImageSource)? onPick;
  final ReceiptImagePickResult? recoveredResult;
  ReceiptImagePickResult result = const ReceiptImageCancelled();

  @override
  Future<ReceiptImagePickResult> pickImage(ReceiptImageSource source) {
    return onPick?.call(source) ?? Future.value(result);
  }

  @override
  Future<ReceiptImagePickResult?> recoverLostImage() async => recoveredResult;
}
