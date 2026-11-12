import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/quick_capture_sheet.dart';
import '../../../core/widgets/section_header.dart';
import '../../learning/providers/roadmap_provider.dart';
import '../../learning/screens/topic_detail_screen.dart';
import '../../planning/providers/planning_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/screens/task_detail_screen.dart';
import '../../tasks/widgets/task_card.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/habits/providers/habit_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dayDateStr = DateFormat('EEEE · MMM d').format(now).toUpperCase();

    // Providers
    final taskMetricsAsync = ref.watch(todayTaskMetricsProvider);
    final focusMinutesAsync = ref.watch(todayFocusMinutesProvider);
    final habitMetricsAsync = ref.watch(todayHabitMetricsProvider);
    final topPrioritiesAsync = ref.watch(topPrioritiesProvider);
    final activeRoadmapAsync = ref.watch(activeRoadmapSpotlightProvider);
    final scheduleBlocksAsync = ref.watch(scheduleBlocksProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayTaskMetricsProvider);
            ref.invalidate(todayFocusMinutesProvider);
            ref.invalidate(todayHabitMetricsProvider);
            ref.invalidate(topPrioritiesProvider);
            ref.invalidate(activeRoadmapSpotlightProvider);
            ref.invalidate(scheduleBlocksProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Day & Motivational greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayDateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 24,
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
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primaryLight),
                      tooltip: 'Quick Capture',
                      onPressed: () => QuickCaptureSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2x2 Metric Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    // Tasks Metric
                    taskMetricsAsync.when(
                      data: (m) {
                        final total = m['total'] ?? 0;
                        final done = m['completed'] ?? 0;
                        return MetricCard(
                          title: 'Tasks completed',
                          value: '$done/$total',
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.primaryLight,
                          progress: total > 0 ? done / total : 0.0,
                        );
                      },
                      loading: () => const MetricCard(
                        title: 'Tasks completed',
                        value: '...',
                        icon: Icons.check_circle_outline,
                      ),
                      error: (err, stack) => const MetricCard(
                        title: 'Tasks completed',
                        value: '0',
                        icon: Icons.check_circle_outline,
                      ),
                    ),

                    // Focus Time Metric
                    focusMinutesAsync.when(
                      data: (mins) => MetricCard(
                        title: 'Focus time today',
                        value: '$mins min',
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.pomodoro,
                      ),
                      loading: () => const MetricCard(
                        title: 'Focus time today',
                        value: '...',
                        icon: Icons.timer_outlined,
                      ),
                      error: (err, stack) => const MetricCard(
                        title: 'Focus time today',
                        value: '0 min',
                        icon: Icons.timer_outlined,
                      ),
                    ),

                    // Habits Completed Metric
                    habitMetricsAsync.when(
                      data: (h) {
                        final total = h['total'] ?? 0;
                        final done = h['completed'] ?? 0;
                        return MetricCard(
                          title: 'Habits completed',
                          value: '$done/$total',
                          icon: Icons.bolt,
                          iconColor: AppColors.accent,
                          progress: total > 0 ? done / total : 0.0,
                        );
                      },
                      loading: () => const MetricCard(
                        title: 'Habits completed',
                        value: '...',
                        icon: Icons.bolt,
                      ),
                      error: (err, stack) => const MetricCard(
                        title: 'Habits completed',
                        value: '0/0',
                        icon: Icons.bolt,
                      ),
                    ),

                    // Learning Session Metric
                    activeRoadmapAsync.when(
                      data: (spotlight) {
                        final roadmap = spotlight?['roadmap'] as Roadmap?;
                        final progress = roadmap?.progressPercentage ?? 0.0;
                        return MetricCard(
                          title: 'Roadmap progress',
                          value: '${(progress * 100).round()}%',
                          icon: Icons.school_outlined,
                          iconColor: AppColors.secondary,
                          progress: progress,
                        );
                      },
                      loading: () => const MetricCard(
                        title: 'Roadmap progress',
                        value: '...',
                        icon: Icons.school_outlined,
                      ),
                      error: (err, stack) => const MetricCard(
                        title: 'Roadmap progress',
                        value: '0%',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Priorities Section
                const SectionHeader(
                  title: "Today's Priorities",
                  subtitle: "Up to 3 high-leverage focus items",
                ),
                topPrioritiesAsync.when(
                  data: (priorities) {
                    if (priorities.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'All priorities completed for today! 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
                          onTap: () => TaskDetailSheet.show(context, task),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),

                // Active Learning Roadmap Spotlight
                const SectionHeader(
                  title: "Active Learning Roadmap",
                  subtitle: "Sequential skill progression",
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
                              Row(
                                children: [
                                  const Icon(Icons.school, size: 18, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    roadmap.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(roadmap.progressPercentage * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: roadmap.progressPercentage,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (topic != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                borderRadius: BorderRadius.circular(12),
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
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          topic.status.displayName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topic.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${topic.completedLessonsCount} of ${topic.lessons.length} lessons completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                          icon: const Icon(Icons.arrow_forward, size: 16),
                                          label: const Text('Open Topic', style: TextStyle(fontSize: 12)),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          ref.read(focusTimerProvider.notifier).linkTopic(topic.id, topic.title);
                                          ref.read(focusTimerProvider.notifier).setPreset(50, 'focus');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Focus timer prepared for "${topic.title}"')),
                                          );
                                        },
                                        icon: const Icon(Icons.timer_outlined, size: 16),
                                        label: const Text('Focus', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryLight,
                                          side: const BorderSide(color: AppColors.primary),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),

                // Today's Time Blocks / Schedule
                const SectionHeader(
                  title: "Today's Schedule",
                  subtitle: "Time-blocked commitments",
                ),
                scheduleBlocksAsync.when(
                  data: (blocks) {
                    if (blocks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No scheduled time blocks for today.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: blocks.map((b) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${b.startTime} - ${b.endTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  b.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: b.isCompleted ? TextDecoration.lineThrough : null,
                                    color: b.isCompleted
                                        ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: b.isCompleted,
                                activeColor: AppColors.success,
                                onChanged: (val) async {
                                  final repo = ref.read(planningRepositoryProvider);
                                  await repo.toggleScheduleBlock(b.id, val ?? false);
                                  ref.invalidate(scheduleBlocksProvider);
                                },
                              ),
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
        ),
      ),
    );
  }
}
