import 'package:flutter/material.dart';
import 'package:splitlens/app/navigation/app_routes.dart';
import 'package:splitlens/app/theme/app_theme.dart';
import 'package:splitlens/features/expense_split/presentation/expense_split_screen.dart';
import 'package:splitlens/features/expense_history/presentation/expense_history_screen.dart';
import 'package:splitlens/features/home/presentation/home_screen.dart';
import 'package:splitlens/features/receipt_capture/presentation/receipt_capture_screen.dart';

class SplitLensApp extends StatelessWidget {
  const SplitLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.expenseSplit: (_) => const ExpenseSplitScreen(),
        AppRoutes.expenseHistory: (_) => const ExpenseHistoryScreen(),
        AppRoutes.receiptCapture: (_) => const ReceiptCaptureScreen(),
      },
    );
  }
}
