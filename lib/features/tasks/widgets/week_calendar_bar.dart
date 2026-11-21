import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';

/// Minimal, Material 3 Expressive Expandable Calendar for Life OS Tasks.
/// - Collapsed (normal): Shows the snappy 7-day week bar (Mon - Sun).
/// - Expanded: Seamlessly expands in the exact same component into the full month calendar.
/// - Mon - Sun columns stay pixel-aligned with smooth squircle day cells.
/// - Inherits page background (transparent, zero separate card boxes).
class WeekCalendarBar extends ConsumerStatefulWidget {
  const WeekCalendarBar({super.key});

  @override
  ConsumerState<WeekCalendarBar> createState() => _WeekCalendarBarState();
}

class _WeekCalendarBarState extends ConsumerState<WeekCalendarBar> {
  static const int _basePage = 5000;
  late final DateTime _anchorMonday;
  late final DateTime _anchorMonth;
  late final PageController _weekPageController;
  late final PageController _monthPageController;

  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of reference week
    _anchorMonday = today.subtract(Duration(days: today.weekday - 1));
    _anchorMonth = DateTime(now.year, now.month, 1);
    _displayedMonth = DateTime(now.year, now.month, 1);

    _weekPageController = PageController(initialPage: _basePage);
    _monthPageController = PageController(initialPage: _basePage);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }

  int _pageForWeek(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day).subtract(
      Duration(days: date.weekday - 1),
    );
    final diffDays = monday.difference(_anchorMonday).inDays;
    return _basePage + (diffDays / 7).round();
  }

  DateTime _mondayForWeekPage(int page) {
    final weekOffset = page - _basePage;
    return _anchorMonday.add(Duration(days: weekOffset * 7));
  }

  int _pageForMonth(DateTime date) {
    final monthsDiff = (date.year - _anchorMonth.year) * 12 + (date.month - _anchorMonth.month);
    return _basePage + monthsDiff;
  }

  DateTime _monthForMonthPage(int page) {
    final monthOffset = page - _basePage;
    return DateTime(_anchorMonth.year, _anchorMonth.month + monthOffset, 1);
  }

  void _syncWithDate(DateTime date) {
    final targetWeekPage = _pageForWeek(date);
    if (_weekPageController.hasClients && _weekPageController.page?.round() != targetWeekPage) {
      _weekPageController.animateToPage(
        targetWeekPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    final targetMonthPage = _pageForMonth(date);
    if (_monthPageController.hasClients && _monthPageController.page?.round() != targetMonthPage) {
      _monthPageController.animateToPage(
        targetMonthPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {
      _displayedMonth = DateTime(date.year, date.month, 1);
    });
  }

  void _toggleExpanded() {
    ref.read(weekCalendarExpandedProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isExpanded = ref.watch(weekCalendarExpandedProvider);
    final selectedDate = ref.watch(selectedTaskDateProvider);
    final weekTaskDatesAsync = ref.watch(weekTaskDatesProvider);
    final dateNotifier = ref.read(selectedTaskDateProvider.notifier);

    // Sync controllers if selected date was changed externally
    ref.listen<DateTime>(selectedTaskDateProvider, (prev, next) {
      _syncWithDate(next);
    });

    // Sync controllers if expanded state changed (either via tap or pull-down gesture)
    ref.listen<bool>(weekCalendarExpandedProvider, (prev, nextExpanded) {
      final curDate = ref.read(selectedTaskDateProvider);
      if (nextExpanded) {
        setState(() {
          _displayedMonth = DateTime(curDate.year, curDate.month, 1);
        });
        final targetMonthPage = _pageForMonth(curDate);
        if (_monthPageController.hasClients) {
          _monthPageController.jumpToPage(targetMonthPage);
        }
      } else {
        final targetWeekPage = _pageForWeek(curDate);
        if (_weekPageController.hasClients) {
          _weekPageController.jumpToPage(targetWeekPage);
        }
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final titleDate = _displayedMonth;
    final monthYearTitle = DateFormat('MMMM yyyy').format(titleDate);
    final taskDates = weekTaskDatesAsync.value ?? <String>{};

    return Container(
      color: Colors.transparent, // Seamlessly inherits page background
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Month / Year title with dropdown arrow + Today pill + Chevrons when expanded
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthYearTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month navigation chevrons when in expanded mode
                  if (isExpanded) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous Month',
                      onPressed: () {
                        if (_monthPageController.hasClients) {
                          _monthPageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next Month',
                      onPressed: () {
                        if (_monthPageController.hasClients) {
                          _monthPageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                    ),
                  ],

                  if (!isToday) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        dateNotifier.jumpToToday();
                        _syncWithDate(today);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Fixed 7-Column Weekday Header Bar (MON, TUE, WED, THU, FRI, SAT, SUN)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Row(
              children: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((dayName) {
                return Expanded(
                  child: Center(
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Calendar Days Area: Animated expansion between 1 Week (48px) and Full Month (260px)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildWeekView(today, selectedDate, taskDates, dateNotifier),
            secondChild: _buildMonthView(today, selectedDate, taskDates, dateNotifier),
          ),

          // 4. Subtle Hairline Drag / Tap Handle
          GestureDetector(
            onTap: _toggleExpanded,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null) {
                if (details.primaryDelta! < -4 && isExpanded) {
                  ref.read(weekCalendarExpandedProvider.notifier).setExpanded(false);
                } else if (details.primaryDelta! > 4 && !isExpanded) {
                  ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                }
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Collapsed 1-Week PageView (snaps 7 days Mon-Sun per swipe) ---
  Widget _buildWeekView(
    DateTime today,
    DateTime selectedDate,
    Set<String> taskDates,
    SelectedTaskDateNotifier dateNotifier,
  ) {
    return SizedBox(
      height: 48,
      child: PageView.builder(
        controller: _weekPageController,
        pageSnapping: true,
        onPageChanged: (pageIndex) {
          final pageMonday = _mondayForWeekPage(pageIndex);
          final midWeek = pageMonday.add(const Duration(days: 3));
          setState(() {
            _displayedMonth = DateTime(midWeek.year, midWeek.month, 1);
          });
        },
        itemBuilder: (context, pageIndex) {
          final pageMonday = _mondayForWeekPage(pageIndex);
          final days = List.generate(7, (i) => pageMonday.add(Duration(days: i)));

          return Row(
            children: days.map((day) {
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isDayToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final dayKey = DateFormat('yyyy-MM-dd').format(day);
              final hasTasks = taskDates.contains(dayKey);

              return _DayCell(
                day: day,
                isSelected: isSelected,
                isToday: isDayToday,
                isCurrentMonth: true,
                hasTasks: hasTasks,
                onTap: () {
                  dateNotifier.setDate(day);
                  setState(() {
                    _displayedMonth = DateTime(day.year, day.month, 1);
                  });
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // --- Expanded Full Month PageView (snaps month per swipe, rows of 7 days) ---
  Widget _buildMonthView(
    DateTime today,
    DateTime selectedDate,
    Set<String> taskDates,
    SelectedTaskDateNotifier dateNotifier,
  ) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _monthPageController,
        pageSnapping: true,
        onPageChanged: (pageIndex) {
          final month = _monthForMonthPage(pageIndex);
          setState(() => _displayedMonth = month);
        },
        itemBuilder: (context, pageIndex) {
          final monthFirst = _monthForMonthPage(pageIndex);
          final weekdayOfFirst = monthFirst.weekday; // 1 = Mon ... 7 = Sun
          final firstMonday = monthFirst.subtract(Duration(days: weekdayOfFirst - 1));
          final daysInMonth = DateTime(monthFirst.year, monthFirst.month + 1, 0).day;
          final totalDays = (weekdayOfFirst - 1) + daysInMonth;
          final totalWeeks = (totalDays / 7.0).ceil();

          return Column(
            children: List.generate(totalWeeks, (weekIdx) {
              final weekStart = firstMonday.add(Duration(days: weekIdx * 7));
              final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: days.map((day) {
                      final isSelected = day.year == selectedDate.year &&
                          day.month == selectedDate.month &&
                          day.day == selectedDate.day;
                      final isDayToday = day.year == today.year &&
                          day.month == today.month &&
                          day.day == today.day;
                      final isCurrentMonth = day.month == monthFirst.month;
                      final dayKey = DateFormat('yyyy-MM-dd').format(day);
                      final hasTasks = taskDates.contains(dayKey);

                      return _DayCell(
                        day: day,
                        isSelected: isSelected,
                        isToday: isDayToday,
                        isCurrentMonth: isCurrentMonth,
                        hasTasks: hasTasks,
                        onTap: () {
                          dateNotifier.setDate(day);
                          _syncWithDate(day);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Unified, minimal Material 3 Expressive day cell for both Week Bar (collapsed) and Month Calendar (expanded).
class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;
  final bool hasTasks;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isCurrentMonth,
    required this.hasTasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onSelectedColor = ThemeData.estimateBrightnessForColor(primary) == Brightness.light
        ? const Color(0xFF141416)
        : Colors.white;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary
                    : (isToday
                        ? (isDark ? const Color(0xFF1C1C20) : const Color(0xFFEBEBF0))
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isToday
                          ? primary.withValues(alpha: 0.45)
                          : Colors.transparent),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w800
                          : (isCurrentMonth ? FontWeight.w600 : FontWeight.w400),
                      color: isSelected
                          ? onSelectedColor
                          : (isToday
                              ? primary
                              : (!isCurrentMonth
                                  ? (isDark
                                      ? AppColors.darkTextMuted.withValues(alpha: 0.35)
                                      : AppColors.lightTextMuted.withValues(alpha: 0.35))
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary))),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Task dot indicator
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasTasks
                          ? (isSelected ? onSelectedColor : primary)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
