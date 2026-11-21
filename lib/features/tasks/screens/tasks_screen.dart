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

/// Material 3 Expressive Tasks workspace for Life OS.
/// Features:
/// - Uncluttered, typography-led M3 header with inline search & view switchers
/// - Seamless expandable calendar bar
/// - Material 3 SegmentedButton for All / Pending / Done filters
/// - Calm, spacious sections: Pending (All-Day first, then timed) & Completed at bottom
/// - Tactile squircle checkboxes with generous whitespace
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
  DateTime? _lastExpandTime;

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
    final primary = Theme.of(context).colorScheme.primary;
    final selectedDate = ref.watch(selectedTaskDateProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final viewMode = ref.watch(taskViewModeProvider);
    final tasksAsync = ref.watch(tasksListProvider);

    final isInboxMode = currentFilter == 'inbox';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF0F0F4),
                          hintText: 'Search tasks...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE2E2E6),
                              width: 0.8,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF2C2C32) : const Color(0xFFE2E2E6),
                              width: 0.8,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
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
              icon: const Icon(Icons.search_rounded, size: 22),
              tooltip: 'Search tasks',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: Icon(
                viewMode == TaskViewMode.list
                    ? Icons.calendar_month_rounded
                    : Icons.format_list_bulleted_rounded,
                size: 22,
                color: viewMode == TaskViewMode.calendar ? primary : null,
              ),
              tooltip: viewMode == TaskViewMode.list ? 'Switch to Calendar View' : 'Switch to List View',
              onPressed: () => ref.read(taskViewModeProvider.notifier).toggle(),
            ),
            IconButton(
              icon: Icon(
                isInboxMode ? Icons.today_rounded : Icons.inbox_rounded,
                size: 22,
                color: isInboxMode ? primary : null,
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
                // 1. Expandable Calendar Bar
                if (!isInboxMode) const WeekCalendarBar(),

                // 2. Day Label Row (Clean, spacious, typography-led)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 8),
                  child: Row(
                    children: [
                      Text(
                        isInboxMode
                            ? 'ALL INBOX TASKS'
                            : _formatDayHeader(selectedDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const Spacer(),
                      tasksAsync.maybeWhen(
                        data: (tasks) {
                          final pendingCount = tasks.where((t) => !t.isCompleted).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFEAEAEE),
                              borderRadius: BorderRadius.circular(12),
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

                // 3. Dedicated Filter Row: M3 Expressive SegmentedButton
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 2, AppSpacing.lg, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.apps_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'pending',
                          label: Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.radio_button_unchecked_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'completed',
                          label: Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.check_circle_rounded, size: 16),
                        ),
                      ],
                      selected: {
                        (currentFilter == 'all' || currentFilter == 'pending' || currentFilter == 'completed')
                            ? currentFilter
                            : 'all'
                      },
                      onSelectionChanged: (newSelection) {
                        ref.read(taskFilterProvider.notifier).setFilter(newSelection.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: isDark ? const Color(0xFF28282E) : const Color(0xFFE2E2E8),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Task List with Two Distinct Sections: Pending & Completed
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
                            final isExpanded = ref.read(weekCalendarExpandedProvider);
                            if (!isExpanded) {
                              // Pull down when collapsed -> expand to month
                              bool shouldExpand = false;
                              if (notification is OverscrollNotification && notification.overscroll < -12) {
                                shouldExpand = true;
                              } else if (notification is ScrollUpdateNotification &&
                                  notification.metrics.pixels < -20 &&
                                  (notification.scrollDelta ?? 0) < 0) {
                                shouldExpand = true;
                              }
                              if (shouldExpand) {
                                _lastExpandTime = DateTime.now();
                                ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                              }
                            } else {
                              // Scroll up when expanded -> collapse back to week
                              // 1. Debounce cooldown: ignore ANY scroll updates within 600ms of expanding
                              // so the bounce-back from a large pull-down will NEVER trigger collapse
                              final now = DateTime.now();
                              if (_lastExpandTime != null &&
                                  now.difference(_lastExpandTime!).inMilliseconds < 600) {
                                return false;
                              }

                              // 2. Only collapse on genuine user touch drag up from positive scroll position
                              if (notification is ScrollUpdateNotification &&
                                  notification.dragDetails != null &&
                                  notification.metrics.pixels >= 10 &&
                                  (notification.scrollDelta ?? 0) > 6) {
                                ref.read(weekCalendarExpandedProvider.notifier).setExpanded(false);
                              } else if (notification is OverscrollNotification &&
                                  notification.dragDetails != null &&
                                  notification.overscroll > 10) {
                                ref.read(weekCalendarExpandedProvider.notifier).setExpanded(false);
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: SizedBox(
                              height: 380,
                              child: EmptyState(
                                icon: isInboxMode ? Icons.inbox_rounded : Icons.calendar_today_rounded,
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
                          final isExpanded = ref.read(weekCalendarExpandedProvider);
                          if (!isExpanded) {
                            // Pull down when collapsed -> expand to month
                            bool shouldExpand = false;
                            if (notification is OverscrollNotification && notification.overscroll < -12) {
                              shouldExpand = true;
                            } else if (notification is ScrollUpdateNotification &&
                                notification.metrics.pixels < -20 &&
                                (notification.scrollDelta ?? 0) < 0) {
                              shouldExpand = true;
                            }
                            if (shouldExpand) {
                              _lastExpandTime = DateTime.now();
                              ref.read(weekCalendarExpandedProvider.notifier).setExpanded(true);
                            }
                          } else {
                            // Scroll up when expanded -> collapse back to week
                            // 1. Debounce cooldown: ignore ANY scroll updates within 600ms of expanding
                            // so the bounce-back from a large pull-down will NEVER trigger collapse
                            final now = DateTime.now();
                            if (_lastExpandTime != null &&
                                now.difference(_lastExpandTime!).inMilliseconds < 600) {
                              return false;
                            }

                            // 2. Only collapse on genuine user touch drag up from positive scroll position
                            if (notification is ScrollUpdateNotification &&
                                notification.dragDetails != null &&
                                notification.metrics.pixels >= 10 &&
                                (notification.scrollDelta ?? 0) > 6) {
                              ref.read(weekCalendarExpandedProvider.notifier).setExpanded(false);
                            } else if (notification is OverscrollNotification &&
                                notification.dragDetails != null &&
                                notification.overscroll > 10) {
                              ref.read(weekCalendarExpandedProvider.notifier).setExpanded(false);
                            }
                          }
                          return false;
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 100),
                          children: [
                            // 1. Pending Section (Always present by default)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 6),
                              child: Text(
                                'PENDING (${pendingTasks.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
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
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'No pending tasks',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.lg),

                            // 2. Completed Section (Always present by default)
                            InkWell(
                              onTap: () {
                                setState(() => _isCompletedExpanded = !_isCompletedExpanded);
                              },
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      'COMPLETED (${completedTasks.length})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _isCompletedExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
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
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No completed tasks yet',
                                    style: TextStyle(
                                      fontSize: 13,
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
