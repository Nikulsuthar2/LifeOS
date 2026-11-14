import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';
import 'create_task_sheet.dart';

/// Google Calendar style calendar view for Tasks.
/// Supports 4 modes:
/// 1. Day View: Hourly time slots, all-day banner, duration-scaled task blocks
/// 2. Week View: 7-day multi-column time grid
/// 3. Month View: 7x5 month grid with colored task pills
/// 4. Schedule View: Chronological agenda timeline feed
class TaskCalendarView extends ConsumerWidget {
  const TaskCalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(calendarViewTypeProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);
    final selectedDate = ref.watch(selectedTaskDateProvider);

    return Column(
      children: [
        // 1. Calendar View Mode Selector (Day | Week | Month | Schedule)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              _ViewTypeChip(
                label: 'Day',
                isSelected: viewType == CalendarViewType.day,
                onTap: () => ref.read(calendarViewTypeProvider.notifier).setType(CalendarViewType.day),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ViewTypeChip(
                label: 'Week',
                isSelected: viewType == CalendarViewType.week,
                onTap: () => ref.read(calendarViewTypeProvider.notifier).setType(CalendarViewType.week),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ViewTypeChip(
                label: 'Month',
                isSelected: viewType == CalendarViewType.month,
                onTap: () => ref.read(calendarViewTypeProvider.notifier).setType(CalendarViewType.month),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ViewTypeChip(
                label: 'Schedule',
                isSelected: viewType == CalendarViewType.schedule,
                onTap: () => ref.read(calendarViewTypeProvider.notifier).setType(CalendarViewType.schedule),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 2. Active Calendar View Sub-screen
        Expanded(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, stack) => Center(child: Text('Error loading calendar: $err')),
            data: (tasks) {
              switch (viewType) {
                case CalendarViewType.day:
                  return _CalendarDayView(selectedDate: selectedDate, tasks: tasks);
                case CalendarViewType.week:
                  return _CalendarWeekView(selectedDate: selectedDate, tasks: tasks);
                case CalendarViewType.month:
                  return _CalendarMonthView(selectedDate: selectedDate, tasks: tasks);
                case CalendarViewType.schedule:
                  return _CalendarScheduleView(selectedDate: selectedDate, tasks: tasks);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ViewTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withValues(alpha: 0.4)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryLight
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// A. DAY VIEW (Hourly grid with All-Day banner & time positioning)
// -------------------------------------------------------------
class _CalendarDayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarDayView({
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Filter tasks for this day
    final dayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(t.dueDate!) == dateStr;
    }).toList();

    final allDayTasks = dayTasks.where((t) => t.isAllDay).toList();
    final timedTasks = dayTasks.where((t) => !t.isAllDay).toList();

    const hourHeight = 60.0;
    const startHour = 6; // 06:00
    const endHour = 23; // 23:00
    final totalHours = endHour - startHour + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // All-Day Banner
          if (allDayTasks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALL DAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allDayTasks.map((task) {
                      return InkWell(
                        onTap: () => TaskDetailSheet.show(context, task),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Hourly Timeline Stack
          SizedBox(
            height: totalHours * hourHeight,
            child: Stack(
              children: [
                // 1. Hour grid rows
                ...List.generate(totalHours, (index) {
                  final hour = startHour + index;
                  final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

                  return Positioned(
                    top: index * hourHeight,
                    left: 0,
                    right: 0,
                    height: hourHeight,
                    child: InkWell(
                      onTap: () {
                        CreateTaskSheet.show(
                          context,
                          initialDate: selectedDate,
                          initialTime: timeLabel,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              padding: const EdgeInsets.only(top: 4, right: 8),
                              alignment: Alignment.topRight,
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // 2. Timed Task Cards
                ...timedTasks.map((task) {
                  int hour = 9;
                  int minute = 0;
                  if (task.scheduledTime != null && task.scheduledTime!.contains(':')) {
                    final parts = task.scheduledTime!.split(':');
                    hour = int.tryParse(parts[0]) ?? 9;
                    minute = int.tryParse(parts[1]) ?? 0;
                  }

                  if (hour < startHour || hour > endHour) {
                    hour = hour.clamp(startHour, endHour);
                  }

                  final minutesFromStart = (hour - startHour) * 60 + minute;
                  final topOffset = (minutesFromStart / 60.0) * hourHeight;
                  final durationMinutes = task.estimateMinutes.clamp(20, 180);
                  final cardHeight = ((durationMinutes / 60.0) * hourHeight).clamp(42.0, 180.0);

                  Color cardAccent;
                  switch (task.priority) {
                    case TaskPriority.urgent:
                      cardAccent = AppColors.urgent;
                      break;
                    case TaskPriority.high:
                      cardAccent = AppColors.high;
                      break;
                    case TaskPriority.medium:
                      cardAccent = AppColors.primary;
                      break;
                    case TaskPriority.low:
                      cardAccent = AppColors.low;
                      break;
                  }

                  return Positioned(
                    top: topOffset,
                    left: 62,
                    right: 14,
                    height: cardHeight,
                    child: GestureDetector(
                      onTap: () => TaskDetailSheet.show(context, task),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardAccent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: cardAccent, width: 3.5),
                            top: BorderSide(color: cardAccent.withValues(alpha: 0.3)),
                            right: BorderSide(color: cardAccent.withValues(alpha: 0.3)),
                            bottom: BorderSide(color: cardAccent.withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (cardHeight > 50) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${task.scheduledTime ?? "Anytime"} · ${task.estimateMinutes}m',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// B. WEEK VIEW (7 columns, Monday to Sunday multi-day overview)
// -------------------------------------------------------------
class _CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarWeekView({
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Weekday Column Headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Row(
            children: weekDays.map((day) {
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.primaryLight : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // 7-day Multi-column tasks list
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weekDays.map((day) {
              final dayStr = DateFormat('yyyy-MM-dd').format(day);
              final dayTasks = tasks.where((t) {
                if (t.dueDate == null) return false;
                return DateFormat('yyyy-MM-dd').format(t.dueDate!) == dayStr;
              }).toList();

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    itemCount: dayTasks.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == dayTasks.length) {
                        // Tap to add task to this day
                        return InkWell(
                          onTap: () => CreateTaskSheet.show(context, initialDate: day),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        );
                      }
                      final task = dayTasks[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => TaskDetailSheet.show(context, task),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.scheduledTime ?? (task.isAllDay ? 'All Day' : 'Task'),
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// C. MONTH VIEW (Full 7x5 month grid with colored task badges)
// -------------------------------------------------------------
class _CalendarMonthView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarMonthView({
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday ... 7 = Sunday

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Weekday header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((w) {
              return Text(
                w,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              );
            }).toList(),
          ),
        ),

        // Grid of Days
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: (startingWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                return const SizedBox.shrink();
              }
              final dayNum = index - (startingWeekday - 1) + 1;
              final cellDate = DateTime(selectedDate.year, selectedDate.month, dayNum);
              final cellStr = DateFormat('yyyy-MM-dd').format(cellDate);

              final dayTasks = tasks.where((t) {
                if (t.dueDate == null) return false;
                return DateFormat('yyyy-MM-dd').format(t.dueDate!) == cellStr;
              }).toList();

              final isToday = cellDate.year == today.year && cellDate.month == today.month && cellDate.day == today.day;
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              return InkWell(
                onTap: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(cellDate);
                  ref.read(calendarViewTypeProvider.notifier).setType(CalendarViewType.day);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primaryLight
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                      width: isToday ? 1.2 : 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isToday ? AppColors.primaryLight : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: dayTasks.take(3).map((t) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (dayTasks.length > 3)
                        Text(
                          '+${dayTasks.length - 3}',
                          style: const TextStyle(fontSize: 8, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// D. SCHEDULE VIEW (Continuous vertical chronological agenda feed)
// -------------------------------------------------------------
class _CalendarScheduleView extends StatelessWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarScheduleView({
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group tasks by date string
    final Map<String, List<TaskItem>> grouped = {};
    for (final t in tasks) {
      if (t.dueDate != null) {
        final key = DateFormat('yyyy-MM-dd').format(t.dueDate!);
        grouped.putIfAbsent(key, () => []).add(t);
      }
    }

    final sortedDates = grouped.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            const SizedBox(height: AppSpacing.sm),
            const Text('No scheduled tasks in this period', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Add tasks with due dates to view your agenda.',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
      itemCount: sortedDates.length,
      itemBuilder: (context, idx) {
        final dateKey = sortedDates[idx];
        final dateTasks = grouped[dateKey]!;
        final parsedDate = DateTime.parse(dateKey);

        final now = DateTime.now();
        final isToday = parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${parsedDate.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isToday ? AppColors.primaryLight : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'Today · ${DateFormat('EEEE').format(parsedDate)}' : DateFormat('EEEE, MMM d').format(parsedDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isToday ? AppColors.primaryLight : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      Text(
                        '${dateTasks.length} task${dateTasks.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tasks for this date
            ...dateTasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 8),
                child: InkWell(
                  onTap: () => TaskDetailSheet.show(context, task),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        // Scheduled time or All-day pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.isAllDay ? 'All Day' : (task.scheduledTime ?? 'Anytime'),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                  : null,
                            ),
                          ),
                        ),
                        if (task.estimateMinutes > 0 && !task.isAllDay) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${task.estimateMinutes}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}
