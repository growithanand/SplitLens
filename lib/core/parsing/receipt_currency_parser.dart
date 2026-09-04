sealed class ReceiptCurrencyParseResult {
  const ReceiptCurrencyParseResult();
}

final class ReceiptCurrencyFound extends ReceiptCurrencyParseResult {
  const ReceiptCurrencyFound({
    required this.currencyCode,
    required this.sourceText,
  });

  final String currencyCode;
  final String sourceText;
}

final class ReceiptCurrencyNotFound extends ReceiptCurrencyParseResult {
  const ReceiptCurrencyNotFound();
}

abstract final class ReceiptCurrencyParser {
  static final _eurCode = RegExp(
    r'(^|[^A-Za-z])(EUR)(?=$|[^A-Za-z])',
    caseSensitive: false,
  );

  static ReceiptCurrencyParseResult parse(String rawText) {
    final euroSymbolOffset = rawText.indexOf('€');
    final eurCodeMatch = _eurCode.firstMatch(rawText);
    final eurCodeOffset = eurCodeMatch == null
        ? -1
        : eurCodeMatch.start + eurCodeMatch.group(1)!.length;

    if (euroSymbolOffset < 0 && eurCodeOffset < 0) {
      return const ReceiptCurrencyNotFound();
    }

    final sourceText =
        euroSymbolOffset >= 0 &&
            (eurCodeOffset < 0 || euroSymbolOffset < eurCodeOffset)
        ? '€'
        : eurCodeMatch!.group(2)!;
    return ReceiptCurrencyFound(currencyCode: 'EUR', sourceText: sourceText);
  }
}
