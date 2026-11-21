import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/roadmap_provider.dart';
import '../../skills/screens/skills_screen.dart';
import 'roadmap_detail_screen.dart';

class RoadmapsScreen extends ConsumerStatefulWidget {
  const RoadmapsScreen({super.key});

  @override
  ConsumerState<RoadmapsScreen> createState() => _RoadmapsScreenState();
}

class _RoadmapsScreenState extends ConsumerState<RoadmapsScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Tech';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCreateRoadmapDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Learning Roadmap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Full-Stack Web Development',
                  labelText: 'Roadmap Title',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Master frontend, backend & databases',
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Tech', child: Text('Tech & Software')),
                  DropdownMenuItem(value: 'AI/ML', child: Text('AI & Machine Learning')),
                  DropdownMenuItem(value: 'Design', child: Text('Design & UI/UX')),
                  DropdownMenuItem(value: 'Business', child: Text('Business & Systems')),
                  DropdownMenuItem(value: 'Language', child: Text('Language & Writing')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => _category = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;

                final roadmap = Roadmap(
                  id: const Uuid().v4(),
                  title: title,
                  description: _descController.text.trim(),
                  category: _category,
                  color: 0xFF6366F1,
                  status: 'active',
                );

                final repo = ref.read(roadmapRepositoryProvider);
                await repo.insertRoadmap(roadmap);

                _titleController.clear();
                _descController.clear();
                ref.invalidate(roadmapsListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Create Roadmap'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roadmapsAsync = ref.watch(roadmapsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Roadmaps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_rounded),
            tooltip: 'Polymath Skills Matrix',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SkillsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Roadmap',
            onPressed: _showCreateRoadmapDialog,
          ),
        ],
      ),
      body: roadmapsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (roadmaps) {
          if (roadmaps.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'No Learning Roadmaps Yet',
              message: 'Build structured, sequential roadmaps for programming, languages, or complex skills.',
              buttonText: 'Create Roadmap',
              onButtonPressed: _showCreateRoadmapDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: roadmaps.length,
            itemBuilder: (context, index) {
              final roadmap = roadmaps[index];
              final progress = roadmap.progressPercentage;
              final nextTopic = roadmap.nextAvailableTopic;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoadmapDetailScreen(initialRoadmap: roadmap),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            roadmap.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (roadmap.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              roadmap.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(roadmap.color)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Next Topic or Stages count
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nextTopic != null
                                      ? 'Next: ${nextTopic.title}'
                                      : '${roadmap.stages.length} Stages · ${roadmap.totalTopicsCount} Topics',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: nextTopic != null
                                        ? AppColors.primaryLight
                                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
