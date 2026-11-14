import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';

/// Snappy, typography-led 7-day week calendar bar for Life OS.
/// - Snaps 1 full week (Mon - Sun) per swipe using PageView
/// - Inherits page background (zero card container separation)
/// - Dropdown down arrow next to Month/Year opens a full-month quick navigator
/// - Subtle 'Today' indicator when away from current date
class WeekCalendarBar extends ConsumerStatefulWidget {
  const WeekCalendarBar({super.key});

  @override
  ConsumerState<WeekCalendarBar> createState() => _WeekCalendarBarState();
}

class _WeekCalendarBarState extends ConsumerState<WeekCalendarBar> {
  static const int _basePage = 5000;
  late final DateTime _anchorMonday;
  late final PageController _pageController;
  bool _isMonthExpanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Monday of the reference week
    _anchorMonday = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    _pageController = PageController(initialPage: _basePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageForDate(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day).subtract(
      Duration(days: date.weekday - 1),
    );
    final diffDays = monday.difference(_anchorMonday).inDays;
    return _basePage + (diffDays / 7).round();
  }

  DateTime _mondayForPage(int page) {
    final weekOffset = page - _basePage;
    return _anchorMonday.add(Duration(days: weekOffset * 7));
  }

  void _syncPageWithDate(DateTime date) {
    final targetPage = _pageForDate(date);
    if (_pageController.hasClients && _pageController.page?.round() != targetPage) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedTaskDateProvider);
    final weekTaskDatesAsync = ref.watch(weekTaskDatesProvider);
    final dateNotifier = ref.read(selectedTaskDateProvider.notifier);

    // Sync page if date changed outside this widget
    ref.listen<DateTime>(selectedTaskDateProvider, (prev, next) {
      _syncPageWithDate(next);
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final monthYearTitle = DateFormat('MMMM yyyy').format(selectedDate);
    final taskDates = weekTaskDatesAsync.value ?? <String>{};

    return Container(
      color: Colors.transparent, // Seamlessly inherits page background
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Month / Year title with dropdown arrow + Today pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _isMonthExpanded = !_isMonthExpanded);
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        _isMonthExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isToday)
                GestureDetector(
                  onTap: () {
                    dateNotifier.jumpToToday();
                    _syncPageWithDate(today);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 2. Full Month Collapsible Grid (opened via down arrow)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _isMonthExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _MonthGridPicker(
              selectedDate: selectedDate,
              onSelectDate: (pickedDate) {
                dateNotifier.setDate(pickedDate);
                _syncPageWithDate(pickedDate);
                setState(() => _isMonthExpanded = false);
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 3. Snappy 7-Day PageView (snaps week by week: Monday to Sunday)
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _pageController,
              pageSnapping: true,
              onPageChanged: (pageIndex) {
                final pageMonday = _mondayForPage(pageIndex);
                final currentWeekday = selectedDate.weekday; // 1 = Mon ... 7 = Sun
                final newSelectedDate = pageMonday.add(Duration(days: currentWeekday - 1));
                dateNotifier.setDate(newSelectedDate);
              },
              itemBuilder: (context, pageIndex) {
                final pageMonday = _mondayForPage(pageIndex);
                final days = List.generate(7, (i) => pageMonday.add(Duration(days: i)));

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: days.map((day) {
                    final isSelected = day.year == selectedDate.year &&
                        day.month == selectedDate.month &&
                        day.day == selectedDate.day;
                    final isDayToday = day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day;
                    final dayKey = DateFormat('yyyy-MM-dd').format(day);
                    final hasTasks = taskDates.contains(dayKey);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              dateNotifier.setDate(day);
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: AnimatedContainer(
                              duration: AppDurations.fast,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDayToday
                                        ? (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDayToday
                                          ? AppColors.primary.withValues(alpha: 0.35)
                                          : Colors.transparent),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(day).substring(0, 3).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected || isDayToday ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDayToday
                                              ? AppColors.primaryLight
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Task dot indicator
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasTasks
                                          ? (isSelected ? Colors.white : AppColors.primaryLight)
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
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inline month calendar view displayed when expanding the month dropdown.
class _MonthGridPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthGridPicker({
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  State<_MonthGridPicker> createState() => _MonthGridPickerState();
}

class _MonthGridPickerState extends State<_MonthGridPicker> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // 1 = Monday ... 7 = Sunday
    final startingWeekday = firstDayOfMonth.weekday;

    final prevMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    final nextMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() => _displayedMonth = prevMonth);
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_displayedMonth),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() => _displayedMonth = nextMonth);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Weekday initials (Mon to Sun)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((letter) {
              return SizedBox(
                width: 32,
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (startingWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - (startingWeekday - 1) + 1;
              final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
              final isSelected = cellDate.year == widget.selectedDate.year &&
                  cellDate.month == widget.selectedDate.month &&
                  cellDate.day == widget.selectedDate.day;
              final isCellToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              return InkWell(
                onTap: () => widget.onSelectDate(cellDate),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: isCellToday && !isSelected
                        ? Border.all(color: AppColors.primaryLight, width: 1)
                        : null,
                  ),
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected || isCellToday ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
