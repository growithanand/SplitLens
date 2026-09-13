import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';

abstract final class ExpenseHistoryFilter {
  static List<PersistedExpense> apply(
    Iterable<PersistedExpense> expenses,
    String query,
  ) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) {
      return List.unmodifiable(expenses);
    }

    return List.unmodifiable(
      expenses.where((expense) {
        final searchableText = [
          expense.receipt.merchant,
          ...expense.allocations.map(
            (allocation) => allocation.participant.name,
          ),
        ].join('\n').toLowerCase();
        return terms.every(searchableText.contains);
      }),
    );
  }
}
