import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/utils/local_id_generator.dart';
import 'package:splitlens/data/database/app_database.dart';
import 'package:splitlens/data/repositories/drift_expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_storage.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

void main() {
  late AppDatabase database;
  late _FakeReceiptImageStorage imageStorage;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    imageStorage = _FakeReceiptImageStorage();
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and retrieves a complete expense graph', () async {
    final repository = DriftExpenseRepository.withDependencies(
      database,
      _CountingIdGenerator(),
      imageStorage,
      clock: () => DateTime.utc(2026, 9, 5, 2, 30),
    );

    final saved = await repository.save(_expense());
    final retrieved = await repository.getById(saved.id);

    expect(saved.id, 'id-0');
    expect(retrieved, isNotNull);
    expect(retrieved!.receipt.merchant, 'Synthetic Market');
    expect(retrieved.receipt.total, Money.eur(599));
    expect(retrieved.receipt.receiptImagePath, 'managed-id-0.png');
    expect(retrieved.receipt.rawOcrText, 'SYNTHETIC MARKET\nTOTAL EUR 5.99');
    expect(retrieved.paidBy.name, 'Anand');
    expect(
      retrieved.allocations
          .map((allocation) => allocation.amount.cents)
          .toSet(),
      {300, 299},
    );
    expect(retrieved.createdAt, DateTime.utc(2026, 9, 5, 2, 30));
    expect(retrieved.createdAt.isUtc, isTrue);
    expect(imageStorage.persistRequests, [
      (sourcePath: 'synthetic-receipt.png', imageId: 'id-0'),
    ]);
    expect(imageStorage.deletedPaths, isEmpty);
    expect(await database.select(database.expenses).get(), hasLength(1));
    expect(await database.select(database.participants).get(), hasLength(2));
    expect(
      await database.select(database.expenseAllocations).get(),
      hasLength(2),
    );
  });

  test(
    'retrieves all expenses newest first and returns null when missing',
    () async {
      final times = [
        DateTime.utc(2026, 9, 5, 1),
        DateTime.utc(2026, 9, 5, 2),
      ].iterator;
      final repository = DriftExpenseRepository.withDependencies(
        database,
        _CountingIdGenerator(),
        imageStorage,
        clock: () {
          times.moveNext();
          return times.current;
        },
      );
      final first = await repository.save(_expense(merchant: 'First Market'));
      final second = await repository.save(_expense(merchant: 'Second Market'));

      final expenses = await repository.getAll();

      expect(expenses.map((expense) => expense.receipt.merchant), [
        'Second Market',
        'First Market',
      ]);
      expect(await repository.getById(first.id), isNotNull);
      expect(await repository.getById(second.id), isNotNull);
      expect(await repository.getById('missing-expense'), isNull);
    },
  );

  test('rolls back every row when a transactional insert fails', () async {
    final repository = DriftExpenseRepository.withDependencies(
      database,
      _SequenceIdGenerator([
        'expense-id',
        'duplicate-participant-id',
        'duplicate-participant-id',
      ]),
      imageStorage,
      clock: () => DateTime.utc(2026, 9, 5, 2, 30),
    );

    await expectLater(repository.save(_expense()), throwsA(isA<Exception>()));

    expect(await database.select(database.expenses).get(), isEmpty);
    expect(await database.select(database.participants).get(), isEmpty);
    expect(await database.select(database.expenseAllocations).get(), isEmpty);
    expect(imageStorage.deletedPaths, ['managed-expense-id.png']);
  });

  test('does not write database rows when image storage fails', () async {
    imageStorage.failure = FileSystemException('Synthetic copy failure');
    final repository = DriftExpenseRepository.withDependencies(
      database,
      _CountingIdGenerator(),
      imageStorage,
    );

    await expectLater(repository.save(_expense()), throwsA(isA<Exception>()));

    expect(await database.select(database.expenses).get(), isEmpty);
    expect(await database.select(database.participants).get(), isEmpty);
    expect(imageStorage.deletedPaths, isEmpty);
  });

  test('rejects allocations that do not equal the receipt total', () async {
    final repository = DriftExpenseRepository.withDependencies(
      database,
      _CountingIdGenerator(),
      imageStorage,
    );
    final invalid = _expense(allocationCents: [300, 300]);

    await expectLater(repository.save(invalid), throwsArgumentError);

    expect(await database.select(database.expenses).get(), isEmpty);
    expect(await database.select(database.participants).get(), isEmpty);
    expect(imageStorage.persistRequests, isEmpty);
  });
}

ConfirmedExpense _expense({
  String merchant = 'Synthetic Market',
  List<int> allocationCents = const [300, 299],
}) {
  const participants = [
    SplitParticipant(id: 0, name: 'Anand'),
    SplitParticipant(id: 1, name: 'Mira'),
  ];
  return ConfirmedExpense(
    receipt: ConfirmedReceiptReview(
      merchant: merchant,
      date: DateTime(2026, 9, 4),
      currencyCode: 'EUR',
      total: Money.eur(599),
      receiptImagePath: 'synthetic-receipt.png',
      rawOcrText: 'SYNTHETIC MARKET\nTOTAL EUR 5.99',
    ),
    paidBy: participants.first,
    allocations: [
      for (var index = 0; index < participants.length; index++)
        ConfirmedExpenseAllocation(
          participant: participants[index],
          amount: Money.eur(allocationCents[index]),
        ),
    ],
  );
}

final class _CountingIdGenerator implements LocalIdGenerator {
  int _next = 0;

  @override
  String generate() => 'id-${_next++}';
}

final class _SequenceIdGenerator implements LocalIdGenerator {
  _SequenceIdGenerator(this._ids);

  final List<String> _ids;
  int _index = 0;

  @override
  String generate() => _ids[_index++];
}

final class _FakeReceiptImageStorage implements ReceiptImageStorage {
  final List<({String sourcePath, String imageId})> persistRequests = [];
  final List<String> deletedPaths = [];
  Object? failure;

  @override
  Future<String> persist({
    required String sourcePath,
    required String imageId,
  }) async {
    persistRequests.add((sourcePath: sourcePath, imageId: imageId));
    final error = failure;
    if (error != null) {
      throw error;
    }
    return 'managed-$imageId.png';
  }

  @override
  Future<void> delete(String storedPath) async {
    deletedPaths.add(storedPath);
  }
}
