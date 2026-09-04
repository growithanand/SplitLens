import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/core/money/equal_split.dart';
import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

enum ExpenseParticipantNameError { blank, duplicate }

enum ExpenseConfirmationValidationError { participantsRequired, payerRequired }

final class ExpenseConfirmationInput {
  const ExpenseConfirmationInput(this.receipt);

  final ConfirmedReceiptReview receipt;
}

final expenseConfirmationControllerProvider = NotifierProvider.autoDispose
    .family<
      ExpenseConfirmationController,
      ExpenseConfirmationState,
      ExpenseConfirmationInput
    >(ExpenseConfirmationController.new);

final class ExpenseConfirmationState {
  ExpenseConfirmationState({
    required this.receipt,
    Iterable<SplitParticipant> participants = const [],
    this.selectedPayerId,
    this.participantNameError,
    Iterable<ExpenseConfirmationValidationError> validationErrors = const [],
    this.confirmedExpense,
  }) : participants = List.unmodifiable(participants),
       validationErrors = Set.unmodifiable(validationErrors);

  final ConfirmedReceiptReview receipt;
  final List<SplitParticipant> participants;
  final int? selectedPayerId;
  final ExpenseParticipantNameError? participantNameError;
  final Set<ExpenseConfirmationValidationError> validationErrors;
  final ConfirmedExpense? confirmedExpense;

  EqualSplitSuccess? get split {
    if (participants.isEmpty) {
      return null;
    }

    final result = EqualSplitCalculator.split(
      total: receipt.total,
      participantCount: participants.length,
    );
    return result is EqualSplitSuccess ? result : null;
  }

  SplitParticipant? get selectedPayer {
    final payerId = selectedPayerId;
    if (payerId == null) {
      return null;
    }

    for (final participant in participants) {
      if (participant.id == payerId) {
        return participant;
      }
    }
    return null;
  }
}

final class ExpenseConfirmationController
    extends Notifier<ExpenseConfirmationState> {
  ExpenseConfirmationController(this.input);

  final ExpenseConfirmationInput input;
  int _nextParticipantId = 0;

  @override
  ExpenseConfirmationState build() =>
      ExpenseConfirmationState(receipt: input.receipt);

  bool addParticipant(String input) {
    final name = input.trim();
    if (name.isEmpty) {
      _replaceState(participantNameError: ExpenseParticipantNameError.blank);
      return false;
    }

    final normalizedName = name.toLowerCase();
    final isDuplicate = state.participants.any(
      (participant) => participant.name.toLowerCase() == normalizedName,
    );
    if (isDuplicate) {
      _replaceState(
        participantNameError: ExpenseParticipantNameError.duplicate,
      );
      return false;
    }

    final participant = SplitParticipant(id: _nextParticipantId++, name: name);
    _replaceState(
      participants: [...state.participants, participant],
      clearParticipantNameError: true,
      validationErrors: state.validationErrors
          .where(
            (error) =>
                error !=
                ExpenseConfirmationValidationError.participantsRequired,
          )
          .toSet(),
      clearConfirmedExpense: true,
    );
    return true;
  }

  void removeParticipant(int participantId) {
    final updatedParticipants = state.participants
        .where((participant) => participant.id != participantId)
        .toList(growable: false);
    final removedSelectedPayer = state.selectedPayerId == participantId;
    final updatedErrors = {...state.validationErrors};
    if (updatedParticipants.isEmpty) {
      updatedErrors.add(
        ExpenseConfirmationValidationError.participantsRequired,
      );
    }
    if (removedSelectedPayer) {
      updatedErrors.add(ExpenseConfirmationValidationError.payerRequired);
    }

    _replaceState(
      participants: updatedParticipants,
      selectedPayerId: removedSelectedPayer ? null : state.selectedPayerId,
      clearSelectedPayer: removedSelectedPayer,
      validationErrors: updatedErrors,
      clearConfirmedExpense: true,
    );
  }

  void selectPayer(int participantId) {
    final isParticipant = state.participants.any(
      (participant) => participant.id == participantId,
    );
    if (!isParticipant) {
      return;
    }

    _replaceState(
      selectedPayerId: participantId,
      validationErrors: state.validationErrors
          .where(
            (error) =>
                error != ExpenseConfirmationValidationError.payerRequired,
          )
          .toSet(),
      clearConfirmedExpense: true,
    );
  }

  void clearParticipantNameError() {
    if (state.participantNameError == null) {
      return;
    }
    _replaceState(clearParticipantNameError: true);
  }

  bool confirm() {
    final errors = <ExpenseConfirmationValidationError>{};
    if (state.participants.isEmpty) {
      errors.add(ExpenseConfirmationValidationError.participantsRequired);
    }
    final payer = state.selectedPayer;
    if (payer == null) {
      errors.add(ExpenseConfirmationValidationError.payerRequired);
    }

    final split = state.split;
    if (errors.isNotEmpty || split == null) {
      _replaceState(validationErrors: errors, clearConfirmedExpense: true);
      return false;
    }

    final allocations = <ConfirmedExpenseAllocation>[
      for (var index = 0; index < state.participants.length; index++)
        ConfirmedExpenseAllocation(
          participant: state.participants[index],
          amount: split.allocations[index],
        ),
    ];
    final confirmedExpense = ConfirmedExpense(
      receipt: state.receipt,
      paidBy: payer!,
      allocations: allocations,
    );
    _replaceState(
      validationErrors: const {},
      confirmedExpense: confirmedExpense,
    );
    return true;
  }

  void _replaceState({
    Iterable<SplitParticipant>? participants,
    int? selectedPayerId,
    bool clearSelectedPayer = false,
    ExpenseParticipantNameError? participantNameError,
    bool clearParticipantNameError = false,
    Iterable<ExpenseConfirmationValidationError>? validationErrors,
    ConfirmedExpense? confirmedExpense,
    bool clearConfirmedExpense = false,
  }) {
    state = ExpenseConfirmationState(
      receipt: state.receipt,
      participants: participants ?? state.participants,
      selectedPayerId: clearSelectedPayer
          ? null
          : selectedPayerId ?? state.selectedPayerId,
      participantNameError: clearParticipantNameError
          ? null
          : participantNameError ?? state.participantNameError,
      validationErrors: validationErrors ?? state.validationErrors,
      confirmedExpense: clearConfirmedExpense
          ? null
          : confirmedExpense ?? state.confirmedExpense,
    );
  }
}
