import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/expense_split/application/expense_split_controller.dart';

void main() {
  group('ExpenseSplitController', () {
    late ProviderContainer container;
    late ExpenseSplitController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(expenseSplitControllerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('trims participant names and preserves their order', () {
      controller.addParticipant('  Alice  ');
      controller.addParticipant('Bob');

      final state = container.read(expenseSplitControllerProvider);
      expect(state.participants.map((participant) => participant.name), [
        'Alice',
        'Bob',
      ]);
    });

    test('rejects blank and case-insensitive duplicate names', () {
      expect(controller.addParticipant('   '), isFalse);
      expect(
        container.read(expenseSplitControllerProvider).participantNameError,
        ParticipantNameError.blank,
      );

      expect(controller.addParticipant('Alice'), isTrue);
      expect(controller.addParticipant(' alice '), isFalse);
      expect(
        container.read(expenseSplitControllerProvider).participantNameError,
        ParticipantNameError.duplicate,
      );
    });

    test('removes a participant by stable identifier', () {
      controller.addParticipant('Alice');
      controller.addParticipant('Bob');
      final aliceId = container
          .read(expenseSplitControllerProvider)
          .participants
          .first
          .id;

      controller.removeParticipant(aliceId);

      final participants = container
          .read(expenseSplitControllerProvider)
          .participants;
      expect(participants.map((participant) => participant.name), ['Bob']);
    });

    test('derives exact allocations and remainder recipients', () {
      controller.updateTotal('10.00');
      controller.addParticipant('Alice');
      controller.addParticipant('Bob');
      controller.addParticipant('Charlie');

      final state = container.read(expenseSplitControllerProvider);
      expect(state.split?.allocations.map((allocation) => allocation.cents), [
        334,
        333,
        333,
      ]);
      expect(state.extraCentRecipientCount, 1);
      expect(state.extraCentRecipients.single.name, 'Alice');
    });
  });
}
