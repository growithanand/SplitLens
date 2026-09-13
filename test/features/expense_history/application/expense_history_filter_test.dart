import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/expense_history/application/expense_history_filter.dart';

import '../../../support/fixtures/persisted_expense_fixture.dart';

void main() {
  final marketExpense = persistedExpenseFixture(
    id: 'market-expense',
    merchant: 'Berlin Synthetic Market',
    participantNames: const ['Anand', 'Mira'],
  );
  final cafeExpense = persistedExpenseFixture(
    id: 'cafe-expense',
    merchant: 'Corner Cafe',
    participantNames: const ['Parth', 'Malavika'],
  );
  final expenses = [marketExpense, cafeExpense];

  test('keeps every expense and its order for a blank query', () {
    final result = ExpenseHistoryFilter.apply(expenses, '   ');

    expect(result, [marketExpense, cafeExpense]);
  });

  test('matches merchant names without case sensitivity', () {
    final result = ExpenseHistoryFilter.apply(expenses, 'BERLIN market');

    expect(result, [marketExpense]);
  });

  test('matches participant names', () {
    final result = ExpenseHistoryFilter.apply(expenses, 'malavika');

    expect(result, [cafeExpense]);
  });

  test('allows search terms to match across merchant and participants', () {
    final result = ExpenseHistoryFilter.apply(expenses, 'synthetic mira');

    expect(result, [marketExpense]);
  });

  test('returns an immutable empty result when nothing matches', () {
    final result = ExpenseHistoryFilter.apply(expenses, 'no match');

    expect(result, isEmpty);
    expect(() => result.add(marketExpense), throwsUnsupportedError);
  });
}
