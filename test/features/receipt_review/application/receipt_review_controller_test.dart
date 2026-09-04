import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/receipt_review/application/receipt_review_controller.dart';

void main() {
  group('ReceiptReviewController', () {
    test('combines reliable parser proposals into editable inputs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = receiptReviewControllerProvider(
        _input(_reliableReceipt),
      );

      final state = container.read(provider);
      expect(state.status, ReceiptReviewStatus.reviewing);
      expect(state.merchantInput, 'SYNTHETIC CORNER MARKET LTD');
      expect(state.dateInput, '04/09/2026');
      expect(state.currencyInput, 'EUR');
      expect(state.totalInput, '12.99');
      expect(
        state.proposals.merchant.confidence,
        ReceiptProposalConfidence.reliable,
      );
      expect(
        state.proposals.total.confidence,
        ReceiptProposalConfidence.reliable,
      );
    });

    test('leaves ambiguous date and total inputs blank with alternatives', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const rawOcrText = '''
SYNTHETIC MARKET LTD
ORDER DATE 03.09.2026
RECEIPT DATE 04.09.2026
TOTAL EUR 10.00
TOTAL EUR 12.00
''';
      final provider = receiptReviewControllerProvider(_input(rawOcrText));

      final state = container.read(provider);
      expect(state.dateInput, isEmpty);
      expect(state.totalInput, isEmpty);
      expect(
        state.proposals.date.confidence,
        ReceiptProposalConfidence.uncertain,
      );
      expect(state.proposals.date.alternatives, hasLength(2));
      expect(
        state.proposals.total.confidence,
        ReceiptProposalConfidence.uncertain,
      );
      expect(state.proposals.total.alternatives.toSet(), {'10.00', '12.00'});
    });

    test('requires every reviewed field before confirmation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = receiptReviewControllerProvider(_input('RECEIPT'));
      final controller = container.read(provider.notifier);

      final wasConfirmed = controller.confirm();

      final state = container.read(provider);
      expect(wasConfirmed, isFalse);
      expect(state.confirmedReceipt, isNull);
      expect(state.errors, {
        ReceiptReviewField.merchant: ReceiptReviewValidationError.required,
        ReceiptReviewField.date: ReceiptReviewValidationError.required,
        ReceiptReviewField.currency: ReceiptReviewValidationError.required,
        ReceiptReviewField.total: ReceiptReviewValidationError.required,
      });
    });

    test('normalizes and confirms valid user-reviewed values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = receiptReviewControllerProvider(_input('RECEIPT'));
      final controller = container.read(provider.notifier);
      controller
        ..updateField(ReceiptReviewField.merchant, '  Edited   Market  ')
        ..updateField(ReceiptReviewField.date, '2026-09-04')
        ..updateField(ReceiptReviewField.currency, '€')
        ..updateField(ReceiptReviewField.total, '12,99 €');

      final wasConfirmed = controller.confirm();

      final state = container.read(provider);
      final confirmation = state.confirmedReceipt!;
      expect(wasConfirmed, isTrue);
      expect(state.status, ReceiptReviewStatus.confirmed);
      expect(state.errors, isEmpty);
      expect(confirmation.merchant, 'Edited Market');
      expect(confirmation.date, DateTime(2026, 9, 4));
      expect(confirmation.currencyCode, 'EUR');
      expect(confirmation.total, Money.eur(1299));
      expect(confirmation.receiptImagePath, 'synthetic-receipt.png');
      expect(confirmation.rawOcrText, 'RECEIPT');
    });

    test('reports invalid date, currency, and zero total separately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = receiptReviewControllerProvider(_input('RECEIPT'));
      final controller = container.read(provider.notifier);
      controller
        ..updateField(ReceiptReviewField.merchant, 'Synthetic Shop')
        ..updateField(ReceiptReviewField.date, '31/02/2026')
        ..updateField(ReceiptReviewField.currency, 'USD')
        ..updateField(ReceiptReviewField.total, '0.00');

      final wasConfirmed = controller.confirm();

      final state = container.read(provider);
      expect(wasConfirmed, isFalse);
      expect(state.errors, {
        ReceiptReviewField.date: ReceiptReviewValidationError.invalidDate,
        ReceiptReviewField.currency:
            ReceiptReviewValidationError.unsupportedCurrency,
        ReceiptReviewField.total:
            ReceiptReviewValidationError.totalMustBePositive,
      });
    });

    test('editing a confirmed field requires confirmation again', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = receiptReviewControllerProvider(
        _input(_reliableReceipt),
      );
      final controller = container.read(provider.notifier);
      expect(controller.confirm(), isTrue);

      controller.updateField(ReceiptReviewField.total, '13.00');

      final state = container.read(provider);
      expect(state.status, ReceiptReviewStatus.reviewing);
      expect(state.confirmedReceipt, isNull);
      expect(state.editedFields, contains(ReceiptReviewField.total));
    });
  });
}

const _reliableReceipt = '''
SYNTHETIC CORNER MARKET LTD
DATE 04/09/2026
TOTAL EUR 12.99
''';

ReceiptReviewInput _input(String rawOcrText) => ReceiptReviewInput(
  receiptImagePath: 'synthetic-receipt.png',
  rawOcrText: rawOcrText,
);
