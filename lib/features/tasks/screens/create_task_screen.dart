import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/recurrence_engine.dart';
import '../providers/task_provider.dart';
import '../widgets/recurrence_selector_sheet.dart';

/// Full-page screen for creating tasks in Life OS.
/// Features:
/// - Clean, modern borderless input fields without floating border labels
/// - 15-minute multiple stepper + quick pill duration input (no dropdowns)
/// - Modern recurrence rule engine (specific days of week, day of month, end date)
/// - Tactile priority segmented control & iOS Inset Grouped Settings
class CreateTaskScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;

  const CreateTaskScreen({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  static Future<void> open(
    BuildContext context, {
    DateTime? initialDate,
    String? initialTime,
  }) {
    return Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CreateTaskScreen(
          initialDate: initialDate,
          initialTime: initialTime,
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    String? initialTime,
  }) =>
      open(context, initialDate: initialDate, initialTime: initialTime);

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskInputController = TextEditingController();

  late DateTime _startDate;
  TimeOfDay? _scheduledTime;
  int _estimateMinutes = 30; // 15-minute multiples
  bool _isAllDay = false;
  TaskPriority _priority = TaskPriority.medium;

  // Recurrence
  String _recurrence = 'none';
  DateTime? _recurrenceEndDate;

  // Deadline
  DateTime? _deadlineDate;

  // Subtasks list
  final List<String> _subtasks = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate ?? DateTime.now();
    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        _scheduledTime = TimeOfDay(hour: h, minute: m);
      }
    } else {
      _scheduledTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    if (minutes == 60) return '1 hr';
    if (minutes % 60 == 0) return '${minutes ~/ 60} hr';
    if (minutes > 60 && minutes % 15 == 0) {
      final hrs = minutes / 60;
      return '${hrs.toStringAsFixed(hrs % 1 == 0 ? 0 : 2)} hr';
    }
    return '$minutes min';
  }

  void _applyTemplate(TaskTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descController.text = template.description;
      _priority = template.priority;
      _estimateMinutes = template.estimateMinutes;
      _isAllDay = template.isAllDay;
      _subtasks.clear();
      _subtasks.addAll(template.subtasks);
    });
  }

  Future<void> _showTemplatePicker() async {
    final templatesAsync = await ref.read(taskTemplatesProvider.future);
    if (!mounted) return;

    if (templatesAsync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates saved yet. Create a task and tap "Save as Template".')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Task Template',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templatesAsync.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final t = templatesAsync[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyTemplate(t);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF28282E) : const Color(0xFFE5E5EA),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.bookmark_fill, size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (t.description.isNotEmpty)
                                    Text(
                                      t.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text('${t.estimateMinutes}m', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addSubtask() {
    final text = _subtaskInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(text);
      _subtaskInputController.clear();
    });
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final scheduledTimeStr = _isAllDay || _scheduledTime == null
          ? null
          : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';

      final taskId = const Uuid().v4();
      final subtaskList = _subtasks.asMap().entries.map((e) {
        return Subtask(
          id: const Uuid().v4(),
          taskId: taskId,
          title: e.value,
          isCompleted: false,
          position: e.key,
        );
      }).toList();

      final task = TaskItem(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        dueDate: _startDate,
        scheduledTime: scheduledTimeStr,
        estimateMinutes: _isAllDay ? 0 : _estimateMinutes,
        isAllDay: _isAllDay,
        recurrence: _recurrence,
        recurrenceEndDate: _recurrenceEndDate,
        endDate: _deadlineDate,
        subtasks: subtaskList,
      );

      final repo = ref.read(taskRepositoryProvider);
      await repo.insertTask(task);

      ref.invalidate(tasksListProvider);
      ref.invalidate(calendarTasksProvider);
      ref.invalidate(weekTaskDatesProvider);
      ref.invalidate(topPrioritiesProvider);
      ref.invalidate(todayTaskMetricsProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAsTemplate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title first')),
      );
      return;
    }

    final newTemplate = TaskTemplate(
      id: const Uuid().v4(),
      title: title,
      description: _descController.text.trim(),
      priority: _priority,
      estimateMinutes: _estimateMinutes,
      isAllDay: _isAllDay,
      subtasks: List.from(_subtasks),
    );

    final repo = ref.read(taskRepositoryProvider);
    await repo.insertTemplate(newTemplate);
    ref.invalidate(taskTemplatesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$title" as a template!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = RecurrenceRule.fromString(_recurrence, endDate: _recurrenceEndDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ),
        leadingWidth: 72,
        title: Text(
          'New Task',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(CupertinoIcons.bookmark, size: 16),
            label: const Text('Templates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: _showTemplatePicker,
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Task Title (Modern flat style without floating border label)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: InputBorder.none,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a task title' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Notes / Description
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Notes or description (optional)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Subtasks Section (Placed directly below description)
                Text(
                  'SUBTASKS (${_subtasks.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_subtasks.isNotEmpty)
                  ..._subtasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sub = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.square, size: 18, color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFC7C7CC)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(sub, style: const TextStyle(fontSize: 13.5)),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.xmark, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _subtasks.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: _subtaskInputController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add a subtask...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.primaryLight, size: 28),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Priority Selector
                Text(
                  'PRIORITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<TaskPriority>(
                    groupValue: _priority,
                    backgroundColor: isDark ? const Color(0xFF161618) : const Color(0xFFE5E5EA),
                    thumbColor: isDark ? const Color(0xFF26262B) : Colors.white,
                    children: const {
                      TaskPriority.low: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Low', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      TaskPriority.medium: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Med', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      TaskPriority.high: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('High', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      TaskPriority.urgent: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Urgent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Inset Grouped Settings Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Date Row
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.calendar, size: 18, color: AppColors.primaryLight),
                              const SizedBox(width: 12),
                              const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_forward, size: 14),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),

                      // All Day Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.sun_max, size: 18, color: Colors.amber),
                            const SizedBox(width: 12),
                            const Text('All Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            CupertinoSwitch(
                              value: _isAllDay,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => setState(() => _isAllDay = val),
                            ),
                          ],
                        ),
                      ),

                      // Time & Duration (visible when not All Day)
                      if (!_isAllDay) ...[
                        Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _scheduledTime = picked);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.clock, size: 18, color: AppColors.primaryLight),
                                const SizedBox(width: 12),
                                const Text('Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text(
                                  _scheduledTime != null ? _scheduledTime!.format(context) : 'Set Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.chevron_forward, size: 14),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),

                        // Duration Stepper & Quick Pills (Multiple of 15 min, Non-dropdown)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.timer, size: 18, color: AppColors.primaryLight),
                                  const SizedBox(width: 12),
                                  const Text('Duration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  // Stepper Controls
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.minus_circle, size: 20),
                                    onPressed: _estimateMinutes > 15
                                        ? () => setState(() => _estimateMinutes = (_estimateMinutes - 15).clamp(15, 480))
                                        : null,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF222227) : const Color(0xFFE5E5EA),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatDuration(_estimateMinutes),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.plus_circle, size: 20),
                                    onPressed: () => setState(() => _estimateMinutes = (_estimateMinutes + 15).clamp(15, 480)),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Quick Duration Pills
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [15, 30, 45, 60, 75, 90, 120].map((m) {
                                    final isSelected = _estimateMinutes == m;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: InkWell(
                                        onTap: () => setState(() => _estimateMinutes = m),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF222227) : const Color(0xFFE5E5EA)),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _formatDuration(m),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),

                      // Recurrence Row (Opens interactive RecurrenceSelectorSheet)
                      InkWell(
                        onTap: () async {
                          final res = await RecurrenceSelectorSheet.show(
                            context,
                            initialRecurrence: _recurrence,
                            initialEndDate: _recurrenceEndDate,
                            taskDate: _startDate,
                          );
                          if (res != null) {
                            setState(() {
                              _recurrence = res.recurrence;
                              _recurrenceEndDate = res.endDate;
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.repeat, size: 18, color: AppColors.primaryLight),
                              const SizedBox(width: 12),
                              const Text('Repeat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  rule.summaryLabel,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _recurrence != 'none'
                                        ? AppColors.primaryLight
                                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_forward, size: 14),
                            ],
                          ),
                        ),
                      ),

                      if (_recurrence != 'none' && _recurrenceEndDate != null) ...[
                        Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.calendar_badge_plus, size: 18, color: AppColors.primaryLight),
                              const SizedBox(width: 12),
                              const Text('Until', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(
                                DateFormat('MMM d, yyyy').format(_recurrenceEndDate!),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),

                      // Deadline Row
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deadlineDate ?? _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _deadlineDate = picked);
                          }
                        },
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.flag, size: 18, color: AppColors.urgent),
                              const SizedBox(width: 12),
                              const Text('Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(
                                _deadlineDate != null ? DateFormat('MMM d, yyyy').format(_deadlineDate!) : 'None',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _deadlineDate != null ? FontWeight.w600 : FontWeight.normal,
                                  color: _deadlineDate != null
                                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                ),
                              ),
                              if (_deadlineDate != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() => _deadlineDate = null),
                                  child: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                                ),
                              ] else ...[
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.chevron_forward, size: 14),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 6. Action Buttons: Full-width Create Task with Save as Template underneath
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create Task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(CupertinoIcons.bookmark, size: 16, color: AppColors.primaryLight),
                        label: const Text(
                          'Save as Template',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                        ),
                        onPressed: _saveAsTemplate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
