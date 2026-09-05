import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/expense_history/application/expense_history_controller.dart';

import '../../../support/fakes/fake_expense_repository.dart';
import '../../../support/fixtures/persisted_expense_fixture.dart';

void main() {
  test('loads saved expenses from the repository', () async {
    final pendingExpenses = Completer<List<PersistedExpense>>();
    final expense = persistedExpenseFixture();
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(
          FakeExpenseRepository(onGetAll: () => pendingExpenses.future),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      expenseHistoryControllerProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    expect(container.read(expenseHistoryControllerProvider).isLoading, isTrue);

    pendingExpenses.complete([expense]);
    final loaded = await container.read(
      expenseHistoryControllerProvider.future,
    );

    expect(loaded, [same(expense)]);
  });

  test('exposes an error and can retry loading', () async {
    final expense = persistedExpenseFixture();
    var loadCount = 0;
    final repository = FakeExpenseRepository(
      onGetAll: () async {
        loadCount++;
        if (loadCount == 1) {
          throw StateError('synthetic database failure');
        }
        return [expense];
      },
    );
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      expenseHistoryControllerProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(expenseHistoryControllerProvider.future),
      throwsStateError,
    );
    expect(container.read(expenseHistoryControllerProvider).hasError, isTrue);

    await container.read(expenseHistoryControllerProvider.notifier).reload();

    expect(container.read(expenseHistoryControllerProvider).value, [
      same(expense),
    ]);
    expect(loadCount, 2);
  });
}
