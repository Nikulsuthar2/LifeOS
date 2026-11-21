import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/daily_plan.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/daily_progress_summary.dart';
import '../../../core/widgets/quick_capture_sheet.dart';
import '../../../core/widgets/section_header.dart';
import '../../learning/providers/roadmap_provider.dart';
import '../../learning/screens/roadmaps_screen.dart';
import '../../learning/screens/topic_detail_screen.dart';
import '../../planning/providers/planning_provider.dart';
import '../../planning/widgets/schedule_timeline.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/widgets/task_card.dart';
import '../../tasks/widgets/task_view_sheet.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/habits/providers/habit_provider.dart';
import '../../gamification/widgets/unified_life_score_heatmap_card.dart';

/// Premium, action-oriented Home / Dashboard for Life OS.
/// Replaces oversized statistics with actionable priorities, quick habit toggles,
/// visual schedule timeline, and active learning roadmap integration.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showAddTimeBlockDialog(BuildContext context) {
    final titleController = TextEditingController();
    final startController = TextEditingController(text: '09:00');
    final endController = TextEditingController(text: '10:00');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Time Block'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Activity / Block Title',
                hintText: 'e.g. Deep Work: System Design',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    decoration: const InputDecoration(labelText: 'Start (e.g. 09:00)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: endController,
                    decoration: const InputDecoration(labelText: 'End (e.g. 10:30)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final now = DateTime.now();
              final dateStr = DateFormat('yyyy-MM-dd').format(now);
              final block = ScheduleBlock(
                id: const Uuid().v4(),
                title: title,
                startTime: startController.text.trim(),
                endTime: endController.text.trim(),
                dateStr: dateStr,
                isCompleted: false,
              );

              final repo = ref.read(planningRepositoryProvider);
              await repo.insertScheduleBlock(block);
              ref.invalidate(scheduleBlocksProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Add Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final dayDateStr = DateFormat('EEEE · MMM d').format(now).toUpperCase();

    // Data streams
    final taskMetricsAsync = ref.watch(todayTaskMetricsProvider);
    final focusMinutesAsync = ref.watch(todayFocusMinutesProvider);
    final habitMetricsAsync = ref.watch(todayHabitMetricsProvider);
    final topPrioritiesAsync = ref.watch(topPrioritiesProvider);
    final activeRoadmapAsync = ref.watch(activeRoadmapSpotlightProvider);
    final scheduleBlocksAsync = ref.watch(scheduleBlocksProvider);
    final habitsListAsync = ref.watch(habitsListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          onRefresh: () async {
            ref.invalidate(todayTaskMetricsProvider);
            ref.invalidate(todayFocusMinutesProvider);
            ref.invalidate(todayHabitMetricsProvider);
            ref.invalidate(topPrioritiesProvider);
            ref.invalidate(activeRoadmapSpotlightProvider);
            ref.invalidate(scheduleBlocksProvider);
            ref.invalidate(habitsListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Date, Calm Greeting, and Quick Capture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayDateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Make today count, one task at a time.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Quick Capture',
                      onPressed: () => QuickCaptureSheet.show(context),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        foregroundColor: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. One Compact Daily Progress Summary (Replaces 2x2 oversized KPI grid)
                DailyProgressSummary(
                  tasksCompleted: taskMetricsAsync.value?['completed'] ?? 0,
                  tasksTotal: taskMetricsAsync.value?['total'] ?? 0,
                  focusMinutes: focusMinutesAsync.value ?? 0,
                  habitsCompleted: habitMetricsAsync.value?['completed'] ?? 0,
                  habitsTotal: habitMetricsAsync.value?['total'] ?? 0,
                  roadmapProgress: (activeRoadmapAsync.value?['roadmap'] as Roadmap?)?.progressPercentage ?? 0.0,
                ),
                const SizedBox(height: AppSpacing.md),
                const UnifiedLifeScoreHeatmapCard(),
                const SizedBox(height: AppSpacing.md),

                // 2. Today's Top Priorities (Action-first hero section)
                SectionHeader(
                  title: "Today's Priorities",
                  subtitle: "High-leverage focus items",
                  actionLabel: "+ Add",
                  onAction: () => QuickCaptureSheet.show(context),
                ),
                topPrioritiesAsync.when(
                  data: (priorities) {
                    if (priorities.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'All priorities for today completed. Great momentum! ✨',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: priorities.map((task) {
                        return TaskCard(
                          task: task,
                          onTap: () => TaskViewSheet.show(context, task),
                          trailing: IconButton(
                            icon: const Icon(Icons.timer_outlined, size: 18),
                            tooltip: 'Focus on this task',
                            visualDensity: VisualDensity.compact,
                            color: primary,
                            onPressed: () {
                              ref.read(focusTimerProvider.notifier).linkTask(task.id, task.title);
                              ref.read(focusTimerProvider.notifier).setPreset(task.estimateMinutes, 'focus');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Focus timer primed for "${task.title}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text('Error loading priorities: $e'),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 3. Small Habit Summary: Fast Daily Habit Check-off Strip
                const SectionHeader(
                  title: "Today's Habits",
                  subtitle: "Consistency without punishment",
                ),
                habitsListAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: habits.map((hw) {
                          final isDone = hw.isCompletedToday;
                          final h = hw.habit;

                          return Container(
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isDone
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final repo = ref.read(habitRepositoryProvider);
                                    await repo.toggleHabitCompletion(h.id);
                                    ref.invalidate(habitsListProvider);
                                    ref.invalidate(todayHabitMetricsProvider);
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone ? AppColors.success : Colors.transparent,
                                      border: Border.all(
                                        color: isDone
                                            ? AppColors.success
                                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                        width: 1.8,
                                      ),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                        color: isDone
                                            ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    if (hw.streakDays > 0)
                                      Text(
                                        '🔥 ${hw.streakDays}d streak',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 4. Current Learning Activity (Roadmap Spotlight)
                SectionHeader(
                  title: "Active Learning",
                  subtitle: "Sequential skill roadmap",
                  actionLabel: "All roadmaps",
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoadmapsScreen()),
                    );
                  },
                ),
                activeRoadmapAsync.when(
                  data: (spotlight) {
                    if (spotlight == null) {
                      return const SizedBox.shrink();
                    }

                    final roadmap = spotlight['roadmap'] as Roadmap;
                    final stage = spotlight['stage'] as RoadmapStage?;
                    final topic = spotlight['topic'] as Topic?;

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                              Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 16, color: primary),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    roadmap.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(roadmap.progressPercentage * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: roadmap.progressPercentage,
                              minHeight: 4,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          if (topic != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        stage != null ? stage.title : 'Current Stage',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          topic.status.displayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    topic.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '${topic.completedLessonsCount} of ${topic.lessons.length} lessons completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () {
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
                                          icon: const Icon(Icons.arrow_forward, size: 14),
                                          label: const Text('Open Topic', style: TextStyle(fontSize: 12)),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          ref.read(focusTimerProvider.notifier).linkTopic(topic.id, topic.title);
                                          ref.read(focusTimerProvider.notifier).setPreset(50, 'focus');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Focus timer primed for "${topic.title}"')),
                                          );
                                        },
                                        icon: const Icon(Icons.timer_outlined, size: 14),
                                        label: const Text('Focus 50m', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 5. Today's Upcoming Schedule (Visual Timeline)
                SectionHeader(
                  title: "Today's Schedule",
                  subtitle: "Visual timeline blocks",
                  actionLabel: "+ Add Block",
                  onAction: () => _showAddTimeBlockDialog(context),
                ),
                scheduleBlocksAsync.when(
                  data: (blocks) => ScheduleTimelineWidget(
                    blocks: blocks,
                    onAddBlock: () => _showAddTimeBlockDialog(context),
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
