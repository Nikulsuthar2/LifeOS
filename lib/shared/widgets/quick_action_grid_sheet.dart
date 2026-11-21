import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/notes/screens/note_edit_screen.dart';
import '../../features/tasks/screens/create_task_screen.dart';
import '../../features/track/focus/screens/focus_screen.dart';
import '../../features/track/habits/screens/habit_detail_screen.dart';

/// Material 3 Expressive grid-based action sheet opened from the center Add button in bottom navigation.
/// Allows fast creation of tasks, habits, focus sessions, notes, journal reflections, and health logs.
class QuickActionGridSheet extends ConsumerWidget {
  const QuickActionGridSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickActionGridSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333338) : const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quick capture across all LifeOS modules',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF222226) : const Color(0xFFF0F0F4),
                    foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3x2 Grid of Actions with M3 Expressive cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                // 1. Task (To-Do)
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.check_circle_rounded,
                  iconColor: primary,
                  title: 'New Task',
                  subtitle: 'To-do, schedule & deadline',
                  onTap: () {
                    Navigator.pop(context);
                    CreateTaskScreen.open(context);
                  },
                ),

                // 2. Habit
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'New Habit',
                  subtitle: 'Daily streak & routine',
                  onTap: () {
                    Navigator.pop(context);
                    HabitDetailScreen.open(context, isNew: true);
                  },
                ),

                // 3. Note
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.note_add_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  title: 'New Note',
                  subtitle: 'Markdown & folder docs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const NoteEditScreen()),
                    );
                  },
                ),

                // 4. Daily Reflection
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.auto_stories_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Reflection',
                  subtitle: 'Mood & daily journal entry',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const JournalScreen()),
                    );
                  },
                ),

                // 5. Health Log
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Health Log',
                  subtitle: 'Vitals, water & workout',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const HealthScreen()),
                    );
                  },
                ),

                // 6. Focus Session
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Focus Timer',
                  subtitle: 'Pomodoro deep work',
                  onTap: () {
                    Navigator.pop(context);
                    FocusScreen.open(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF28282E) : const Color(0xFFE6E6EA),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
