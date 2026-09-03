import 'package:intl/intl.dart';

final class Money {
  Money.eur(this.cents) {
    if (cents < 0 || cents > maxCents) {
      throw RangeError.range(cents, 0, maxCents, 'cents');
    }
  }

  static const currencyCode = 'EUR';

  /// The largest amount supported by v0.1: EUR 999,999,999.99.
  static const maxCents = 99_999_999_999;

  static final _wholeEuroFormat = NumberFormat.decimalPattern('en_US');

  final int cents;

  String get currency => currencyCode;

  String format() {
    final wholeEuros = cents ~/ 100;
    final centPart = (cents % 100).toString().padLeft(2, '0');
    final groupedEuros = _wholeEuroFormat.format(wholeEuros);

    return '€$groupedEuros.$centPart';
  }

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => Object.hash(currencyCode, cents);

  @override
  String toString() => 'Money(currency: $currencyCode, cents: $cents)';
}
