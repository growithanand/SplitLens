import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/parsing/receipt_merchant_parser.dart';

void main() {
  group('ReceiptMerchantParser', () {
    test('finds an early merchant on a synthetic English receipt', () {
      const receipt = '''
SYNTHETIC CORNER MARKET LTD
123 HIGH STREET
LONDON
DATE 04/09/2026
TOTAL EUR 12.99
''';

      final result = ReceiptMerchantParser.parse(receipt);

      final candidate = (result as ReceiptMerchantFound).candidate;
      expect(candidate.name, 'SYNTHETIC CORNER MARKET LTD');
      expect(candidate.lineIndex, 0);
    });

    test('finds an early merchant on a synthetic German receipt', () {
      const receipt = '''
Synthetische Bäckerei Müller GmbH
Musterstraße 12
10115 Berlin
DATUM 04.09.2026
GESAMT 12,99 €
''';

      final result = ReceiptMerchantParser.parse(receipt);

      final candidate = (result as ReceiptMerchantFound).candidate;
      expect(candidate.name, 'Synthetische Bäckerei Müller GmbH');
      expect(candidate.lineIndex, 0);
    });

    test('rejects obvious non-merchant receipt metadata', () {
      const receipt = '''
RECEIPT
04/09/2026
TOTAL EUR 12.99
Tel: +49 30 12345678
VAT ID DE123456789
Receipt No. 12345
123 HIGH STREET
10115 Berlin
''';

      final result = ReceiptMerchantParser.parse(receipt);

      expect(result, isA<ReceiptMerchantNotFound>());
      expect(
        (result as ReceiptMerchantNotFound).reason,
        ReceiptMerchantNotFoundReason.noPlausibleMerchant,
      );
    });

    test('reports competing early names as uncertain', () {
      const receipt = '''
ALPHA FOODS
FRESH GOODS
TOTAL EUR 12.99
''';

      final result = ReceiptMerchantParser.parse(receipt);

      expect(result, isA<ReceiptMerchantUncertain>());
      final candidates = (result as ReceiptMerchantUncertain).candidates;
      expect(candidates.map((candidate) => candidate.name), [
        'ALPHA FOODS',
        'FRESH GOODS',
      ]);
    });

    test('reports a weak late candidate as uncertain', () {
      const receipt = '''
RECEIPT
DATE 04/09/2026
TIME 10:30
TEL +49 30 12345678
VAT ID DE123456789
SUBTOTAL EUR 10.00
TAX EUR 1.90
TOTAL EUR 11.90
Possible Shop
''';

      final result = ReceiptMerchantParser.parse(receipt);

      final candidates = (result as ReceiptMerchantUncertain).candidates;
      expect(candidates.single.name, 'Possible Shop');
    });

    test('normalizes repeated OCR whitespace in the proposed name', () {
      final result = ReceiptMerchantParser.parse(
        'SYNTHETIC   MARKET   GMBH\nTOTAL EUR 1.00',
      );

      expect(
        (result as ReceiptMerchantFound).candidate.name,
        'SYNTHETIC MARKET GMBH',
      );
    });

    test('allows a plausible merchant name containing digits', () {
      final result = ReceiptMerchantParser.parse(
        'Studio 54 GmbH\nTOTAL EUR 20.00',
      );

      expect((result as ReceiptMerchantFound).candidate.name, 'Studio 54 GmbH');
    });

    test('deduplicates a repeated merchant name', () {
      const receipt = '''
SAMPLE MARKET
SAMPLE MARKET
TOTAL EUR 5.00
''';

      final result = ReceiptMerchantParser.parse(receipt);

      expect(result, isA<ReceiptMerchantFound>());
      expect((result as ReceiptMerchantFound).candidate.name, 'SAMPLE MARKET');
    });

    test('does not inspect merchant-like text deep in a receipt', () {
      const receipt = '''
RECEIPT
DATE 04/09/2026
TIME 10:30
TEL +49 30 12345678
VAT ID DE123456789
SUBTOTAL EUR 10.00
TAX EUR 1.90
TOTAL EUR 11.90
CARD
THANK YOU
UNRELATED COMPANY GMBH
''';

      final result = ReceiptMerchantParser.parse(receipt);

      expect(result, isA<ReceiptMerchantNotFound>());
    });

    test('rejects websites and email addresses', () {
      const receipt = '''
www.synthetic-market.example
hello@synthetic-market.example
TOTAL EUR 1.00
''';

      final result = ReceiptMerchantParser.parse(receipt);

      expect(result, isA<ReceiptMerchantNotFound>());
    });

    test('exposes an immutable uncertain-candidate list', () {
      final result = ReceiptMerchantParser.parse(
        'ALPHA FOODS\nFRESH GOODS\nTOTAL EUR 12.99',
      );
      final candidates = (result as ReceiptMerchantUncertain).candidates;

      expect(
        () => candidates.add(
          const ReceiptMerchantCandidate(
            name: 'ANOTHER SHOP',
            sourceText: 'ANOTHER SHOP',
            lineIndex: 2,
            rankingScore: 40,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
