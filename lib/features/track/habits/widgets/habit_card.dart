import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';
import '../repositories/habit_repository.dart';
import '../screens/habit_detail_screen.dart';
import 'habit_view_sheet.dart';

class HabitCard extends ConsumerWidget {
  final HabitWithStatus habitWithStatus;
  final bool? isCollapsed;

  const HabitCard({
    super.key,
    required this.habitWithStatus,
    this.isCollapsed,
  });

  void _showActionMenu(BuildContext context, WidgetRef ref) {
    final habit = habitWithStatus.habit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(CupertinoIcons.calendar, size: 20),
                  title: const Text('Calendar View', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 0);
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.chart_bar, size: 20),
                  title: const Text('Statistics & Charts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 1);
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil, size: 20),
                  title: const Text('Edit Habit Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    HabitDetailScreen.open(context, habit: habit, initialTab: 2);
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: AppColors.error, size: 20),
                  title: const Text('Delete Habit', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dlgCtx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
                        title: const Text('Delete Habit?'),
                        content: const Text('Are you sure you want to delete this habit and all its history?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(dlgCtx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final repo = ref.read(habitRepositoryProvider);
                      await repo.deleteHabit(habit.id);
                      ref.invalidate(habitsListProvider);
                      ref.invalidate(todayHabitMetricsProvider);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habit = habitWithStatus.habit;
    final category = HabitCategoryPresets.getCategory(habit.category);

    final collapsed = isCollapsed ?? (ref.watch(habitViewModeProvider) == HabitViewMode.collapsed);

    String freqSubtitle;
    if (habit.frequency == 'daily') {
      freqSubtitle = 'Everyday';
    } else {
      const dayNames = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
      freqSubtitle = habit.daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
    }

    if (habit.timeOfDay != 'all') {
      freqSubtitle += ' · ${habit.timeOfDay[0].toUpperCase()}${habit.timeOfDay.substring(1)}';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    if (collapsed) {
      return _buildCollapsedCard(context, ref, habit, category, freqSubtitle, isDark, todayStr);
    }

    return _buildExpandedCard(context, ref, habit, category, freqSubtitle, isDark, today);
  }

  // -------------------------------------------------------------
  // A. COLLAPSED VIEW: Header + Single 3-State Checkbox
  // -------------------------------------------------------------
  Widget _buildCollapsedCard(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    HabitCategoryItem category,
    String freqSubtitle,
    bool isDark,
    String todayStr,
  ) {
    final todayStatus = habitWithStatus.todayStatus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => HabitViewSheet.show(context, habitWithStatus),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(habit.color).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  size: 18,
                  color: Color(habit.color),
                ),
              ),
              const SizedBox(width: 12),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          freqSubtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (habitWithStatus.streakDays > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🔥 ${habitWithStatus.streakDays}d',
                            style: const TextStyle(
                              fontSize: 11.5,
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

              const SizedBox(width: 12),

              // Single 3-State Rectangular Checkbox
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final repo = ref.read(habitRepositoryProvider);
                  await repo.cycleHabitDayStatus(habit.id, todayStr);
                  ref.invalidate(habitsListProvider);
                  ref.invalidate(todayHabitMetricsProvider);
                  ref.invalidate(habitMonthLogsProvider);
                  ref.invalidate(habitDetailedStatsProvider);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: todayStatus == HabitDayStatus.done
                        ? AppColors.success
                        : todayStatus == HabitDayStatus.fail
                            ? AppColors.error
                            : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: todayStatus == HabitDayStatus.done
                          ? AppColors.success
                          : todayStatus == HabitDayStatus.fail
                              ? AppColors.error
                              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6)),
                      width: 1.4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: todayStatus == HabitDayStatus.done
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : todayStatus == HabitDayStatus.fail
                          ? const Icon(Icons.close, size: 18, color: Colors.white)
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // B. EXPANDED VIEW: Header + 7 Weekdays + Bottom Metrics Row
  // -------------------------------------------------------------
  Widget _buildExpandedCard(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    HabitCategoryItem category,
    String freqSubtitle,
    bool isDark,
    DateTime today,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => HabitViewSheet.show(context, habitWithStatus),
        borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top row: Icon + Name + Frequency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(habit.color).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      size: 20,
                      color: Color(habit.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              freqSubtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (habitWithStatus.streakDays > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '🔥 ${habitWithStatus.streakDays}d',
                                style: const TextStyle(
                                  fontSize: 11.5,
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
                ],
              ),

              const SizedBox(height: 14),

              // 2. 7 Days of Week Bar (Mon - Sun)
              Row(
                children: List.generate(7, (i) {
                  final day = habitWithStatus.weekDays[i];
                  final isUnlocked = habitWithStatus.weekDayEnabled[i];
                  final isScheduled = habitWithStatus.weekDayScheduled[i];
                  final isFuture = DateTime(day.year, day.month, day.day).isAfter(today);
                  final status = habitWithStatus.weekStatuses[i];
                  final dayLetter = DateFormat('E').format(day).substring(0, 1);
                  final dStr = DateFormat('yyyy-MM-dd').format(day);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLetter,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isUnlocked
                                  ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isUnlocked
                                ? () async {
                                    final repo = ref.read(habitRepositoryProvider);
                                    await repo.cycleHabitDayStatus(habit.id, dStr);
                                    ref.invalidate(habitsListProvider);
                                    ref.invalidate(todayHabitMetricsProvider);
                                    ref.invalidate(habitMonthLogsProvider);
                                    ref.invalidate(habitDetailedStatsProvider);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: !isUnlocked
                                    ? Colors.transparent
                                    : status == HabitDayStatus.done
                                        ? AppColors.success
                                        : status == HabitDayStatus.fail
                                            ? AppColors.error
                                            : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                                border: Border.all(
                                  color: !isScheduled
                                      ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE5E5EA))
                                      : isFuture
                                          ? (isDark ? const Color(0xFF2E2E34) : const Color(0xFFE5E5EA))
                                          : status == HabitDayStatus.done
                                              ? AppColors.success
                                              : status == HabitDayStatus.fail
                                                  ? AppColors.error
                                                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6)),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isFuture || !isScheduled
                                  ? Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF52525B) : const Color(0xFFB0B0B8),
                                      ),
                                    )
                                  : status == HabitDayStatus.done
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : status == HabitDayStatus.fail
                                          ? const Icon(Icons.close, size: 16, color: Colors.white)
                                          : Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 6),

              // 3. Bottom Row: Count & % on left; Calendar, Stats & 3-dots on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Count and percentage up to today
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(habit.color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        habitWithStatus.weekEnabledCount > 0
                            ? '${habitWithStatus.weekCompletedCount}/${habitWithStatus.weekEnabledCount} days · ${habitWithStatus.weekPercentage}%'
                            : 'Upcoming week',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Right: Calendar, Statistics & 3-dots buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.calendar, size: 17),
                        tooltip: 'Calendar View',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          HabitDetailScreen.open(context, habit: habit, initialTab: 0);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(CupertinoIcons.chart_bar, size: 17),
                        tooltip: 'Statistics',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          HabitDetailScreen.open(context, habit: habit, initialTab: 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: 'More Options',
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _showActionMenu(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
