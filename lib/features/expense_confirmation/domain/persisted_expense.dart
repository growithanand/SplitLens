import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

final class PersistedParticipant {
  const PersistedParticipant({required this.id, required this.name});

  final String id;
  final String name;
}

final class PersistedExpenseAllocation {
  const PersistedExpenseAllocation({
    required this.id,
    required this.participant,
    required this.amount,
  });

  final String id;
  final PersistedParticipant participant;
  final Money amount;
}

final class PersistedExpense {
  PersistedExpense({
    required this.id,
    required this.receipt,
    required this.paidBy,
    required Iterable<PersistedExpenseAllocation> allocations,
    required this.createdAt,
    required this.updatedAt,
  }) : allocations = List.unmodifiable(allocations);

  final String id;
  final ConfirmedReceiptReview receipt;
  final PersistedParticipant paidBy;
  final List<PersistedExpenseAllocation> allocations;
  final DateTime createdAt;
  final DateTime updatedAt;
}
