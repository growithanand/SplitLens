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
  static const _followingLineWindow = 5;
  static const _columnEndBonus = 10;

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

      final followingLines = _followingAmountLines(
        lines: lines,
        labelLineIndex: labelLineIndex,
      );
      final columnEndLines = _columnEndLineIndices(followingLines);
      for (final followingLine in followingLines) {
        if (!followingLine.isEligible) {
          continue;
        }
        candidates.addAll(
          _candidatesForLine(
            line: followingLine.text,
            amountLineIndex: followingLine.index,
            lineCount: lines.length,
            labelMatch: labelMatch,
            isLabelLine: false,
            additionalScore: columnEndLines.contains(followingLine.index)
                ? _columnEndBonus
                : 0,
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
    int additionalScore = 0,
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
          positionScore +
          additionalScore;

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

  static List<_FollowingAmountLine> _followingAmountLines({
    required List<String> lines,
    required int labelLineIndex,
  }) {
    final followingLines = <_FollowingAmountLine>[];
    for (var distance = 1; distance <= _followingLineWindow; distance++) {
      final lineIndex = labelLineIndex + distance;
      if (lineIndex >= lines.length) {
        break;
      }

      final line = lines[lineIndex];
      if (_findLabel(line) != null && !_looksLikeSubtotal(line)) {
        break;
      }
      final isEligible = !_looksLikeExcludedAmountLine(line);
      final amounts = isEligible
          ? _findAmounts(line).toList(growable: false)
          : const <_AmountMatch>[];
      followingLines.add(
        _FollowingAmountLine(
          text: line,
          index: lineIndex,
          isEligible: isEligible,
          isAmountOnly: _isAmountOnlyLine(line, amounts),
        ),
      );
    }
    return followingLines;
  }

  static Set<int> _columnEndLineIndices(List<_FollowingAmountLine> lines) {
    final columnEndLines = <int>{};
    var runLength = 0;
    int? lastAmountLineIndex;

    void finishRun() {
      if (runLength >= 2) {
        columnEndLines.add(lastAmountLineIndex!);
      }
      runLength = 0;
      lastAmountLineIndex = null;
    }

    for (final line in lines) {
      if (line.isAmountOnly) {
        runLength++;
        lastAmountLineIndex = line.index;
      } else {
        finishRun();
      }
    }
    finishRun();
    return columnEndLines;
  }

  static bool _isAmountOnlyLine(String line, List<_AmountMatch> amounts) {
    if (amounts.length != 1) {
      return false;
    }
    final amount = amounts.single;
    return line.substring(0, amount.start).trim().isEmpty &&
        line.substring(amount.end).trim().isEmpty;
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

  static bool _looksLikeExcludedAmountLine(String line) {
    final lettersOnly = line.toUpperCase().replaceAll(_nonLetters, '');
    return const [
      'SUBTOTAL',
      'ZWISCHENSUMME',
      'TAX',
      'VAT',
      'MWST',
      'CASH',
      'TENDER',
      'CHANGE',
      'WECHSELGELD',
      'RUECKGELD',
    ].any(lettersOnly.contains);
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

final class _FollowingAmountLine {
  const _FollowingAmountLine({
    required this.text,
    required this.index,
    required this.isEligible,
    required this.isAmountOnly,
  });

  final String text;
  final int index;
  final bool isEligible;
  final bool isAmountOnly;
}
