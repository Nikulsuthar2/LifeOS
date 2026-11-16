import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/models/focus_session.dart';
import 'package:life_os/core/models/habit.dart';
import 'package:life_os/core/models/roadmap.dart';
import 'package:life_os/core/models/task.dart';
import 'package:life_os/features/learning/repositories/roadmap_repository.dart';
import 'package:life_os/features/tasks/repositories/task_repository.dart';
import 'package:life_os/features/track/focus/repositories/focus_repository.dart';
import 'package:life_os/features/track/habits/repositories/habit_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  group('LifeOS Core Domain & Repositories Test', () {
    setUp(() async {
      await AppDatabase.instance.initForTest();
    });

    test('Initial database seed populates roadmaps, tasks, and habits', () async {
      final db = await AppDatabase.instance.database;
      final taskCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks'));
      final roadmapCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM roadmaps'));
      final habitCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM habits'));

      expect(taskCount, greaterThanOrEqualTo(4));
      expect(roadmapCount, greaterThanOrEqualTo(1));
      expect(habitCount, greaterThanOrEqualTo(5));
    });

    test('Learning Roadmap: generates study task for today and updates topic progress', () async {
      final db = await AppDatabase.instance.database;
      final roadmapRepo = RoadmapRepository();

      // Query topic 'Binary Trees & Graph Traversals'
      final topicRows = await db.query('topics', where: "title LIKE ?", whereArgs: ['%Binary Trees%']);
      expect(topicRows.isNotEmpty, isTrue);

      final topic = Topic.fromMap(topicRows.first);
      expect(topic.title, contains('Binary Trees'));

      // Generate task from topic
      final taskId = await roadmapRepo.createTaskFromTopic(topic, roadmapTitle: 'Computer Science');
      expect(taskId.isNotEmpty, isTrue);

      // Verify task was inserted in database with roadmap link
      final taskRows = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
      expect(taskRows.isNotEmpty, isTrue);
      expect(taskRows.first['roadmap_topic_id'], topic.id);
      expect(taskRows.first['is_top_priority'], 1);
    });

    test('Focus Session: records time and propagates actual minutes to linked topic and task', () async {
      final db = await AppDatabase.instance.database;
      final focusRepo = FocusRepository();

      final topicRows = await db.query('topics', limit: 1);
      final topicId = topicRows.first['id'] as String;
      final initialMinutes = (topicRows.first['actual_minutes_spent'] as int?) ?? 0;

      final session = FocusSession(
        id: 'test-session-1',
        title: 'Deep Focus Test',
        topicId: topicId,
        startedAt: DateTime.now().subtract(const Duration(minutes: 50)),
        endedAt: DateTime.now(),
        durationSeconds: 50 * 60, // 50 mins
        sessionType: 'focus',
      );

      await focusRepo.saveFocusSession(session);

      final updatedTopicRows = await db.query('topics', where: 'id = ?', whereArgs: [topicId]);
      final updatedMinutes = updatedTopicRows.first['actual_minutes_spent'] as int;
      expect(updatedMinutes, equals(initialMinutes + 50));
    });

    test('Habit Tracking: toggles completion and calculates streaks', () async {
      final habitRepo = HabitRepository();
      final habitsWithStatus = await habitRepo.getHabitsWithStatus();

      expect(habitsWithStatus.isNotEmpty, isTrue);
      final firstHabit = habitsWithStatus.first;
      expect(firstHabit.streakDays, greaterThan(0));

      // Toggle habit
      await habitRepo.toggleHabitCompletion(firstHabit.habit.id);
      final updatedList = await habitRepo.getHabitsWithStatus();
      final updatedHabit = updatedList.firstWhere((h) => h.habit.id == firstHabit.habit.id);
      expect(updatedHabit.isCompletedToday, !firstHabit.isCompletedToday);
    });

    test('Task Management: marks task complete and updates today metrics', () async {
      final taskRepo = TaskRepository();
      final tasks = await taskRepo.getTasks(status: 'pending');
      expect(tasks.isNotEmpty, isTrue);

      final taskToComplete = tasks.first;
      await taskRepo.toggleTaskCompletion(taskToComplete.id, true);

      final updatedTask = await taskRepo.getTaskById(taskToComplete.id);
      expect(updatedTask?.isCompleted, isTrue);

      final metrics = await taskRepo.getTodayTaskMetrics();
      expect(metrics['completed'], greaterThan(0));
    });

    test('Task Recurrence: monthly repeating task appears on Nov 6, Dec 6, Jan 6 and stops after Jan 31', () async {
      final taskRepo = TaskRepository();
      final recurringTask = TaskItem(
        id: 'recurring-monthly-task',
        title: 'Monthly Financial Audit',
        dueDate: DateTime(2026, 11, 6),
        recurrence: 'monthly',
        recurrenceEndDate: DateTime(2027, 1, 31),
      );

      await taskRepo.insertTask(recurringTask);

      // Check Nov 6 (start date)
      final novTasks = await taskRepo.getTasksForDate(DateTime(2026, 11, 6));
      expect(novTasks.any((t) => t.title == 'Monthly Financial Audit'), isTrue);

      // Check Dec 6 (recurring month 1)
      final decTasks = await taskRepo.getTasksForDate(DateTime(2026, 12, 6));
      expect(decTasks.any((t) => t.title == 'Monthly Financial Audit'), isTrue);

      // Check Jan 6 (recurring month 2)
      final janTasks = await taskRepo.getTasksForDate(DateTime(2027, 1, 6));
      expect(janTasks.any((t) => t.title == 'Monthly Financial Audit'), isTrue);

      // Check Feb 6 (past recurrenceEndDate of Jan 31)
      final febTasks = await taskRepo.getTasksForDate(DateTime(2027, 2, 6));
      expect(febTasks.any((t) => t.title == 'Monthly Financial Audit'), isFalse);
    });

    test('Habit 3-State Cycle & Restart: pending -> done -> fail -> pending and restart resets logs', () async {
      final habitRepo = HabitRepository();
      final habitsWithStatus = await habitRepo.getHabitsWithStatus();
      final habit = habitsWithStatus.first.habit;

      const testDateStr = '2026-11-20';

      // 1. Initial state without log is pending
      // Cycle: pending -> done
      final s1 = await habitRepo.cycleHabitDayStatus(habit.id, testDateStr);
      expect(s1, HabitDayStatus.done);

      // Cycle: done -> fail
      final s2 = await habitRepo.cycleHabitDayStatus(habit.id, testDateStr);
      expect(s2, HabitDayStatus.fail);

      // Cycle: fail -> pending
      final s3 = await habitRepo.cycleHabitDayStatus(habit.id, testDateStr);
      expect(s3, HabitDayStatus.pending);

      // 2. Set to done, verify month logs
      await habitRepo.setHabitDayStatus(habit.id, testDateStr, HabitDayStatus.done);
      final monthResult = await habitRepo.getMonthLogs(habit.id, 2026, 11);
      expect(monthResult.dayStatuses[testDateStr], HabitDayStatus.done);

      // 3. Restart habit progress
      await habitRepo.restartHabitProgress(habit.id);
      final restartedHabit = await habitRepo.getHabitById(habit.id);
      expect(restartedHabit, isNotNull);
      final monthResultAfterRestart = await habitRepo.getMonthLogs(habit.id, 2026, 11);
      expect(monthResultAfterRestart.dayStatuses[testDateStr], isNull);
    });

    test('Habit Progress up to Current Date: week tracking considers only days up to today', () async {
      final habitRepo = HabitRepository();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));

      // Query habits with weekDate = today
      final habitsWithStatus = await habitRepo.getHabitsWithStatus(weekDate: today);
      final firstHabit = habitsWithStatus.first;

      // Eligible days in current week should equal elapsed days up to today
      final expectedEligible = today.weekday;
      expect(firstHabit.weekEnabledCount, equals(expectedEligible));

      // Future days in current week should NOT be unlocked
      for (int i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        if (d.isAfter(today)) {
          expect(firstHabit.weekDayEnabled[i], isFalse);
        } else {
          expect(firstHabit.weekDayEnabled[i], isTrue);
        }
      }
    });

    test('Habit Statistics: starting a habit today and completing today yields 100% score', () async {
      final habitRepo = HabitRepository();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      final newHabit = Habit(
        id: 'new-habit-started-today',
        title: 'Drink 2L Water',
        category: 'Health',
        startDate: today,
      );

      await habitRepo.insertHabit(newHabit);

      // Initially with no logs, overall score is 0%
      final initialStats = await habitRepo.getHabitDetailedStats(newHabit.id);
      expect(initialStats.totalDaysTracked, equals(1));
      expect(initialStats.timesCompletedAllTime, equals(0));
      expect(initialStats.overallScorePercentage, equals(0));

      // Mark today as done
      await habitRepo.setHabitDayStatus(newHabit.id, todayStr, HabitDayStatus.done);

      // Detailed stats should now show 100% (1 completed out of 1 active day)
      final statsAfterDone = await habitRepo.getHabitDetailedStats(newHabit.id);
      expect(statsAfterDone.totalDaysTracked, equals(1));
      expect(statsAfterDone.timesCompletedAllTime, equals(1));
      expect(statsAfterDone.overallScorePercentage, equals(100));
      expect(statsAfterDone.currentStreak, equals(1));
    });
  });
}
