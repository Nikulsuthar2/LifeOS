import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/models/task.dart';
import 'package:life_os/core/widgets/metric_card.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
import 'package:life_os/features/tasks/screens/task_detail_screen.dart';
import 'package:life_os/features/tasks/widgets/create_task_sheet.dart';
import 'package:life_os/features/tasks/widgets/task_calendar_view.dart';
import 'package:life_os/features/tasks/widgets/task_card.dart';

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
  });
}
