import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';
import '../repositories/habit_repository.dart';
import '../screens/habit_detail_screen.dart';

class HabitViewSheet extends ConsumerWidget {
  final HabitWithStatus habitWithStatus;

  const HabitViewSheet({super.key, required this.habitWithStatus});

  static Future<void> show(BuildContext context, HabitWithStatus habitWithStatus) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitViewSheet(habitWithStatus: habitWithStatus),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habit = habitWithStatus.habit;
    final category = HabitCategoryPresets.getCategory(habit.category);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Category Icon + Title + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(habit.color).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  size: 22,
                  color: Color(habit.color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(habit.color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(habit.color),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222226) : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            habit.frequency == 'daily' ? 'Everyday' : 'Specific Days',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        if (habit.timeOfDay != 'all')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222226) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              habit.timeOfDay[0].toUpperCase() + habit.timeOfDay.substring(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              habit.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Quick Streak & Metrics Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF8F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E5EA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickMetric('Current Streak', '🔥 ${habitWithStatus.streakDays}d', AppColors.high),
                Container(width: 1, height: 28, color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E5EA)),
                _buildQuickMetric('Best Streak', '🏆 ${habitWithStatus.bestStreakDays}d', Theme.of(context).colorScheme.primary),
                Container(width: 1, height: 28, color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E5EA)),
                _buildQuickMetric('This Week', '${habitWithStatus.weekCompletedCount}/${habitWithStatus.weekEnabledCount}', Color(habit.color)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Today's Status Interactive Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Check-in',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              InkWell(
                onTap: () async {
                  final repo = ref.read(habitRepositoryProvider);
                  await repo.cycleHabitDayStatus(habit.id, todayStr);
                  ref.invalidate(habitsListProvider);
                  ref.invalidate(todayHabitMetricsProvider);
                  ref.invalidate(habitMonthLogsProvider);
                  ref.invalidate(habitDetailedStatsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: habitWithStatus.todayStatus == HabitDayStatus.done
                        ? AppColors.success.withValues(alpha: 0.2)
                        : habitWithStatus.todayStatus == HabitDayStatus.fail
                            ? AppColors.error.withValues(alpha: 0.2)
                            : (isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: habitWithStatus.todayStatus == HabitDayStatus.done
                          ? AppColors.success
                          : habitWithStatus.todayStatus == HabitDayStatus.fail
                              ? AppColors.error
                              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        habitWithStatus.todayStatus == HabitDayStatus.done
                            ? Icons.check_circle_rounded
                            : habitWithStatus.todayStatus == HabitDayStatus.fail
                                ? Icons.cancel_rounded
                                : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: habitWithStatus.todayStatus == HabitDayStatus.done
                            ? AppColors.success
                            : habitWithStatus.todayStatus == HabitDayStatus.fail
                                ? AppColors.error
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        habitWithStatus.todayStatus == HabitDayStatus.done
                            ? 'Done'
                            : habitWithStatus.todayStatus == HabitDayStatus.fail
                                ? 'Failed'
                                : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: habitWithStatus.todayStatus == HabitDayStatus.done
                              ? AppColors.success
                              : habitWithStatus.todayStatus == HabitDayStatus.fail
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3 prominent Action Buttons: Calendar, Statistics, Edit
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(habit.color),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 2);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF71717A)),
        ),
      ],
    );
  }
}
