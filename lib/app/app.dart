import 'package:flutter/material.dart';
import 'package:splitlens/app/navigation/app_routes.dart';
import 'package:splitlens/app/theme/app_theme.dart';
import 'package:splitlens/features/home/presentation/home_screen.dart';

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
      routes: {AppRoutes.home: (_) => const HomeScreen()},
    );
  }
}
