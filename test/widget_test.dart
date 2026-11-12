import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/models/task.dart';
import 'package:life_os/core/widgets/metric_card.dart';
import 'package:life_os/core/widgets/priority_badge.dart';
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

  testWidgets('TaskCard displays task title and metadata', (WidgetTester tester) async {
    final task = TaskItem(
      id: 'task-1',
      title: 'Study Binary Search Trees',
      priority: TaskPriority.high,
      estimateMinutes: 45,
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
    expect(find.text('45m'), findsOneWidget);
  });
}
