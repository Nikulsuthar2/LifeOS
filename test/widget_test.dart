import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/models/habit.dart';
import 'package:life_os/core/models/task.dart';
import 'package:life_os/core/utils/time_utils.dart';
import 'package:life_os/core/widgets/metric_card.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/features/tasks/providers/task_provider.dart';
import 'package:life_os/features/tasks/screens/task_detail_screen.dart';
import 'package:life_os/features/tasks/screens/tasks_screen.dart';
import 'package:life_os/features/tasks/widgets/create_task_sheet.dart';
import 'package:life_os/features/tasks/widgets/task_calendar_view.dart';
import 'package:life_os/features/tasks/widgets/task_card.dart';
import 'package:life_os/features/tasks/widgets/task_view_sheet.dart';
import 'package:life_os/features/tasks/widgets/week_calendar_bar.dart';
import 'package:life_os/features/track/habits/repositories/habit_repository.dart';
import 'package:life_os/features/track/habits/widgets/habit_card.dart';
import 'package:life_os/features/track/habits/widgets/habit_view_sheet.dart';
import 'package:life_os/shared/shell/main_navigation_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MetricCard displays value and title correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            title: 'Tasks completed',
            value: '4/6',
            icon: Icons.check_circle_outline,
            progress: 0.67,
          ),
        ),
      ),
    );

    expect(find.text('Tasks completed'), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('PriorityBadge renders appropriate priority label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriorityBadge(priority: TaskPriority.urgent),
        ),
      ),
    );

    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('TaskCard displays task title and metadata without description on list item', (WidgetTester tester) async {
    final task = TaskItem(
      id: 'task-1',
      title: 'Study Binary Search Trees',
      description: 'Hidden description notes that must not crowd the list item',
      priority: TaskPriority.high,
      estimateMinutes: 45,
      isAllDay: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskCard(task: task),
          ),
        ),
      ),
    );

    expect(find.text('Study Binary Search Trees'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('All Day'), findsOneWidget);
    // Description preview must not be present on the list item
    expect(find.text('Hidden description notes that must not crowd the list item'), findsNothing);
  });

  testWidgets('TaskCalendarView displays 4 view modes (Day, Week, Month, Schedule)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const TaskCalendarView(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('CreateTaskSheet renders comprehensive task fields and template action', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const CreateTaskSheet(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New Task'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('PRIORITY'), findsOneWidget);
    expect(find.text('All Day'), findsOneWidget);
    expect(find.text('Save as Template'), findsOneWidget);
    expect(find.text('Create Task'), findsOneWidget);
  });

  testWidgets('TaskDetailSheet renders cleanly with 20 minute estimate without dropdown crash', (WidgetTester tester) async {
    final task = TaskItem(
      id: 'task-20m',
      title: 'Read System Design Chapter',
      priority: TaskPriority.medium,
      estimateMinutes: 20, // Value that was throwing the DropdownButton exception
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskDetailSheet(task: task),
          ),
        ),
      ),
    );

    expect(find.text('Task Details'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('PRIORITY'), findsOneWidget);
    expect(find.text('All Day'), findsOneWidget);
    expect(find.text('Save as Template'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('WeekCalendarBar renders 7 weekday columns and toggles expand/collapse in-place', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WeekCalendarBar(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify 7-column weekday header
    expect(find.text('MON'), findsOneWidget);
    expect(find.text('TUE'), findsOneWidget);
    expect(find.text('WED'), findsOneWidget);
    expect(find.text('THU'), findsOneWidget);
    expect(find.text('FRI'), findsOneWidget);
    expect(find.text('SAT'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);

    // Down arrow is visible in collapsed mode
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);

    // Tap dropdown to expand
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    // Now up arrow is visible in expanded mode in the exact same component
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // Tap up arrow to collapse back
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('MainNavigationShell renders glassmorphic bar with Home, Tasks, Habits, More and prominent center Add button without Add label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );
    await tester.pump();

    // Verify 4 tab destination labels are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Verify prominent center Add button with add_rounded icon and hidden text label
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('Add'), findsNothing);
  });

  testWidgets('TaskViewSheet renders read-only task details and two action buttons', (WidgetTester tester) async {
    final task = TaskItem(
      id: 'task-preview-1',
      title: 'Review System Architecture',
      description: 'Check DB indexes and Riverpod providers',
      priority: TaskPriority.high,
      estimateMinutes: 45,
      isAllDay: false,
      scheduledTime: '10:00',
      subtasks: [
        Subtask(id: 'sub-1', taskId: 'task-preview-1', title: 'Verify migrations', isCompleted: true),
        Subtask(id: 'sub-2', taskId: 'task-preview-1', title: 'Bench query time', isCompleted: false),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskViewSheet(task: task),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify task title and description
    expect(find.text('Review System Architecture'), findsOneWidget);
    expect(find.text('Check DB indexes and Riverpod providers'), findsOneWidget);

    // Verify subtasks are present right below description
    expect(find.text('Verify migrations'), findsOneWidget);
    expect(find.text('Bench query time'), findsOneWidget);
    expect(find.text('SUBTASKS (1/2)'), findsOneWidget);

    // Verify two action buttons: Open in Focus / Pomodoro & Edit Task
    expect(find.text('Focus Pomodoro'), findsOneWidget);
    expect(find.text('Edit Task'), findsOneWidget);
  });

  testWidgets('Pulling down task list expands week bar to month view', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksListProvider.overrideWith((ref) => Future.value([])),
          weekTaskDatesProvider.overrideWith((ref) => Future.value({})),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially collapsed (down arrow visible, up arrow not visible)
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);

    // Pull down on empty state scroll view
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 120));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now expanded to month (up arrow visible)
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
  });

  testWidgets('HabitCard displays title, frequency, 7 days of week, and action buttons', (WidgetTester tester) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final habitWithStatus = HabitWithStatus(
      habit: Habit(
        id: 'habit-test-1',
        title: 'Morning 5km Run',
        category: 'Sport',
        frequency: 'daily',
        timeOfDay: 'morning',
        startDate: monday.subtract(const Duration(days: 10)),
      ),
      todayStatus: HabitDayStatus.done,
      streakDays: 5,
      bestStreakDays: 14,
      weekDays: weekDays,
      weekStatuses: const [
        HabitDayStatus.done,
        HabitDayStatus.done,
        HabitDayStatus.done,
        HabitDayStatus.fail,
        HabitDayStatus.done,
        HabitDayStatus.pending,
        HabitDayStatus.pending,
      ],
      weekDayEnabled: const [true, true, true, true, true, true, true],
      weekCompletedCount: 4,
      weekEnabledCount: 7,
      weekPercentage: 57,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HabitCard(habitWithStatus: habitWithStatus),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Habit Title and Frequency Subtitle
    expect(find.text('Morning 5km Run'), findsOneWidget);
    expect(find.text('Everyday · Morning'), findsOneWidget);
    expect(find.text('🔥 5d'), findsOneWidget);

    // Verify bottom count and percentage
    expect(find.text('4/7 days · 57%'), findsOneWidget);

    // Verify action buttons exist
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  testWidgets('HabitViewSheet displays quick details, states, and 3 detail navigation buttons', (WidgetTester tester) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final habitWithStatus = HabitWithStatus(
      habit: Habit(
        id: 'habit-test-2',
        title: 'Daily Meditation',
        description: 'Mindful breathing for 15 minutes',
        category: 'Meditation',
        frequency: 'daily',
        timeOfDay: 'morning',
      ),
      todayStatus: HabitDayStatus.done,
      streakDays: 7,
      bestStreakDays: 21,
      weekDays: weekDays,
      weekStatuses: List.filled(7, HabitDayStatus.done),
      weekDayEnabled: List.filled(7, true),
      weekCompletedCount: 7,
      weekEnabledCount: 7,
      weekPercentage: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HabitViewSheet(habitWithStatus: habitWithStatus),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Title & description
    expect(find.text('Daily Meditation'), findsOneWidget);
    expect(find.text('Mindful breathing for 15 minutes'), findsOneWidget);

    // Verify 3 prominent buttons: Calendar, Statistics, Edit
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('HabitCard in collapsed mode renders compact header and single 3-state checkbox without 7 weekdays row', (WidgetTester tester) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final habitWithStatus = HabitWithStatus(
      habit: Habit(
        id: 'habit-collapsed-test',
        title: 'Drink 2.5L Water',
        category: 'Health',
        frequency: 'daily',
        timeOfDay: 'afternoon',
      ),
      todayStatus: HabitDayStatus.done,
      streakDays: 4,
      bestStreakDays: 10,
      weekDays: weekDays,
      weekStatuses: List.filled(7, HabitDayStatus.done),
      weekDayEnabled: List.filled(7, true),
      weekCompletedCount: 1,
      weekEnabledCount: 1,
      weekPercentage: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HabitCard(habitWithStatus: habitWithStatus, isCollapsed: true),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Habit Title and Frequency Subtitle
    expect(find.text('Drink 2.5L Water'), findsOneWidget);
    expect(find.text('Everyday · Afternoon'), findsOneWidget);

    // Verify single 3-state checkbox is rendered with done icon (check)
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Verify 7 weekdays and bottom action buttons are NOT present in collapsed mode
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  test('TimeUtils converts 24-hr strings and hour integers to clean 12-hr AM/PM', () {
    expect(TimeUtils.formatTo12Hour('14:30'), '2:30 PM');
    expect(TimeUtils.formatTo12Hour('09:05'), '9:05 AM');
    expect(TimeUtils.formatTo12Hour('12:00'), '12:00 PM');
    expect(TimeUtils.formatTo12Hour('00:00'), '12:00 AM');
    expect(TimeUtils.formatTo12Hour(null), 'Anytime');

    expect(TimeUtils.formatHour(0), '12 AM');
    expect(TimeUtils.formatHour(9), '9 AM');
    expect(TimeUtils.formatHour(12), '12 PM');
    expect(TimeUtils.formatHour(14), '2 PM');
    expect(TimeUtils.formatHour(23), '11 PM');
  });

  testWidgets('TaskCard renders Top Focus star chip when isTopFocus is true', (WidgetTester tester) async {
    final topFocusTask = TaskItem(
      id: 'task-star-test',
      title: 'Review System Architecture',
      priority: TaskPriority.high,
      scheduledTime: '15:00',
      isTopPriority: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskCard(task: topFocusTask),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review System Architecture'), findsOneWidget);
    expect(find.text('3:00 PM'), findsOneWidget);
    expect(find.text('Top Focus'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });
}
