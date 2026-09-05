import 'package:drift/drift.dart';
import 'package:splitlens/data/database/tables/participants.dart';

class Expenses extends Table {
  TextColumn get id => text()();

  TextColumn get merchant => text().withLength(min: 1, max: 200)();

  DateTimeColumn get expenseDate => dateTime()();

  TextColumn get currency => text().withLength(min: 3, max: 3)();

  IntColumn get totalCents => integer()();

  TextColumn get paidByParticipantId =>
      text().references(Participants, #id, onDelete: KeyAction.restrict)();

  TextColumn get receiptLocalPath => text()();

  TextColumn get rawOcrText => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (currency = 'EUR')",
    'CHECK (total_cents > 0)',
  ];
}
