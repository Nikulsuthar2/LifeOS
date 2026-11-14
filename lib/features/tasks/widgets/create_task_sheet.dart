import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';

/// Dedicated, comprehensive task creation sheet for Life OS.
/// Features:
/// - Title, description, priority selector
/// - Date, time, duration dropdown
/// - All-Day option (clears/disables time & duration)
/// - Recurrence frequency and recurrence end date (how long repeated)
/// - Deadline / end date
/// - Subtask checklist builder
/// - Template picker & "Save as Template" capability
class CreateTaskSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;

  const CreateTaskSheet({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    String? initialTime,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskSheet(
        initialDate: initialDate,
        initialTime: initialTime,
      ),
    );
  }

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskInputController = TextEditingController();

  late DateTime _startDate;
  TimeOfDay? _scheduledTime;
  int _estimateMinutes = 30;
  bool _isAllDay = false;
  TaskPriority _priority = TaskPriority.medium;

  // Recurrence
  String _recurrence = 'none'; // 'none', 'daily', 'weekly', 'weekdays', 'monthly'
  DateTime? _recurrenceEndDate;

  // Deadline / End Date
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied template "${template.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showTemplatePicker() async {
    final templates = await ref.read(taskTemplatesProvider.future);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Load Task Template',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (templates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: Text('No templates saved yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, idx) {
                      final t = templates[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${t.estimateMinutes}m · ${t.priority.displayName} · ${t.subtasks.length} subtasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.pop(ctx);
                          _applyTemplate(t);
                        },
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

  Future<void> _saveAsTemplate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title first.')),
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
        SnackBar(content: Text('Saved "$title" as a new template!')),
      );
    }
  }

  void _addSubtask() {
    final text = _subtaskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(text);
        _subtaskInputController.clear();
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(taskRepositoryProvider);
    const uuid = Uuid();
    final taskId = uuid.v4();

    String? scheduledTimeStr;
    if (!_isAllDay && _scheduledTime != null) {
      final h = _scheduledTime!.hour.toString().padLeft(2, '0');
      final m = _scheduledTime!.minute.toString().padLeft(2, '0');
      scheduledTimeStr = '$h:$m';
    }

    final subtaskObjects = _subtasks.asMap().entries.map((entry) {
      return Subtask(
        id: uuid.v4(),
        taskId: taskId,
        title: entry.value,
        position: entry.key,
      );
    }).toList();

    final newTask = TaskItem(
      id: taskId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: TaskStatus.todo,
      priority: _priority,
      dueDate: _startDate,
      scheduledTime: scheduledTimeStr,
      estimateMinutes: _isAllDay ? 0 : _estimateMinutes,
      isAllDay: _isAllDay,
      recurrence: _recurrence,
      endDate: _deadlineDate,
      recurrenceEndDate: _recurrenceEndDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      subtasks: subtaskObjects,
    );

    await repo.insertTask(newTask);

    ref.invalidate(tasksListProvider);
    ref.invalidate(calendarTasksProvider);
    ref.invalidate(weekTaskDatesProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottomInset + AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Grab Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header with Template Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.bookmark_outline, size: 16),
                      label: const Text('Templates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: _showTemplatePicker,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 1. Title Input
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a task title' : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add description or notes (optional)',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Priority Row
                Text(
                  'PRIORITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: TaskPriority.values.map((p) {
                    final isSelected = _priority == p;
                    Color priorityColor;
                    switch (p) {
                      case TaskPriority.urgent:
                        priorityColor = AppColors.urgent;
                        break;
                      case TaskPriority.high:
                        priorityColor = AppColors.high;
                        break;
                      case TaskPriority.medium:
                        priorityColor = AppColors.medium;
                        break;
                      case TaskPriority.low:
                        priorityColor = AppColors.low;
                        break;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => setState(() => _priority = p),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? priorityColor.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isSelected ? priorityColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? priorityColor : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Date & All-Day Switch
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, yyyy').format(_startDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // All Day Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('All Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            value: _isAllDay,
                            onChanged: (val) => setState(() => _isAllDay = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // 5. Time & Duration (hidden if All-Day)
                if (!_isAllDay) ...[
                  Row(
                    children: [
                      // Time picker
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _scheduledTime = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 8),
                                Text(
                                  _scheduledTime != null ? _scheduledTime!.format(context) : 'Set Time',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Duration dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _estimateMinutes,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              items: const [
                                DropdownMenuItem(value: 15, child: Text('15 min', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 30, child: Text('30 min', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 45, child: Text('45 min', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 60, child: Text('1 hour', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 90, child: Text('1.5 hours', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 120, child: Text('2 hours', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _estimateMinutes = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // 6. Recurrence (Repeat Task)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _recurrence,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Does not repeat', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'daily', child: Text('Repeats Daily', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'weekdays', child: Text('Repeats Weekdays (M-F)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'weekly', child: Text('Repeats Weekly', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'monthly', child: Text('Repeats Monthly', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _recurrence = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    if (_recurrence != 'none') ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _recurrenceEndDate ?? _startDate.add(const Duration(days: 30)),
                              firstDate: _startDate,
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => _recurrenceEndDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_repeat, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _recurrenceEndDate != null
                                        ? 'Until ${DateFormat('MMM d').format(_recurrenceEndDate!)}'
                                        : 'Until Forever',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // 7. Deadline / End Date
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 16, color: AppColors.urgent),
                            const SizedBox(width: 8),
                            Text(
                              _deadlineDate != null
                                  ? 'Deadline: ${DateFormat('MMM d, yyyy').format(_deadlineDate!)}'
                                  : 'Add Deadline / End Date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _deadlineDate != null ? FontWeight.w600 : FontWeight.normal,
                                color: _deadlineDate != null
                                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ],
                        ),
                        if (_deadlineDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _deadlineDate = null),
                            child: const Icon(Icons.clear, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 8. Subtasks Section
                Text(
                  'SUBTASKS (${_subtasks.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
                          Icon(Icons.check_box_outline_blank, size: 18, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(sub, style: const TextStyle(fontSize: 13)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryLight),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 9. Actions: Save Template & Create Task
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: const Text('Save as Template', style: TextStyle(fontSize: 12)),
                      onPressed: _saveAsTemplate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create Task', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
