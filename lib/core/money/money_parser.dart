import 'package:splitlens/core/money/money.dart';

enum MoneyParseError {
  empty,
  negativeAmount,
  unsupportedCurrency,
  invalidFormat,
  ambiguousSeparator,
  amountTooLarge,
}

final class MoneyParseResult {
  const MoneyParseResult.success(Money this.money) : error = null;

  const MoneyParseResult.failure(MoneyParseError this.error) : money = null;

  final Money? money;
  final MoneyParseError? error;

  bool get isSuccess => money != null;
}

abstract final class MoneyParser {
  static final _leadingCurrency = RegExp(r'^(EUR|€)\s*', caseSensitive: false);
  static final _trailingCurrency = RegExp(r'\s*(EUR|€)$', caseSensitive: false);
  static final _unsupportedCurrency = RegExp(r'[A-Za-z$£¥€]');
  static final _allowedAmountCharacters = RegExp(r'^[0-9., ]+$');
  static final _digitsOnly = RegExp(r'^\d+$');

  static MoneyParseResult parseEur(String input) {
    var amountText = input
        .trim()
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u202f', ' ');

    if (amountText.isEmpty) {
      return const MoneyParseResult.failure(MoneyParseError.empty);
    }

    final leadingMatch = _leadingCurrency.firstMatch(amountText);
    final hadLeadingCurrency = leadingMatch != null;
    if (leadingMatch != null) {
      amountText = amountText.substring(leadingMatch.end).trim();
    }

    final trailingMatch = _trailingCurrency.firstMatch(amountText);
    final hadTrailingCurrency = trailingMatch != null;
    if (trailingMatch != null) {
      amountText = amountText.substring(0, trailingMatch.start).trim();
    }

    if (hadLeadingCurrency && hadTrailingCurrency) {
      return const MoneyParseResult.failure(MoneyParseError.invalidFormat);
    }

    if (amountText.isEmpty) {
      return const MoneyParseResult.failure(MoneyParseError.empty);
    }

    if (amountText.startsWith('-') ||
        (amountText.startsWith('(') && amountText.endsWith(')'))) {
      return const MoneyParseResult.failure(MoneyParseError.negativeAmount);
    }

    if (_unsupportedCurrency.hasMatch(amountText)) {
      return const MoneyParseResult.failure(
        MoneyParseError.unsupportedCurrency,
      );
    }

    if (!_allowedAmountCharacters.hasMatch(amountText)) {
      return const MoneyParseResult.failure(MoneyParseError.invalidFormat);
    }

    final parsed = _parseCents(amountText);
    final error = parsed.error;
    if (error != null) {
      return MoneyParseResult.failure(error);
    }

    return MoneyParseResult.success(Money.eur(parsed.cents!));
  }

  static ({int? cents, MoneyParseError? error}) _parseCents(String input) {
    final dotCount = '.'.allMatches(input).length;
    final commaCount = ','.allMatches(input).length;
    String? decimalSeparator;

    if (dotCount > 0 && commaCount > 0) {
      decimalSeparator = input.lastIndexOf('.') > input.lastIndexOf(',')
          ? '.'
          : ',';
      final decimalCount = decimalSeparator == '.' ? dotCount : commaCount;
      if (decimalCount != 1) {
        return (cents: null, error: MoneyParseError.invalidFormat);
      }
    } else {
      final separator = dotCount > 0
          ? '.'
          : commaCount > 0
          ? ','
          : null;
      final separatorCount = dotCount + commaCount;

      if (separator != null && separatorCount == 1) {
        final fractionLength = input.length - input.lastIndexOf(separator) - 1;
        if (fractionLength == 1 || fractionLength == 2) {
          decimalSeparator = separator;
        } else if (fractionLength == 3) {
          return (cents: null, error: MoneyParseError.ambiguousSeparator);
        } else {
          return (cents: null, error: MoneyParseError.invalidFormat);
        }
      }
    }

    final wholePart = decimalSeparator == null
        ? input
        : input.substring(0, input.lastIndexOf(decimalSeparator));
    final fractionPart = decimalSeparator == null
        ? '00'
        : input.substring(input.lastIndexOf(decimalSeparator) + 1);

    if (!_digitsOnly.hasMatch(fractionPart) || fractionPart.length > 2) {
      return (cents: null, error: MoneyParseError.invalidFormat);
    }

    final normalizedWhole = _normalizeWholePart(wholePart, decimalSeparator);
    if (normalizedWhole == null) {
      return (cents: null, error: MoneyParseError.invalidFormat);
    }

    final wholeEuros = int.tryParse(normalizedWhole);
    if (wholeEuros == null) {
      return (cents: null, error: MoneyParseError.amountTooLarge);
    }

    final normalizedFraction = fractionPart.padRight(2, '0');
    final cents = int.parse(normalizedFraction);
    final maximumWholeEuros = Money.maxCents ~/ 100;
    final maximumCentPart = Money.maxCents % 100;

    if (wholeEuros > maximumWholeEuros ||
        (wholeEuros == maximumWholeEuros && cents > maximumCentPart)) {
      return (cents: null, error: MoneyParseError.amountTooLarge);
    }

    return (cents: wholeEuros * 100 + cents, error: null);
  }

  static String? _normalizeWholePart(
    String wholePart,
    String? decimalSeparator,
  ) {
    if (wholePart.isEmpty) {
      return null;
    }

    final groupingSeparators = <String>{};
    for (final separator in [',', '.', ' ']) {
      if (separator != decimalSeparator && wholePart.contains(separator)) {
        groupingSeparators.add(separator);
      }
    }

    if (groupingSeparators.length > 1) {
      return null;
    }

    if (groupingSeparators.isEmpty) {
      return _digitsOnly.hasMatch(wholePart) ? wholePart : null;
    }

    final separator = groupingSeparators.single;
    final groups = wholePart.split(separator);
    if (groups.first.isEmpty || groups.first.length > 3) {
      return null;
    }

    if (groups.any((group) => !_digitsOnly.hasMatch(group)) ||
        groups.skip(1).any((group) => group.length != 3)) {
      return null;
    }

    return groups.join();
  }
}
