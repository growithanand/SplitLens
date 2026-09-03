import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/core/money/equal_split.dart';
import 'package:splitlens/core/money/money.dart';
import 'package:splitlens/core/money/money_parser.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';

enum ParticipantNameError { blank, duplicate }

final expenseSplitControllerProvider =
    NotifierProvider<ExpenseSplitController, ExpenseSplitState>(
      ExpenseSplitController.new,
    );

final class ExpenseSplitState {
  ExpenseSplitState({
    this.totalInput = '',
    this.totalResult,
    List<SplitParticipant> participants = const [],
    this.participantNameError,
  }) : participants = List.unmodifiable(participants);

  final String totalInput;
  final MoneyParseResult? totalResult;
  final List<SplitParticipant> participants;
  final ParticipantNameError? participantNameError;

  Money? get total => totalResult?.money;

  MoneyParseError? get totalError => totalResult?.error;

  EqualSplitSuccess? get split {
    final currentTotal = total;
    if (currentTotal == null || participants.isEmpty) {
      return null;
    }

    final result = EqualSplitCalculator.split(
      total: currentTotal,
      participantCount: participants.length,
    );
    return result is EqualSplitSuccess ? result : null;
  }

  int get extraCentRecipientCount {
    final currentTotal = total;
    if (currentTotal == null || participants.isEmpty) {
      return 0;
    }

    return currentTotal.cents % participants.length;
  }

  List<SplitParticipant> get extraCentRecipients =>
      participants.take(extraCentRecipientCount).toList(growable: false);
}

final class ExpenseSplitController extends Notifier<ExpenseSplitState> {
  int _nextParticipantId = 0;

  @override
  ExpenseSplitState build() => ExpenseSplitState();

  void updateTotal(String input) {
    final result = input.trim().isEmpty ? null : MoneyParser.parseEur(input);
    state = ExpenseSplitState(
      totalInput: input,
      totalResult: result,
      participants: state.participants,
      participantNameError: state.participantNameError,
    );
  }

  bool addParticipant(String input) {
    final name = input.trim();
    if (name.isEmpty) {
      _setParticipantNameError(ParticipantNameError.blank);
      return false;
    }

    final normalizedName = name.toLowerCase();
    final isDuplicate = state.participants.any(
      (participant) => participant.name.toLowerCase() == normalizedName,
    );
    if (isDuplicate) {
      _setParticipantNameError(ParticipantNameError.duplicate);
      return false;
    }

    final participant = SplitParticipant(id: _nextParticipantId++, name: name);
    state = ExpenseSplitState(
      totalInput: state.totalInput,
      totalResult: state.totalResult,
      participants: [...state.participants, participant],
    );
    return true;
  }

  void removeParticipant(int participantId) {
    state = ExpenseSplitState(
      totalInput: state.totalInput,
      totalResult: state.totalResult,
      participants: state.participants
          .where((participant) => participant.id != participantId)
          .toList(growable: false),
    );
  }

  void clearParticipantNameError() {
    if (state.participantNameError == null) {
      return;
    }

    state = ExpenseSplitState(
      totalInput: state.totalInput,
      totalResult: state.totalResult,
      participants: state.participants,
    );
  }

  void _setParticipantNameError(ParticipantNameError error) {
    state = ExpenseSplitState(
      totalInput: state.totalInput,
      totalResult: state.totalResult,
      participants: state.participants,
      participantNameError: error,
    );
  }
}
