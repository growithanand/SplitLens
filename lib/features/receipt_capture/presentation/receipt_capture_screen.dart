import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/app/navigation/app_routes.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_text_recognition_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';
import 'package:splitlens/features/receipt_review/presentation/receipt_review_screen.dart';

class ReceiptCaptureScreen extends ConsumerStatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  ConsumerState<ReceiptCaptureScreen> createState() =>
      _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends ConsumerState<ReceiptCaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recoverLostImage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(receiptCaptureControllerProvider);
    final recognitionState = ref.watch(
      receiptTextRecognitionControllerProvider,
    );
    final isBusy = captureState.isSelecting || recognitionState.isRecognizing;

    return Scaffold(
      appBar: AppBar(title: const Text('Add a receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose a receipt image',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a clear photo of a printed receipt or select a '
                    'receipt screenshot. Your image stays on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _ImagePreview(state: captureState),
                  const SizedBox(height: 20),
                  if (captureState.status == ReceiptCaptureStatus.selecting)
                    _SelectingNotice(source: captureState.requestedSource!),
                  if (captureState.status == ReceiptCaptureStatus.cancelled)
                    const _StatusNotice(
                      icon: Icons.info_outline,
                      message:
                          'Image selection was cancelled. Nothing changed.',
                    ),
                  if (captureState.status == ReceiptCaptureStatus.failure)
                    _StatusNotice(
                      icon: Icons.error_outline,
                      message: captureState.errorMessage!,
                      isError: true,
                    ),
                  if (captureState.status == ReceiptCaptureStatus.ready &&
                      recognitionState.status ==
                          ReceiptTextRecognitionStatus.idle) ...[
                    const _StatusNotice(
                      icon: Icons.check_circle_outline,
                      message:
                          'Receipt image selected. It is ready for on-device '
                          'text recognition.',
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('take-photo-button'),
                    onPressed: isBusy
                        ? null
                        : () => _selectImage(ReceiptImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take a photo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('select-gallery-button'),
                    onPressed: isBusy
                        ? null
                        : () => _selectImage(ReceiptImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select from gallery'),
                  ),
                  if (captureState.image case final image?) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      'Recognize receipt text',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recognition runs on this device. You will review the '
                      'raw result before SplitLens uses any values.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      key: const ValueKey('recognize-text-button'),
                      onPressed: isBusy
                          ? null
                          : () => ref
                                .read(
                                  receiptTextRecognitionControllerProvider
                                      .notifier,
                                )
                                .recognize(image),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(
                        recognitionState.status ==
                                ReceiptTextRecognitionStatus.success
                            ? 'Recognize text again'
                            : 'Recognize text',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (recognitionState.status ==
                        ReceiptTextRecognitionStatus.recognizing)
                      const _StatusNotice(
                        icon: Icons.hourglass_top,
                        message: 'Recognizing printed text on this device…',
                        showProgress: true,
                      ),
                    if (recognitionState.status ==
                        ReceiptTextRecognitionStatus.failure)
                      _StatusNotice(
                        icon: Icons.error_outline,
                        message: recognitionState.errorMessage!,
                        isError: true,
                      ),
                    if (recognitionState.status ==
                        ReceiptTextRecognitionStatus.success) ...[
                      _RawTextResult(rawText: recognitionState.rawText!),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('review-receipt-button'),
                        onPressed: () => _openReceiptReview(
                          imagePath: image.path,
                          rawOcrText: recognitionState.rawText!,
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Review receipt details'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recoverLostImage() async {
    final previousImage = ref.read(receiptCaptureControllerProvider).image;
    await ref
        .read(receiptCaptureControllerProvider.notifier)
        .recoverLostImage();
    if (!mounted) {
      return;
    }

    _clearRecognitionForChangedImage(previousImage);
  }

  Future<void> _selectImage(ReceiptImageSource source) async {
    final previousImage = ref.read(receiptCaptureControllerProvider).image;
    await ref
        .read(receiptCaptureControllerProvider.notifier)
        .selectImage(source);
    if (!mounted) {
      return;
    }

    _clearRecognitionForChangedImage(previousImage);
  }

  void _clearRecognitionForChangedImage(ReceiptImage? previousImage) {
    final selectedImage = ref.read(receiptCaptureControllerProvider).image;
    final imageChanged =
        selectedImage != null &&
        (selectedImage.path != previousImage?.path ||
            selectedImage.source != previousImage?.source);
    if (imageChanged) {
      ref.read(receiptTextRecognitionControllerProvider.notifier).clear();
    }
  }

  void _openReceiptReview({
    required String imagePath,
    required String rawOcrText,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.receiptReview),
        builder: (_) => ReceiptReviewScreen(
          receiptImagePath: imagePath,
          rawOcrText: rawOcrText,
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.state});

  final ReceiptCaptureState state;

  @override
  Widget build(BuildContext context) {
    final image = state.image;
    if (image == null) {
      return Container(
        key: const ValueKey('empty-receipt-preview'),
        height: 260,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64),
            SizedBox(height: 12),
            Text('No receipt image selected'),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Selected receipt image preview',
      image: true,
      child: ClipRRect(
        key: const ValueKey('selected-receipt-preview'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 220, maxHeight: 420),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Image.file(
            File(image.path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 260,
              child: Center(
                child: Text('The selected image preview is unavailable.'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectingNotice extends StatelessWidget {
  const _SelectingNotice({required this.source});

  final ReceiptImageSource source;

  @override
  Widget build(BuildContext context) {
    final message = switch (source) {
      ReceiptImageSource.camera => 'Opening camera…',
      ReceiptImageSource.gallery => 'Opening gallery…',
      ReceiptImageSource.recovered =>
        'Checking for an interrupted image selection…',
    };

    return _StatusNotice(
      icon: Icons.hourglass_top,
      message: message,
      showProgress: true,
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.message,
    this.isError = false,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final bool isError;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (showProgress)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foregroundColor,
                ),
              )
            else
              Icon(icon, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foregroundColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawTextResult extends StatelessWidget {
  const _RawTextResult({required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey('raw-ocr-text-card'),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Raw OCR text',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This is an unverified recognition result. Receipt values will '
              'remain editable before they can be saved.',
            ),
            const SizedBox(height: 16),
            SelectionArea(
              child: Text(
                rawText,
                key: const ValueKey('raw-ocr-text'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
