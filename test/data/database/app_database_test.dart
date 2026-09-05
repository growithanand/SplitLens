import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/data/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates schema version 1 with foreign keys enabled', () async {
    final foreignKeySetting = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(database.schemaVersion, 1);
    expect(foreignKeySetting.read<int>('foreign_keys'), 1);
    expect(database.allTables.map((table) => table.actualTableName), {
      'participants',
      'expenses',
      'expense_allocations',
    });
  });

  test('round-trips an expense with participants and allocations', () async {
    await _insertParticipant(database, id: 'participant-anand', name: 'Anand');
    await _insertParticipant(database, id: 'participant-mira', name: 'Mira');
    await _insertExpense(database);
    await database
        .into(database.expenseAllocations)
        .insert(
          ExpenseAllocationsCompanion.insert(
            id: 'allocation-anand',
            expenseId: 'expense-1',
            participantId: 'participant-anand',
            amountCents: 300,
          ),
        );
    await database
        .into(database.expenseAllocations)
        .insert(
          ExpenseAllocationsCompanion.insert(
            id: 'allocation-mira',
            expenseId: 'expense-1',
            participantId: 'participant-mira',
            amountCents: 299,
          ),
        );

    final expense = await database.select(database.expenses).getSingle();
    final allocations = await database
        .select(database.expenseAllocations)
        .get();

    expect(expense.merchant, 'Synthetic Market');
    expect(expense.totalCents, 599);
    expect(expense.paidByParticipantId, 'participant-anand');
    expect(expense.receiptLocalPath, 'synthetic-receipt.png');
    expect(expense.rawOcrText, 'SYNTHETIC MARKET\nTOTAL EUR 5.99');
    expect(allocations.map((allocation) => allocation.amountCents), [300, 299]);
  });

  test('rejects invalid monetary and relationship data', () async {
    await _insertParticipant(database, id: 'participant-anand', name: 'Anand');

    await expectLater(
      _insertExpense(database, currency: 'USD'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      _insertExpense(database, totalCents: -1),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      _insertExpense(database, paidByParticipantId: 'missing-participant'),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'enforces one allocation per participant and cascades expense deletion',
    () async {
      await _insertParticipant(
        database,
        id: 'participant-anand',
        name: 'Anand',
      );
      await _insertExpense(database);
      await database
          .into(database.expenseAllocations)
          .insert(
            ExpenseAllocationsCompanion.insert(
              id: 'allocation-1',
              expenseId: 'expense-1',
              participantId: 'participant-anand',
              amountCents: 599,
            ),
          );

      await expectLater(
        database
            .into(database.expenseAllocations)
            .insert(
              ExpenseAllocationsCompanion.insert(
                id: 'allocation-2',
                expenseId: 'expense-1',
                participantId: 'participant-anand',
                amountCents: 599,
              ),
            ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        (database.delete(database.participants)..where(
              (participant) => participant.id.equals('participant-anand'),
            ))
            .go(),
        throwsA(isA<Exception>()),
      );

      await database.delete(database.expenses).go();

      expect(await database.select(database.expenseAllocations).get(), isEmpty);
      expect(await database.select(database.participants).get(), hasLength(1));
    },
  );
}

Future<void> _insertParticipant(
  AppDatabase database, {
  required String id,
  required String name,
}) async {
  await database
      .into(database.participants)
      .insert(ParticipantsCompanion.insert(id: id, name: name));
}

Future<void> _insertExpense(
  AppDatabase database, {
  String currency = 'EUR',
  int totalCents = 599,
  String paidByParticipantId = 'participant-anand',
}) async {
  final recordedAt = DateTime.utc(2026, 9, 5, 1, 30);
  await database
      .into(database.expenses)
      .insert(
        ExpensesCompanion.insert(
          id: 'expense-1',
          merchant: 'Synthetic Market',
          expenseDate: DateTime(2026, 9, 4),
          currency: currency,
          totalCents: totalCents,
          paidByParticipantId: paidByParticipantId,
          receiptLocalPath: 'synthetic-receipt.png',
          rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 5.99',
          createdAt: recordedAt,
          updatedAt: recordedAt,
        ),
      );
}
