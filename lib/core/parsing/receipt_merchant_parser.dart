import 'package:splitlens/core/parsing/receipt_date_parser.dart';

final class ReceiptMerchantCandidate {
  const ReceiptMerchantCandidate({
    required this.name,
    required this.sourceText,
    required this.lineIndex,
    required this.rankingScore,
  });

  final String name;
  final String sourceText;

  /// Zero-based line containing the candidate.
  final int lineIndex;

  /// Deterministic confidence score used to compare candidates.
  final int rankingScore;
}

enum ReceiptMerchantNotFoundReason { noPlausibleMerchant }

sealed class ReceiptMerchantParseResult {
  const ReceiptMerchantParseResult();
}

final class ReceiptMerchantFound extends ReceiptMerchantParseResult {
  const ReceiptMerchantFound(this.candidate);

  final ReceiptMerchantCandidate candidate;
}

final class ReceiptMerchantNotFound extends ReceiptMerchantParseResult {
  const ReceiptMerchantNotFound(this.reason);

  final ReceiptMerchantNotFoundReason reason;
}

final class ReceiptMerchantUncertain extends ReceiptMerchantParseResult {
  ReceiptMerchantUncertain(Iterable<ReceiptMerchantCandidate> candidates)
    : candidates = List.unmodifiable(candidates);

  final List<ReceiptMerchantCandidate> candidates;
}

abstract final class ReceiptMerchantParser {
  static const _maximumLinesToInspect = 10;
  static const _ambiguityScoreMargin = 6;
  static const _minimumConfidentScore = 32;

  static final _whitespace = RegExp(r'\s+');
  static final _latinLetter = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');
  static final _nonLatinLetter = RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ]');
  static final _moneyLike = RegExp(
    r'(?:EUR|€)|(?:^|[^0-9])\d[\d .]*[.,]\s*\d{2}(?=$|[^0-9])',
    caseSensitive: false,
  );
  static final _phoneLabel = RegExp(
    r'\b(?:tel|telephone|telefon|phone|mobile|mobil|fax)\b',
    caseSensitive: false,
  );
  static final _phoneNumber = RegExp(r'(?:^|\s)\+?\d[\d ()/-]{7,}\d');
  static final _taxIdentifier = RegExp(
    r'\b(?:vat|ust[. -]?(?:id|nr)|umsatzsteuer|mwst|steuer(?:nummer|nr)?|tax\s*(?:id|no|number))\b',
    caseSensitive: false,
  );
  static final _receiptMetadata = RegExp(
    r'\b(?:receipt|beleg|bon|kassenbon|quittung|invoice|rechnung|order|transaction|transaktion|register|kasse|cashier|kassierer|terminal|date|datum|time|uhrzeit)\b',
    caseSensitive: false,
  );
  static final _totalOrPaymentMetadata = RegExp(
    r'\b(?:grand\s+total|sub\s*total|total|amount|gesamt|summe|betrag|zahlbetrag|zwischensumme|cash|bar|card|karte|visa|mastercard)\b',
    caseSensitive: false,
  );
  static final _postalCode = RegExp(r'(?:^|\s)\d{5}\s+[A-Za-zÀ-ÖØ-öø-ÿ]');
  static final _addressKeyword = RegExp(
    r'\b(?:street|st|road|rd|avenue|ave|boulevard|blvd|lane|drive|strasse|straße|str|weg|platz|allee)\b',
    caseSensitive: false,
  );
  static final _addressSuffixBeforeNumber = RegExp(
    r'(?:street|road|avenue|boulevard|lane|drive|strasse|straße|weg|platz|allee)\.?\s*\d',
    caseSensitive: false,
  );
  static final _itemQuantity = RegExp(r'^\d+\s*[xX×]\s+');
  static final _businessHint = RegExp(
    r'\b(?:gmbh|ag|kg|ug|ltd|limited|llc|inc|market|markt|restaurant|cafe|café|bäckerei|bakery|supermarkt)\b',
    caseSensitive: false,
  );

  static const _genericLetterPrefixes = <String>[
    'RECEIPT',
    'KASSENBON',
    'BELEG',
    'QUITTUNG',
    'CUSTOMERCOPY',
    'MERCHANTCOPY',
    'THANKYOU',
    'VIELENDANK',
    'WILLKOMMEN',
    'WELCOME',
  ];

  static const _metadataLetters = <String>{
    'TOTAL',
    'GRANDTOTAL',
    'SUBTOTAL',
    'AMOUNT',
    'GESAMT',
    'SUMME',
    'BETRAG',
    'ZAHLBETRAG',
    'ZWISCHENSUMME',
    'DATE',
    'DATUM',
    'TIME',
    'UHRZEIT',
  };

  static ReceiptMerchantParseResult parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final candidates = <ReceiptMerchantCandidate>[];
    final inspectedLineCount = lines.length < _maximumLinesToInspect
        ? lines.length
        : _maximumLinesToInspect;

    for (var lineIndex = 0; lineIndex < inspectedLineCount; ++lineIndex) {
      final sourceText = lines[lineIndex].trim();
      final normalized = sourceText.replaceAll(_whitespace, ' ');
      if (!_isPlausibleMerchantLine(normalized)) {
        continue;
      }

      candidates.add(
        ReceiptMerchantCandidate(
          name: normalized,
          sourceText: sourceText,
          lineIndex: lineIndex,
          rankingScore: _scoreCandidate(normalized, lineIndex),
        ),
      );
    }

    if (candidates.isEmpty) {
      return const ReceiptMerchantNotFound(
        ReceiptMerchantNotFoundReason.noPlausibleMerchant,
      );
    }

    candidates.sort(_compareCandidates);
    final uniqueByName = <String, ReceiptMerchantCandidate>{};
    for (final candidate in candidates) {
      uniqueByName.putIfAbsent(candidate.name.toLowerCase(), () => candidate);
    }

    final rankedCandidates = uniqueByName.values.toList();
    final best = rankedCandidates.first;
    final plausibleWinners = rankedCandidates
        .where(
          (candidate) =>
              best.rankingScore - candidate.rankingScore <=
              _ambiguityScoreMargin,
        )
        .toList();

    if (plausibleWinners.length > 1 ||
        best.rankingScore < _minimumConfidentScore) {
      return ReceiptMerchantUncertain(plausibleWinners);
    }
    return ReceiptMerchantFound(best);
  }

  static bool _isPlausibleMerchantLine(String line) {
    if (line.length < 2 || line.length > 60) {
      return false;
    }

    final letters = _latinLetter.allMatches(line).length;
    final digits = RegExp(r'\d').allMatches(line).length;
    if (letters < 2 || digits > letters) {
      return false;
    }

    final lettersOnly = line.toUpperCase().replaceAll(_nonLatinLetter, '');
    if (_metadataLetters.contains(lettersOnly) ||
        _genericLetterPrefixes.any(lettersOnly.startsWith)) {
      return false;
    }

    if (ReceiptDateParser.parse(line) is! ReceiptDateNotFound ||
        _moneyLike.hasMatch(line) ||
        _phoneLabel.hasMatch(line) ||
        _phoneNumber.hasMatch(line) ||
        _taxIdentifier.hasMatch(line) ||
        _receiptMetadata.hasMatch(line) ||
        _totalOrPaymentMetadata.hasMatch(line) ||
        _postalCode.hasMatch(line) ||
        _itemQuantity.hasMatch(line) ||
        line.contains('@') ||
        line.toLowerCase().contains('www.') ||
        line.toLowerCase().contains('http')) {
      return false;
    }

    final containsDigit = digits > 0;
    if ((containsDigit && _addressKeyword.hasMatch(line)) ||
        _addressSuffixBeforeNumber.hasMatch(line)) {
      return false;
    }

    return true;
  }

  static int _scoreCandidate(String line, int lineIndex) {
    final rawLinePenalty = lineIndex * 4;
    final linePenalty = rawLinePenalty > 28 ? 28 : rawLinePenalty;
    var score = 40 - linePenalty;

    final words = line.split(' ');
    if (words.length <= 5) {
      score += 4;
    } else {
      score -= 8;
    }

    final lettersOnly = line.replaceAll(_nonLatinLetter, '');
    if (lettersOnly.length >= 2 && lettersOnly == lettersOnly.toUpperCase()) {
      score += 4;
    }
    if (!RegExp(r'\d').hasMatch(line)) {
      score += 4;
    }
    if (_businessHint.hasMatch(line)) {
      score += 15;
    }

    return score;
  }

  static int _compareCandidates(
    ReceiptMerchantCandidate left,
    ReceiptMerchantCandidate right,
  ) {
    final byScore = right.rankingScore.compareTo(left.rankingScore);
    if (byScore != 0) {
      return byScore;
    }

    final byLine = left.lineIndex.compareTo(right.lineIndex);
    if (byLine != 0) {
      return byLine;
    }
    return left.name.compareTo(right.name);
  }
}
