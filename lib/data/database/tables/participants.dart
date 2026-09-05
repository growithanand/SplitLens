import 'package:drift/drift.dart';

class Participants extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
