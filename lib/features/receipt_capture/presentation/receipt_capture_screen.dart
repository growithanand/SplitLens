import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/features/receipt_capture/application/receipt_capture_controller.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image.dart';

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
        ref.read(receiptCaptureControllerProvider.notifier).recoverLostImage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptCaptureControllerProvider);

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
                  _ImagePreview(state: state),
                  const SizedBox(height: 20),
                  if (state.status == ReceiptCaptureStatus.selecting)
                    _SelectingNotice(source: state.requestedSource!),
                  if (state.status == ReceiptCaptureStatus.cancelled)
                    const _StatusNotice(
                      icon: Icons.info_outline,
                      message:
                          'Image selection was cancelled. Nothing changed.',
                    ),
                  if (state.status == ReceiptCaptureStatus.failure)
                    _StatusNotice(
                      icon: Icons.error_outline,
                      message: state.errorMessage!,
                      isError: true,
                    ),
                  if (state.status == ReceiptCaptureStatus.ready) ...[
                    const _StatusNotice(
                      icon: Icons.check_circle_outline,
                      message:
                          'Receipt image selected. OCR has not been run yet.',
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('take-photo-button'),
                    onPressed: state.isSelecting
                        ? null
                        : () => _selectImage(ReceiptImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take a photo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('select-gallery-button'),
                    onPressed: state.isSelecting
                        ? null
                        : () => _selectImage(ReceiptImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select from gallery'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectImage(ReceiptImageSource source) {
    ref.read(receiptCaptureControllerProvider.notifier).selectImage(source);
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
