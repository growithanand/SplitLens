import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/expense_history/presentation/expense_history_screen.dart';

import '../../../support/fakes/fake_expense_repository.dart';
import '../../../support/fixtures/persisted_expense_fixture.dart';

void main() {
  testWidgets('shows a loading state while expenses are being read', (
    tester,
  ) async {
    final pendingExpenses = Completer<List<PersistedExpense>>();
    await _pumpHistory(
      tester,
      FakeExpenseRepository(onGetAll: () => pendingExpenses.future),
    );

    expect(
      find.byKey(const ValueKey('expense-history-loading')),
      findsOneWidget,
    );
    expect(find.text('Loading saved expenses…'), findsOneWidget);
  });

  testWidgets('shows a useful empty state', (tester) async {
    await _pumpHistory(tester, FakeExpenseRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-history-empty')), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Add a receipt'), findsOneWidget);
  });

  testWidgets('shows merchant, date, total, and participant count', (
    tester,
  ) async {
    final expense = persistedExpenseFixture(
      id: 'saved-expense',
      merchant: 'SplitLens Synthetic Market',
      date: DateTime(2026, 9, 4),
      totalCents: 599,
      participantNames: const ['Anand', 'Mira', 'Parth'],
    );
    await _pumpHistory(
      tester,
      FakeExpenseRepository(initialExpenses: [expense]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-history-list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-history-item-saved-expense')),
      findsOneWidget,
    );
    expect(find.text('SplitLens Synthetic Market'), findsOneWidget);
    expect(find.text('04 Sep 2026'), findsOneWidget);
    expect(find.text('€5.99'), findsOneWidget);
    expect(find.text('3 participants'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-history-search-field')),
      findsOneWidget,
    );
  });

  testWidgets('filters by merchant or participant and clears the query', (
    tester,
  ) async {
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
    await _pumpHistory(
      tester,
      FakeExpenseRepository(initialExpenses: [marketExpense, cafeExpense]),
    );
    await tester.pumpAndSettle();

    final searchField = find.byKey(
      const ValueKey('expense-history-search-field'),
    );
    await tester.enterText(searchField, 'PARTH');
    await tester.pump();

    expect(find.text('Corner Cafe'), findsOneWidget);
    expect(find.text('Berlin Synthetic Market'), findsNothing);

    await tester.enterText(searchField, 'missing merchant');
    await tester.pump();

    expect(
      find.byKey(const ValueKey('expense-history-no-matches')),
      findsOneWidget,
    );
    expect(find.text('No matching expenses'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('clear-no-matches-search-button')),
    );
    await tester.pump();

    expect(find.text('Berlin Synthetic Market'), findsOneWidget);
    expect(find.text('Corner Cafe'), findsOneWidget);
    expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
  });

  testWidgets('opens the selected saved expense', (tester) async {
    final expense = persistedExpenseFixture(
      id: 'saved-expense',
      merchant: 'SplitLens Synthetic Market',
    );
    await _pumpHistory(
      tester,
      FakeExpenseRepository(initialExpenses: [expense]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-expense-saved-expense')));
    await tester.pumpAndSettle();

    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text('SplitLens Synthetic Market'), findsOneWidget);
    expect(find.text('Paid by Anand'), findsOneWidget);
  });

  testWidgets('refreshes history after a confirmed expense deletion', (
    tester,
  ) async {
    final expense = persistedExpenseFixture(
      id: 'saved-expense',
      merchant: 'SplitLens Synthetic Market',
    );
    final repository = FakeExpenseRepository(initialExpenses: [expense]);
    await _pumpHistory(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-expense-saved-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete expense?'), findsOneWidget);
    expect(repository.deleteRequests, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('confirm-delete-expense-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.deleteRequests, [expense.id]);
    expect(find.byKey(const ValueKey('expense-history-empty')), findsOneWidget);
    expect(find.text('Expense deleted.'), findsOneWidget);
  });

  testWidgets('adapts expense cards for narrow large-text screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final expense = persistedExpenseFixture(
      id: 'saved-expense',
      merchant: 'SplitLens Synthetic Neighborhood Market',
      totalCents: 599,
      participantNames: const ['Anand', 'Malavika', 'Parth'],
    );

    await _pumpHistory(
      tester,
      FakeExpenseRepository(initialExpenses: [expense]),
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();

    expect(find.text('€5.99'), findsOneWidget);
    expect(find.text('3 participants'), findsOneWidget);
    final historyCard = find.bySemanticsLabel(
      RegExp(
        r'SplitLens Synthetic Neighborhood Market, .*€5\.99, '
        r'3 participants\. Open expense details\.',
      ),
    );
    expect(historyCard, findsOneWidget);
    expect(
      tester
          .getSemantics(historyCard)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('shows an error and retries the repository read', (tester) async {
    var loadCount = 0;
    final expense = persistedExpenseFixture();
    final repository = FakeExpenseRepository(
      onGetAll: () async {
        loadCount++;
        if (loadCount == 1) {
          throw StateError('synthetic database failure');
        }
        return [expense];
      },
    );
    await _pumpHistory(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-history-error')), findsOneWidget);
    expect(find.text('Expense history unavailable'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('retry-expense-history-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Market'), findsOneWidget);
    expect(loadCount, 2);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  FakeExpenseRepository repository, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const ExpenseHistoryScreen(),
      ),
    ),
  );
}
