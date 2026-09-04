import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/receipt_review/application/receipt_review_controller.dart';
import 'package:splitlens/features/receipt_review/presentation/receipt_review_screen.dart';

void main() {
  testWidgets('prefills reliable receipt suggestions for review', (
    tester,
  ) async {
    await _pumpScreen(tester, rawOcrText: _reliableReceipt);

    expect(find.text('Review receipt details'), findsOneWidget);
    expect(
      _fieldText(tester, ReceiptReviewField.merchant),
      'SYNTHETIC MARKET LTD',
    );
    expect(_fieldText(tester, ReceiptReviewField.date), '04.09.2026');
    expect(_fieldText(tester, ReceiptReviewField.currency), 'EUR');
    expect(_fieldText(tester, ReceiptReviewField.total), '12.99');
    expect(
      find.text('Suggested from the receipt — confirm or correct it.'),
      findsNWidgets(4),
    );
  });

  testWidgets('keeps the original image and raw OCR text accessible', (
    tester,
  ) async {
    await _pumpScreen(tester, rawOcrText: _reliableReceipt);

    expect(find.text('Original receipt image'), findsOneWidget);
    expect(find.text('Raw OCR text'), findsOneWidget);

    await tester.tap(find.text('Original receipt image'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-receipt-image')), findsOneWidget);

    await tester.ensureVisible(find.text('Raw OCR text'));
    await tester.tap(find.text('Raw OCR text'));
    await tester.pumpAndSettle();
    expect(find.text(_reliableReceipt), findsOneWidget);
  });

  testWidgets('shows ambiguous parser alternatives without prefilling', (
    tester,
  ) async {
    const rawOcrText = '''
SYNTHETIC MARKET LTD
ORDER DATE 03.09.2026
RECEIPT DATE 04.09.2026
TOTAL EUR 10.00
TOTAL EUR 12.00
''';
    await _pumpScreen(tester, rawOcrText: rawOcrText);

    expect(_fieldText(tester, ReceiptReviewField.date), isEmpty);
    expect(_fieldText(tester, ReceiptReviewField.total), isEmpty);
    expect(
      find.textContaining('Multiple suggestions found:'),
      findsNWidgets(2),
    );
  });

  testWidgets('shows validation errors instead of confirming empty fields', (
    tester,
  ) async {
    await _pumpScreen(tester, rawOcrText: 'RECEIPT');

    final confirmButton = find.byKey(
      const ValueKey('confirm-receipt-review-button'),
    );
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('confirmed-receipt-review-card')),
      findsNothing,
    );
  });

  testWidgets('confirms corrected values and preserves receipt evidence', (
    tester,
  ) async {
    final scope = await _pumpScreen(tester, rawOcrText: _reliableReceipt);
    await tester.enterText(
      _fieldFinder(ReceiptReviewField.merchant),
      'Edited Synthetic Market',
    );
    await tester.enterText(_fieldFinder(ReceiptReviewField.date), '2026-09-04');
    await tester.enterText(_fieldFinder(ReceiptReviewField.currency), 'EUR');
    await tester.enterText(_fieldFinder(ReceiptReviewField.total), '14,50');

    final confirmButton = find.byKey(
      const ValueKey('confirm-receipt-review-button'),
    );
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('confirmed-receipt-review-card')),
      findsOneWidget,
    );
    expect(find.text('Receipt details confirmed'), findsOneWidget);
    expect(find.text('Confirmed by you.'), findsNWidgets(4));
    final confirmation = scope.container
        .read(receiptReviewControllerProvider(scope.input))
        .confirmedReceipt!;
    expect(confirmation.merchant, 'Edited Synthetic Market');
    expect(confirmation.date, DateTime(2026, 9, 4));
    expect(confirmation.total, Money.eur(1450));
    expect(confirmation.rawOcrText, _reliableReceipt);
  });
}

Future<({ProviderContainer container, ReceiptReviewInput input})> _pumpScreen(
  WidgetTester tester, {
  required String rawOcrText,
}) async {
  final container = ProviderContainer();
  final input = ReceiptReviewInput(
    receiptImagePath: 'missing-synthetic-receipt.png',
    rawOcrText: rawOcrText,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReceiptReviewScreen(
          receiptImagePath: input.receiptImagePath,
          rawOcrText: input.rawOcrText,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, input: input);
}

Finder _fieldFinder(ReceiptReviewField field) =>
    find.byKey(ValueKey('receipt-review-${field.name}-field'));

String _fieldText(WidgetTester tester, ReceiptReviewField field) =>
    tester.widget<TextField>(_fieldFinder(field)).controller!.text;

const _reliableReceipt = '''
SYNTHETIC MARKET LTD
DATE 04.09.2026
TOTAL EUR 12.99
''';
