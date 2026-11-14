import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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

class LifeOsApp extends ConsumerWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final ColorScheme? lightScheme = themeSettings.followDynamicColor ? lightDynamic : null;
        final ColorScheme? darkScheme = themeSettings.followDynamicColor ? darkDynamic : null;

        return MaterialApp(
          title: 'Life OS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(
            dynamicScheme: lightScheme,
            customAccent: themeSettings.accentColor,
          ),
          darkTheme: AppTheme.buildDarkTheme(
            dynamicScheme: darkScheme,
            customAccent: themeSettings.accentColor,
          ),
          themeMode: themeSettings.themeMode,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}
