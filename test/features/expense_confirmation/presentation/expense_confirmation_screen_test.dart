import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/expense_confirmation/presentation/expense_confirmation_screen.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

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
      expect(
        find.byKey(const ValueKey('confirmed-expense-card')),
        findsNothing,
      );
    },
  );

  testWidgets('confirms a payer and exact participant allocations', (
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

    expect(
      find.byKey(const ValueKey('confirmed-expense-card')),
      findsOneWidget,
    );
    expect(find.text('Expense ready to save'), findsOneWidget);
    expect(find.text('Paid by Mira'), findsOneWidget);
    expect(find.text('Expense confirmed in memory.'), findsOneWidget);
    expect(
      find.textContaining('currently held in memory only'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ExpenseConfirmationScreen(receipt: _receipt)),
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
