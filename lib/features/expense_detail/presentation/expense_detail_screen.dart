import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/expense_detail/application/expense_detail_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(expenseDetailProvider(expenseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: SafeArea(
        child: expense.when(
          loading: () => const _DetailLoading(),
          error: (error, stackTrace) => _DetailUnavailable(
            onRetry: () => ref.invalidate(expenseDetailProvider(expenseId)),
          ),
          data: (expense) => expense == null
              ? const _ExpenseNotFound()
              : _ExpenseDetails(expense: expense),
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('expense-detail-loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading expense details…'),
        ],
      ),
    );
  }
}

class _DetailUnavailable extends StatelessWidget {
  const _DetailUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _DetailMessage(
      key: const ValueKey('expense-detail-error'),
      icon: Icons.error_outline,
      title: 'Expense details unavailable',
      message: 'The saved expense could not be loaded. Try again.',
      action: FilledButton.icon(
        key: const ValueKey('retry-expense-detail-button'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}

class _ExpenseNotFound extends StatelessWidget {
  const _ExpenseNotFound();

  @override
  Widget build(BuildContext context) {
    return const _DetailMessage(
      key: ValueKey('expense-detail-not-found'),
      icon: Icons.search_off_outlined,
      title: 'Expense not found',
      message: 'This expense is no longer available on this device.',
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (action case final action?) ...[
                const SizedBox(height: 24),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseDetails extends StatelessWidget {
  const _ExpenseDetails({required this.expense});

  final PersistedExpense expense;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('expense-detail-content'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExpenseSummary(expense: expense),
              const SizedBox(height: 24),
              Text(
                'Participants',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _AllocationList(expense: expense),
              const SizedBox(height: 24),
              Text(
                'Receipt evidence',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _ReceiptImageSection(path: expense.receipt.receiptImagePath),
              const SizedBox(height: 8),
              _RawOcrSection(rawText: expense.receipt.rawOcrText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({required this.expense});

  final PersistedExpense expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.receipt.merchant,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Text(
              expense.receipt.total.format(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryFact(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('dd MMM yyyy').format(expense.receipt.date),
                ),
                const SizedBox(height: 8),
                _SummaryFact(
                  icon: Icons.euro_outlined,
                  label: expense.receipt.currencyCode,
                ),
                const SizedBox(height: 8),
                _SummaryFact(
                  icon: Icons.payments_outlined,
                  label: 'Paid by ${expense.paidBy.name}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryFact extends StatelessWidget {
  const _SummaryFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimaryContainer;
    return Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: TextStyle(color: foreground)),
        ),
      ],
    );
  }
}

class _AllocationList extends StatelessWidget {
  const _AllocationList({required this.expense});

  final PersistedExpense expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < expense.allocations.length; index++) ...[
            Builder(
              builder: (context) {
                final allocation = expense.allocations[index];
                final isPayer = allocation.participant.id == expense.paidBy.id;
                return ListTile(
                  key: ValueKey('expense-allocation-${allocation.id}'),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(allocation.participant.name),
                  subtitle: isPayer
                      ? const Text('Paid for this expense')
                      : null,
                  trailing: Text(
                    allocation.amount.format(),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            if (index < expense.allocations.length - 1)
              Divider(height: 1, indent: 72, color: colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _ReceiptImageSection extends StatelessWidget {
  const _ReceiptImageSection({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const ValueKey('expense-receipt-image-section'),
        leading: const Icon(Icons.image_outlined),
        title: const Text('Original receipt image'),
        subtitle: const Text('Stored device reference'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Receipt image unavailable at its stored location.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RawOcrSection extends StatelessWidget {
  const _RawOcrSection({required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: const ValueKey('expense-raw-ocr-section'),
        leading: const Icon(Icons.text_snippet_outlined),
        title: const Text('Raw OCR text'),
        subtitle: const Text('Unverified recognition output'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectionArea(
              child: Text(
                rawText,
                key: const ValueKey('expense-raw-ocr-text'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
