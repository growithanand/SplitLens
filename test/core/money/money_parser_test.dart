import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/money/money_parser.dart';

void main() {
  group('MoneyParser.parseEur', () {
    test('parses supported decimal and currency forms', () {
      final examples = {
        '12.99': 1299,
        '12,99': 1299,
        '€12.99': 1299,
        '12,99 €': 1299,
        'EUR 12.99': 1299,
        'eur12,99': 1299,
        '12': 1200,
        '12.5': 1250,
      };

      for (final MapEntry(key: input, value: expectedCents)
          in examples.entries) {
        final result = MoneyParser.parseEur(input);

        expect(result.isSuccess, isTrue, reason: input);
        expect(result.error, isNull, reason: input);
        expect(result.money?.cents, expectedCents, reason: input);
      }
    });

    test('parses unambiguous thousands separators', () {
      final examples = {
        '1,234.56': 123456,
        '1.234,56': 123456,
        '1 234,56': 123456,
        '1,234,567.89': 123456789,
        '1.234.567,89': 123456789,
      };

      for (final MapEntry(key: input, value: expectedCents)
          in examples.entries) {
        expect(
          MoneyParser.parseEur(input).money?.cents,
          expectedCents,
          reason: input,
        );
      }
    });

    test('accepts the largest supported amount', () {
      final result = MoneyParser.parseEur('€999,999,999.99');

      expect(result.money, Money.eur(Money.maxCents));
    });

    test('reports empty input', () {
      _expectFailure('   ', MoneyParseError.empty);
    });

    test('reports negative amounts', () {
      _expectFailure('-1.00', MoneyParseError.negativeAmount);
      _expectFailure('(1.00)', MoneyParseError.negativeAmount);
    });

    test('reports unsupported currencies', () {
      _expectFailure('USD 12.99', MoneyParseError.unsupportedCurrency);
      _expectFailure('£12.99', MoneyParseError.unsupportedCurrency);
    });

    test('rejects malformed amounts', () {
      _expectFailure('12.3456', MoneyParseError.invalidFormat);
      _expectFailure('1,23,4.56', MoneyParseError.invalidFormat);
      _expectFailure('EUR 12.99 €', MoneyParseError.invalidFormat);
      _expectFailure('12..99', MoneyParseError.invalidFormat);
    });

    test('rejects ambiguous single separators', () {
      _expectFailure('1,234', MoneyParseError.ambiguousSeparator);
      _expectFailure('1.234', MoneyParseError.ambiguousSeparator);
    });

    test('reports values above the supported maximum', () {
      _expectFailure('€1,000,000,000.00', MoneyParseError.amountTooLarge);
      _expectFailure(
        '999999999999999999999.00',
        MoneyParseError.amountTooLarge,
      );
    });
  });
}

void _expectFailure(String input, MoneyParseError expectedError) {
  final result = MoneyParser.parseEur(input);

  expect(result.isSuccess, isFalse, reason: input);
  expect(result.money, isNull, reason: input);
  expect(result.error, expectedError, reason: input);
}
