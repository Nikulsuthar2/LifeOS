import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit? habit;
  final int initialTab;
  final bool isNew;

  const HabitDetailScreen({
    super.key,
    this.habit,
    this.initialTab = 0,
    this.isNew = false,
  });

  static Future<void> open(
    BuildContext context, {
    Habit? habit,
    int initialTab = 0,
    bool isNew = false,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(
          habit: habit,
          initialTab: isNew ? 2 : initialTab,
          isNew: isNew,
        ),
      ),
    );
  }

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Habit _currentHabit;

  // Calendar tab state
  late DateTime _calendarMonth;

  // Stats tab state
  String _statsPeriod = 'week'; // 'week', 'month', 'year'

  // Edit / Create Form Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _selectedCategory;
  late String _selectedTimeOfDay;
  late String _selectedPriority;
  late String _selectedFrequency;
  late List<int> _selectedDaysOfWeek;
  late DateTime _selectedStartDate;
  late DateTime? _selectedEndDate;
  late bool _isForever;
  late int _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.isNew ? 2 : widget.initialTab.clamp(0, 2),
    );

    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month, 1);

    _currentHabit = widget.habit ??
        Habit(
          id: '',
          title: '',
          category: 'Health',
          frequency: 'daily',
          timeOfDay: 'morning',
          priority: 'medium',
          startDate: DateTime(now.year, now.month, now.day),
          color: HabitCategoryPresets.getCategory('Health').color,
          icon: 'bolt',
        );

    _titleController = TextEditingController(text: _currentHabit.title);
    _descController = TextEditingController(text: _currentHabit.description);
    _selectedCategory = _currentHabit.category;
    _selectedTimeOfDay = _currentHabit.timeOfDay;
    _selectedPriority = _currentHabit.priority;
    _selectedFrequency = _currentHabit.frequency;
    _selectedDaysOfWeek = List.from(_currentHabit.daysOfWeek);
    _selectedStartDate = _currentHabit.startDate;
    _selectedEndDate = _currentHabit.endDate;
    _isForever = _currentHabit.endDate == null;
    _selectedColor = _currentHabit.color;
    _selectedIcon = _currentHabit.icon;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onCategorySelected(HabitCategoryItem cat) {
    setState(() {
      _selectedCategory = cat.name;
      _selectedColor = cat.color;
      _selectedIcon = cat.id;
    });
  }

  Future<void> _showCustomCategoryDialog() async {
    final catNameController = TextEditingController();
    int chosenColor = 0xFF6366F1;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
              title: const Text('New Custom Category', style: TextStyle(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: catNameController,
                    decoration: const InputDecoration(hintText: 'e.g. Coding, Music, Cooking'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      0xFF10B981,
                      0xFF3B82F6,
                      0xFF8B5CF6,
                      0xFFEC4899,
                      0xFFF97316,
                      0xFFEAB308,
                      0xFF06B6D4,
                    ].map((c) {
                      final isSel = chosenColor == c;
                      return GestureDetector(
                        onTap: () => setDlgState(() => chosenColor = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = catNameController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(ctx, {'name': name, 'color': chosenColor});
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCategory = result['name'] as String;
        _selectedColor = result['color'] as int;
        _selectedIcon = 'bolt';
      });
    }
  }

  Future<void> _saveHabit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    final repo = ref.read(habitRepositoryProvider);

    final habitToSave = _currentHabit.copyWith(
      title: title,
      description: _descController.text.trim(),
      category: _selectedCategory,
      timeOfDay: _selectedTimeOfDay,
      priority: _selectedPriority,
      frequency: _selectedFrequency,
      daysOfWeek: _selectedDaysOfWeek,
      startDate: _selectedStartDate,
      endDate: _isForever ? null : _selectedEndDate,
      clearEndDate: _isForever,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    if (widget.isNew || _currentHabit.id.isEmpty) {
      await repo.insertHabit(habitToSave);
      ref.invalidate(habitsListProvider);
      ref.invalidate(todayHabitMetricsProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      await repo.updateHabit(habitToSave);
      setState(() {
        _currentHabit = habitToSave;
      });
      ref.invalidate(habitsListProvider);
      ref.invalidate(todayHabitMetricsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit settings saved')),
        );
      }
    }
  }

  Future<void> _confirmRestartProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
          title: const Text('Restart Habit Progress?'),
          content: const Text(
            'This will permanently reset all completion logs and set the start date to today. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.high),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restart Progress'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final repo = ref.read(habitRepositoryProvider);
      await repo.restartHabitProgress(_currentHabit.id);
      final updated = await repo.getHabitById(_currentHabit.id);
      if (updated != null) {
        setState(() {
          _currentHabit = updated;
          _selectedStartDate = updated.startDate;
        });
      }
      ref.invalidate(habitsListProvider);
      ref.invalidate(todayHabitMetricsProvider);
      ref.invalidate(habitMonthLogsProvider);
      ref.invalidate(habitDetailedStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress has been reset from today.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
          title: const Text('Delete Habit?'),
          content: const Text(
            'Are you sure you want to delete this habit and all its logged history? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete Habit'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final repo = ref.read(habitRepositoryProvider);
      await repo.deleteHabit(_currentHabit.id);
      ref.invalidate(habitsListProvider);
      ref.invalidate(todayHabitMetricsProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catItem = HabitCategoryPresets.getCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.isNew ? 'Create Habit' : _currentHabit.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        bottom: widget.isNew
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Color(_selectedColor),
                indicatorWeight: 3,
                labelColor: isDark ? Colors.white : Colors.black87,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'Calendar'),
                  Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Statistics'),
                  Tab(icon: Icon(Icons.edit_rounded, size: 20), text: 'Edit'),
                ],
              ),
      ),
      body: widget.isNew
          ? _buildEditTab(isDark, catItem)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTab(isDark),
                _buildStatisticsTab(isDark),
                _buildEditTab(isDark, catItem),
              ],
            ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: CALENDAR (Month Grid with 3 States & Month Streak)
  // -------------------------------------------------------------
  Widget _buildCalendarTab(bool isDark) {
    final query = HabitMonthQuery(
      habitId: _currentHabit.id,
      year: _calendarMonth.year,
      month: _calendarMonth.month,
    );

    final monthDataAsync = ref.watch(habitMonthLogsProvider(query));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month navigation bar: < Month Year >
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_calendarMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Calendar Grid Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                // Weekday Headers: Mon, Tue, Wed, Thu, Fri, Sat, Sun
                Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((letter) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Month Day Cells
                monthDataAsync.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 120,
                    child: Center(child: Text('Error loading month: $e')),
                  ),
                  data: (monthResult) {
                    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
                    final firstWeekday = DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday;
                    final startOffset = firstWeekday - 1;
                    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

                    final now = DateTime.now();
                    final todayStr = DateFormat('yyyy-MM-dd').format(now);
                    final startOnly = DateTime(_currentHabit.startDate.year, _currentHabit.startDate.month, _currentHabit.startDate.day);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: totalCells,
                      itemBuilder: (context, index) {
                        final dayNum = index - startOffset + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox.shrink();
                        }

                        final cellDate = DateTime(_calendarMonth.year, _calendarMonth.month, dayNum);
                        final dStr = DateFormat('yyyy-MM-dd').format(cellDate);
                        final isToday = dStr == todayStr;
                        final isBeforeStart = cellDate.isBefore(startOnly);
                        final isAfterEnd = _currentHabit.endDate != null && cellDate.isAfter(_currentHabit.endDate!);
                        final isFrequencyDay = _currentHabit.daysOfWeek.contains(cellDate.weekday);
                        final isFuture = cellDate.isAfter(DateTime(now.year, now.month, now.day));
                        final isEnabled = !isBeforeStart && !isAfterEnd && isFrequencyDay && !isFuture;

                        final status = monthResult.dayStatuses[dStr] ?? HabitDayStatus.pending;

                        return InkWell(
                          onTap: isEnabled
                              ? () async {
                                  final repo = ref.read(habitRepositoryProvider);
                                  await repo.cycleHabitDayStatus(_currentHabit.id, dStr);
                                  ref.invalidate(habitMonthLogsProvider(query));
                                  ref.invalidate(habitsListProvider);
                                  ref.invalidate(habitDetailedStatsProvider);
                                  ref.invalidate(todayHabitMetricsProvider);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isEnabled
                                  ? Colors.transparent
                                  : status == HabitDayStatus.done
                                      ? AppColors.success.withValues(alpha: 0.25)
                                      : status == HabitDayStatus.fail
                                          ? AppColors.error.withValues(alpha: 0.22)
                                          : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !isEnabled
                                    ? Colors.transparent
                                    : isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : status == HabitDayStatus.done
                                            ? AppColors.success
                                            : status == HabitDayStatus.fail
                                                ? AppColors.error
                                                : (isDark ? const Color(0xFF2C2C30) : const Color(0xFFE5E5EA)),
                                width: isToday ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: !isEnabled
                                ? Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D1D6),
                                    ),
                                  )
                                : status == HabitDayStatus.done
                                    ? const Icon(Icons.check, size: 16, color: AppColors.success)
                                    : status == HabitDayStatus.fail
                                        ? const Icon(Icons.close, size: 16, color: AppColors.error)
                                        : Text(
                                            '$dayNum',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                              color: isToday
                                                  ? Theme.of(context).colorScheme.primary
                                                  : (isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Highest Streak of this Month Banner
          monthDataAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (monthResult) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.high.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: AppColors.high, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Highest Streak in ${DateFormat('MMMM').format(_calendarMonth)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${monthResult.highestStreak} Days Streak',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendMetric('Done', '${monthResult.completedCount}', AppColors.success),
                        _buildLegendMetric('Failed', '${monthResult.failedCount}', AppColors.error),
                        _buildLegendMetric(
                          'Pending',
                          '${monthResult.pendingCount}',
                          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendMetric(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: STATISTICS (Overall Score, Streaks, Period Breakdown)
  // -------------------------------------------------------------
  Widget _buildStatisticsTab(bool isDark) {
    final query = HabitStatsQuery(
      habitId: _currentHabit.id,
      period: _statsPeriod,
    );
    final statsAsync = ref.watch(habitDetailedStatsProvider(query));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading stats: $e')),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Habit Score Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: stats.overallScorePercentage / 100.0,
                            strokeWidth: 6.5,
                            backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(_selectedColor)),
                          ),
                        ),
                        Text(
                          '${stats.overallScorePercentage}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Habit Score',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.timesCompletedAllTime} completed days out of ${stats.totalDaysTracked} active days',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Streaks: Current vs Best
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.high),
                              SizedBox(width: 6),
                              Text('Current Streak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${stats.currentStreak} Days',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              const Text('Best Streak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${stats.bestStreak} Days',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. Times Completed: This Week, Month, Year, All
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Times Completed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCompletedSlot('This Week', '${stats.timesCompletedThisWeek}', isDark),
                        _buildCompletedSlot('This Month', '${stats.timesCompletedThisMonth}', isDark),
                        _buildCompletedSlot('This Year', '${stats.timesCompletedThisYear}', isDark),
                        _buildCompletedSlot('All Time', '${stats.timesCompletedAllTime}', isDark),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Detailed Trend / History Chart with Period Switch (Week, Month, Year)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion Trend',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'week', label: Text('Week', style: TextStyle(fontSize: 11.5))),
                            ButtonSegment(value: 'month', label: Text('Month', style: TextStyle(fontSize: 11.5))),
                            ButtonSegment(value: 'year', label: Text('Year', style: TextStyle(fontSize: 11.5))),
                          ],
                          selected: {_statsPeriod},
                          onSelectionChanged: (set) {
                            setState(() => _statsPeriod = set.first);
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _statsPeriod == 'week'
                              ? 1.2
                              : (_statsPeriod == 'month' ? 7.0 : 31.0),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < stats.timeline.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        stats.timeline[idx].label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(stats.timeline.length, (i) {
                            final pt = stats.timeline[i];
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: pt.completed.toDouble(),
                                  color: Color(_selectedColor),
                                  width: _statsPeriod == 'week' ? 18 : (_statsPeriod == 'month' ? 22 : 12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. Success vs Fail Circular Ratio Chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success vs Failure Ratio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 28,
                              sections: [
                                PieChartSectionData(
                                  value: stats.timesCompletedAllTime > 0 ? stats.timesCompletedAllTime.toDouble() : 1.0,
                                  color: AppColors.success,
                                  radius: 20,
                                  showTitle: false,
                                ),
                                if (stats.totalFailedAllTime > 0)
                                  PieChartSectionData(
                                    value: stats.totalFailedAllTime.toDouble(),
                                    color: AppColors.error,
                                    radius: 20,
                                    showTitle: false,
                                  ),
                                if (stats.totalPendingAllTime > 0)
                                  PieChartSectionData(
                                    value: stats.totalPendingAllTime.toDouble(),
                                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
                                    radius: 20,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPieLegendRow('Completed', '${stats.timesCompletedAllTime}', AppColors.success),
                              const SizedBox(height: 8),
                              _buildPieLegendRow('Failed', '${stats.totalFailedAllTime}', AppColors.error),
                              const SizedBox(height: 8),
                              _buildPieLegendRow(
                                'Pending',
                                '${stats.totalPendingAllTime}',
                                isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedSlot(String label, String count, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendRow(String title, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: EDIT HABIT (Complete Settings Form)
  // -------------------------------------------------------------
  Widget _buildEditTab(bool isDark, HabitCategoryItem currentCategoryItem) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Habit Name
          Text(
            'HABIT NAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Morning 5km Run, Meditate 15 mins',
            ),
          ),

          const SizedBox(height: 18),

          // 2. Category Selection (Presets + Custom)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              InkWell(
                onTap: _showCustomCategoryDialog,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Custom Category',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...HabitCategoryPresets.all.map((cat) {
                final isSelected = _selectedCategory.toLowerCase() == cat.name.toLowerCase();
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : Color(cat.color)),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: Color(cat.color),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (val) {
                    if (val) _onCategorySelected(cat);
                  },
                );
              }),
              if (currentCategoryItem.isCustom)
                ChoiceChip(
                  avatar: const Icon(Icons.star, size: 14, color: Colors.white),
                  label: Text(_selectedCategory),
                  selected: true,
                  selectedColor: Color(_selectedColor),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  onSelected: (_) {},
                ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Description
          Text(
            'DESCRIPTION (OPTIONAL)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add instructions, motivation, or triggers...',
            ),
          ),

          const SizedBox(height: 18),

          // 4. Time of Day
          Text(
            'TIME OF DAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'id': 'morning', 'label': 'Morning 🌅'},
              {'id': 'afternoon', 'label': 'Afternoon ☀️'},
              {'id': 'evening', 'label': 'Evening 🌙'},
              {'id': 'night', 'label': 'Night 🌌'},
              {'id': 'all', 'label': 'Anytime ⏰'},
            ].map((slot) {
              final isSel = _selectedTimeOfDay == slot['id'];
              return ChoiceChip(
                label: Text(slot['label']!),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedTimeOfDay = slot['id']!);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // 5. Priority
          Text(
            'PRIORITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'low', label: Text('Low')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'high', label: Text('High')),
            ],
            selected: {_selectedPriority},
            onSelectionChanged: (set) => setState(() => _selectedPriority = set.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 6. Frequency
          Text(
            'FREQUENCY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Everyday (Daily)')),
              ButtonSegment(value: 'specific_days', label: Text('Specific Days')),
            ],
            selected: {_selectedFrequency},
            onSelectionChanged: (set) {
              final v = set.first;
              setState(() {
                _selectedFrequency = v;
                if (v == 'daily') {
                  _selectedDaysOfWeek = const [1, 2, 3, 4, 5, 6, 7];
                }
              });
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_selectedFrequency == 'specific_days') ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final weekdayNum = i + 1; // 1 = Mon .. 7 = Sun
                final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
                final isSelected = _selectedDaysOfWeek.contains(weekdayNum);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedDaysOfWeek.length > 1) {
                              _selectedDaysOfWeek.remove(weekdayNum);
                            }
                          } else {
                            _selectedDaysOfWeek.add(weekdayNum);
                            _selectedDaysOfWeek.sort();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(_selectedColor)
                              : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 18),

          // 7. Start Date & End Date
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        DateFormat('MMM d, yyyy').format(_selectedStartDate),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedStartDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'END DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        _isForever
                            ? 'Forever (No End)'
                            : DateFormat('MMM d, yyyy').format(_selectedEndDate ?? DateTime.now()),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isForever
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: _selectedStartDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _selectedEndDate = picked);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Habit is Forever (No End Date)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: _isForever,
            onChanged: (val) {
              setState(() {
                _isForever = val;
                if (!val && _selectedEndDate == null) {
                  _selectedEndDate = _selectedStartDate.add(const Duration(days: 90));
                }
              });
            },
          ),

          const SizedBox(height: 24),

          // Primary Save Changes Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Color(_selectedColor),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saveHabit,
            child: Text(
              widget.isNew ? 'Create Habit' : 'Save Changes',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),

          if (!widget.isNew && _currentHabit.id.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Restart Habit Progress Button
            OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt_rounded, color: AppColors.high, size: 18),
              label: const Text(
                'Restart Habit Progress',
                style: TextStyle(color: AppColors.high, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.high),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _confirmRestartProgress,
            ),

            const SizedBox(height: 10),

            // Delete Habit Button
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
              label: const Text(
                'Delete Habit',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _confirmDeleteHabit,
            ),
          ],
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
