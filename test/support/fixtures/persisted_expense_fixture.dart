import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

PersistedExpense persistedExpenseFixture({
  String id = 'expense-1',
  String merchant = 'Synthetic Market',
  DateTime? date,
  int totalCents = 599,
  List<String> participantNames = const ['Anand', 'Mira'],
}) {
  assert(participantNames.isNotEmpty);
  final participants = [
    for (var index = 0; index < participantNames.length; index++)
      PersistedParticipant(
        id: '$id-participant-$index',
        name: participantNames[index],
      ),
  ];
  final share = totalCents ~/ participants.length;
  final remainder = totalCents % participants.length;
  final allocations = [
    for (var index = 0; index < participants.length; index++)
      PersistedExpenseAllocation(
        id: '$id-allocation-$index',
        participant: participants[index],
        amount: Money.eur(share + (index < remainder ? 1 : 0)),
      ),
  ];
  final recordedAt = DateTime.utc(2026, 9, 5, 12);

  return PersistedExpense(
    id: id,
    receipt: ConfirmedReceiptReview(
      merchant: merchant,
      date: date ?? DateTime(2026, 9, 4),
      currencyCode: Money.currencyCode,
      total: Money.eur(totalCents),
      receiptImagePath: 'synthetic-receipt.png',
      rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 5.99',
    ),
    paidBy: participants.first,
    allocations: allocations,
    createdAt: recordedAt,
    updatedAt: recordedAt,
  );
}
