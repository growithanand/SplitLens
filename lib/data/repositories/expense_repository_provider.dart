import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/data/database/app_database.dart';
import 'package:splitlens/data/repositories/drift_expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return DriftExpenseRepository(ref.watch(appDatabaseProvider));
});
