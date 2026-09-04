enum ReceiptDateFormat {
  dayMonthYearDots,
  dayMonthYearSlashes,
  yearMonthDayDashes,
}

final class ReceiptDateCandidate {
  const ReceiptDateCandidate({
    required this.date,
    required this.sourceText,
    required this.format,
  });

  final DateTime date;
  final String sourceText;
  final ReceiptDateFormat format;
}

sealed class ReceiptDateParseResult {
  const ReceiptDateParseResult();
}

final class ReceiptDateFound extends ReceiptDateParseResult {
  const ReceiptDateFound(this.candidate);

  final ReceiptDateCandidate candidate;
}

final class ReceiptDateNotFound extends ReceiptDateParseResult {
  const ReceiptDateNotFound();
}

final class ReceiptDateAmbiguous extends ReceiptDateParseResult {
  ReceiptDateAmbiguous(Iterable<ReceiptDateCandidate> candidates)
    : candidates = List.unmodifiable(candidates);

  final List<ReceiptDateCandidate> candidates;
}

abstract final class ReceiptDateParser {
  static final _patterns = <_DatePattern>[
    _DatePattern(
      expression: RegExp(r'(^|[^0-9])(\d{2})\.(\d{2})\.(\d{4})(?=$|[^0-9])'),
      format: ReceiptDateFormat.dayMonthYearDots,
      yearGroup: 4,
      monthGroup: 3,
      dayGroup: 2,
    ),
    _DatePattern(
      expression: RegExp(r'(^|[^0-9])(\d{2})/(\d{2})/(\d{4})(?=$|[^0-9])'),
      format: ReceiptDateFormat.dayMonthYearSlashes,
      yearGroup: 4,
      monthGroup: 3,
      dayGroup: 2,
    ),
    _DatePattern(
      expression: RegExp(r'(^|[^0-9])(\d{4})-(\d{2})-(\d{2})(?=$|[^0-9])'),
      format: ReceiptDateFormat.yearMonthDayDashes,
      yearGroup: 2,
      monthGroup: 3,
      dayGroup: 4,
    ),
  ];

  static ReceiptDateParseResult parse(String rawText) {
    final locatedCandidates = <_LocatedDateCandidate>[];
    for (final pattern in _patterns) {
      for (final match in pattern.expression.allMatches(rawText)) {
        final year = int.parse(match.group(pattern.yearGroup)!);
        final month = int.parse(match.group(pattern.monthGroup)!);
        final day = int.parse(match.group(pattern.dayGroup)!);
        if (!_isValidDate(year: year, month: month, day: day)) {
          continue;
        }

        final prefixLength = match.group(1)!.length;
        final sourceStart = match.start + prefixLength;
        final sourceText = rawText.substring(sourceStart, match.end);
        locatedCandidates.add(
          _LocatedDateCandidate(
            offset: sourceStart,
            candidate: ReceiptDateCandidate(
              date: DateTime(year, month, day),
              sourceText: sourceText,
              format: pattern.format,
            ),
          ),
        );
      }
    }

    locatedCandidates.sort(
      (left, right) => left.offset.compareTo(right.offset),
    );
    final uniqueCandidates = <String, ReceiptDateCandidate>{};
    for (final located in locatedCandidates) {
      final date = located.candidate.date;
      final key = '${date.year}-${date.month}-${date.day}';
      uniqueCandidates.putIfAbsent(key, () => located.candidate);
    }

    return switch (uniqueCandidates.values.toList()) {
      [] => const ReceiptDateNotFound(),
      [final candidate] => ReceiptDateFound(candidate),
      final candidates => ReceiptDateAmbiguous(candidates),
    };
  }

  static bool _isValidDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }

    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }
}

final class _DatePattern {
  const _DatePattern({
    required this.expression,
    required this.format,
    required this.yearGroup,
    required this.monthGroup,
    required this.dayGroup,
  });

  final RegExp expression;
  final ReceiptDateFormat format;
  final int yearGroup;
  final int monthGroup;
  final int dayGroup;
}

final class _LocatedDateCandidate {
  const _LocatedDateCandidate({required this.offset, required this.candidate});

  final int offset;
  final ReceiptDateCandidate candidate;
}
