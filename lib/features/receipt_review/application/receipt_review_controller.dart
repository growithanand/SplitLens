import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/money/money_parser.dart';
import 'package:splitlens/core/parsing/receipt_currency_parser.dart';
import 'package:splitlens/core/parsing/receipt_date_parser.dart';
import 'package:splitlens/core/parsing/receipt_merchant_parser.dart';
import 'package:splitlens/core/parsing/receipt_total_parser.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

enum ReceiptReviewStatus { reviewing, confirmed }

enum ReceiptReviewField { merchant, date, currency, total }

enum ReceiptProposalConfidence { reliable, uncertain, missing }

enum ReceiptReviewValidationError {
  required,
  invalidDate,
  unsupportedCurrency,
  invalidTotal,
  totalMustBePositive,
}

final class ReceiptReviewInput {
  const ReceiptReviewInput({
    required this.receiptImagePath,
    required this.rawOcrText,
  });

  final String receiptImagePath;
  final String rawOcrText;

  @override
  bool operator ==(Object other) =>
      other is ReceiptReviewInput &&
      other.receiptImagePath == receiptImagePath &&
      other.rawOcrText == rawOcrText;

  @override
  int get hashCode => Object.hash(receiptImagePath, rawOcrText);
}

final receiptReviewControllerProvider = NotifierProvider.autoDispose
    .family<ReceiptReviewController, ReceiptReviewState, ReceiptReviewInput>(
      ReceiptReviewController.new,
    );

final class ReceiptFieldProposal {
  ReceiptFieldProposal({
    required this.confidence,
    this.value,
    Iterable<String> alternatives = const [],
  }) : alternatives = List.unmodifiable(alternatives);

  final ReceiptProposalConfidence confidence;
  final String? value;
  final List<String> alternatives;
}

final class ReceiptReviewProposals {
  const ReceiptReviewProposals({
    required this.merchant,
    required this.date,
    required this.currency,
    required this.total,
  });

  final ReceiptFieldProposal merchant;
  final ReceiptFieldProposal date;
  final ReceiptFieldProposal currency;
  final ReceiptFieldProposal total;

  ReceiptFieldProposal forField(ReceiptReviewField field) => switch (field) {
    ReceiptReviewField.merchant => merchant,
    ReceiptReviewField.date => date,
    ReceiptReviewField.currency => currency,
    ReceiptReviewField.total => total,
  };
}

final class ReceiptReviewState {
  ReceiptReviewState({
    required this.status,
    required this.receiptImagePath,
    required this.rawOcrText,
    required this.merchantInput,
    required this.dateInput,
    required this.currencyInput,
    required this.totalInput,
    required Iterable<ReceiptReviewField> editedFields,
    required Map<ReceiptReviewField, ReceiptReviewValidationError> errors,
    required this.proposals,
    this.confirmedReceipt,
  }) : editedFields = Set.unmodifiable(editedFields),
       errors = Map.unmodifiable(errors);

  final ReceiptReviewStatus status;
  final String receiptImagePath;
  final String rawOcrText;
  final ReceiptReviewProposals proposals;
  final String merchantInput;
  final String dateInput;
  final String currencyInput;
  final String totalInput;
  final Set<ReceiptReviewField> editedFields;
  final Map<ReceiptReviewField, ReceiptReviewValidationError> errors;
  final ConfirmedReceiptReview? confirmedReceipt;

  ReceiptReviewState copyWith({
    ReceiptReviewStatus? status,
    String? merchantInput,
    String? dateInput,
    String? currencyInput,
    String? totalInput,
    Iterable<ReceiptReviewField>? editedFields,
    Map<ReceiptReviewField, ReceiptReviewValidationError>? errors,
    ConfirmedReceiptReview? confirmedReceipt,
    bool clearConfirmedReceipt = false,
  }) {
    return ReceiptReviewState(
      status: status ?? this.status,
      receiptImagePath: receiptImagePath,
      rawOcrText: rawOcrText,
      proposals: proposals,
      merchantInput: merchantInput ?? this.merchantInput,
      dateInput: dateInput ?? this.dateInput,
      currencyInput: currencyInput ?? this.currencyInput,
      totalInput: totalInput ?? this.totalInput,
      editedFields: editedFields ?? this.editedFields,
      errors: errors ?? this.errors,
      confirmedReceipt: clearConfirmedReceipt
          ? null
          : confirmedReceipt ?? this.confirmedReceipt,
    );
  }
}

final class ReceiptReviewController extends Notifier<ReceiptReviewState> {
  ReceiptReviewController(this.input);

  final ReceiptReviewInput input;
  static final _whitespace = RegExp(r'\s+');

  @override
  ReceiptReviewState build() {
    final proposals = _buildProposals(input.rawOcrText);
    return ReceiptReviewState(
      status: ReceiptReviewStatus.reviewing,
      receiptImagePath: input.receiptImagePath,
      rawOcrText: input.rawOcrText,
      proposals: proposals,
      merchantInput: proposals.merchant.value ?? '',
      dateInput: proposals.date.value ?? '',
      currencyInput: proposals.currency.value ?? '',
      totalInput: proposals.total.value ?? '',
      editedFields: const {},
      errors: const {},
    );
  }

  void updateField(ReceiptReviewField field, String value) {
    final updatedErrors =
        Map<ReceiptReviewField, ReceiptReviewValidationError>.of(state.errors)
          ..remove(field);
    state = state.copyWith(
      status: ReceiptReviewStatus.reviewing,
      merchantInput: field == ReceiptReviewField.merchant
          ? value
          : state.merchantInput,
      dateInput: field == ReceiptReviewField.date ? value : state.dateInput,
      currencyInput: field == ReceiptReviewField.currency
          ? value
          : state.currencyInput,
      totalInput: field == ReceiptReviewField.total ? value : state.totalInput,
      editedFields: {...state.editedFields, field},
      errors: updatedErrors,
      clearConfirmedReceipt: true,
    );
  }

  bool confirm() {
    final errors = <ReceiptReviewField, ReceiptReviewValidationError>{};
    final merchant = state.merchantInput.trim().replaceAll(_whitespace, ' ');
    if (merchant.isEmpty) {
      errors[ReceiptReviewField.merchant] =
          ReceiptReviewValidationError.required;
    }

    final dateInput = state.dateInput.trim();
    DateTime? date;
    if (dateInput.isEmpty) {
      errors[ReceiptReviewField.date] = ReceiptReviewValidationError.required;
    } else {
      final dateResult = ReceiptDateParser.parse(dateInput);
      if (dateResult case ReceiptDateFound(:final candidate)
          when candidate.sourceText == dateInput) {
        date = candidate.date;
      } else {
        errors[ReceiptReviewField.date] =
            ReceiptReviewValidationError.invalidDate;
      }
    }

    final currencyInput = state.currencyInput.trim();
    String? currencyCode;
    if (currencyInput.isEmpty) {
      errors[ReceiptReviewField.currency] =
          ReceiptReviewValidationError.required;
    } else if (currencyInput.toUpperCase() == Money.currencyCode ||
        currencyInput == '€') {
      currencyCode = Money.currencyCode;
    } else {
      errors[ReceiptReviewField.currency] =
          ReceiptReviewValidationError.unsupportedCurrency;
    }

    final totalInput = state.totalInput.trim();
    Money? total;
    if (totalInput.isEmpty) {
      errors[ReceiptReviewField.total] = ReceiptReviewValidationError.required;
    } else {
      final totalResult = MoneyParser.parseEur(totalInput);
      total = totalResult.money;
      if (total == null) {
        errors[ReceiptReviewField.total] =
            ReceiptReviewValidationError.invalidTotal;
      } else if (total.cents == 0) {
        errors[ReceiptReviewField.total] =
            ReceiptReviewValidationError.totalMustBePositive;
      }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(
        status: ReceiptReviewStatus.reviewing,
        errors: errors,
        clearConfirmedReceipt: true,
      );
      return false;
    }

    final confirmedReceipt = ConfirmedReceiptReview(
      merchant: merchant,
      date: date!,
      currencyCode: currencyCode!,
      total: total!,
      receiptImagePath: state.receiptImagePath,
      rawOcrText: state.rawOcrText,
    );
    state = state.copyWith(
      status: ReceiptReviewStatus.confirmed,
      errors: const {},
      confirmedReceipt: confirmedReceipt,
    );
    return true;
  }

  static ReceiptReviewProposals _buildProposals(String rawOcrText) {
    return ReceiptReviewProposals(
      merchant: _merchantProposal(ReceiptMerchantParser.parse(rawOcrText)),
      date: _dateProposal(ReceiptDateParser.parse(rawOcrText)),
      currency: _currencyProposal(ReceiptCurrencyParser.parse(rawOcrText)),
      total: _totalProposal(ReceiptTotalParser.parse(rawOcrText)),
    );
  }

  static ReceiptFieldProposal _merchantProposal(
    ReceiptMerchantParseResult result,
  ) => switch (result) {
    ReceiptMerchantFound(:final candidate) => ReceiptFieldProposal(
      confidence: ReceiptProposalConfidence.reliable,
      value: candidate.name,
    ),
    ReceiptMerchantUncertain(:final candidates) => ReceiptFieldProposal(
      confidence: ReceiptProposalConfidence.uncertain,
      value: candidates.length == 1 ? candidates.single.name : null,
      alternatives: candidates.map((candidate) => candidate.name),
    ),
    ReceiptMerchantNotFound() => ReceiptFieldProposal(
      confidence: ReceiptProposalConfidence.missing,
    ),
  };

  static ReceiptFieldProposal _dateProposal(ReceiptDateParseResult result) =>
      switch (result) {
        ReceiptDateFound(:final candidate) => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.reliable,
          value: candidate.sourceText,
        ),
        ReceiptDateAmbiguous(:final candidates) => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.uncertain,
          alternatives: candidates.map((candidate) => candidate.sourceText),
        ),
        ReceiptDateNotFound() => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.missing,
        ),
      };

  static ReceiptFieldProposal _currencyProposal(
    ReceiptCurrencyParseResult result,
  ) => switch (result) {
    ReceiptCurrencyFound(:final currencyCode) => ReceiptFieldProposal(
      confidence: ReceiptProposalConfidence.reliable,
      value: currencyCode,
    ),
    ReceiptCurrencyNotFound() => ReceiptFieldProposal(
      confidence: ReceiptProposalConfidence.missing,
    ),
  };

  static ReceiptFieldProposal _totalProposal(ReceiptTotalParseResult result) =>
      switch (result) {
        ReceiptTotalFound(:final candidate) => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.reliable,
          value: _formatAmountInput(candidate.money),
        ),
        ReceiptTotalAmbiguous(:final candidates) => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.uncertain,
          alternatives: candidates.map(
            (candidate) => _formatAmountInput(candidate.money),
          ),
        ),
        ReceiptTotalNotFound() => ReceiptFieldProposal(
          confidence: ReceiptProposalConfidence.missing,
        ),
      };

  static String _formatAmountInput(Money money) {
    final wholeEuros = money.cents ~/ 100;
    final cents = (money.cents % 100).toString().padLeft(2, '0');
    return '$wholeEuros.$cents';
  }
}
