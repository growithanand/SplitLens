import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitlens/app/navigation/app_routes.dart';
import 'package:splitlens/features/expense_confirmation/domain/persisted_expense.dart';
import 'package:splitlens/features/expense_detail/presentation/expense_detail_screen.dart';
import 'package:splitlens/features/expense_history/application/expense_history_controller.dart';
import 'package:splitlens/features/expense_history/application/expense_history_filter.dart';

class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(expenseHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense history'),
        actions: [
          IconButton(
            key: const ValueKey('refresh-expense-history-button'),
            onPressed: history.isLoading
                ? null
                : () => ref
                      .read(expenseHistoryControllerProvider.notifier)
                      .reload(),
            tooltip: 'Refresh expense history',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: history.when(
          loading: () => const _HistoryLoading(),
          error: (error, stackTrace) => _HistoryError(
            onRetry: () =>
                ref.read(expenseHistoryControllerProvider.notifier).reload(),
          ),
          data: (expenses) => expenses.isEmpty
              ? const _EmptyHistory()
              : _HistoryContent(
                  filteredExpenses: ExpenseHistoryFilter.apply(
                    expenses,
                    _query,
                  ),
                  searchController: _searchController,
                  query: _query,
                  onQueryChanged: (query) => setState(() => _query = query),
                  onClearSearch: _clearSearch,
                  onExpenseChanged: () => ref
                      .read(expenseHistoryControllerProvider.notifier)
                      .reload(),
                ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey('expense-history-loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading saved expenses…'),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('expense-history-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'No expenses yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Saved receipt expenses will appear here and remain '
                'available on this device.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.receiptCapture),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add a receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('expense-history-error'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Expense history unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved expenses remain on this device. Try loading '
                'them again.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('retry-expense-history-button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.filteredExpenses,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onExpenseChanged,
  });

  final List<PersistedExpense> filteredExpenses;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onExpenseChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            key: const ValueKey('expense-history-search-field'),
            controller: searchController,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search expenses',
              hintText: 'Merchant or participant',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('clear-expense-history-search'),
                      onPressed: onClearSearch,
                      tooltip: 'Clear expense search',
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: filteredExpenses.isEmpty
              ? _NoMatchingExpenses(query: query, onClearSearch: onClearSearch)
              : _ExpenseList(
                  expenses: filteredExpenses,
                  onExpenseChanged: onExpenseChanged,
                ),
        ),
      ],
    );
  }
}

class _NoMatchingExpenses extends StatelessWidget {
  const _NoMatchingExpenses({required this.query, required this.onClearSearch});

  final String query;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('expense-history-no-matches'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'No matching expenses',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'No merchant or participant matches “${query.trim()}”.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const ValueKey('clear-no-matches-search-button'),
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses, required this.onExpenseChanged});

  final List<PersistedExpense> expenses;
  final Future<void> Function() onExpenseChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('expense-history-list'),
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _ExpenseHistoryCard(
        expense: expenses[index],
        onOpen: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              settings: const RouteSettings(name: AppRoutes.expenseDetail),
              builder: (_) =>
                  ExpenseDetailScreen(expenseId: expenses[index].id),
            ),
          );
          if (changed == true && context.mounted) {
            await onExpenseChanged();
          }
        },
      ),
    );
  }
}

class _ExpenseHistoryCard extends StatelessWidget {
  const _ExpenseHistoryCard({required this.expense, required this.onOpen});

  final PersistedExpense expense;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final participantCount = expense.allocations.length;
    final participantLabel = participantCount == 1
        ? '1 participant'
        : '$participantCount participants';
    final dateLabel = DateFormat('dd MMM yyyy').format(expense.receipt.date);
    final amountLabel = expense.receipt.total.format();
    final usesCompactLayout =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;

    return Semantics(
      button: true,
      onTap: onOpen,
      label:
          '${expense.receipt.merchant}, $dateLabel, $amountLabel, '
          '$participantLabel. Open expense details.',
      excludeSemantics: true,
      child: Card(
        key: ValueKey('expense-history-item-${expense.id}'),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('open-expense-${expense.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.receipt_long_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.receipt.merchant,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(child: Text(participantLabel)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!usesCompactLayout) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (usesCompactLayout) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        amountLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
