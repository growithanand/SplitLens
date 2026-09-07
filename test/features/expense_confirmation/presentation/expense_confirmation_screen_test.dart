import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/presentation/expense_confirmation_screen.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

import '../../../support/fakes/fake_expense_repository.dart';

void main() {
  testWidgets('shows the reviewed receipt as fixed expense context', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Split the reviewed receipt'), findsOneWidget);
    expect(find.text('Synthetic Market'), findsOneWidget);
    expect(find.text('€5.99'), findsOneWidget);
    expect(find.text('04.09.2026 · EUR'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reviewed-receipt-summary-card')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows final validation when participants and payer are missing',
    (tester) async {
      await _pumpScreen(tester);

      final confirmButton = find.byKey(
        const ValueKey('confirm-expense-button'),
      );
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.text('Add at least one participant.'), findsOneWidget);
      expect(find.text('Select who paid for the expense.'), findsOneWidget);
      expect(find.byKey(const ValueKey('saved-expense-card')), findsNothing);
    },
  );

  testWidgets('saves a payer and exact participant allocations', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await _addParticipant(tester, 'Anand');
    await _addParticipant(tester, 'Mira');
    await _addParticipant(tester, 'Jonas');
    expect(
      find.text('Anand and Mira each receive one extra cent.'),
      findsOneWidget,
    );

    final payerChoice = find.byKey(const ValueKey('payer-choice-1'));
    await tester.ensureVisible(payerChoice);
    await tester.tap(payerChoice);
    await tester.pumpAndSettle();

    final confirmButton = find.byKey(const ValueKey('confirm-expense-button'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-expense-card')), findsOneWidget);
    expect(find.text('Expense saved'), findsOneWidget);
    expect(find.text('Paid by Mira'), findsOneWidget);
    expect(find.text('Expense saved on this device.'), findsOneWidget);
    expect(
      find.textContaining('Stored locally on this device'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    expect(
      find.byKey(const ValueKey('view-saved-expense-button')),
      findsOneWidget,
    );

    final viewSavedExpenseButton = find.byKey(
      const ValueKey('view-saved-expense-button'),
    );
    await tester.ensureVisible(viewSavedExpenseButton);
    await tester.tap(viewSavedExpenseButton);
    await tester.pumpAndSettle();

    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text('Synthetic Market'), findsOneWidget);
  });

  testWidgets('adapts participant entry for a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(tester, textScaler: const TextScaler.linear(2));

    final field = find.byKey(
      const ValueKey('expense-confirmation-participant-field'),
    );
    final addButton = find.byKey(
      const ValueKey('expense-confirmation-add-participant-button'),
    );
    expect(
      tester.getTopLeft(addButton).dy,
      greaterThan(tester.getBottomLeft(field).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows progress and a retryable save error', (tester) async {
    final pendingSave = Completer<PersistedExpense>();
    final repository = FakeExpenseRepository(onSave: (_) => pendingSave.future);
    await _pumpScreen(tester, repository: repository);
    await _addParticipant(tester, 'Anand');
    await tester.tap(find.byKey(const ValueKey('payer-choice-0')));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const ValueKey('confirm-expense-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Saving expense…'), findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    pendingSave.completeError(StateError('synthetic database failure'));
    await tester.pumpAndSettle();
    expect(find.text('Expense could not be saved. Try again.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-save-error-card')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  FakeExpenseRepository? repository,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final resolvedRepository = repository ?? FakeExpenseRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(resolvedRepository),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: ExpenseConfirmationScreen(receipt: _receipt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _addParticipant(WidgetTester tester, String name) async {
  final field = find.byKey(
    const ValueKey('expense-confirmation-participant-field'),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, name);
  await tester.tap(
    find.byKey(const ValueKey('expense-confirmation-add-participant-button')),
  );
  await tester.pumpAndSettle();
}

final _receipt = ConfirmedReceiptReview(
  merchant: 'Synthetic Market',
  date: DateTime(2026, 9, 4),
  currencyCode: 'EUR',
  total: Money.eur(599),
  receiptImagePath: 'synthetic-receipt.png',
  rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 5.99',
);
