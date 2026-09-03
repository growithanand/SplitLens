import 'package:splitlens/core/money/money.dart';

enum EqualSplitError { participantCountMustBePositive }

sealed class EqualSplitResult {
  const EqualSplitResult();
}

final class EqualSplitSuccess extends EqualSplitResult {
  EqualSplitSuccess._({required this.total, required List<Money> allocations})
    : allocations = List.unmodifiable(allocations) {
    final allocatedCents = this.allocations.fold<int>(
      0,
      (sum, allocation) => sum + allocation.cents,
    );

    if (allocatedCents != total.cents) {
      throw StateError('Split allocations must add up to the original total.');
    }
  }

  final Money total;
  final List<Money> allocations;

  int get participantCount => allocations.length;
}

final class EqualSplitFailure extends EqualSplitResult {
  const EqualSplitFailure(this.error);

  final EqualSplitError error;
}

abstract final class EqualSplitCalculator {
  static EqualSplitResult split({
    required Money total,
    required int participantCount,
  }) {
    if (participantCount <= 0) {
      return const EqualSplitFailure(
        EqualSplitError.participantCountMustBePositive,
      );
    }

    final baseCents = total.cents ~/ participantCount;
    final extraCentCount = total.cents % participantCount;
    final allocations = List.generate(
      participantCount,
      (index) => Money.eur(baseCents + (index < extraCentCount ? 1 : 0)),
      growable: false,
    );

    return EqualSplitSuccess._(total: total, allocations: allocations);
  }
}
