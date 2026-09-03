import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/core/money/money_parser.dart';
import 'package:splitlens/features/expense_split/application/expense_split_controller.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';

class ExpenseSplitScreen extends ConsumerStatefulWidget {
  const ExpenseSplitScreen({super.key});

  @override
  ConsumerState<ExpenseSplitScreen> createState() => _ExpenseSplitScreenState();
}

class _ExpenseSplitScreenState extends ConsumerState<ExpenseSplitScreen> {
  late final TextEditingController _totalController;
  final _participantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(
      text: ref.read(expenseSplitControllerProvider).totalInput,
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseSplitControllerProvider);
    final split = state.split;

    return Scaffold(
      appBar: AppBar(title: const Text('Split an expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the receipt total',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amounts are stored as integer cents and divided without '
                    'rounding money away.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const ValueKey('total-field'),
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Total',
                      hintText: '12.99',
                      prefixText: '€ ',
                      border: const OutlineInputBorder(),
                      errorText: _totalErrorText(state.totalError),
                    ),
                    onChanged: ref
                        .read(expenseSplitControllerProvider.notifier)
                        .updateTotal,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Participants',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('participant-name-field'),
                          controller: _participantController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Participant name',
                            border: const OutlineInputBorder(),
                            errorText: _participantErrorText(
                              state.participantNameError,
                            ),
                          ),
                          onChanged: (_) => ref
                              .read(expenseSplitControllerProvider.notifier)
                              .clearParticipantNameError(),
                          onSubmitted: (_) => _addParticipant(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const ValueKey('add-participant-button'),
                        onPressed: _addParticipant,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (state.participants.isEmpty)
                    const _EmptyParticipantsCard()
                  else
                    _ParticipantList(
                      participants: state.participants,
                      allocationCents: split?.allocations
                          .map((allocation) => allocation.format())
                          .toList(growable: false),
                      onRemove: (participantId) => ref
                          .read(expenseSplitControllerProvider.notifier)
                          .removeParticipant(participantId),
                    ),
                  if (split != null) ...[
                    const SizedBox(height: 24),
                    _SplitSummaryCard(state: state),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addParticipant() {
    final wasAdded = ref
        .read(expenseSplitControllerProvider.notifier)
        .addParticipant(_participantController.text);
    if (wasAdded) {
      _participantController.clear();
    }
  }
}

class _EmptyParticipantsCard extends StatelessWidget {
  const _EmptyParticipantsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.group_add_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Add at least one participant to preview the split.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantList extends StatelessWidget {
  const _ParticipantList({
    required this.participants,
    required this.allocationCents,
    required this.onRemove,
  });

  final List<SplitParticipant> participants;
  final List<String>? allocationCents;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < participants.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(participants[index].name),
              subtitle: allocationCents == null
                  ? const Text('Enter a valid total to calculate')
                  : const Text('Equal allocation'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allocationCents != null)
                    Text(
                      allocationCents![index],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  IconButton(
                    key: ValueKey(
                      'remove-participant-${participants[index].id}',
                    ),
                    onPressed: () => onRemove(participants[index].id),
                    tooltip: 'Remove ${participants[index].name}',
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({required this.state});

  final ExpenseSplitState state;

  @override
  Widget build(BuildContext context) {
    final split = state.split!;
    final extraCentCount = state.extraCentRecipientCount;

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${split.total.format()} across '
              '${split.participantCount} participant'
              '${split.participantCount == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    extraCentCount == 0
                        ? 'No rounding adjustment is needed.'
                        : _remainderMessage(state.extraCentRecipients),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _remainderMessage(List<SplitParticipant> recipients) {
  final names = recipients.map((participant) => participant.name).toList();
  if (names.length == 1) {
    return 'Rounding: ${names.single} receives one extra cent.';
  }

  return 'Rounding: ${_joinNames(names)} each receive one extra cent.';
}

String _joinNames(List<String> names) {
  if (names.length == 2) {
    return '${names.first} and ${names.last}';
  }

  return '${names.take(names.length - 1).join(', ')}, and ${names.last}';
}

String? _totalErrorText(MoneyParseError? error) => switch (error) {
  null => null,
  MoneyParseError.empty => 'Enter a total.',
  MoneyParseError.negativeAmount => 'Total cannot be negative.',
  MoneyParseError.unsupportedCurrency => 'Only EUR is supported.',
  MoneyParseError.invalidFormat => 'Enter a valid amount, such as 12.99.',
  MoneyParseError.ambiguousSeparator =>
    'Use two decimal digits to make the amount clear.',
  MoneyParseError.amountTooLarge => 'Total is above the supported limit.',
};

String? _participantErrorText(ParticipantNameError? error) => switch (error) {
  null => null,
  ParticipantNameError.blank => 'Name cannot be blank.',
  ParticipantNameError.duplicate => 'Participant names must be unique.',
};
