import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/goal_project.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/goal_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _goalTitleController = TextEditingController();
  final _goalDescController = TextEditingController();
  final _projectTitleController = TextEditingController();

  @override
  void dispose() {
    _goalTitleController.dispose();
    _goalDescController.dispose();
    _projectTitleController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Life Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goalTitleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Master AI Engineering'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _goalDescController,
              decoration: const InputDecoration(hintText: 'Goal motivation and objectives'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = _goalTitleController.text.trim();
              if (title.isEmpty) return;

              final goal = Goal(
                id: const Uuid().v4(),
                title: title,
                description: _goalDescController.text.trim(),
                category: 'Career',
              );

              final repo = ref.read(goalRepositoryProvider);
              await repo.insertGoal(goal);

              _goalTitleController.clear();
              _goalDescController.clear();
              ref.invalidate(goalsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Project'),
        content: TextField(
          controller: _projectTitleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Mobile Portfolio App'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = _projectTitleController.text.trim();
              if (title.isEmpty) return;

              final proj = Project(
                id: const Uuid().v4(),
                title: title,
              );

              final repo = ref.read(goalRepositoryProvider);
              await repo.insertProject(proj);

              _projectTitleController.clear();
              ref.invalidate(projectsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalsAsync = ref.watch(goalsListProvider);
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Goal',
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Projects Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Projects',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Project', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Text('No projects yet.');
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: projects.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        width: 200,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(p.color),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.description.isNotEmpty ? p.description : 'In progress',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // Long-term Goals
            Text(
              'Long-Term Direction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),

            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return const Text('No goals set yet.');
                }

                return Column(
                  children: goals.map((goal) {
                    final progress = goal.progressPercentage;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          if (goal.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              goal.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Milestones checklist
                          Text(
                            'Milestones',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...goal.milestones.map((m) {
                            return Row(
                              children: [
                                Checkbox(
                                  value: m.isCompleted,
                                  activeColor: AppColors.success,
                                  onChanged: (val) async {
                                    final repo = ref.read(goalRepositoryProvider);
                                    await repo.toggleMilestone(m.id, val ?? false);
                                    ref.invalidate(goalsListProvider);
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    m.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                                      color: m.isCompleted
                                          ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
