import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';

abstract interface class ExpenseRepository {
  Future<PersistedExpense> save(ConfirmedExpense expense);

  Future<PersistedExpense?> getById(String expenseId);

  Future<List<PersistedExpense>> getAll();
}
