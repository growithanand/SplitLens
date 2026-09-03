import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';

void main() {
  group('Money', () {
    test('stores EUR as integer cents', () {
      final money = Money.eur(1299);

      expect(money.cents, 1299);
      expect(money.currency, 'EUR');
    });

    test('allows zero cents', () {
      expect(Money.eur(0).cents, 0);
    });

    test('rejects a negative amount', () {
      expect(() => Money.eur(-1), throwsRangeError);
    });

    test('rejects an amount above the supported maximum', () {
      expect(() => Money.eur(Money.maxCents + 1), throwsRangeError);
    });

    test('formats EUR without floating-point conversion', () {
      expect(Money.eur(0).format(), '€0.00');
      expect(Money.eur(1299).format(), '€12.99');
      expect(Money.eur(123456789).format(), '€1,234,567.89');
    });

    test('uses value equality', () {
      expect(Money.eur(1299), Money.eur(1299));
      expect(Money.eur(1299), isNot(Money.eur(1300)));
      expect(Money.eur(1299).hashCode, Money.eur(1299).hashCode);
    });
  });
}
