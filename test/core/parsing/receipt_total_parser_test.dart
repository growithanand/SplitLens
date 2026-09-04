import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/parsing/receipt_total_parser.dart';

void main() {
  group('ReceiptTotalParser', () {
    test('recognizes every supported English and German label', () {
      final examples = {
        'GRAND TOTAL': ReceiptTotalLabel.grandTotal,
        'total': ReceiptTotalLabel.total,
        'AMOUNT': ReceiptTotalLabel.amount,
        'GESAMT': ReceiptTotalLabel.gesamt,
        'SUMME': ReceiptTotalLabel.summe,
        'BETRAG': ReceiptTotalLabel.betrag,
        'ZAHLBETRAG': ReceiptTotalLabel.zahlbetrag,
      };

      for (final MapEntry(key: label, value: expectedLabel)
          in examples.entries) {
        final result = ReceiptTotalParser.parse('$label EUR 1.00');

        expect(
          (result as ReceiptTotalFound).candidate.label,
          expectedLabel,
          reason: label,
        );
      }
    });

    test('extracts one obvious English total with a decimal point', () {
      const receipt = '''
SYNTHETIC CORNER SHOP
TEST RECEIPT - NO REAL PURCHASE
TOTAL EUR 12.99
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(1299));
      expect(candidate.label, ReceiptTotalLabel.total);
      expect(candidate.sourceText, 'EUR 12.99');
    });

    test('extracts a German total with a decimal comma', () {
      const receipt = '''
SYNTHETISCHER MARKT
TESTBELEG - KEIN ECHTER EINKAUF
GESAMT 12,99 €
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(1299));
      expect(candidate.label, ReceiptTotalLabel.gesamt);
      expect(candidate.sourceText, '12,99 €');
    });

    test('prefers TOTAL over a preceding SUBTOTAL', () {
      const receipt = '''
SUBTOTAL EUR 18.00
TOTAL EUR 20.00
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(2000));
      expect(candidate.label, ReceiptTotalLabel.total);
    });

    test('does not mistake tax for the final total', () {
      const receipt = '''
NET EUR 10.00
TAX EUR 1.90
GRAND TOTAL EUR 11.90
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(1190));
      expect(candidate.label, ReceiptTotalLabel.grandTotal);
    });

    test('reports distinct near-tied total candidates as ambiguous', () {
      const receipt = '''
TOTAL EUR 10.00
TOTAL EUR 12.00
''';

      final result = ReceiptTotalParser.parse(receipt);

      expect(result, isA<ReceiptTotalAmbiguous>());
      final candidates = (result as ReceiptTotalAmbiguous).candidates;
      expect(candidates.map((candidate) => candidate.money.cents).toSet(), {
        1000,
        1200,
      });
    });

    test('ranks a stronger final-total label above AMOUNT', () {
      const receipt = '''
AMOUNT EUR 10.00
GRAND TOTAL EUR 12.00
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(1200));
      expect(candidate.label, ReceiptTotalLabel.grandTotal);
    });

    test('reads an amount from the line immediately after its label', () {
      const receipt = '''
ZAHLBETRAG
24,50 €
''';

      final result = ReceiptTotalParser.parse(receipt);

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(2450));
      expect(candidate.label, ReceiptTotalLabel.zahlbetrag);
    });

    test('does not choose the largest unrelated receipt number', () {
      const receipt = '''
ITEM 1 EUR 99.00
ITEM 2 EUR 50.00
TOTAL EUR 12.50
''';

      final result = ReceiptTotalParser.parse(receipt);

      expect((result as ReceiptTotalFound).candidate.money, Money.eur(1250));
    });

    test('distinguishes a missing total label', () {
      final result = ReceiptTotalParser.parse('ITEM EUR 12.99');

      expect(result, isA<ReceiptTotalNotFound>());
      expect(
        (result as ReceiptTotalNotFound).reason,
        ReceiptTotalNotFoundReason.missingTotalLabel,
      );
    });

    test('distinguishes a total label without a valid amount', () {
      final result = ReceiptTotalParser.parse('TOTAL 12.3456');

      expect(result, isA<ReceiptTotalNotFound>());
      expect(
        (result as ReceiptTotalNotFound).reason,
        ReceiptTotalNotFoundReason.noValidAmount,
      );
    });

    test('tolerates common OCR spacing around a label and separator', () {
      final result = ReceiptTotalParser.parse('G E S A M T   12 , 99 €');

      final candidate = (result as ReceiptTotalFound).candidate;
      expect(candidate.money, Money.eur(1299));
      expect(candidate.label, ReceiptTotalLabel.gesamt);
    });

    test('deduplicates repeated evidence for the same total', () {
      const receipt = '''
TOTAL EUR 12.00
ZAHLBETRAG 12,00 €
''';

      final result = ReceiptTotalParser.parse(receipt);

      expect(result, isA<ReceiptTotalFound>());
      expect((result as ReceiptTotalFound).candidate.money, Money.eur(1200));
    });

    test('exposes an immutable ambiguous-candidate list', () {
      final result = ReceiptTotalParser.parse(
        'TOTAL EUR 10.00\nTOTAL EUR 12.00',
      );
      final candidates = (result as ReceiptTotalAmbiguous).candidates;

      expect(
        () => candidates.add(
          ReceiptTotalCandidate(
            money: Money.eur(1400),
            label: ReceiptTotalLabel.total,
            labelSourceText: 'TOTAL',
            sourceText: 'EUR 14.00',
            lineIndex: 2,
            rankingScore: 100,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
