import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/money/money_parser.dart';

enum ReceiptTotalLabel {
  grandTotal,
  total,
  amount,
  gesamt,
  summe,
  betrag,
  zahlbetrag,
}

final class ReceiptTotalCandidate {
  const ReceiptTotalCandidate({
    required this.money,
    required this.label,
    required this.labelSourceText,
    required this.sourceText,
    required this.lineIndex,
    required this.rankingScore,
  });

  final Money money;
  final ReceiptTotalLabel label;
  final String labelSourceText;
  final String sourceText;

  /// Zero-based line containing the monetary value.
  final int lineIndex;

  /// Deterministic confidence score used to compare candidates.
  final int rankingScore;
}

enum ReceiptTotalNotFoundReason { missingTotalLabel, noValidAmount }

sealed class ReceiptTotalParseResult {
  const ReceiptTotalParseResult();
}

final class ReceiptTotalFound extends ReceiptTotalParseResult {
  const ReceiptTotalFound(this.candidate);

  final ReceiptTotalCandidate candidate;
}

final class ReceiptTotalNotFound extends ReceiptTotalParseResult {
  const ReceiptTotalNotFound(this.reason);

  final ReceiptTotalNotFoundReason reason;
}

final class ReceiptTotalAmbiguous extends ReceiptTotalParseResult {
  ReceiptTotalAmbiguous(Iterable<ReceiptTotalCandidate> candidates)
    : candidates = List.unmodifiable(candidates);

  final List<ReceiptTotalCandidate> candidates;
}

abstract final class ReceiptTotalParser {
  static const _ambiguityScoreMargin = 4;

  static final _amountExpression = RegExp(
    r'(^|[^A-Za-z0-9])((?:(?:EUR|€)\s*)?[0-9](?:[0-9.,\s]*[0-9])?(?:\s*(?:EUR|€))?)(?=$|[^A-Za-z0-9])',
    caseSensitive: false,
  );
  static final _currencyMarker = RegExp(r'EUR|€', caseSensitive: false);
  static final _nonLetters = RegExp('[^A-Z]');
  static final _separatorSpacing = RegExp(r'\s*([.,])\s*');

  // Specific compound labels precede their shorter suffixes so a line such as
  // "GRAND TOTAL" produces one label rather than a second TOTAL candidate.
  static final _labelPatterns = <_TotalLabelPattern>[
    _TotalLabelPattern(
      label: ReceiptTotalLabel.grandTotal,
      expression: RegExp(
        r'(^|[^A-Z])(G\s*R\s*A\s*N\s*D\s*T\s*O\s*T\s*A\s*L)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 60,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.zahlbetrag,
      expression: RegExp(
        r'(^|[^A-Z])(Z\s*A\s*H\s*L\s*B\s*E\s*T\s*R\s*A\s*G)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 60,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.total,
      expression: RegExp(
        r'(^|[^A-Z])(T\s*O\s*T\s*A\s*L)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 50,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.gesamt,
      expression: RegExp(
        r'(^|[^A-Z])(G\s*E\s*S\s*A\s*M\s*T)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 50,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.summe,
      expression: RegExp(
        r'(^|[^A-Z])(S\s*U\s*M\s*M\s*E)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 50,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.amount,
      expression: RegExp(
        r'(^|[^A-Z])(A\s*M\s*O\s*U\s*N\s*T)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 45,
    ),
    _TotalLabelPattern(
      label: ReceiptTotalLabel.betrag,
      expression: RegExp(
        r'(^|[^A-Z])(B\s*E\s*T\s*R\s*A\s*G)(?=$|[^A-Z])',
        caseSensitive: false,
      ),
      strength: 45,
    ),
  ];

  static ReceiptTotalParseResult parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final candidates = <ReceiptTotalCandidate>[];
    var foundSupportedLabel = false;

    for (
      var labelLineIndex = 0;
      labelLineIndex < lines.length;
      ++labelLineIndex
    ) {
      final labelLine = lines[labelLineIndex];
      if (_looksLikeSubtotal(labelLine)) {
        continue;
      }

      final labelMatch = _findLabel(labelLine);
      if (labelMatch == null) {
        continue;
      }
      foundSupportedLabel = true;

      candidates.addAll(
        _candidatesForLine(
          line: labelLine,
          amountLineIndex: labelLineIndex,
          lineCount: lines.length,
          labelMatch: labelMatch,
          isLabelLine: true,
        ),
      );

      final followingLineIndex = labelLineIndex + 1;
      if (followingLineIndex < lines.length) {
        candidates.addAll(
          _candidatesForLine(
            line: lines[followingLineIndex],
            amountLineIndex: followingLineIndex,
            lineCount: lines.length,
            labelMatch: labelMatch,
            isLabelLine: false,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return ReceiptTotalNotFound(
        foundSupportedLabel
            ? ReceiptTotalNotFoundReason.noValidAmount
            : ReceiptTotalNotFoundReason.missingTotalLabel,
      );
    }

    candidates.sort(_compareCandidates);
    final uniqueByAmount = <int, ReceiptTotalCandidate>{};
    for (final candidate in candidates) {
      uniqueByAmount.putIfAbsent(candidate.money.cents, () => candidate);
    }

    final rankedCandidates = uniqueByAmount.values.toList();
    final bestScore = rankedCandidates.first.rankingScore;
    final plausibleWinners = rankedCandidates
        .where(
          (candidate) =>
              bestScore - candidate.rankingScore <= _ambiguityScoreMargin,
        )
        .toList();

    if (plausibleWinners.length > 1) {
      return ReceiptTotalAmbiguous(plausibleWinners);
    }
    return ReceiptTotalFound(rankedCandidates.first);
  }

  static Iterable<ReceiptTotalCandidate> _candidatesForLine({
    required String line,
    required int amountLineIndex,
    required int lineCount,
    required _TotalLabelMatch labelMatch,
    required bool isLabelLine,
  }) sync* {
    for (final amountMatch in _findAmounts(line)) {
      final proximityScore = isLabelLine
          ? _sameLineProximityScore(labelMatch, amountMatch)
          : 0;
      final positionScore = lineCount <= 1
          ? 0
          : (amountLineIndex * 4) ~/ (lineCount - 1);
      final rankingScore =
          labelMatch.strength +
          (isLabelLine ? 30 : 15) +
          proximityScore +
          (amountMatch.hasCurrencyMarker ? 6 : 0) +
          positionScore;

      yield ReceiptTotalCandidate(
        money: amountMatch.money,
        label: labelMatch.label,
        labelSourceText: labelMatch.sourceText,
        sourceText: amountMatch.sourceText,
        lineIndex: amountLineIndex,
        rankingScore: rankingScore,
      );
    }
  }

  static _TotalLabelMatch? _findLabel(String line) {
    for (final pattern in _labelPatterns) {
      final match = pattern.expression.firstMatch(line);
      if (match == null) {
        continue;
      }

      final prefixLength = match.group(1)!.length;
      final start = match.start + prefixLength;
      final sourceText = line.substring(start, match.end);
      return _TotalLabelMatch(
        label: pattern.label,
        sourceText: sourceText,
        start: start,
        end: match.end,
        strength: pattern.strength,
      );
    }
    return null;
  }

  static Iterable<_AmountMatch> _findAmounts(String line) sync* {
    for (final match in _amountExpression.allMatches(line)) {
      final sourceText = match.group(2)!;
      final normalizedText = sourceText
          .replaceAll('\u00a0', ' ')
          .replaceAll('\u202f', ' ')
          .replaceAllMapped(
            _separatorSpacing,
            (separatorMatch) => separatorMatch.group(1)!,
          )
          .trim();
      final parseResult = MoneyParser.parseEur(normalizedText);
      final money = parseResult.money;
      if (money == null) {
        continue;
      }

      final prefixLength = match.group(1)!.length;
      final start = match.start + prefixLength;
      yield _AmountMatch(
        money: money,
        sourceText: sourceText,
        start: start,
        end: start + sourceText.length,
        hasCurrencyMarker: _currencyMarker.hasMatch(sourceText),
      );
    }
  }

  static int _sameLineProximityScore(
    _TotalLabelMatch label,
    _AmountMatch amount,
  ) {
    if (amount.start >= label.end) {
      final distance = amount.start - label.end;
      return distance >= 10 ? 0 : 10 - distance;
    }

    final distance = label.start - amount.end;
    return distance >= 4 ? 0 : 4 - distance;
  }

  static bool _looksLikeSubtotal(String line) {
    final lettersOnly = line.toUpperCase().replaceAll(_nonLetters, '');
    return lettersOnly.contains('SUBTOTAL') ||
        lettersOnly.contains('ZWISCHENSUMME');
  }

  static int _compareCandidates(
    ReceiptTotalCandidate left,
    ReceiptTotalCandidate right,
  ) {
    final byScore = right.rankingScore.compareTo(left.rankingScore);
    if (byScore != 0) {
      return byScore;
    }

    final byLine = right.lineIndex.compareTo(left.lineIndex);
    if (byLine != 0) {
      return byLine;
    }
    return right.money.cents.compareTo(left.money.cents);
  }
}

final class _TotalLabelPattern {
  const _TotalLabelPattern({
    required this.label,
    required this.expression,
    required this.strength,
  });

  final ReceiptTotalLabel label;
  final RegExp expression;
  final int strength;
}

final class _TotalLabelMatch {
  const _TotalLabelMatch({
    required this.label,
    required this.sourceText,
    required this.start,
    required this.end,
    required this.strength,
  });

  final ReceiptTotalLabel label;
  final String sourceText;
  final int start;
  final int end;
  final int strength;
}

final class _AmountMatch {
  const _AmountMatch({
    required this.money,
    required this.sourceText,
    required this.start,
    required this.end,
    required this.hasCurrencyMarker,
  });

  final Money money;
  final String sourceText;
  final int start;
  final int end;
  final bool hasCurrencyMarker;
}
