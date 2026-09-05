import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:splitlens/data/database/tables/expense_allocations.dart';
import 'package:splitlens/data/database/tables/expenses.dart';
import 'package:splitlens/data/database/tables/participants.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Participants, Expenses, ExpenseAllocations])
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'splitlens'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
