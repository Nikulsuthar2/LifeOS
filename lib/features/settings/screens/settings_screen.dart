import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../goals/providers/goal_provider.dart';
import '../../goals/screens/goals_screen.dart';
import '../../journal/providers/journal_provider.dart';
import '../../journal/screens/journal_screen.dart';
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
                if (dialogCtx.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error restoring data: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Restore'),
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
          'This will reset your local database to the default sample dataset (Computer Science Roadmap, Daily Habits, Tasks).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppDatabase.instance.resetToSeedData();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('More & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Life Modules Navigation Section
          Text(
            'Life Modules',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.primaryLight),
                  title: const Text('Goals & Projects', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Long-term direction, milestones & projects'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined, color: AppColors.secondary),
                  title: const Text('Journal & Reflection', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Daily review, lessons learned & notes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data & Storage Section (Local-first & Backup)
          Text(
            'Data & Privacy (Local-First)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),

          Material(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 24),

          // App Info
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.all_inclusive, size: 28, color: AppColors.primaryLight),
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
