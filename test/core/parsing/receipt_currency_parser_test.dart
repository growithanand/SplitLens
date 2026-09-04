import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/parsing/receipt_currency_parser.dart';

void main() {
  group('ReceiptCurrencyParser', () {
    test('recognizes and normalizes EUR in a synthetic English receipt', () {
      const receipt = '''
SYNTHETIC CORNER SHOP
TEST RECEIPT - NO REAL PURCHASE
TOTAL EUR 12.99
''';

      final result = ReceiptCurrencyParser.parse(receipt);

      expect(result, isA<ReceiptCurrencyFound>());
      expect((result as ReceiptCurrencyFound).currencyCode, 'EUR');
      expect(result.sourceText, 'EUR');
    });

    test('recognizes the euro symbol in a synthetic German receipt', () {
      const receipt = '''
SYNTHETISCHER MARKT
TESTBELEG - KEIN ECHTER EINKAUF
GESAMT 12,99 €
''';

      final result = ReceiptCurrencyParser.parse(receipt);

      expect(result, isA<ReceiptCurrencyFound>());
      expect((result as ReceiptCurrencyFound).currencyCode, 'EUR');
      expect(result.sourceText, '€');
    });

    test('recognizes lowercase currency codes', () {
      final result = ReceiptCurrencyParser.parse('amount 7,50 eur');

      expect((result as ReceiptCurrencyFound).currencyCode, 'EUR');
      expect(result.sourceText, 'eur');
    });

    test('does not match EUR inside another word', () {
      final result = ReceiptCurrencyParser.parse('NEURO MARKET\nTOTAL 12.99');

      expect(result, isA<ReceiptCurrencyNotFound>());
    });

    test('reports missing when only an unsupported currency is present', () {
      final result = ReceiptCurrencyParser.parse('TOTAL USD 12.99');

      expect(result, isA<ReceiptCurrencyNotFound>());
    });

    test('uses the earliest supported marker as evidence', () {
      final result = ReceiptCurrencyParser.parse('€ 12,99\nTOTAL EUR 12,99');

      expect((result as ReceiptCurrencyFound).sourceText, '€');
    });
  });
}
