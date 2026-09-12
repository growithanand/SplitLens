import 'package:drift/drift.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/utils/local_id_generator.dart';
import 'package:splitlens/data/database/app_database.dart';
import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_storage.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

final class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(
    AppDatabase database,
    ReceiptImageStorage receiptImageStorage,
  ) : this.withDependencies(
        database,
        const UuidV4LocalIdGenerator(),
        receiptImageStorage,
      );

  DriftExpenseRepository.withDependencies(
    this._database,
    this._idGenerator,
    this._receiptImageStorage, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final LocalIdGenerator _idGenerator;
  final ReceiptImageStorage _receiptImageStorage;
  final DateTime Function() _clock;

  @override
  Future<PersistedExpense> save(ConfirmedExpense expense) async {
    _validate(expense);

    final expenseId = _idGenerator.generate();
    final storedImagePath = await _receiptImageStorage.persist(
      sourcePath: expense.receipt.receiptImagePath,
      imageId: expenseId,
    );
    final storedReceipt = ConfirmedReceiptReview(
      merchant: expense.receipt.merchant,
      date: expense.receipt.date,
      currencyCode: expense.receipt.currencyCode,
      total: expense.receipt.total,
      receiptImagePath: storedImagePath,
      rawOcrText: expense.receipt.rawOcrText,
    );

    try {
      return await _database.transaction(() async {
        final recordedAt = _clock().toUtc();
        final storedParticipants = <int, PersistedParticipant>{};

        for (final allocation in expense.allocations) {
          final participant = PersistedParticipant(
            id: _idGenerator.generate(),
            name: allocation.participant.name,
          );
          storedParticipants[allocation.participant.id] = participant;
          await _database
              .into(_database.participants)
              .insert(
                ParticipantsCompanion.insert(
                  id: participant.id,
                  name: participant.name,
                ),
              );
        }

        final paidBy = storedParticipants[expense.paidBy.id]!;
        await _database
            .into(_database.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: expenseId,
                merchant: expense.receipt.merchant,
                expenseDate: expense.receipt.date,
                currency: expense.receipt.currencyCode,
                totalCents: expense.receipt.total.cents,
                paidByParticipantId: paidBy.id,
                receiptLocalPath: storedReceipt.receiptImagePath,
                rawOcrText: expense.receipt.rawOcrText,
                createdAt: recordedAt,
                updatedAt: recordedAt,
              ),
            );

        final storedAllocations = <PersistedExpenseAllocation>[];
        for (final allocation in expense.allocations) {
          final storedParticipant =
              storedParticipants[allocation.participant.id]!;
          final storedAllocation = PersistedExpenseAllocation(
            id: _idGenerator.generate(),
            participant: storedParticipant,
            amount: allocation.amount,
          );
          storedAllocations.add(storedAllocation);
          await _database
              .into(_database.expenseAllocations)
              .insert(
                ExpenseAllocationsCompanion.insert(
                  id: storedAllocation.id,
                  expenseId: expenseId,
                  participantId: storedParticipant.id,
                  amountCents: storedAllocation.amount.cents,
                ),
              );
        }

        return PersistedExpense(
          id: expenseId,
          receipt: storedReceipt,
          paidBy: paidBy,
          allocations: storedAllocations,
          createdAt: recordedAt,
          updatedAt: recordedAt,
        );
      });
    } on Object {
      try {
        await _receiptImageStorage.delete(storedImagePath);
      } on Object {
        // Preserve the database failure that prevented the expense save.
      }
      rethrow;
    }
  }

  @override
  Future<PersistedExpense?> getById(String expenseId) async {
    final expense = await (_database.select(
      _database.expenses,
    )..where((row) => row.id.equals(expenseId))).getSingleOrNull();
    if (expense == null) {
      return null;
    }

    return _loadExpense(expense);
  }

  @override
  Future<List<PersistedExpense>> getAll() async {
    final expenses =
        await (_database.select(_database.expenses)..orderBy([
              (row) => OrderingTerm.desc(row.createdAt),
              (row) => OrderingTerm.desc(row.id),
            ]))
            .get();

    return Future.wait(expenses.map(_loadExpense));
  }

  @override
  Future<ExpenseDeletionResult> deleteById(String expenseId) async {
    final receiptImagePath = await _database.transaction<String?>(() async {
      final expense = await (_database.select(
        _database.expenses,
      )..where((row) => row.id.equals(expenseId))).getSingleOrNull();
      if (expense == null) {
        return null;
      }

      final allocations = await (_database.select(
        _database.expenseAllocations,
      )..where((row) => row.expenseId.equals(expenseId))).get();
      final participantIds = allocations
          .map((allocation) => allocation.participantId)
          .toList(growable: false);

      final deletedExpenseCount = await (_database.delete(
        _database.expenses,
      )..where((row) => row.id.equals(expenseId))).go();
      if (deletedExpenseCount != 1) {
        throw StateError('The stored expense could not be deleted.');
      }

      for (final participantId in participantIds) {
        await (_database.delete(
          _database.participants,
        )..where((row) => row.id.equals(participantId))).go();
      }

      return expense.receiptLocalPath;
    });

    if (receiptImagePath == null) {
      return ExpenseDeletionResult.notFound;
    }

    try {
      await _receiptImageStorage.delete(receiptImagePath);
      return ExpenseDeletionResult.deleted;
    } on Object {
      return ExpenseDeletionResult.deletedWithReceiptCleanupFailure;
    }
  }

  Future<PersistedExpense> _loadExpense(Expense expense) async {
    final rows = await (_database.select(_database.expenseAllocations).join([
      innerJoin(
        _database.participants,
        _database.participants.id.equalsExp(
          _database.expenseAllocations.participantId,
        ),
      ),
    ])..where(_database.expenseAllocations.expenseId.equals(expense.id))).get();

    final allocations = rows
        .map((row) {
          final allocation = row.readTable(_database.expenseAllocations);
          final participant = row.readTable(_database.participants);
          return PersistedExpenseAllocation(
            id: allocation.id,
            participant: PersistedParticipant(
              id: participant.id,
              name: participant.name,
            ),
            amount: Money.eur(allocation.amountCents),
          );
        })
        .toList(growable: false);
    final paidBy = allocations
        .map((allocation) => allocation.participant)
        .where((participant) => participant.id == expense.paidByParticipantId)
        .firstOrNull;
    if (paidBy == null) {
      throw StateError('Stored expense payer has no allocation.');
    }

    return PersistedExpense(
      id: expense.id,
      receipt: ConfirmedReceiptReview(
        merchant: expense.merchant,
        date: expense.expenseDate,
        currencyCode: expense.currency,
        total: Money.eur(expense.totalCents),
        receiptImagePath: expense.receiptLocalPath,
        rawOcrText: expense.rawOcrText,
      ),
      paidBy: paidBy,
      allocations: allocations,
      createdAt: expense.createdAt.toUtc(),
      updatedAt: expense.updatedAt.toUtc(),
    );
  }

  static void _validate(ConfirmedExpense expense) {
    if (expense.allocations.isEmpty) {
      throw ArgumentError.value(
        expense.allocations,
        'expense.allocations',
        'At least one allocation is required.',
      );
    }
    final participantIds = expense.allocations
        .map((allocation) => allocation.participant.id)
        .toSet();
    if (participantIds.length != expense.allocations.length) {
      throw ArgumentError('Participant allocations must be unique.');
    }
    if (!participantIds.contains(expense.paidBy.id)) {
      throw ArgumentError('The payer must have an allocation.');
    }
    final allocatedCents = expense.allocations.fold<int>(
      0,
      (sum, allocation) => sum + allocation.amount.cents,
    );
    if (allocatedCents != expense.receipt.total.cents) {
      throw ArgumentError('Allocations must add up to the expense total.');
    }
  }
}
