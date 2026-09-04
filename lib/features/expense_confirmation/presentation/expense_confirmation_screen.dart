import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitlens/features/expense_confirmation/application/expense_confirmation_controller.dart';
import 'package:splitlens/features/expense_confirmation/domain/confirmed_expense.dart';
import 'package:splitlens/features/expense_split/domain/split_participant.dart';
import 'package:splitlens/features/receipt_review/domain/confirmed_receipt_review.dart';

class ExpenseConfirmationScreen extends ConsumerStatefulWidget {
  const ExpenseConfirmationScreen({required this.receipt, super.key});

  final ConfirmedReceiptReview receipt;

  @override
  ConsumerState<ExpenseConfirmationScreen> createState() =>
      _ExpenseConfirmationScreenState();
}

class _ExpenseConfirmationScreenState
    extends ConsumerState<ExpenseConfirmationScreen> {
  late final ExpenseConfirmationInput _input;
  final _participantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input = ExpenseConfirmationInput(widget.receipt);
  }

  @override
  void dispose() {
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseConfirmationControllerProvider(_input));
    final split = state.split;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm expense')),
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
                    'Split the reviewed receipt',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add everyone sharing this expense, choose who paid, '
                    'and check the exact allocation before confirming.',
                  ),
                  const SizedBox(height: 20),
                  _ReviewedReceiptCard(receipt: state.receipt),
                  const SizedBox(height: 28),
                  Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey(
                            'expense-confirmation-participant-field',
                          ),
                          controller: _participantController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Participant name',
                            border: const OutlineInputBorder(),
                            errorText: _participantNameErrorText(
                              state.participantNameError,
                            ),
                          ),
                          onChanged: (_) => ref
                              .read(
                                expenseConfirmationControllerProvider(_input)
                                    .notifier,
                              )
                              .clearParticipantNameError(),
                          onSubmitted: (_) => _addParticipant(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const ValueKey(
                          'expense-confirmation-add-participant-button',
                        ),
                        onPressed: _addParticipant,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.participants.isEmpty)
                    const _EmptyParticipantsCard()
                  else
                    _ParticipantAllocationList(
                      participants: state.participants,
                      allocationLabels: split!.allocations
                          .map((allocation) => allocation.format())
                          .toList(growable: false),
                      onRemove: (participantId) => ref
                          .read(
                            expenseConfirmationControllerProvider(_input)
                                .notifier,
                          )
                          .removeParticipant(participantId),
                    ),
                  if (state.validationErrors.contains(
                    ExpenseConfirmationValidationError.participantsRequired,
                  )) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add at least one participant.',
                      key: const ValueKey('participants-required-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Who paid?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.participants.isEmpty
                        ? 'Add a participant before selecting the payer.'
                        : 'Select one participant as the payer.',
                  ),
                  if (state.participants.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final participant in state.participants)
                          ChoiceChip(
                            key: ValueKey('payer-choice-${participant.id}'),
                            label: Text(participant.name),
                            selected: state.selectedPayerId == participant.id,
                            onSelected: (_) => ref
                                .read(
                                  expenseConfirmationControllerProvider(_input)
                                      .notifier,
                                )
                                .selectPayer(participant.id),
                          ),
                      ],
                    ),
                  ],
                  if (state.validationErrors.contains(
                    ExpenseConfirmationValidationError.payerRequired,
                  )) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Select who paid for the expense.',
                      key: const ValueKey('payer-required-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (split != null) ...[
                    const SizedBox(height: 24),
                    _RoundingSummary(
                      participants: state.participants,
                      totalCents: state.receipt.total.cents,
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    key: const ValueKey('confirm-expense-button'),
                    onPressed: _confirmExpense,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm expense'),
                  ),
                  if (state.confirmedExpense case final expense?) ...[
                    const SizedBox(height: 20),
                    _ConfirmedExpenseCard(expense: expense),
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
        .read(expenseConfirmationControllerProvider(_input).notifier)
        .addParticipant(_participantController.text);
    if (wasAdded) {
      _participantController.clear();
    }
  }

  void _confirmExpense() {
    final wasConfirmed = ref
        .read(expenseConfirmationControllerProvider(_input).notifier)
        .confirm();
    if (wasConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense confirmed in memory.')),
      );
    }
  }
}

class _ReviewedReceiptCard extends StatelessWidget {
  const _ReviewedReceiptCard({required this.receipt});

  final ConfirmedReceiptReview receipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('reviewed-receipt-summary-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    receipt.merchant,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  receipt.total.format(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_formatDate(receipt.date)} · ${receipt.currencyCode}'),
            const SizedBox(height: 4),
            const Text('Total confirmed during receipt review.'),
          ],
        ),
      ),
    );
  }
}

class _EmptyParticipantsCard extends StatelessWidget {
  const _EmptyParticipantsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No participants added yet.'),
      ),
    );
  }
}

class _ParticipantAllocationList extends StatelessWidget {
  const _ParticipantAllocationList({
    required this.participants,
    required this.allocationLabels,
    required this.onRemove,
  });

  final List<SplitParticipant> participants;
  final List<String> allocationLabels;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('expense-allocation-list'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < participants.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(participants[index].name),
              subtitle: const Text('Equal allocation'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allocationLabels[index],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    key: ValueKey(
                      'expense-confirmation-remove-${participants[index].id}',
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

class _RoundingSummary extends StatelessWidget {
  const _RoundingSummary({
    required this.participants,
    required this.totalCents,
  });

  final List<SplitParticipant> participants;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final extraCentCount = totalCents % participants.length;
    final message = extraCentCount == 0
        ? 'The total divides evenly; no rounding adjustment is needed.'
        : _remainderMessage(
            participants.take(extraCentCount).toList(growable: false),
          );

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ConfirmedExpenseCard extends StatelessWidget {
  const _ConfirmedExpenseCard({required this.expense});

  final ConfirmedExpense expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('confirmed-expense-card'),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Expense ready to save',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${expense.receipt.merchant} · ${expense.receipt.total.format()}',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            Text(
              'Paid by ${expense.paidBy.name}',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            for (final allocation in expense.allocations)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        allocation.participant.name,
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    Text(
                      allocation.amount.format(),
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'This confirmation is currently held in memory only. '
              'Local saving is the next implementation step.',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _remainderMessage(List<SplitParticipant> recipients) {
  final names = recipients.map((participant) => participant.name).toList();
  if (names.length == 1) {
    return '${names.single} receives one extra cent.';
  }

  return '${_joinNames(names)} each receive one extra cent.';
}

String _joinNames(List<String> names) {
  if (names.length == 2) {
    return '${names.first} and ${names.last}';
  }

  return '${names.take(names.length - 1).join(', ')}, and ${names.last}';
}

String? _participantNameErrorText(ExpenseParticipantNameError? error) =>
    switch (error) {
      null => null,
      ExpenseParticipantNameError.blank => 'Name cannot be blank.',
      ExpenseParticipantNameError.duplicate =>
        'Participant names must be unique.',
    };
