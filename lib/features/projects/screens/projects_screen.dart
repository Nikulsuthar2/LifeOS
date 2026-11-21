import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/goal_project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../goals/providers/goal_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String? _selectedProjectId;

  void _showAddProjectDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'e.g. LifeOS Flutter App, Money Tracker',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description / Scope',
                hintText: 'Deliverables and tech stack...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final project = Project(
                id: const Uuid().v4(),
                title: title,
                description: descController.text.trim(),
                color: 0xFF6366F1,
              );
              await ref.read(goalRepositoryProvider).insertProject(project);
              ref.invalidate(projectsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  void _showAddFeatureDialog(String projectId) {
    final titleController = TextEditingController();
    String status = 'upcoming';
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Feature / Deliverable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Feature Title',
                  hintText: 'e.g. SQLite Offline Cache Layer',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Initial Stage'),
                items: const [
                  DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'done', child: Text('Done')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => status = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => priority = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final feature = ProjectFeature(
                  id: const Uuid().v4(),
                  projectId: projectId,
                  title: title,
                  status: status,
                  priority: priority,
                );
                await ref.read(goalRepositoryProvider).insertProjectFeature(feature);
                ref.invalidate(projectsListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Add Feature'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Project Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        backgroundColor: primary,
        foregroundColor: ThemeData.estimateBrightnessForColor(primary) == Brightness.light
            ? const Color(0xFF141416)
            : Colors.white,
        icon: const Icon(Icons.rocket_launch_rounded),
        label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 48,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active projects',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a project to organize deliverables and feature backlogs.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final currentProject = projects.firstWhere(
            (p) => p.id == _selectedProjectId,
            orElse: () => projects.first,
          );

          return Column(
            children: [
              // Project horizontal selector tabs
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: projects.map((proj) {
                    final isSelected = proj.id == currentProject.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(proj.title),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedProjectId = proj.id),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        visualDensity: VisualDensity.compact,
                        selectedColor: primary.withValues(alpha: 0.2),
                        checkmarkColor: primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Selected Project Header Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentProject.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete Project',
                            onPressed: () async {
                              await ref.read(goalRepositoryProvider).deleteProject(currentProject.id);
                              ref.invalidate(projectsListProvider);
                            },
                          ),
                        ],
                      ),
                      if (currentProject.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentProject.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: currentProject.progressPercentage,
                                backgroundColor: isDark ? const Color(0xFF26262C) : const Color(0xFFE8E8EC),
                                valueColor: AlwaysStoppedAnimation(
                                  currentProject.progressPercentage == 1.0 ? AppColors.success : primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(currentProject.progressPercentage * 100).toInt()}% Done',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Kanban Columns: Upcoming, In Progress, Done
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: [
                            const Expanded(
                              child: TabBar(
                                tabs: [
                                  Tab(text: 'Upcoming'),
                                  Tab(text: 'In Progress'),
                                  Tab(text: 'Done'),
                                ],
                                indicatorSize: TabBarIndicatorSize.tab,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              tooltip: 'Add Feature',
                              onPressed: () => _showAddFeatureDialog(currentProject.id),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildFeatureColumn(
                              features: currentProject.features.where((f) => f.status == 'upcoming').toList(),
                              nextStatus: 'in_progress',
                              nextLabel: 'Start',
                              isDark: isDark,
                              primary: primary,
                            ),
                            _buildFeatureColumn(
                              features: currentProject.features.where((f) => f.status == 'in_progress').toList(),
                              nextStatus: 'done',
                              nextLabel: 'Complete',
                              isDark: isDark,
                              primary: primary,
                            ),
                            _buildFeatureColumn(
                              features: currentProject.features.where((f) => f.status == 'done').toList(),
                              nextStatus: 'upcoming',
                              nextLabel: 'Reopen',
                              isDark: isDark,
                              primary: primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildFeatureColumn({
    required List<ProjectFeature> features,
    required String nextStatus,
    required String nextLabel,
    required bool isDark,
    required Color primary,
  }) {
    if (features.isEmpty) {
      return Center(
        child: Text(
          'No features in this column',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 96),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feat = features[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feat.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feat.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: feat.priority == 'urgent' ? AppColors.urgent : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(goalRepositoryProvider).updateProjectFeatureStatus(feat.id, nextStatus);
                  ref.invalidate(projectsListProvider);
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Text(nextLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  await ref.read(goalRepositoryProvider).deleteProjectFeature(feat.id);
                  ref.invalidate(projectsListProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
