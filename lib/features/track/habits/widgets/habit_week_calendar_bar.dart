import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';

/// Minimal, Cupertino-inspired Expandable Calendar for Life OS Habits.
/// - Collapsed: Shows the snappy 7-day week bar (Mon - Sun).
/// - Expanded: Expands in-place into the full month calendar.
/// - Inherits page background (pitch charcoal #09090B).
class HabitWeekCalendarBar extends ConsumerStatefulWidget {
  const HabitWeekCalendarBar({super.key});

  @override
  ConsumerState<HabitWeekCalendarBar> createState() => _HabitWeekCalendarBarState();
}

class _HabitWeekCalendarBarState extends ConsumerState<HabitWeekCalendarBar> {
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
    ref.read(habitCalendarExpandedProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedHabitDateProvider);
    final isExpanded = ref.watch(habitCalendarExpandedProvider);

    ref.listen<DateTime>(selectedHabitDateProvider, (prev, next) {
      if (prev != next) {
        _syncWithDate(next);
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth = _displayedMonth.year == today.year && _displayedMonth.month == today.month;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Month Name + Arrow button to toggle expand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrentMonth)
                    TextButton(
                      onPressed: () {
                        ref.read(selectedHabitDateProvider.notifier).jumpToToday();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.calendar,
                      size: 18,
                      color: isExpanded ? Theme.of(context).colorScheme.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    tooltip: isExpanded ? 'Collapse to week' : 'Expand to month',
                    visualDensity: VisualDensity.compact,
                    onPressed: _toggleExpanded,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Weekday Labels Header: Mon, Tue, Wed, Thu, Fri, Sat, Sun
          Row(
            children: List.generate(7, (index) {
              final sampleDay = _anchorMonday.add(Duration(days: index));
              final dayLetter = DateFormat('E').format(sampleDay).substring(0, 1);
              final isWeekend = index >= 5;

              return Expanded(
                child: Center(
                  child: Text(
                    dayLetter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? (isDark ? const Color(0xFF71717A) : const Color(0xFF8E8E93))
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),

          // Animated Body: 1 week (collapsed) vs Full Month (expanded)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildCollapsedWeekView(selectedDate, today, isDark),
            secondChild: _buildExpandedMonthView(selectedDate, today, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedWeekView(DateTime selectedDate, DateTime today, bool isDark) {
    return SizedBox(
      height: 48,
      child: PageView.builder(
        controller: _weekPageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (page) {
          final monday = _mondayForWeekPage(page);
          if (monday.month != _displayedMonth.month || monday.year != _displayedMonth.year) {
            setState(() {
              _displayedMonth = DateTime(monday.year, monday.month, 1);
            });
          }
        },
        itemBuilder: (context, page) {
          final monday = _mondayForWeekPage(page);
          final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

          return Row(
            children: weekDays.map((day) {
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

              return Expanded(
                child: _buildDayCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  isDark: isDark,
                  onTap: () {
                    ref.read(selectedHabitDateProvider.notifier).setDate(day);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildExpandedMonthView(DateTime selectedDate, DateTime today, bool isDark) {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _monthPageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (page) {
          final month = _monthForMonthPage(page);
          setState(() {
            _displayedMonth = month;
          });
        },
        itemBuilder: (context, page) {
          final monthDate = _monthForMonthPage(page);
          final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
          final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
          final startWeekdayOffset = firstDayOfMonth.weekday - 1;

          final totalCells = ((startWeekdayOffset + daysInMonth + 6) ~/ 7) * 7;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
              childAspectRatio: 1.15,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - startWeekdayOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(monthDate.year, monthDate.month, dayNumber);
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              return _buildDayCell(
                day: cellDate,
                isSelected: isSelected,
                isToday: isToday,
                isDark: isDark,
                onTap: () {
                  ref.read(selectedHabitDateProvider.notifier).setDate(cellDate);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Color textColor;
    Color? cellBg;
    Border? cellBorder;

    final primary = Theme.of(context).colorScheme.primary;

    if (isSelected) {
      cellBg = primary;
      textColor = Colors.white;
    } else if (isToday) {
      textColor = primary;
      cellBorder = Border.all(color: primary.withValues(alpha: 0.6), width: 1.2);
    } else {
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: BorderRadius.circular(10),
            border: cellBorder,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
