import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';
import 'package:splitlens/features/expense_detail/application/expense_deletion_controller.dart';

import '../../../support/fakes/fake_expense_repository.dart';
import '../../../support/fixtures/persisted_expense_fixture.dart';

void main() {
  test('deletes the requested expense and exposes completion', () async {
    final expense = persistedExpenseFixture(id: 'expense-to-delete');
    final repository = FakeExpenseRepository(initialExpenses: [expense]);
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = expenseDeletionControllerProvider(expense.id);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    final result = await container.read(provider.notifier).delete();

    expect(result, ExpenseDeletionStatus.deleted);
    expect(container.read(provider).status, ExpenseDeletionStatus.deleted);
    expect(repository.deleteRequests, [expense.id]);
    expect(await repository.getById(expense.id), isNull);
  });

  test(
    'distinguishes receipt cleanup warnings from deletion failure',
    () async {
      final expense = persistedExpenseFixture(id: 'expense-to-delete');
      final repository = FakeExpenseRepository(
        initialExpenses: [expense],
        onDeleteById: (_) async =>
            ExpenseDeletionResult.deletedWithReceiptCleanupFailure,
      );
      final container = ProviderContainer(
        overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = expenseDeletionControllerProvider(expense.id);
      final subscription = container.listen(provider, (previous, next) {});
      addTearDown(subscription.close);

      final result = await container.read(provider.notifier).delete();

      expect(result, ExpenseDeletionStatus.deletedWithReceiptCleanupFailure);
      expect(
        container.read(provider).status,
        ExpenseDeletionStatus.deletedWithReceiptCleanupFailure,
      );
    },
  );

  test('exposes a retryable failure when repository deletion fails', () async {
    final repository = FakeExpenseRepository(
      onDeleteById: (_) async => throw StateError('synthetic delete failure'),
    );
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = expenseDeletionControllerProvider('expense-to-delete');
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    final result = await container.read(provider.notifier).delete();

    expect(result, ExpenseDeletionStatus.failure);
    expect(container.read(provider).status, ExpenseDeletionStatus.failure);
    expect(
      container.read(provider).errorMessage,
      'Expense could not be deleted. Try again.',
    );
  });
}
