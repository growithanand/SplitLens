import 'package:drift/drift.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/utils/local_id_generator.dart';
import 'package:splitlens/data/database/app_database.dart';
import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

final class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(AppDatabase database)
    : this.withDependencies(database, const UuidV4LocalIdGenerator());

  DriftExpenseRepository.withDependencies(
    this._database,
    this._idGenerator, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final LocalIdGenerator _idGenerator;
  final DateTime Function() _clock;

  @override
  Future<PersistedExpense> save(ConfirmedExpense expense) async {
    _validate(expense);

    return _database.transaction(() async {
      final expenseId = _idGenerator.generate();
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
              receiptLocalPath: expense.receipt.receiptImagePath,
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
        receipt: expense.receipt,
        paidBy: paidBy,
        allocations: storedAllocations,
        createdAt: recordedAt,
        updatedAt: recordedAt,
      );
    });
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
