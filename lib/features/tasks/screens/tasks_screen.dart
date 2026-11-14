import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/task_provider.dart';
import '../widgets/create_task_sheet.dart';
import '../widgets/task_calendar_view.dart';
import '../widgets/task_card.dart';
import '../widgets/week_calendar_bar.dart';
import 'task_detail_screen.dart';

/// Clean, minimal, and typography-led Tasks workspace for Life OS.
/// Features:
/// - Snappy 7-day week calendar bar with month navigator
/// - AppBar view switch (List View vs. Google Calendar View)
/// - Two-section list view: Pending (All-day tasks first, then timed) & Completed at bottom
/// - Rectangular checkbox task items with generous whitespace
/// - Dedicated Task-only creation action
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              )
            : const Text('Tasks'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'Search tasks',
              onPressed: () => setState(() => _isSearching = true),
            ),

          // View switch icon: List View vs Calendar View
          IconButton(
            icon: Icon(
              viewMode == TaskViewMode.list
                  ? Icons.calendar_month_outlined
                  : Icons.view_agenda_outlined,
              size: 21,
              color: viewMode == TaskViewMode.calendar ? AppColors.primaryLight : null,
            ),
            tooltip: viewMode == TaskViewMode.list ? 'Switch to Calendar View' : 'Switch to List View',
            onPressed: () {
              ref.read(taskViewModeProvider.notifier).toggle();
            },
          ),

          // Inbox toggle button
          IconButton(
            icon: Icon(
              isInboxMode ? Icons.calendar_today_outlined : Icons.inbox_outlined,
              size: 20,
              color: isInboxMode ? AppColors.primaryLight : null,
            ),
            tooltip: isInboxMode ? 'View Calendar Days' : 'View Inbox',
            onPressed: () {
              ref.read(taskFilterProvider.notifier).setFilter(isInboxMode ? 'all' : 'inbox');
            },
          ),
        ],
      ),
      body: viewMode == TaskViewMode.calendar
          ? const TaskCalendarView()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Snappy 7-Day Week Calendar Bar (transparent, blends into page background)
                if (!isInboxMode) const WeekCalendarBar(),

                // 2. Day Header & Filter Pills
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isInboxMode ? 'Inbox' : _formatDayHeader(selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      // Compact Filter Pills
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FilterPill(
                            label: 'All',
                            isSelected: currentFilter == 'all',
                            onTap: () => ref.read(taskFilterProvider.notifier).setFilter('all'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterPill(
                            label: 'Pending',
                            isSelected: currentFilter == 'pending',
                            onTap: () => ref.read(taskFilterProvider.notifier).setFilter('pending'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _FilterPill(
                            label: 'Done',
                            isSelected: currentFilter == 'completed',
                            onTap: () => ref.read(taskFilterProvider.notifier).setFilter('completed'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // 3. Task List with Two Distinct Sections: Pending (All-Day first, then timed) & Completed
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
                        return EmptyState(
                          icon: isInboxMode ? Icons.inbox_outlined : Icons.calendar_today_outlined,
                          title: isInboxMode ? 'Inbox is empty' : 'No tasks for this day',
                          message: isInboxMode
                              ? 'Capture unscheduled thoughts, ideas, or action items.'
                              : 'Plan ahead or take a well-deserved break.',
                          buttonText: 'Add Task',
                          onButtonPressed: () => CreateTaskSheet.show(
                            context,
                            initialDate: isInboxMode ? null : selectedDate,
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

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 96),
                        children: [
                          // Pending Section
                          if (pendingTasks.isNotEmpty) ...[
                            if (completedTasks.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 2),
                                child: Text(
                                  'PENDING (${pendingTasks.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ),
                            ...pendingTasks.map((task) {
                              return TaskCard(
                                task: task,
                                onTap: () => TaskDetailSheet.show(context, task),
                              );
                            }),
                          ],

                          // Completed Section
                          if (completedTasks.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isCompletedExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isCompletedExpanded) ...[
                              const SizedBox(height: AppSpacing.xs),
                              ...completedTasks.map((task) {
                                return TaskCard(
                                  task: task,
                                  onTap: () => TaskDetailSheet.show(context, task),
                                );
                              }),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
