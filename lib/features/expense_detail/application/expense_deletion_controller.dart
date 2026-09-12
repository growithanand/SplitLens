import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/data/repositories/expense_repository_provider.dart';
import 'package:splitlens/features/expense_confirmation/domain/expense_repository.dart';

enum ExpenseDeletionStatus {
  idle,
  deleting,
  deleted,
  notFound,
  deletedWithReceiptCleanupFailure,
  failure,
}

final class ExpenseDeletionState {
  const ExpenseDeletionState({
    this.status = ExpenseDeletionStatus.idle,
    this.errorMessage,
  });

  final ExpenseDeletionStatus status;
  final String? errorMessage;

  bool get isDeleting => status == ExpenseDeletionStatus.deleting;
}

final expenseDeletionControllerProvider = NotifierProvider.autoDispose
    .family<ExpenseDeletionController, ExpenseDeletionState, String>(
      ExpenseDeletionController.new,
    );

final class ExpenseDeletionController extends Notifier<ExpenseDeletionState> {
  ExpenseDeletionController(this.expenseId);

  final String expenseId;

  @override
  ExpenseDeletionState build() => const ExpenseDeletionState();

  Future<ExpenseDeletionStatus?> delete() async {
    if (state.isDeleting) {
      return null;
    }

    state = const ExpenseDeletionState(status: ExpenseDeletionStatus.deleting);

    try {
      final result = await ref
          .read(expenseRepositoryProvider)
          .deleteById(expenseId);
      final status = switch (result) {
        ExpenseDeletionResult.deleted => ExpenseDeletionStatus.deleted,
        ExpenseDeletionResult.notFound => ExpenseDeletionStatus.notFound,
        ExpenseDeletionResult.deletedWithReceiptCleanupFailure =>
          ExpenseDeletionStatus.deletedWithReceiptCleanupFailure,
      };
      state = ExpenseDeletionState(status: status);
      return status;
    } on Object {
      state = const ExpenseDeletionState(
        status: ExpenseDeletionStatus.failure,
        errorMessage: 'Expense could not be deleted. Try again.',
      );
      return ExpenseDeletionStatus.failure;
    }
  }
}
