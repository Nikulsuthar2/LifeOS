import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';
import '../repositories/habit_repository.dart';

class HabitCard extends ConsumerWidget {
  final HabitWithStatus habitWithStatus;

  const HabitCard({super.key, required this.habitWithStatus});

  IconData _getIconData(String name) {
    switch (name) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'bolt':
        return Icons.bolt;
      case 'menu_book':
        return Icons.menu_book;
      case 'water_drop':
        return Icons.water_drop;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'school':
        return Icons.school;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habit = habitWithStatus.habit;
    final isDone = habitWithStatus.isCompletedToday;
    final streak = habitWithStatus.streakDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(habit.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(habit.icon),
                    size: 20,
                    color: Color(habit.color),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          if (streak > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '🔥 $streak days',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.high,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Check-in button
                GestureDetector(
                  onTap: () async {
                    final repo = ref.read(habitRepositoryProvider);
                    await repo.toggleHabitCompletion(habit.id);
                    ref.invalidate(habitsListProvider);
                    ref.invalidate(todayHabitMetricsProvider);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.success : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                      border: Border.all(
                        color: isDone ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: isDone ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 7 Days History Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                Row(
                  children: List.generate(habitWithStatus.last7Days.length, (i) {
                    final completed = habitWithStatus.last7Days[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? Color(habit.color)
                            : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                        border: Border.all(
                          color: completed ? Color(habit.color) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 1,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

