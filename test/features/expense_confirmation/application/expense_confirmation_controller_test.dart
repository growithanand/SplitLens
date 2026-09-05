import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/application/expense_confirmation_controller.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

import '../../../support/fakes/fake_expense_repository.dart';

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

    test('requires at least one participant and a payer', () async {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);

      expect(await controller.confirm(), isFalse);
      expect(scope.container.read(provider).validationErrors, {
        ExpenseConfirmationValidationError.participantsRequired,
        ExpenseConfirmationValidationError.payerRequired,
      });

      controller.addParticipant('Anand');
      expect(await controller.confirm(), isFalse);
      expect(scope.container.read(provider).validationErrors, {
        ExpenseConfirmationValidationError.payerRequired,
      });
    });

    test('saves payer and exact remainder-safe allocations', () async {
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

      expect(await controller.confirm(), isTrue);

      final state = scope.container.read(provider);
      final expense = state.confirmedExpense!;
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
      expect(state.saveStatus, ExpenseSaveStatus.saved);
      expect(state.persistedExpense, isNotNull);
      expect(scope.repository.saveRequests.single, same(expense));
    });

    test('removing the payer invalidates an existing save', () async {
      final scope = _createScope();
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final controller = scope.container.read(provider.notifier);
      controller
        ..addParticipant('Anand')
        ..addParticipant('Mira');
      final payerId = scope.container.read(provider).participants.first.id;
      controller.selectPayer(payerId);
      await controller.confirm();
      controller.removeParticipant(payerId);

      final state = scope.container.read(provider);
      expect(state.selectedPayer, isNull);
      expect(state.confirmedExpense, isNull);
      expect(state.persistedExpense, isNull);
      expect(
        state.validationErrors,
        contains(ExpenseConfirmationValidationError.payerRequired),
      );
    });

    test('exposes saving and safe failure states', () async {
      final pendingSave = Completer<PersistedExpense>();
      final repository = FakeExpenseRepository(
        onSave: (_) => pendingSave.future,
      );
      final scope = _createScope(repository: repository);
      addTearDown(scope.container.dispose);
      final provider = expenseConfirmationControllerProvider(scope.input);
      final subscription = scope.container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final controller = scope.container.read(provider.notifier);
      controller.addParticipant('Anand');
      final payerId = scope.container.read(provider).participants.single.id;
      controller.selectPayer(payerId);

      final saveFuture = controller.confirm();
      await Future<void>.delayed(Duration.zero);

      expect(
        scope.container.read(provider).saveStatus,
        ExpenseSaveStatus.saving,
      );
      expect(scope.container.read(provider).isSaving, isTrue);

      pendingSave.completeError(StateError('synthetic database failure'));
      expect(await saveFuture, isFalse);
      final failedState = scope.container.read(provider);
      expect(failedState.saveStatus, ExpenseSaveStatus.failure);
      expect(failedState.confirmedExpense, isNotNull);
      expect(failedState.persistedExpense, isNull);
      expect(
        failedState.saveErrorMessage,
        'Expense could not be saved. Try again.',
      );
    });
  });
}

({
  ProviderContainer container,
  ExpenseConfirmationInput input,
  FakeExpenseRepository repository,
})
_createScope({FakeExpenseRepository? repository}) {
  final resolvedRepository = repository ?? FakeExpenseRepository();
  final container = ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(resolvedRepository),
    ],
  );
  final input = ExpenseConfirmationInput(_receipt);
  return (container: container, input: input, repository: resolvedRepository);
}

final _receipt = ConfirmedReceiptReview(
  merchant: 'Synthetic Market',
  date: DateTime(2026, 9, 4),
  currencyCode: 'EUR',
  total: Money.eur(1000),
  receiptImagePath: 'synthetic-receipt.png',
  rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 10.00',
);
