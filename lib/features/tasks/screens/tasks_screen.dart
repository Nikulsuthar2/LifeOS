import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/task_provider.dart';
import 'create_task_screen.dart';
import '../widgets/task_calendar_view.dart';
import '../widgets/task_card.dart';
import '../widgets/task_view_sheet.dart';
import '../widgets/week_calendar_bar.dart';

/// Minimal, modern Cupertino-inspired Tasks workspace for Life OS.
/// Features:
/// - Uncluttered, typography-led header with inline search & view switcher
/// - Seamless expandable calendar bar
/// - Smooth Cupertino sliding segmented control for filters
/// - Two calm sections: Pending (All-Day first, then timed) & Completed at bottom
/// - Tactile squircle checkboxes with generous whitespace
/// - Ergonomic "+ New Task" action
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isCompletedExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    final formatted = DateFormat('EEEE, MMM d').format(date);

    if (diff == 0) return 'Today · $formatted';
    if (diff == 1) return 'Tomorrow · $formatted';
    if (diff == -1) return 'Yesterday · $formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedTaskDateProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final viewMode = ref.watch(taskViewModeProvider);
    final tasksAsync = ref.watch(tasksListProvider);

    final isInboxMode = currentFilter == 'inbox';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      placeholderStyle: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                isInboxMode ? 'Inbox' : 'Tasks',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(CupertinoIcons.search, size: 20),
              tooltip: 'Search tasks',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: Icon(
                viewMode == TaskViewMode.list
                    ? CupertinoIcons.calendar
                    : CupertinoIcons.list_bullet,
                size: 20,
                color: viewMode == TaskViewMode.calendar ? AppColors.primaryLight : null,
              ),
              tooltip: viewMode == TaskViewMode.list ? 'Switch to Calendar View' : 'Switch to List View',
              onPressed: () => ref.read(taskViewModeProvider.notifier).toggle(),
            ),
            IconButton(
              icon: Icon(
                isInboxMode ? CupertinoIcons.calendar_today : CupertinoIcons.tray,
                size: 20,
                color: isInboxMode ? AppColors.primaryLight : null,
              ),
              tooltip: isInboxMode ? 'View Calendar Days' : 'View Inbox',
              onPressed: () {
                ref.read(taskFilterProvider.notifier).setFilter(isInboxMode ? 'all' : 'inbox');
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: viewMode == TaskViewMode.calendar
          ? const TaskCalendarView()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Expandable Calendar Bar (transparent, blends into background)
                if (!isInboxMode) const WeekCalendarBar(),

                // 2. Day Label Row (Clean, spacious, no wrapping)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 6),
                  child: Row(
                    children: [
                      Text(
                        isInboxMode
                            ? 'ALL INBOX TASKS'
                            : _formatDayHeader(selectedDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const Spacer(),
                      tasksAsync.maybeWhen(
                        data: (tasks) {
                          final pendingCount = tasks.where((t) => !t.isCompleted).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C20) : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // 3. Dedicated Filter Row: ONLY the Cupertino Sliding Segmented Control across the full row
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: (currentFilter == 'all' || currentFilter == 'pending' || currentFilter == 'completed')
                          ? currentFilter
                          : 'all',
                      backgroundColor: isDark ? const Color(0xFF161618) : const Color(0xFFE5E5EA),
                      thumbColor: isDark ? const Color(0xFF26262B) : Colors.white,
                      children: const {
                        'all': Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        'pending': Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        'completed': Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) ref.read(taskFilterProvider.notifier).setFilter(val);
                      },
                    ),
                  ),
                ),

                // 4. Task List with Two Distinct Sections: Pending (All-Day first, then timed) & Completed
                Expanded(
                  child: tasksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (tasks) {
                      final filtered = tasks.where((t) {
                        if (_searchQuery.isEmpty) return true;
                        return t.title.toLowerCase().contains(_searchQuery) ||
                            t.description.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (isInboxMode) return false;
                            if (notification is OverscrollNotification && notification.overscroll < -10) {
                              final isExpanded = ref.read(weekCalendarExpandedProvider);
                              if (!isExpanded) {
                                ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                              }
                            } else if (notification is ScrollUpdateNotification &&
                                notification.metrics.pixels < -20 &&
                                (notification.scrollDelta ?? 0) < 0) {
                              final isExpanded = ref.read(weekCalendarExpandedProvider);
                              if (!isExpanded) {
                                ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: SizedBox(
                              height: 380,
                              child: EmptyState(
                                icon: isInboxMode ? CupertinoIcons.tray : CupertinoIcons.calendar,
                                title: isInboxMode ? 'Inbox is empty' : 'No tasks for this day',
                                message: isInboxMode
                                    ? 'Capture unscheduled thoughts, ideas, or action items.'
                                    : 'Plan ahead or take a well-deserved break.',
                                buttonText: 'Add Task',
                                onButtonPressed: () => CreateTaskScreen.open(
                                  context,
                                  initialDate: isInboxMode ? null : selectedDate,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Split into Pending and Completed
                      final pendingTasks = filtered.where((t) => !t.isCompleted).toList();
                      final completedTasks = filtered.where((t) => t.isCompleted).toList();

                      // Sort pending tasks: All-Day tasks first, then timed tasks sorted by scheduled time
                      pendingTasks.sort((a, b) {
                        if (a.isAllDay != b.isAllDay) {
                          return a.isAllDay ? -1 : 1;
                        }
                        if (a.scheduledTime != null && b.scheduledTime != null) {
                          return a.scheduledTime!.compareTo(b.scheduledTime!);
                        }
                        if (a.scheduledTime != null) return -1;
                        if (b.scheduledTime != null) return 1;
                        return 0;
                      });

                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (isInboxMode) return false;
                          if (notification is OverscrollNotification && notification.overscroll < -10) {
                            final isExpanded = ref.read(weekCalendarExpandedProvider);
                            if (!isExpanded) {
                              ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                            }
                          } else if (notification is ScrollUpdateNotification &&
                              notification.metrics.pixels < -20 &&
                              (notification.scrollDelta ?? 0) < 0) {
                            final isExpanded = ref.read(weekCalendarExpandedProvider);
                            if (!isExpanded) {
                              ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                            }
                          }
                          return false;
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 96),
                          children: [
                            // 1. Pending Section (Always present by default)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 4),
                              child: Text(
                                'PENDING (${pendingTasks.length})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                            if (pendingTasks.isNotEmpty) ...[
                              ...pendingTasks.map((task) {
                                return TaskCard(
                                  task: task,
                                  onTap: () => TaskViewSheet.show(context, task),
                                );
                              }),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No pending tasks',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.md),

                            // 2. Completed Section (Always present by default)
                            InkWell(
                              onTap: () {
                                setState(() => _isCompletedExpanded = !_isCompletedExpanded);
                              },
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      'COMPLETED (${completedTasks.length})',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isCompletedExpanded
                                          ? CupertinoIcons.chevron_up
                                          : CupertinoIcons.chevron_down,
                                      size: 14,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isCompletedExpanded) ...[
                              if (completedTasks.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                ...completedTasks.map((task) {
                                  return TaskCard(
                                    task: task,
                                    onTap: () => TaskViewSheet.show(context, task),
                                  );
                                }),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    'No completed tasks yet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
