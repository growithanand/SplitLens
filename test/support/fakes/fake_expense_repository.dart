import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';

final class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({this.onSave});

  final Future<PersistedExpense> Function(ConfirmedExpense expense)? onSave;
  final List<ConfirmedExpense> saveRequests = [];
  final List<PersistedExpense> _storedExpenses = [];

  @override
  Future<PersistedExpense> save(ConfirmedExpense expense) async {
    saveRequests.add(expense);
    final callback = onSave;
    final persisted = callback == null
        ? _persistedFrom(expense, _storedExpenses.length)
        : await callback(expense);
    _storedExpenses.add(persisted);
    return persisted;
  }

  @override
  Future<PersistedExpense?> getById(String expenseId) async {
    for (final expense in _storedExpenses) {
      if (expense.id == expenseId) {
        return expense;
      }
    }
    return null;
  }

  @override
  Future<List<PersistedExpense>> getAll() async =>
      List.unmodifiable(_storedExpenses);
}

PersistedExpense _persistedFrom(ConfirmedExpense expense, int expenseIndex) {
  final participants = <int, PersistedParticipant>{};
  final allocations = <PersistedExpenseAllocation>[];
  for (var index = 0; index < expense.allocations.length; index++) {
    final allocation = expense.allocations[index];
    final participant = PersistedParticipant(
      id: 'participant-$expenseIndex-$index',
      name: allocation.participant.name,
    );
    participants[allocation.participant.id] = participant;
    allocations.add(
      PersistedExpenseAllocation(
        id: 'allocation-$expenseIndex-$index',
        participant: participant,
        amount: allocation.amount,
      ),
    );
  }

  final recordedAt = DateTime.utc(2026, 9, 5, 2, expenseIndex);
  return PersistedExpense(
    id: 'expense-$expenseIndex',
    receipt: expense.receipt,
    paidBy: participants[expense.paidBy.id]!,
    allocations: allocations,
    createdAt: recordedAt,
    updatedAt: recordedAt,
  );
}
