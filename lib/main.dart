import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'shared/shell/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initPlatform();

  // Initialize and seed database if not already created
  await AppDatabase.instance.database;

  runApp(
    const ProviderScope(
      child: LifeOsApp(),
    ),
  );
}

class LifeOsApp extends StatelessWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to sleek, premium dark mode
      home: const MainNavigationShell(),
    );
  }
}
