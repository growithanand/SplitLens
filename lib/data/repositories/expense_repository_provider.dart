import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/data/database/app_database.dart';
import 'package:splitlens/data/repositories/drift_expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';
import 'package:splitlens/features/receipt_capture/data/local_receipt_image_storage.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_storage.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final receiptImageStorageProvider = Provider<ReceiptImageStorage>((ref) {
  return LocalReceiptImageStorage();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return DriftExpenseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(receiptImageStorageProvider),
  );
});
