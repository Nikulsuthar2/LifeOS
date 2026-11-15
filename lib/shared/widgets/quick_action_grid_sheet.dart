import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/quick_capture_sheet.dart';
import '../../features/tasks/screens/create_task_screen.dart';
import '../../features/track/focus/providers/focus_provider.dart';

/// Modern grid-based action sheet opened from the center Add button in bottom navigation.
/// Allows fast creation of tasks, habits, focus sessions, and roadmap items without
/// floating buttons cluttering or obstructing the screen.
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Create',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 2x2 Grid of Actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                // 1. Task (To-Do)
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: CupertinoIcons.checkmark_alt_circle_fill,
                  iconColor: AppColors.primaryLight,
                  title: 'New Task',
                  subtitle: 'To-do, schedule, deadline',
                  onTap: () {
                    Navigator.pop(context);
                    CreateTaskScreen.open(context);
                  },
                ),

                // 2. Habit
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: CupertinoIcons.flame_fill,
                  iconColor: Colors.amber,
                  title: 'New Habit',
                  subtitle: 'Daily streak & routine',
                  onTap: () {
                    Navigator.pop(context);
                    QuickCaptureSheet.show(context);
                  },
                ),

                // 3. Focus Session
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: CupertinoIcons.timer,
                  iconColor: Colors.deepOrangeAccent,
                  title: 'Focus Timer',
                  subtitle: 'Pomodoro deep work',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(focusTimerProvider.notifier).startTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Focus session started!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // 4. Quick Capture / Note
                _buildActionCard(
                  context: context,
                  isDark: isDark,
                  icon: CupertinoIcons.pencil_outline,
                  iconColor: Colors.tealAccent,
                  title: 'Quick Note',
                  subtitle: 'Capture thought or idea',
                  onTap: () {
                    Navigator.pop(context);
                    QuickCaptureSheet.show(context);
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C20) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E5EA),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
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
