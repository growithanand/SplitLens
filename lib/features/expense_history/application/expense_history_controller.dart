import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';

final expenseHistoryControllerProvider =
    AsyncNotifierProvider<ExpenseHistoryController, List<PersistedExpense>>(
      ExpenseHistoryController.new,
    );

final class ExpenseHistoryController
    extends AsyncNotifier<List<PersistedExpense>> {
  @override
  Future<List<PersistedExpense>> build() {
    return ref.watch(expenseRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).getAll(),
    );
  }
}
