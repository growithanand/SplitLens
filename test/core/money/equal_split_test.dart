import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/equal_split.dart';
import 'package:splitlens/core/money/money.dart';

void main() {
  group('EqualSplitCalculator', () {
    test('divides an even total equally', () {
      final split = _successfulSplit(totalCents: 1000, participantCount: 4);

      expect(_cents(split), [250, 250, 250, 250]);
    });

    test('assigns a one-cent remainder to the first participant', () {
      final split = _successfulSplit(totalCents: 1000, participantCount: 3);

      expect(_cents(split), [334, 333, 333]);
    });

    test('assigns multiple remainder cents in participant order', () {
      final split = _successfulSplit(totalCents: 1002, participantCount: 4);

      expect(_cents(split), [251, 251, 250, 250]);
    });

    test('gives the full total to one participant', () {
      final split = _successfulSplit(totalCents: 1299, participantCount: 1);

      expect(_cents(split), [1299]);
    });

    test('returns zero allocations for a zero total', () {
      final split = _successfulSplit(totalCents: 0, participantCount: 3);

      expect(_cents(split), [0, 0, 0]);
    });

    test('rejects zero participants', () {
      final result = EqualSplitCalculator.split(
        total: Money.eur(1000),
        participantCount: 0,
      );

      expect(result, isA<EqualSplitFailure>());
      expect(
        (result as EqualSplitFailure).error,
        EqualSplitError.participantCountMustBePositive,
      );
    });

    test('rejects a negative participant count', () {
      final result = EqualSplitCalculator.split(
        total: Money.eur(1000),
        participantCount: -1,
      );

      expect(result, isA<EqualSplitFailure>());
      expect(
        (result as EqualSplitFailure).error,
        EqualSplitError.participantCountMustBePositive,
      );
    });

    test('cannot receive a negative Money total', () {
      expect(() => Money.eur(-1), throwsRangeError);
    });

    test('supports the largest Money total', () {
      final split = _successfulSplit(
        totalCents: Money.maxCents,
        participantCount: 7,
      );

      expect(_cents(split), [
        14285714286,
        14285714286,
        14285714286,
        14285714286,
        14285714285,
        14285714285,
        14285714285,
      ]);
    });

    test('preserves the sum invariant across representative inputs', () {
      const totals = [0, 1, 2, 3, 99, 100, 101, 999, 1000, 1001];
      const participantCounts = [1, 2, 3, 4, 7, 16];

      for (final totalCents in totals) {
        for (final participantCount in participantCounts) {
          final split = _successfulSplit(
            totalCents: totalCents,
            participantCount: participantCount,
          );
          final allocations = _cents(split);

          expect(
            allocations.fold<int>(0, (sum, cents) => sum + cents),
            totalCents,
            reason: '$totalCents cents across $participantCount participants',
          );
          expect(allocations.length, participantCount);
          expect(
            allocations.reduce((a, b) => a > b ? a : b) -
                allocations.reduce((a, b) => a < b ? a : b),
            lessThanOrEqualTo(1),
          );
        }
      }
    });

    test('exposes immutable allocations', () {
      final split = _successfulSplit(totalCents: 1000, participantCount: 3);

      expect(() => split.allocations.add(Money.eur(1)), throwsUnsupportedError);
    });
  });
}

EqualSplitSuccess _successfulSplit({
  required int totalCents,
  required int participantCount,
}) {
  final result = EqualSplitCalculator.split(
    total: Money.eur(totalCents),
    participantCount: participantCount,
  );

  expect(result, isA<EqualSplitSuccess>());
  return result as EqualSplitSuccess;
}

List<int> _cents(EqualSplitSuccess split) =>
    split.allocations.map((allocation) => allocation.cents).toList();
