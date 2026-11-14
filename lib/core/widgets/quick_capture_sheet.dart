import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../../features/tasks/providers/task_provider.dart';
import '../../features/track/habits/providers/habit_provider.dart';

class QuickCaptureSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const QuickCaptureSheet({super.key, this.initialDate});

  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCaptureSheet(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<QuickCaptureSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  int _estimateMinutes = 30;
  late DateTime _targetDate;
  bool _isToday = true;

  final _habitTitleController = TextEditingController();
  String _selectedHabitCategory = 'Health';
  final List<String> _habitCategories = ['Health', 'Learning', 'Mind', 'Routine', 'Career'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _targetDate = widget.initialDate ?? DateTime.now();
    final now = DateTime.now();
    _isToday = _targetDate.year == now.year && _targetDate.month == now.month && _targetDate.day == now.day;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _habitTitleController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) return;

    final dueDate = _isToday ? DateTime.now() : _targetDate;
    final task = TaskItem(
      id: const Uuid().v4(),
      title: title,
      description: _taskDescController.text.trim(),
      status: TaskStatus.todo,
      priority: _selectedPriority,
      dueDate: dueDate,
      estimateMinutes: _estimateMinutes,
      isTopPriority: _selectedPriority == TaskPriority.urgent || _selectedPriority == TaskPriority.high,
    );

    final repo = ref.read(taskRepositoryProvider);
    await repo.insertTask(task);

    ref.invalidate(tasksListProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveHabit() async {
    final title = _habitTitleController.text.trim();
    if (title.isEmpty) return;

    final habit = Habit(
      id: const Uuid().v4(),
      title: title,
      category: _selectedHabitCategory,
      trackingType: 'boolean',
      targetValue: 1.0,
      frequency: 'daily',
      icon: _getIconForCategory(_selectedHabitCategory),
      color: _getColorForCategory(_selectedHabitCategory),
    );

    final repo = ref.read(habitRepositoryProvider);
    await repo.insertHabit(habit);

    ref.invalidate(habitsListProvider);
    ref.invalidate(todayHabitMetricsProvider);

    if (mounted) Navigator.pop(context);
  }

  String _getIconForCategory(String cat) {
    switch (cat) {
      case 'Health':
        return 'fitness_center';
      case 'Learning':
        return 'school';
      case 'Mind':
        return 'self_improvement';
      case 'Career':
        return 'work_outline';
      default:
        return 'check_circle_outline';
    }
  }

  int _getColorForCategory(String cat) {
    switch (cat) {
      case 'Health':
        return 0xFF10B981;
      case 'Learning':
        return 0xFF6366F1;
      case 'Mind':
        return 0xFFF59E0B;
      case 'Career':
        return 0xFF0EA5E9;
      default:
        return 0xFF8B5CF6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
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
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Capture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Task'),
                Tab(text: 'Habit'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          SizedBox(
            height: 290,
            child: TabBarView(
              controller: _tabController,
              children: [
                // TASK CAPTURE
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _taskTitleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'What needs to be done?',
                          prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _taskDescController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Add description or notes (optional)',
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              initialValue: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: TaskPriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(p.displayName, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPriority = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _estimateMinutes,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: (<int>{5, 10, 15, 20, 25, 30, 45, 60, 90, 120, _estimateMinutes}.toList()..sort()).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text('$m min', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _estimateMinutes = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Today', style: TextStyle(fontSize: 12)),
                            selected: _isToday,
                            onSelected: (val) => setState(() => _isToday = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Tomorrow', style: TextStyle(fontSize: 12)),
                            selected: !_isToday,
                            onSelected: (val) => setState(() => _isToday = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _saveTask,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Task', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

                // HABIT CAPTURE
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _habitTitleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Read 15 pages, 20 min walk',
                          prefixIcon: Icon(Icons.bolt, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _habitCategories.map((cat) {
                          final isSelected = _selectedHabitCategory == cat;
                          return ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (val) => setState(() => _selectedHabitCategory = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 36),
                      FilledButton(
                        onPressed: _saveHabit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Habit', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
