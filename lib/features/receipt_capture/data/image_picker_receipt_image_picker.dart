import 'package:image_picker/image_picker.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_picker.dart';

final class ImagePickerReceiptImagePicker implements ReceiptImagePicker {
  ImagePickerReceiptImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<ReceiptImagePickResult> pickImage(ReceiptImageSource source) async {
    if (source == ReceiptImageSource.recovered) {
      return const ReceiptImageFailure(
        'A recovered image cannot be selected as a new source.',
      );
    }

    try {
      final selectedFile = await _imagePicker.pickImage(
        source: source == ReceiptImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (selectedFile == null) {
        return const ReceiptImageCancelled();
      }

      return ReceiptImageSelected(
        ReceiptImage(path: selectedFile.path, source: source),
      );
    } on Object {
      return ReceiptImageFailure(_selectionFailureMessage(source));
    }
  }

  @override
  Future<ReceiptImagePickResult?> recoverLostImage() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }

      final files = response.files;
      if (files != null && files.isNotEmpty) {
        return ReceiptImageSelected(
          ReceiptImage(
            path: files.first.path,
            source: ReceiptImageSource.recovered,
          ),
        );
      }

      return const ReceiptImageFailure(
        'The interrupted image selection could not be recovered. Try again.',
      );
    } on Object {
      return const ReceiptImageFailure(
        'The interrupted image selection could not be recovered. Try again.',
      );
    }
  }
}

String _selectionFailureMessage(ReceiptImageSource source) => switch (source) {
  ReceiptImageSource.camera =>
    'The camera could not provide an image. Check that a camera app is '
        'available, then try again.',
  ReceiptImageSource.gallery =>
    'The gallery could not provide an image. Check photo access, then try '
        'again.',
  ReceiptImageSource.recovered =>
    'The interrupted image selection could not be recovered. Try again.',
};
