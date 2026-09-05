import 'package:flutter/material.dart';
import 'package:splitlens/app/navigation/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('SplitLens')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 52,
                      color: colorScheme.onPrimaryContainer,
                      semanticLabel: 'Receipt',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Split receipts with confidence',
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Capture a receipt, review every detail, and divide the '
                    'total fairly.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add a receipt image',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Take a receipt photo or select a receipt '
                                      'screenshot from your gallery. The image '
                                      'stays on this device.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.receiptCapture),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add a receipt'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('view-expense-history-button'),
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.expenseHistory),
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('View expense history'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.expenseSplit),
                            icon: const Icon(Icons.group_outlined),
                            label: const Text('Start a manual split'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
