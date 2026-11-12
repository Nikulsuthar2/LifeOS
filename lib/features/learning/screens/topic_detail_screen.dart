import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/roadmap_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../track/focus/providers/focus_provider.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final Topic topic;
  final String roadmapTitle;

  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.roadmapTitle,
  });

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  late Topic _topic;
  final _lessonController = TextEditingController();
  final _resTitleController = TextEditingController();
  final _resUrlController = TextEditingController();
  String _resType = 'video';

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
  }

  @override
  void dispose() {
    _lessonController.dispose();
    _resTitleController.dispose();
    _resUrlController.dispose();
    super.dispose();
  }

  Color _getStatusColor(TopicStatus status) {
    switch (status) {
      case TopicStatus.completed:
        return AppColors.success;
      case TopicStatus.inProgress:
        return AppColors.primaryLight;
      case TopicStatus.available:
        return AppColors.secondary;
      case TopicStatus.locked:
        return AppColors.darkTextMuted;
      case TopicStatus.onHold:
        return AppColors.warning;
    }
  }

  Future<void> _updateStatus(TopicStatus newStatus) async {
    final repo = ref.read(roadmapRepositoryProvider);
    await repo.updateTopicStatus(_topic.id, newStatus);
    setState(() {
      _topic = _topic.copyWith(status: newStatus);
    });
    ref.invalidate(roadmapsListProvider);
    ref.invalidate(activeRoadmapSpotlightProvider);
  }

  Future<void> _toggleLesson(Lesson lesson, bool isCompleted) async {
    final repo = ref.read(roadmapRepositoryProvider);
    await repo.toggleLessonCompletion(lesson.id, isCompleted, _topic.id);

    final updatedLessons = _topic.lessons.map((l) {
      if (l.id == lesson.id) return l.copyWith(isCompleted: isCompleted);
      return l;
    }).toList();

    setState(() {
      _topic = _topic.copyWith(lessons: updatedLessons);
    });

    ref.invalidate(roadmapsListProvider);
    ref.invalidate(activeRoadmapSpotlightProvider);
  }

  Future<void> _generateTask() async {
    final repo = ref.read(roadmapRepositoryProvider);
    await repo.createTaskFromTopic(_topic, roadmapTitle: widget.roadmapTitle);

    ref.invalidate(tasksListProvider);
    ref.invalidate(topPrioritiesProvider);
    ref.invalidate(todayTaskMetricsProvider);
    ref.invalidate(roadmapsListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created Today\'s Study Task for "${_topic.title}"!'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _showAddLessonDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Lesson / Concept'),
        content: TextField(
          controller: _lessonController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Iterative BFS Traversal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final text = _lessonController.text.trim();
              if (text.isEmpty) return;

              final lesson = Lesson(
                id: const Uuid().v4(),
                topicId: _topic.id,
                title: text,
                position: _topic.lessons.length,
                isCompleted: false,
              );

              final repo = ref.read(roadmapRepositoryProvider);
              await repo.insertLesson(lesson);

              setState(() {
                _topic = _topic.copyWith(lessons: [..._topic.lessons, lesson]);
              });
              _lessonController.clear();
              ref.invalidate(roadmapsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Learning Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _resTitleController,
                decoration: const InputDecoration(hintText: 'Resource Title (e.g. MIT 6.006 Lecture)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _resUrlController,
                decoration: const InputDecoration(hintText: 'URL or Reference link'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _resType,
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('Video / Lecture')),
                  DropdownMenuItem(value: 'doc', child: Text('Documentation / Article')),
                  DropdownMenuItem(value: 'book', child: Text('Book / Chapter')),
                  DropdownMenuItem(value: 'url', child: Text('Website / Tool')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => _resType = val);
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = _resTitleController.text.trim();
                if (title.isEmpty) return;

                final res = TopicResource(
                  id: const Uuid().v4(),
                  topicId: _topic.id,
                  title: title,
                  resourceType: _resType,
                  url: _resUrlController.text.trim(),
                );

                final repo = ref.read(roadmapRepositoryProvider);
                await repo.insertResource(res);

                setState(() {
                  _topic = _topic.copyWith(resources: [..._topic.resources, res]);
                });
                _resTitleController.clear();
                _resUrlController.clear();
                ref.invalidate(roadmapsListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Add Resource'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(_topic.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roadmapTitle, style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Topic Title Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _topic.status.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      PopupMenuButton<TopicStatus>(
                        tooltip: 'Change Status',
                        onSelected: _updateStatus,
                        itemBuilder: (context) => TopicStatus.values.map((s) {
                          return PopupMenuItem(
                            value: s,
                            child: Text(s.displayName),
                          );
                        }).toList(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _topic.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (_topic.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _topic.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Progress & Time Stats
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Est. Hours',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                            Text(
                              '${_topic.estimatedHours}h',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Spent',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                            Text(
                              '${_topic.actualMinutesSpent} mins',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lessons Done',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                            Text(
                              '${_topic.completedLessonsCount}/${_topic.lessons.length}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons: Generate Task & Start Focus
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _generateTask,
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Study Today'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(focusTimerProvider.notifier).linkTopic(_topic.id, _topic.title);
                      ref.read(focusTimerProvider.notifier).setPreset(50, 'focus');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Linked "${_topic.title}" to Pomodoro Focus timer!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('Start Focus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lessons Checklist Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lessons & Concepts (${_topic.completedLessonsCount}/${_topic.lessons.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: AppColors.primaryLight),
                  onPressed: _showAddLessonDialog,
                  tooltip: 'Add Lesson',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_topic.lessons.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No sub-lessons added yet. Break this topic into actionable concepts.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              )
            else
              ..._topic.lessons.map((lesson) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: lesson.isCompleted,
                        activeColor: AppColors.success,
                        onChanged: (val) => _toggleLesson(lesson, val ?? false),
                      ),
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: lesson.isCompleted ? TextDecoration.lineThrough : null,
                            color: lesson.isCompleted
                                ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Resources Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Resources (${_topic.resources.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: AppColors.primaryLight),
                  onPressed: _showAddResourceDialog,
                  tooltip: 'Add Resource',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_topic.resources.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No resources attached yet. Add tutorials, videos or papers.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              )
            else
              ..._topic.resources.map((res) {
                IconData resIcon = Icons.link;
                if (res.resourceType == 'video') resIcon = Icons.play_circle_outline;
                if (res.resourceType == 'doc') resIcon = Icons.description_outlined;
                if (res.resourceType == 'book') resIcon = Icons.menu_book;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(resIcon, size: 20, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (res.notes.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                res.notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                            if (res.url.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                res.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
