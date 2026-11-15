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
import '../../track/focus/providers/focus_provider.dart';

/// Full-page screen for inspecting and editing task details in Life OS.
class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskItem task;

  const TaskDetailScreen({super.key, required this.task});

  static Future<void> open(BuildContext context, TaskItem task) {
    return Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  static Future<void> show(BuildContext context, TaskItem task) => open(context, task);

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;

  late TaskPriority _priority;
  late int _estimateMinutes;
  late bool _isTopPriority;
  late bool _isAllDay;
  late String _recurrence;
  late DateTime _dueDate;
  TimeOfDay? _scheduledTimeOfDay;
  DateTime? _recurrenceEndDate;
  DateTime? _deadlineDate;
  late List<Subtask> _subtasks;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _subtaskController = TextEditingController();

    _priority = widget.task.priority;
    _estimateMinutes = widget.task.estimateMinutes;
    _isTopPriority = widget.task.isTopPriority;
    _isAllDay = widget.task.isAllDay;
    _recurrence = widget.task.recurrence;
    _dueDate = widget.task.dueDate ?? DateTime.now();

    if (widget.task.scheduledTime != null && widget.task.scheduledTime!.contains(':')) {
      final parts = widget.task.scheduledTime!.split(':');
      final h = int.tryParse(parts[0]) ?? 9;
      final m = int.tryParse(parts[1]) ?? 0;
      _scheduledTimeOfDay = TimeOfDay(hour: h, minute: m);
    } else if (!_isAllDay) {
      _scheduledTimeOfDay = const TimeOfDay(hour: 9, minute: 0);
    }

    _recurrenceEndDate = widget.task.recurrenceEndDate;
    _deadlineDate = widget.task.endDate;
    _subtasks = List.from(widget.task.subtasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
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

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? scheduledTimeStr;
    if (!_isAllDay && _scheduledTimeOfDay != null) {
      final h = _scheduledTimeOfDay!.hour.toString().padLeft(2, '0');
      final m = _scheduledTimeOfDay!.minute.toString().padLeft(2, '0');
      scheduledTimeStr = '$h:$m';
    }

    final updated = widget.task.copyWith(
      title: title,
      description: _descController.text.trim(),
      priority: _priority,
      estimateMinutes: _isAllDay ? 0 : _estimateMinutes,
      isTopPriority: _isTopPriority,
      isAllDay: _isAllDay,
      recurrence: _recurrence,
      dueDate: _dueDate,
      scheduledTime: scheduledTimeStr,
      endDate: _deadlineDate,
      recurrenceEndDate: _recurrenceEndDate,
      subtasks: _subtasks,
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(updated);

    ref.invalidate(tasksListProvider);
    ref.invalidate(calendarTasksProvider);
    ref.invalidate(weekTaskDatesProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);

    if (mounted) Navigator.pop(context);
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
      subtasks: _subtasks.map((s) => s.title).toList(),
    );

    final repo = ref.read(taskRepositoryProvider);
    await repo.insertTemplate(newTemplate);
    ref.invalidate(taskTemplatesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$title" as a reusable template!')),
      );
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(Subtask(
        id: const Uuid().v4(),
        taskId: widget.task.id,
        title: text,
        isCompleted: false,
        position: _subtasks.length,
      ));
      _subtaskController.clear();
    });
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.urgent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(widget.task.id);
      ref.invalidate(tasksListProvider);
      ref.invalidate(calendarTasksProvider);
      ref.invalidate(weekTaskDatesProvider);
      ref.invalidate(topPrioritiesProvider);
      ref.invalidate(todayTaskMetricsProvider);
      if (mounted) Navigator.pop(context);
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
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, size: 20, color: AppColors.urgent),
            tooltip: 'Delete Task',
            onPressed: _deleteTask,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Title Input (No border notch)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Task Title',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 2. Description / Notes (No border notch)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Description or notes...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Subtasks Checklist (Placed directly below description)
              Text(
                'SUBTASKS (${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._subtasks.asMap().entries.map((entry) {
                final s = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            final idx = _subtasks.indexWhere((sub) => sub.id == s.id);
                            if (idx != -1) {
                              _subtasks[idx] = s.copyWith(isCompleted: !s.isCompleted);
                            }
                          });
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: s.isCompleted ? AppColors.success : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: s.isCompleted
                                  ? AppColors.success
                                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFC7C7CC)),
                              width: 1.6,
                            ),
                          ),
                          child: s.isCompleted
                              ? const Icon(CupertinoIcons.checkmark, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                            color: s.isCompleted
                                ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark, size: 16),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _subtasks.removeWhere((sub) => sub.id == s.id);
                          });
                        },
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
                        controller: _subtaskController,
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
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
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
                              DateFormat('MMM d, yyyy').format(_dueDate),
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

                    // Time & Duration
                    if (!_isAllDay) ...[
                      Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _scheduledTimeOfDay ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _scheduledTimeOfDay = picked);
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
                                _scheduledTimeOfDay != null ? _scheduledTimeOfDay!.format(context) : 'Set Time',
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

                    // Recurrence Row
                    InkWell(
                      onTap: () async {
                        final res = await RecurrenceSelectorSheet.show(
                          context,
                          initialRecurrence: _recurrence,
                          initialEndDate: _recurrenceEndDate,
                          taskDate: _dueDate,
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
                          initialDate: _deadlineDate ?? _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _deadlineDate = picked);
                        }
                      },
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

                    Divider(height: 1, thickness: 0.8, indent: 44, color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),

                    // Top Priority Spotlight Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.star_fill, size: 18, color: Colors.amber),
                          const SizedBox(width: 12),
                          const Text("Today's Top Priority", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          CupertinoSwitch(
                            value: _isTopPriority,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isTopPriority = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Pomodoro Focus Action
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(focusTimerProvider.notifier).linkTask(widget.task.id, widget.task.title);
                  ref.read(focusTimerProvider.notifier).setPreset(
                    _isAllDay ? 25 : _estimateMinutes,
                    'focus',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Linked "${widget.task.title}" to Focus Timer'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.timer, size: 16),
                label: const Text('Focus on this Task with Pomodoro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primary, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 7. Bottom Actions: Full-width Save Changes with Save as Template underneath
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
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
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
    );
  }
}

/// Legacy alias / wrapper pointing to the full [TaskDetailScreen].
class TaskDetailSheet extends StatelessWidget {
  final TaskItem task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskItem task) {
    return TaskDetailScreen.open(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return TaskDetailScreen(task: task);
  }
}
