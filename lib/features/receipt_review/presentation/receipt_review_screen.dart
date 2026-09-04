import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/features/receipt_review/application/receipt_review_controller.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  const ReceiptReviewScreen({
    required this.receiptImagePath,
    required this.rawOcrText,
    super.key,
  });

  final String receiptImagePath;
  final String rawOcrText;

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late final ReceiptReviewInput _reviewInput;
  late final TextEditingController _merchantController;
  late final TextEditingController _dateController;
  late final TextEditingController _currencyController;
  late final TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _reviewInput = ReceiptReviewInput(
      receiptImagePath: widget.receiptImagePath,
      rawOcrText: widget.rawOcrText,
    );
    final state = ref.read(receiptReviewControllerProvider(_reviewInput));
    _merchantController = TextEditingController(text: state.merchantInput);
    _dateController = TextEditingController(text: state.dateInput);
    _currencyController = TextEditingController(text: state.currencyInput);
    _totalController = TextEditingController(text: state.totalInput);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _currencyController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptReviewControllerProvider(_reviewInput));

    return Scaffold(
      appBar: AppBar(title: const Text('Review receipt')),
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
                    'Review receipt details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These values are suggestions from unverified OCR. '
                    'Correct every field before confirming the receipt.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _ReceiptEvidence(
                    receiptImagePath: state.receiptImagePath,
                    rawOcrText: state.rawOcrText,
                  ),
                  const SizedBox(height: 24),
                  _ReviewTextField(
                    field: ReceiptReviewField.merchant,
                    controller: _merchantController,
                    label: 'Merchant',
                    hintText: 'Merchant name',
                    state: state,
                    textCapitalization: TextCapitalization.words,
                    onChanged: _updateField,
                  ),
                  const SizedBox(height: 16),
                  _ReviewTextField(
                    field: ReceiptReviewField.date,
                    controller: _dateController,
                    label: 'Date',
                    hintText: '04.09.2026',
                    state: state,
                    keyboardType: TextInputType.datetime,
                    onChanged: _updateField,
                  ),
                  const SizedBox(height: 16),
                  _ReviewTextField(
                    field: ReceiptReviewField.currency,
                    controller: _currencyController,
                    label: 'Currency',
                    hintText: 'EUR',
                    state: state,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _updateField,
                  ),
                  const SizedBox(height: 16),
                  _ReviewTextField(
                    field: ReceiptReviewField.total,
                    controller: _totalController,
                    label: 'Total',
                    hintText: '12.99',
                    state: state,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: _updateField,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('confirm-receipt-review-button'),
                    onPressed: _confirm,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Confirm reviewed details'),
                  ),
                  if (state.confirmedReceipt case final confirmation?) ...[
                    const SizedBox(height: 20),
                    _ConfirmedReceiptCard(confirmation: confirmation),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateField(ReceiptReviewField field, String value) {
    ref
        .read(receiptReviewControllerProvider(_reviewInput).notifier)
        .updateField(field, value);
  }

  void _confirm() {
    final wasConfirmed = ref
        .read(receiptReviewControllerProvider(_reviewInput).notifier)
        .confirm();
    if (wasConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt details confirmed.')),
      );
    }
  }
}

class _ReceiptEvidence extends StatelessWidget {
  const _ReceiptEvidence({
    required this.receiptImagePath,
    required this.rawOcrText,
  });

  final String receiptImagePath;
  final String rawOcrText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receipt evidence', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          key: const ValueKey('review-receipt-image-card'),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Original receipt image'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Semantics(
                label: 'Original receipt image',
                image: true,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 180,
                    maxHeight: 420,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Image.file(
                    File(receiptImagePath),
                    key: const ValueKey('review-receipt-image'),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'The original receipt image is unavailable.',
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          key: const ValueKey('review-raw-ocr-card'),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.text_snippet_outlined),
            title: const Text('Raw OCR text'),
            subtitle: const Text('Unverified recognition output'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              SelectionArea(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rawOcrText,
                    key: const ValueKey('review-raw-ocr-text'),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTextField extends StatelessWidget {
  const _ReviewTextField({
    required this.field,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.state,
    required this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final ReceiptReviewField field;
  final TextEditingController controller;
  final String label;
  final String hintText;
  final ReceiptReviewState state;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final void Function(ReceiptReviewField field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('receipt-review-${field.name}-field'),
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        helperText: _helperText(field, state),
        helperMaxLines: 3,
        errorText: _errorText(state.errors[field]),
        errorMaxLines: 2,
      ),
      onChanged: (value) => onChanged(field, value),
    );
  }
}

class _ConfirmedReceiptCard extends StatelessWidget {
  const _ConfirmedReceiptCard({required this.confirmation});

  final ConfirmedReceiptReview confirmation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('confirmed-receipt-review-card'),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Receipt details confirmed',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${confirmation.merchant} · '
              '${confirmation.currencyCode} '
              '${confirmation.total.format().substring(1)}',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'Participant allocation will be connected in the next step.',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

String _helperText(ReceiptReviewField field, ReceiptReviewState state) {
  if (state.status == ReceiptReviewStatus.confirmed) {
    return 'Confirmed by you.';
  }
  if (state.editedFields.contains(field)) {
    return 'Edited by you — review before confirming.';
  }

  final proposal = state.proposals.forField(field);
  return switch (proposal.confidence) {
    ReceiptProposalConfidence.reliable =>
      'Suggested from the receipt — confirm or correct it.',
    ReceiptProposalConfidence.uncertain when proposal.value != null =>
      'Low-confidence receipt suggestion — check it carefully.',
    ReceiptProposalConfidence.uncertain =>
      'Multiple suggestions found: ${proposal.alternatives.join(', ')}. '
          'Enter the correct value.',
    ReceiptProposalConfidence.missing =>
      'No reliable receipt suggestion was found. Enter this value.',
  };
}

String? _errorText(ReceiptReviewValidationError? error) => switch (error) {
  null => null,
  ReceiptReviewValidationError.required => 'This field is required.',
  ReceiptReviewValidationError.invalidDate =>
    'Use dd.MM.yyyy, dd/MM/yyyy, or yyyy-MM-dd.',
  ReceiptReviewValidationError.unsupportedCurrency =>
    'Only EUR is supported in v0.1.',
  ReceiptReviewValidationError.invalidTotal =>
    'Enter a valid EUR amount, such as 12.99.',
  ReceiptReviewValidationError.totalMustBePositive =>
    'Total must be greater than zero.',
};
