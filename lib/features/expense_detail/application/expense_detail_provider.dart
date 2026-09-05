import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';

final expenseDetailProvider = FutureProvider.autoDispose
    .family<PersistedExpense?, String>((ref, expenseId) {
      return ref.watch(expenseRepositoryProvider).getById(expenseId);
    });
