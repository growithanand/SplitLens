import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/expense_confirmation/application/expense_confirmation_controller.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

void main() {
  group('ExpenseConfirmationController', () {
    test('starts from the user-confirmed receipt', () {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);

      final state = scope.container.read(provider);

      expect(state.receipt, same(_receipt));
      expect(state.participants, isEmpty);
      expect(state.selectedPayer, isNull);
      expect(state.confirmedExpense, isNull);
    });

    test('trims names and rejects blank or duplicate participants', () {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);

      expect(controller.addParticipant('   '), isFalse);
      expect(
        scope.container.read(provider).participantNameError,
        ExpenseParticipantNameError.blank,
      );
      expect(controller.addParticipant('  Anand  '), isTrue);
      expect(controller.addParticipant('anand'), isFalse);

      final state = scope.container.read(provider);
      expect(state.participants.single.name, 'Anand');
      expect(state.participantNameError, ExpenseParticipantNameError.duplicate);
    });

    test('requires at least one participant and a payer', () {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);

      expect(controller.confirm(), isFalse);
      expect(scope.container.read(provider).validationErrors, {
        ExpenseConfirmationValidationError.participantsRequired,
        ExpenseConfirmationValidationError.payerRequired,
      });

      controller.addParticipant('Anand');
      expect(controller.confirm(), isFalse);
      expect(scope.container.read(provider).validationErrors, {
        ExpenseConfirmationValidationError.payerRequired,
      });
    });

    test('confirms payer and exact remainder-safe allocations', () {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);
      controller
        ..addParticipant('Anand')
        ..addParticipant('Mira')
        ..addParticipant('Jonas');
      final participants = scope.container.read(provider).participants;
      controller.selectPayer(participants[1].id);

      expect(controller.confirm(), isTrue);

      final expense = scope.container.read(provider).confirmedExpense!;
      expect(expense.receipt, same(_receipt));
      expect(expense.paidBy.name, 'Mira');
      expect(expense.allocations.map((allocation) => allocation.amount.cents), [
        334,
        333,
        333,
      ]);
      expect(
        expense.allocations.fold<int>(
          0,
          (sum, allocation) => sum + allocation.amount.cents,
        ),
        _receipt.total.cents,
      );
      expect(
        () => expense.allocations.add(expense.allocations.first),
        throwsUnsupportedError,
      );
    });

    test('removing the payer invalidates an existing confirmation', () {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);
      controller
        ..addParticipant('Anand')
        ..addParticipant('Mira');
      final payerId = scope.container.read(provider).participants.first.id;
      controller
        ..selectPayer(payerId)
        ..confirm()
        ..removeParticipant(payerId);

      final state = scope.container.read(provider);
      expect(state.selectedPayer, isNull);
      expect(state.confirmedExpense, isNull);
      expect(
        state.validationErrors,
        contains(ExpenseConfirmationValidationError.payerRequired),
      );
    });
  });
}

({ProviderContainer container, ExpenseConfirmationInput input}) _createScope() {
  final container = ProviderContainer();
  final input = ExpenseConfirmationInput(_receipt);
  return (container: container, input: input);
}

final _receipt = ConfirmedReceiptReview(
  merchant: 'Synthetic Market',
  date: DateTime(2026, 9, 4),
  currencyCode: 'EUR',
  total: Money.eur(1000),
  receiptImagePath: 'synthetic-receipt.png',
  rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 10.00',
);
