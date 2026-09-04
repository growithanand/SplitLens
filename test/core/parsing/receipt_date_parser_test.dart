import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/parsing/receipt_date_parser.dart';

void main() {
  group('ReceiptDateParser', () {
    test('parses dd.MM.yyyy from a synthetic German receipt', () {
      const receipt = '''
SYNTHETISCHER MARKT
TESTBELEG - KEIN ECHTER EINKAUF
DATUM 04.09.2026
GESAMT 12,99 €
''';

      final result = ReceiptDateParser.parse(receipt);

      final candidate = (result as ReceiptDateFound).candidate;
      expect(candidate.date, DateTime(2026, 9, 4));
      expect(candidate.sourceText, '04.09.2026');
      expect(candidate.format, ReceiptDateFormat.dayMonthYearDots);
    });

    test('parses dd/MM/yyyy from a synthetic English receipt', () {
      const receipt = '''
SYNTHETIC CORNER SHOP
TEST RECEIPT - NO REAL PURCHASE
DATE 04/09/2026
TOTAL EUR 12.99
''';

      final result = ReceiptDateParser.parse(receipt);

      final candidate = (result as ReceiptDateFound).candidate;
      expect(candidate.date, DateTime(2026, 9, 4));
      expect(candidate.format, ReceiptDateFormat.dayMonthYearSlashes);
    });

    test('parses yyyy-MM-dd', () {
      final result = ReceiptDateParser.parse('DATE 2026-09-04');

      final candidate = (result as ReceiptDateFound).candidate;
      expect(candidate.date, DateTime(2026, 9, 4));
      expect(candidate.format, ReceiptDateFormat.yearMonthDayDashes);
    });

    test('accepts a valid leap day', () {
      final result = ReceiptDateParser.parse('DATUM 29.02.2024');

      expect(
        (result as ReceiptDateFound).candidate.date,
        DateTime(2024, 2, 29),
      );
    });

    test('rejects impossible calendar dates', () {
      expect(
        ReceiptDateParser.parse('DATE 31/02/2026'),
        isA<ReceiptDateNotFound>(),
      );
      expect(
        ReceiptDateParser.parse('DATE 29.02.2025'),
        isA<ReceiptDateNotFound>(),
      );
      expect(
        ReceiptDateParser.parse('DATE 2026-13-04'),
        isA<ReceiptDateNotFound>(),
      );
    });

    test('does not guess the century for two-digit years', () {
      final result = ReceiptDateParser.parse('DATUM 04.09.26');

      expect(result, isA<ReceiptDateNotFound>());
    });

    test('reports multiple distinct valid dates as ambiguous', () {
      const receipt = '''
ORDER DATE 03.09.2026
RECEIPT DATE 04.09.2026
''';

      final result = ReceiptDateParser.parse(receipt);

      expect(result, isA<ReceiptDateAmbiguous>());
      final candidates = (result as ReceiptDateAmbiguous).candidates;
      expect(candidates.map((candidate) => candidate.date), [
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 4),
      ]);
    });

    test('deduplicates repeated representations of the same date', () {
      const receipt = '''
DATE 04.09.2026
ARCHIVE 2026-09-04
''';

      final result = ReceiptDateParser.parse(receipt);

      expect(result, isA<ReceiptDateFound>());
      final candidate = (result as ReceiptDateFound).candidate;
      expect(candidate.date, DateTime(2026, 9, 4));
      expect(candidate.sourceText, '04.09.2026');
    });

    test('reports missing when no supported date is present', () {
      final result = ReceiptDateParser.parse('SYNTHETIC RECEIPT\nNO DATE');

      expect(result, isA<ReceiptDateNotFound>());
    });

    test('exposes an immutable ambiguous-candidate list', () {
      final result = ReceiptDateParser.parse(
        'ORDER 03.09.2026\nRECEIPT 04.09.2026',
      );
      final candidates = (result as ReceiptDateAmbiguous).candidates;

      expect(
        () => candidates.add(
          ReceiptDateCandidate(
            date: DateTime(2026, 9, 5),
            sourceText: '05.09.2026',
            format: ReceiptDateFormat.dayMonthYearDots,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
