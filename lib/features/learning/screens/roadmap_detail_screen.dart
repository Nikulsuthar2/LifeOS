import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/roadmap_provider.dart';
import 'topic_detail_screen.dart';

class RoadmapDetailScreen extends ConsumerStatefulWidget {
  final Roadmap initialRoadmap;

  const RoadmapDetailScreen({super.key, required this.initialRoadmap});

  @override
  ConsumerState<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends ConsumerState<RoadmapDetailScreen> {
  final _stageTitleController = TextEditingController();
  final _stageDescController = TextEditingController();

  final _topicTitleController = TextEditingController();
  final _topicDescController = TextEditingController();
  double _topicEstHours = 4.0;

  @override
  void dispose() {
    _stageTitleController.dispose();
    _stageDescController.dispose();
    _topicTitleController.dispose();
    _topicDescController.dispose();
    super.dispose();
  }

  void _showAddStageDialog(String roadmapId, int currentStagesCount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Learning Stage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _stageTitleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Stage Title (e.g. Stage 3: Systems)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stageDescController,
              decoration: const InputDecoration(hintText: 'Description or goals'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = _stageTitleController.text.trim();
              if (title.isEmpty) return;

              final stage = RoadmapStage(
                id: const Uuid().v4(),
                roadmapId: roadmapId,
                title: title,
                description: _stageDescController.text.trim(),
                position: currentStagesCount,
              );

              final repo = ref.read(roadmapRepositoryProvider);
              await repo.insertStage(stage);

              _stageTitleController.clear();
              _stageDescController.clear();
              ref.invalidate(roadmapsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Add Stage'),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog(String stageId, int currentTopicsCount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Topic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _topicTitleController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Topic Title (e.g. Dynamic Programming)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicDescController,
                decoration: const InputDecoration(hintText: 'Topic description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                initialValue: _topicEstHours,
                decoration: const InputDecoration(labelText: 'Estimated Hours'),
                items: [1.0, 2.0, 4.0, 6.0, 8.0, 12.0, 20.0].map((h) {
                  return DropdownMenuItem(value: h, child: Text('$h hours'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => _topicEstHours = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = _topicTitleController.text.trim();
                if (title.isEmpty) return;

                final topic = Topic(
                  id: const Uuid().v4(),
                  stageId: stageId,
                  title: title,
                  description: _topicDescController.text.trim(),
                  position: currentTopicsCount,
                  status: TopicStatus.available,
                  estimatedHours: _topicEstHours,
                );

                final repo = ref.read(roadmapRepositoryProvider);
                await repo.insertTopic(topic);

                _topicTitleController.clear();
                _topicDescController.clear();
                ref.invalidate(roadmapsListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Add Topic'),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roadmapsAsync = ref.watch(roadmapsListProvider);

    return roadmapsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (roadmaps) {
        final roadmap = roadmaps.firstWhere(
          (r) => r.id == widget.initialRoadmap.id,
          orElse: () => widget.initialRoadmap,
        );

        final totalTopics = roadmap.totalTopicsCount;
        final completedTopics = roadmap.completedTopicsCount;
        final progress = roadmap.progressPercentage;

        return Scaffold(
          appBar: AppBar(
            title: Text(roadmap.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Stage',
                onPressed: () => _showAddStageDialog(roadmap.id, roadmap.stages.length),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overview Banner Card
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
                              color: Color(roadmap.color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roadmap.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(roadmap.color),
                              ),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}% Completed',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        roadmap.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${roadmap.stages.length} Stages · $totalTopics Topics',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          Text(
                            '$completedTopics of $totalTopics done',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stages & Topics Accordion
                Text(
                  'Learning Stages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                ...roadmap.stages.map((stage) {
                  final isStageComplete = stage.topics.isNotEmpty &&
                      stage.topics.every((t) => t.status == TopicStatus.completed);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                stage.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isStageComplete
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${stage.completedTopicsCount}/${stage.topics.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isStageComplete
                                      ? AppColors.success
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: stage.description.isNotEmpty
                            ? Text(
                                stage.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              )
                            : null,
                        children: [
                          const Divider(height: 1),
                          ...stage.topics.map((topic) {
                            final statusColor = _getStatusColor(topic.status);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TopicDetailScreen(
                                      topic: topic,
                                      roadmapTitle: roadmap.title,
                                    ),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: topic.status == TopicStatus.completed
                                      ? AppColors.success
                                      : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                                  border: Border.all(
                                    color: topic.status == TopicStatus.completed
                                        ? AppColors.success
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                child: Center(
                                  child: topic.status == TopicStatus.completed
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : Text(
                                          '${topic.position + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                topic.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: topic.status == TopicStatus.locked
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                              ),
                              subtitle: Text(
                                '${topic.lessons.length} lessons · ${topic.actualMinutesSpent}m spent',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      topic.status.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 18),
                                ],
                              ),
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextButton.icon(
                              onPressed: () => _showAddTopicDialog(stage.id, stage.topics.length),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Topic to Stage', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
