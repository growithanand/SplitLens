import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

final class ConfirmedExpenseAllocation {
  const ConfirmedExpenseAllocation({
    required this.participant,
    required this.amount,
  });

  final SplitParticipant participant;
  final Money amount;
}

final class ConfirmedExpense {
  ConfirmedExpense({
    required this.receipt,
    required this.paidBy,
    required Iterable<ConfirmedExpenseAllocation> allocations,
  }) : allocations = List.unmodifiable(allocations);

  final ConfirmedReceiptReview receipt;
  final SplitParticipant paidBy;
  final List<ConfirmedExpenseAllocation> allocations;
}
