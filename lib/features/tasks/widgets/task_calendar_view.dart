import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';
import '../screens/create_task_screen.dart';
import 'task_view_sheet.dart';

/// Google Calendar style calendar view for Tasks.
/// Supports 4 modes:
/// 1. Day View: Hourly time slots, Day Navigator, all-day banner, duration-scaled task blocks
/// 2. Week View: Week Navigator, 7-day multi-column time grid with vertical time axis and all-day header
/// 3. Month View: Month Navigator, stretched to full screen height with colored task badges
/// 4. Schedule View: Chronological agenda timeline feed with recurrence support
class TaskCalendarView extends ConsumerWidget {
  const TaskCalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewType = ref.watch(calendarViewTypeProvider);
    final tasksAsync = ref.watch(calendarTasksProvider);
    final selectedDate = ref.watch(selectedTaskDateProvider);

    return Column(
      children: [
        // 1. Sleek Cupertino Sliding Segmented Control (Day | Week | Month | Schedule)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<CalendarViewType>(
              groupValue: viewType,
              backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFE5E5EA),
              thumbColor: isDark ? const Color(0xFF27272A) : Colors.white,
              children: const {
                CalendarViewType.day: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                CalendarViewType.week: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                CalendarViewType.month: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                CalendarViewType.schedule: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              },
              onValueChanged: (val) {
                if (val != null) ref.read(calendarViewTypeProvider.notifier).setType(val);
              },
            ),
          ),
        ),

        Divider(
          height: 1,
          thickness: 0.6,
          color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
        ),

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

// -------------------------------------------------------------
// A. DAY VIEW (Day Navigator + Hourly grid with All-Day banner)
// -------------------------------------------------------------
class _CalendarDayView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarDayView({
    required this.selectedDate,
    required this.tasks,
  });

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFF8F8FA),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(selectedDate.subtract(const Duration(days: 1)));
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      ref.read(selectedTaskDateProvider.notifier).setDate(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 12),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_right, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(selectedDate.add(const Duration(days: 1)));
                },
              ),
              if (!_isToday(selectedDate))
                TextButton(
                  onPressed: () => ref.read(selectedTaskDateProvider.notifier).jumpToToday(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primaryLight,
                  ),
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
            ],
          ),
        ),

        // Hourly timeline scroll view
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // All-Day Banner
                if (allDayTasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141416) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
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
                              onTap: () => TaskViewSheet.show(context, task),
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
                                    color: isDark ? Colors.white : Colors.black87,
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
                              CreateTaskScreen.open(
                                context,
                                initialDate: selectedDate,
                                initialTime: timeLabel,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: (isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA)).withValues(alpha: 0.6),
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
                        final cardHeight = ((durationMinutes / 60.0) * hourHeight).clamp(46.0, 180.0);

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
                            onTap: () => TaskViewSheet.show(context, task),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: cardAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(color: cardAccent, width: 3.5),
                                  top: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                  right: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                  bottom: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${task.scheduledTime ?? "Anytime"} · ${task.estimateMinutes}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
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
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// B. WEEK VIEW (Week Navigator + Vertical Time axis + 7 columns)
// -------------------------------------------------------------
class _CalendarWeekView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TaskItem> tasks;

  const _CalendarWeekView({
    required this.selectedDate,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const hourHeight = 56.0;
    const startHour = 7; // 07:00
    const endHour = 22; // 22:00
    final totalHours = endHour - startHour + 1;

    // Separate all-day tasks
    final allDayWeekTasks = tasks.where((t) => t.isAllDay).toList();

    return Column(
      children: [
        // 1. Week Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFF8F8FA),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(selectedDate.subtract(const Duration(days: 7)));
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_right, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(selectedDate.add(const Duration(days: 7)));
                },
              ),
            ],
          ),
        ),

        // 2. Weekday Column Headers (with 46px time axis spacer)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA), width: 0.8)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 46), // time gutter indent
              ...weekDays.map((day) {
                final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                final isSelected = day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedTaskDateProvider.notifier).setDate(day);
                    },
                    borderRadius: BorderRadius.circular(6),
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
                            color: isToday
                                ? AppColors.primary
                                : (isSelected ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // 3. All-Day Section across the 7 columns (if any all-day tasks)
        if (allDayWeekTasks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF2F2F7),
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA))),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  padding: const EdgeInsets.only(right: 6),
                  alignment: Alignment.centerRight,
                  child: const Text('ALL DAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                ),
                ...weekDays.map((day) {
                  final dayStr = DateFormat('yyyy-MM-dd').format(day);
                  final dayAllDay = allDayWeekTasks.where((t) {
                    if (t.dueDate == null) return false;
                    return DateFormat('yyyy-MM-dd').format(t.dueDate!) == dayStr;
                  }).toList();

                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: dayAllDay.map((t) {
                          return GestureDetector(
                            onTap: () => TaskViewSheet.show(context, t),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // 4. Vertical Time Grid Body: Time on left, 7 vertical columns on right
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: SizedBox(
              height: totalHours * hourHeight,
              child: Stack(
                children: [
                  // Hour dividing lines and vertical time labels on left
                  ...List.generate(totalHours, (index) {
                    final hour = startHour + index;
                    final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

                    return Positioned(
                      top: index * hourHeight,
                      left: 0,
                      right: 0,
                      height: hourHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: (isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA)).withValues(alpha: 0.5),
                              width: 0.7,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              padding: const EdgeInsets.only(top: 2, right: 6),
                              alignment: Alignment.topRight,
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    );
                  }),

                  // 7 vertical day columns with tasks
                  Positioned.fill(
                    left: 46,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: weekDays.map((day) {
                        final dayStr = DateFormat('yyyy-MM-dd').format(day);
                        final dayTimed = tasks.where((t) {
                          if (t.isAllDay || t.dueDate == null) return false;
                          return DateFormat('yyyy-MM-dd').format(t.dueDate!) == dayStr;
                        }).toList();

                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: (isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA)).withValues(alpha: 0.35),
                                  width: 0.7,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Tap empty area to add task
                                Positioned.fill(
                                  child: InkWell(
                                    onTap: () {
                                      CreateTaskScreen.open(context, initialDate: day);
                                    },
                                  ),
                                ),

                                // Timed task cards placed in slots
                                ...dayTimed.map((task) {
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
                                  final durationMinutes = task.estimateMinutes.clamp(15, 120);
                                  final cardHeight = ((durationMinutes / 60.0) * hourHeight).clamp(34.0, 120.0);

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
                                    left: 1.5,
                                    right: 1.5,
                                    height: cardHeight,
                                    child: GestureDetector(
                                      onTap: () => TaskViewSheet.show(context, task),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cardAccent.withValues(alpha: isDark ? 0.30 : 0.18),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border(
                                            left: BorderSide(color: cardAccent, width: 3),
                                            top: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                            right: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                            bottom: BorderSide(color: cardAccent.withValues(alpha: 0.35)),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              task.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                height: 1.15,
                                                fontWeight: FontWeight.w700,
                                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// C. MONTH VIEW (Month Navigator + Proportional stretch to bottom)
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
    final totalCells = (startingWeekday - 1) + daysInMonth;
    final totalRows = (totalCells / 7.0).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // 1. Month Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFF8F8FA),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(
                    DateTime(selectedDate.year, selectedDate.month - 1, 1),
                  );
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_right, size: 18),
                onPressed: () {
                  ref.read(selectedTaskDateProvider.notifier).setDate(
                    DateTime(selectedDate.year, selectedDate.month + 1, 1),
                  );
                },
              ),
            ],
          ),
        ),

        // 2. Weekday Header (Mon - Sun)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? const Color(0xFF161618) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((w) {
              return Text(
                w,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              );
            }).toList(),
          ),
        ),

        // 3. Grid of Days (Stretches to fill full screen height down to bottom navbar)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = (constraints.maxHeight / totalRows).clamp(55.0, 180.0);
              final cellWidth = constraints.maxWidth / 7.0;
              final childAspectRatio = cellWidth / cellHeight;

              return GridView.builder(
                padding: const EdgeInsets.all(3),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalRows * 7,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  if (index < startingWeekday - 1 || index >= totalCells) {
                    return Container(
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7)).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
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
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7)),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primaryLight
                              : (isDark ? const Color(0xFF26262B) : const Color(0xFFE5E5EA)),
                          width: isToday ? 1.4 : 0.6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
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
                                  margin: const EdgeInsets.only(bottom: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600),
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
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// D. SCHEDULE VIEW (Chronological agenda feed with recurring support)
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

    // Filter tasks having a dueDate and sort chronologically
    final scheduledTasks = tasks.where((t) => t.dueDate != null).toList()
      ..sort((a, b) {
        final dateComp = a.dueDate!.compareTo(b.dueDate!);
        if (dateComp != 0) return dateComp;
        if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
        if (a.scheduledTime != null && b.scheduledTime != null) {
          return a.scheduledTime!.compareTo(b.scheduledTime!);
        }
        return 0;
      });

    if (scheduledTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            const SizedBox(height: 12),
            Text(
              'No upcoming scheduled tasks',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Group tasks by Date string (yyyy-MM-dd)
    final Map<String, List<TaskItem>> grouped = {};
    for (final task in scheduledTasks) {
      final key = DateFormat('yyyy-MM-dd').format(task.dueDate!);
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final dateKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final key = dateKeys[index];
        final groupTasks = grouped[key]!;
        final firstDate = groupTasks.first.dueDate!;

        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Text(
                    isToday ? 'TODAY · ' : '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(firstDate).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: (isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA)),
                      thickness: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Tasks in this date
            ...groupTasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => TaskViewSheet.show(context, task),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141416) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222226) : const Color(0xFFE5E5EA),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Time Pill
                        Container(
                          width: 60,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            task.isAllDay ? 'All Day' : (task.scheduledTime ?? 'Anytime'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: task.isAllDay ? AppColors.primaryLight : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                        if (task.recurrence != 'none' && task.recurrence.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Icon(CupertinoIcons.repeat, size: 12, color: AppColors.primaryLight),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
