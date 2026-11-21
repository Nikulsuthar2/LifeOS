import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';
import '../widgets/task_view_sheet.dart';

class EisenhowerMatrixScreen extends ConsumerStatefulWidget {
  const EisenhowerMatrixScreen({super.key});

  @override
  ConsumerState<EisenhowerMatrixScreen> createState() => _EisenhowerMatrixScreenState();
}

class _EisenhowerMatrixScreenState extends ConsumerState<EisenhowerMatrixScreen> {
  int _selectedQuadrantIndex = 0; // 0: Do First, 1: Schedule, 2: Delegate, 3: Eliminate

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final tasksAsync = ref.watch(tasksListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Eisenhower Matrix',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          final activeTasks = allTasks.where((t) => !t.isCompleted).toList();

          // Categorize into 4 Quadrants
          final q1DoFirst = activeTasks.where((t) => t.isTopPriority || t.priority == TaskPriority.urgent).toList();
          final q2Schedule = activeTasks.where((t) => !t.isTopPriority && t.priority == TaskPriority.high).toList();
          final q3Delegate = activeTasks.where((t) => !t.isTopPriority && t.priority == TaskPriority.medium).toList();
          final q4Eliminate = activeTasks.where((t) => !t.isTopPriority && t.priority == TaskPriority.low).toList();

          final quadrants = [
            _QuadrantData(
              index: 0,
              code: 'Q1',
              title: 'Do First',
              subtitle: 'Urgent & Important',
              tasks: q1DoFirst,
              color: AppColors.urgent,
              icon: Icons.priority_high_rounded,
            ),
            _QuadrantData(
              index: 1,
              code: 'Q2',
              title: 'Schedule',
              subtitle: 'Important, Not Urgent',
              tasks: q2Schedule,
              color: primary,
              icon: Icons.calendar_month_rounded,
            ),
            _QuadrantData(
              index: 2,
              code: 'Q3',
              title: 'Delegate / Quick',
              subtitle: 'Urgent, Low Impact',
              tasks: q3Delegate,
              color: const Color(0xFFF97316),
              icon: Icons.speed_rounded,
            ),
            _QuadrantData(
              index: 3,
              code: 'Q4',
              title: 'Eliminate / Backlog',
              subtitle: 'Neither Urgent Nor Critical',
              tasks: q4Eliminate,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              icon: Icons.delete_sweep_outlined,
            ),
          ];

          final currentQ = quadrants[_selectedQuadrantIndex];

          return Column(
            children: [
              // 1. 2x2 Interactive Mini Matrix Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                child: AspectRatio(
                  aspectRatio: 2.4,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildMiniQuadrant(quadrants[0], isDark)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildMiniQuadrant(quadrants[2], isDark)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildMiniQuadrant(quadrants[1], isDark)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildMiniQuadrant(quadrants[3], isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Active Quadrant Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentQ.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentQ.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: currentQ.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQ.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          currentQ.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${currentQ.tasks.length} tasks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Task List for Active Quadrant
              Expanded(
                child: currentQ.tasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks in ${currentQ.title}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 96),
                        itemCount: currentQ.tasks.length,
                        itemBuilder: (context, index) {
                          final task = currentQ.tasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF16161A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                                width: 0.8,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => TaskViewSheet.show(context, task),
                              leading: IconButton(
                                icon: const Icon(Icons.check_circle_outline_rounded),
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                tooltip: 'Complete',
                                onPressed: () async {
                                  await ref.read(taskRepositoryProvider).toggleTaskCompletion(task.id, true);
                                  ref.invalidate(tasksListProvider);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                task.isAllDay
                                    ? 'All Day'
                                    : (task.scheduledTime != null ? task.scheduledTime! : '${task.estimateMinutes}m'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18),
                                onSelected: (val) async {
                                  final repo = ref.read(taskRepositoryProvider);
                                  if (val == 'q1') {
                                    await repo.updateTask(task.copyWith(priority: TaskPriority.urgent, isTopPriority: true));
                                  } else if (val == 'q2') {
                                    await repo.updateTask(task.copyWith(priority: TaskPriority.high, isTopPriority: false));
                                  } else if (val == 'q3') {
                                    await repo.updateTask(task.copyWith(priority: TaskPriority.medium, isTopPriority: false));
                                  } else if (val == 'q4') {
                                    await repo.updateTask(task.copyWith(priority: TaskPriority.low, isTopPriority: false));
                                  }
                                  ref.invalidate(tasksListProvider);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'q1', child: Text('Move to Q1: Do First')),
                                  const PopupMenuItem(value: 'q2', child: Text('Move to Q2: Schedule')),
                                  const PopupMenuItem(value: 'q3', child: Text('Move to Q3: Delegate')),
                                  const PopupMenuItem(value: 'q4', child: Text('Move to Q4: Eliminate')),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildMiniQuadrant(_QuadrantData q, bool isDark) {
    final isSelected = _selectedQuadrantIndex == q.index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedQuadrantIndex = q.index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? q.color.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark ? const Color(0xFF16161A) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? q.color : (isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA)),
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(q.icon, size: 16, color: q.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${q.code} · ${q.title}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? q.color : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${q.tasks.length} items',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadrantData {
  final int index;
  final String code;
  final String title;
  final String subtitle;
  final List<TaskItem> tasks;
  final Color color;
  final IconData icon;

  _QuadrantData({
    required this.index,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.color,
    required this.icon,
  });
}
