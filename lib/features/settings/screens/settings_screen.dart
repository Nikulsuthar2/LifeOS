import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../goals/providers/goal_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../learning/providers/roadmap_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/habits/providers/habit_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _jsonRestoreController = TextEditingController();

  static const List<Map<String, dynamic>> _accentPresets = [
    {'name': 'Indigo', 'color': Color(0xFF6366F1)},
    {'name': 'Emerald', 'color': Color(0xFF10B981)},
    {'name': 'Sky', 'color': Color(0xFF0EA5E9)},
    {'name': 'Amber', 'color': Color(0xFFF59E0B)},
    {'name': 'Rose', 'color': Color(0xFFF43F5E)},
    {'name': 'Violet', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  void dispose() {
    _jsonRestoreController.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    final jsonStr = await AppDatabase.instance.exportToJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup JSON Exported'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your complete local-first database has been copied to your clipboard!'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 120,
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr.substring(0, jsonStr.length > 500 ? 500 : jsonStr.length) +
                        (jsonStr.length > 500 ? '...\n[Full JSON copied to clipboard]' : ''),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
    }
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restore from JSON Backup'),
        content: TextField(
          controller: _jsonRestoreController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste valid LifeOS JSON backup here...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final text = _jsonRestoreController.text.trim();
              if (text.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              try {
                await AppDatabase.instance.restoreFromJson(text);
                _refreshAllProviders();
                _jsonRestoreController.clear();
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Data restored successfully!')),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to restore backup: $e')),
                );
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Sample Data'),
        content: const Text(
          'This will wipe existing records and reload the rich Computer Science & AI Roadmap, default habits, and time blocks. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.urgent),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppDatabase.instance.resetToSampleData();
      _refreshAllProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset to initial sample data.')),
        );
      }
    }
  }

  void _refreshAllProviders() {
    ref.invalidate(tasksListProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);
    ref.invalidate(roadmapsListProvider);
    ref.invalidate(activeRoadmapSpotlightProvider);
    ref.invalidate(habitsListProvider);
    ref.invalidate(todayHabitMetricsProvider);
    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(weeklyFocusTrendProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(goalsListProvider);
    ref.invalidate(projectsListProvider);
    ref.invalidate(journalEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final themeSettings = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 88),
        children: [
          // 1. Appearance & Theme Settings
          Text(
            'APPEARANCE & THEME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeSettings.themeMode},
                    onSelectionChanged: (newSelection) {
                      themeNotifier.setThemeMode(newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                // Follow System Dynamic Color (Material You)
                SwitchListTile(
                  title: const Text(
                    'Follow System Dynamic Color',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Extract wallpaper accent on Android 12+ (Material You)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: themeSettings.followDynamicColor,
                  onChanged: (val) => themeNotifier.setFollowDynamicColor(val),
                ),
                const Divider(height: 1),

                // Custom Accent Palette
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accent Color Palette',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (themeSettings.followDynamicColor)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Dynamic Active',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _accentPresets.map((preset) {
                      final color = preset['color'] as Color;
                      final isSelected = themeSettings.accentColor.toARGB32() == color.toARGB32();

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          themeNotifier.setAccentColor(color);
                          if (themeSettings.followDynamicColor) {
                            themeNotifier.setFollowDynamicColor(false);
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 18, color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 2. Data & Storage Section (Local-first & Backup)
          Text(
            'DATA & PRIVACY (LOCAL-FIRST)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined, color: AppColors.success),
                  title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Save your complete data offline as JSON'),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_outlined, color: AppColors.info),
                  title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Restore data from a JSON backup'),
                  onTap: _showRestoreDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined, color: AppColors.urgent),
                  title: const Text('Reset to Sample Dataset', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.urgent)),
                  subtitle: const Text('Reload the rich initial CS Roadmap and habits'),
                  onTap: _resetToSampleData,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 3. App Info
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.all_inclusive, size: 28, color: primary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Life OS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 · Local-First Architecture',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Designed for intentional living & continuous learning.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
