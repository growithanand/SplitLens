import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/expense_detail/presentation/expense_detail_screen.dart';

import '../../../support/fakes/fake_expense_repository.dart';
import '../../../support/fixtures/persisted_expense_fixture.dart';

void main() {
  testWidgets('shows loading while the expense is being read', (tester) async {
    final pendingExpense = Completer<PersistedExpense?>();
    await _pumpDetail(
      tester,
      FakeExpenseRepository(onGetById: (_) => pendingExpense.future),
    );

    expect(
      find.byKey(const ValueKey('expense-detail-loading')),
      findsOneWidget,
    );
    expect(find.text('Loading expense details…'), findsOneWidget);
  });

  testWidgets('shows expense summary, allocations, and receipt evidence', (
    tester,
  ) async {
    final expense = persistedExpenseFixture(
      id: 'saved-expense',
      merchant: 'SplitLens Synthetic Market',
      date: DateTime(2026, 9, 4),
      totalCents: 599,
      participantNames: const ['Anand', 'Mira', 'Parth'],
    );
    await _pumpDetail(
      tester,
      FakeExpenseRepository(initialExpenses: [expense]),
      expenseId: expense.id,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-detail-content')),
      findsOneWidget,
    );
    expect(find.text('SplitLens Synthetic Market'), findsOneWidget);
    expect(find.text('€5.99'), findsOneWidget);
    expect(find.text('04 Sep 2026'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('Paid by Anand'), findsOneWidget);
    expect(find.text('Anand'), findsOneWidget);
    expect(find.text('Mira'), findsOneWidget);
    expect(find.text('Parth'), findsOneWidget);
    expect(find.text('€2.00'), findsNWidgets(2));
    expect(find.text('€1.99'), findsOneWidget);
    expect(find.text('Paid for this expense'), findsOneWidget);

    final rawOcrSection = find.byKey(const ValueKey('expense-raw-ocr-section'));
    await tester.ensureVisible(rawOcrSection);
    await tester.tap(rawOcrSection);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-raw-ocr-text')), findsOneWidget);
    expect(find.textContaining('TOTAL EUR 5.99'), findsOneWidget);

    final imageSection = find.byKey(
      const ValueKey('expense-receipt-image-section'),
    );
    await tester.ensureVisible(imageSection);
    await tester.tap(imageSection);
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.descendant(of: imageSection, matching: find.byType(Image)),
    );
    final fileImage = image.image as FileImage;
    expect(fileImage.file.path, 'synthetic-receipt.png');
  });

  testWidgets('shows a missing-record state', (tester) async {
    await _pumpDetail(tester, FakeExpenseRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-detail-not-found')),
      findsOneWidget,
    );
    expect(find.text('Expense not found'), findsOneWidget);
  });

  testWidgets('shows an error and retries the expense read', (tester) async {
    var loadCount = 0;
    final expense = persistedExpenseFixture();
    final repository = FakeExpenseRepository(
      onGetById: (_) async {
        loadCount++;
        if (loadCount == 1) {
          throw StateError('synthetic database failure');
        }
        return expense;
      },
    );
    await _pumpDetail(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-detail-error')), findsOneWidget);
    expect(find.text('Expense details unavailable'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retry-expense-detail-button')));
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Market'), findsOneWidget);
    expect(loadCount, 2);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  FakeExpenseRepository repository, {
  String expenseId = 'expense-1',
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: ExpenseDetailScreen(expenseId: expenseId)),
    ),
  );
}
