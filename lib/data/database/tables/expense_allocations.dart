import 'package:drift/drift.dart';
import 'package:splitlens/data/database/tables/expenses.dart';
import 'package:splitlens/data/database/tables/participants.dart';

class ExpenseAllocations extends Table {
  TextColumn get id => text()();

  TextColumn get expenseId =>
      text().references(Expenses, #id, onDelete: KeyAction.cascade)();

  TextColumn get participantId =>
      text().references(Participants, #id, onDelete: KeyAction.restrict)();

  IntColumn get amountCents => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {expenseId, participantId},
  ];

  @override
  List<String> get customConstraints => const ['CHECK (amount_cents >= 0)'];
}
