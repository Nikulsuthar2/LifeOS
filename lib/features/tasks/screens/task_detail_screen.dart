import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/task_provider.dart';
import '../../track/focus/providers/focus_provider.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final TaskItem task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskItem task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;
  late TaskPriority _priority;
  late int _estimateMinutes;
  late bool _isTopPriority;
  late List<Subtask> _subtasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _subtaskController = TextEditingController();
    _priority = widget.task.priority;
    _estimateMinutes = widget.task.estimateMinutes;
    _isTopPriority = widget.task.isTopPriority;
    _subtasks = List.from(widget.task.subtasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      estimateMinutes: _estimateMinutes,
      isTopPriority: _isTopPriority,
      subtasks: _subtasks,
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(updated);

    ref.invalidate(tasksListProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);

    if (mounted) Navigator.pop(context);
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
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(widget.task.id);
      ref.invalidate(tasksListProvider);
      ref.invalidate(topPrioritiesProvider);
      ref.invalidate(todayTaskMetricsProvider);
      if (mounted) Navigator.pop(context);
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
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
                'Task Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.urgent),
                    onPressed: _deleteTask,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Priority and duration row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: TaskPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _estimateMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Est. Time',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [15, 25, 30, 45, 60, 90, 120].map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
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

                  // Top priority toggle
                  SwitchListTile(
                    title: const Text("Today's Top Priority", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Spotlight on the Dashboard priority card', style: TextStyle(fontSize: 12)),
                    value: _isTopPriority,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isTopPriority = val),
                  ),
                  const SizedBox(height: 12),

                  // Start Focus Session button
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(focusTimerProvider.notifier).linkTask(widget.task.id, widget.task.title);
                      ref.read(focusTimerProvider.notifier).setPreset(widget.task.estimateMinutes, 'focus');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Linked "${widget.task.title}" to Focus Timer'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('Focus on this Task with Pomodoro'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtasks Section
                  Text(
                    'Subtasks (${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._subtasks.map((s) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: s.isCompleted,
                        onChanged: (val) {
                          setState(() {
                            final idx = _subtasks.indexWhere((sub) => sub.id == s.id);
                            if (idx != -1) {
                              _subtasks[idx] = s.copyWith(isCompleted: val ?? false);
                            }
                          });
                        },
                      ),
                      title: Text(
                        s.title,
                        style: TextStyle(
                          decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                          color: s.isCompleted ? AppColors.darkTextMuted : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _subtasks.removeWhere((sub) => sub.id == s.id);
                          });
                        },
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: 'Add a subtask...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addSubtask,
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Save button
          FilledButton(
            onPressed: _saveChanges,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
    );
  }
}
