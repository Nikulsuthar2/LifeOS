import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class InitialDatabaseSeed {
  static Future<void> seed(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // 1. Goals & Projects
    final goalId = uuid.v4();
    await db.insert('goals', {
      'id': goalId,
      'title': 'Master Systems & AI Engineering',
      'description': 'Build strong foundational computer science knowledge and modern AI/ML systems capability.',
      'category': 'Career',
      'target_date': now.add(const Duration(days: 365)).toIso8601String(),
      'status': 'active',
      'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
    });

    final m1Id = uuid.v4();
    final m2Id = uuid.v4();
    final m3Id = uuid.v4();
    await db.insert('milestones', {
      'id': m1Id,
      'goal_id': goalId,
      'title': 'Complete Data Structures & Algorithms Core',
      'is_completed': 0,
      'due_date': now.add(const Duration(days: 60)).toIso8601String(),
    });
    await db.insert('milestones', {
      'id': m2Id,
      'goal_id': goalId,
      'title': 'Build and ship LifeOS Cross-Platform App',
      'is_completed': 1,
      'due_date': now.toIso8601String(),
    });
    await db.insert('milestones', {
      'id': m3Id,
      'goal_id': goalId,
      'title': 'Deploy Production AI Agent Pipeline',
      'is_completed': 0,
      'due_date': now.add(const Duration(days: 180)).toIso8601String(),
    });

    final projectId = uuid.v4();
    await db.insert('projects', {
      'id': projectId,
      'title': 'Life OS Development',
      'description': 'Personal productivity and life management system in Flutter.',
      'category_id': 'Dev',
      'goal_id': goalId,
      'status': 'active',
      'target_date': now.add(const Duration(days: 14)).toIso8601String(),
      'color': 0xFF6366F1,
      'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
    });

    // 2. Learning Roadmap: Computer Science & AI
    final roadmapId = uuid.v4();
    await db.insert('roadmaps', {
      'id': roadmapId,
      'title': 'Computer Science & AI Foundations',
      'description': 'Rigorous, structured learning path from algorithmic foundations to modern AI agents.',
      'category': 'Computer Science',
      'color': 0xFF6366F1,
      'icon': 'terminal',
      'status': 'active',
      'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
    });

    // Stages
    final stage1Id = uuid.v4();
    final stage2Id = uuid.v4();
    final stage3Id = uuid.v4();
    final stage4Id = uuid.v4();

    await db.insert('roadmap_stages', {
      'id': stage1Id,
      'roadmap_id': roadmapId,
      'title': 'Stage 1: Programming Fundamentals',
      'description': 'Language fundamentals, OOP, memory, and complexity.',
      'position': 0,
    });
    await db.insert('roadmap_stages', {
      'id': stage2Id,
      'roadmap_id': roadmapId,
      'title': 'Stage 2: Data Structures & Algorithms',
      'description': 'Core computational data structures, graph theory, dynamic programming.',
      'position': 1,
    });
    await db.insert('roadmap_stages', {
      'id': stage3Id,
      'roadmap_id': roadmapId,
      'title': 'Stage 3: Systems & Networks',
      'description': 'Operating systems, concurrency, distributed storage, and computer networks.',
      'position': 2,
    });
    await db.insert('roadmap_stages', {
      'id': stage4Id,
      'roadmap_id': roadmapId,
      'title': 'Stage 4: Machine Learning & Generative AI',
      'description': 'Neural architectures, transformers, fine-tuning, and agent loops.',
      'position': 3,
    });

    // Stage 1 Topics (Completed)
    final top1_1 = uuid.v4();
    await db.insert('topics', {
      'id': top1_1,
      'stage_id': stage1Id,
      'title': 'Variables, Types & Memory Model',
      'description': 'Stack vs Heap, pointers/references, immutability, type systems.',
      'position': 0,
      'status': 'completed',
      'estimated_hours': 4.0,
      'actual_minutes_spent': 280,
    });
    final top1_2 = uuid.v4();
    await db.insert('topics', {
      'id': top1_2,
      'stage_id': stage1Id,
      'title': 'Object-Oriented & Functional Paradigms',
      'description': 'Polymorphism, composition over inheritance, pure functions, closures.',
      'position': 1,
      'status': 'completed',
      'estimated_hours': 6.0,
      'actual_minutes_spent': 390,
    });

    // Stage 2 Topics (In Progress)
    final top2_1 = uuid.v4();
    await db.insert('topics', {
      'id': top2_1,
      'stage_id': stage2Id,
      'title': 'Arrays, Strings & Two Pointers',
      'description': 'Prefix sums, sliding window, fast/slow pointers, amortized analysis.',
      'position': 0,
      'status': 'completed',
      'estimated_hours': 8.0,
      'actual_minutes_spent': 520,
    });

    final targetStudyTopicId = uuid.v4(); // Trees & Graphs - current focus topic!
    await db.insert('topics', {
      'id': targetStudyTopicId,
      'stage_id': stage2Id,
      'title': 'Binary Trees & Graph Traversals',
      'description': 'Tree recursion, DFS vs BFS, BST invariants, LCA, cycle detection.',
      'position': 1,
      'status': 'in_progress',
      'estimated_hours': 10.0,
      'actual_minutes_spent': 210,
    });

    // Lessons for Trees
    final l1 = uuid.v4();
    final l2 = uuid.v4();
    final l3 = uuid.v4();
    final l4 = uuid.v4();
    await db.insert('lessons', {
      'id': l1,
      'topic_id': targetStudyTopicId,
      'title': 'Binary Search Tree properties & validate BST',
      'position': 0,
      'is_completed': 1,
    });
    await db.insert('lessons', {
      'id': l2,
      'topic_id': targetStudyTopicId,
      'title': 'Breadth-First Search (Level Order Traversal) using Queue',
      'position': 1,
      'is_completed': 1,
    });
    await db.insert('lessons', {
      'id': l3,
      'topic_id': targetStudyTopicId,
      'title': 'Depth-First Search (Pre, In, Post-order) iterative & recursive',
      'position': 2,
      'is_completed': 0,
    });
    await db.insert('lessons', {
      'id': l4,
      'topic_id': targetStudyTopicId,
      'title': 'Lowest Common Ancestor in Binary Tree & BST',
      'position': 3,
      'is_completed': 0,
    });

    // Resources for Trees
    await db.insert('topic_resources', {
      'id': uuid.v4(),
      'topic_id': targetStudyTopicId,
      'title': 'MIT 6.006: Introduction to Algorithms - Lecture 6 Trees',
      'resource_type': 'video',
      'url': 'https://ocw.mit.edu',
      'notes': 'Crucial explanation on tree balance and AVL rotations.',
    });
    await db.insert('topic_resources', {
      'id': uuid.v4(),
      'topic_id': targetStudyTopicId,
      'title': 'NeetCode 150 - Trees Section',
      'resource_type': 'doc',
      'url': 'https://neetcode.io',
      'notes': 'Practice problems #104, #226, #102, #235.',
    });

    final top2_3 = uuid.v4();
    await db.insert('topics', {
      'id': top2_3,
      'stage_id': stage2Id,
      'title': 'Dynamic Programming & Memoization',
      'description': 'Optimal substructure, overlapping subproblems, top-down vs bottom-up.',
      'position': 2,
      'status': 'available',
      'estimated_hours': 12.0,
      'actual_minutes_spent': 0,
      'prerequisite_topic_id': targetStudyTopicId,
    });

    // Stage 3 & 4 topics (Available / Locked)
    await db.insert('topics', {
      'id': uuid.v4(),
      'stage_id': stage3Id,
      'title': 'Operating Systems & Concurrency',
      'description': 'Processes, threads, locks, semaphores, virtual memory.',
      'position': 0,
      'status': 'available',
      'estimated_hours': 10.0,
      'actual_minutes_spent': 0,
    });
    await db.insert('topics', {
      'id': uuid.v4(),
      'stage_id': stage4Id,
      'title': 'Transformers & Attention Mechanisms',
      'description': 'Self-attention, multi-head attention, decoder-only architectures, tokenization.',
      'position': 0,
      'status': 'locked',
      'estimated_hours': 15.0,
      'actual_minutes_spent': 0,
    });

    // 3. Tasks & Today's Priorities
    final task1Id = uuid.v4();
    await db.insert('tasks', {
      'id': task1Id,
      'title': 'Study Binary Search Trees & Solve 2 Tree Problems',
      'description': 'Complete lesson 3: iterative DFS traversals and LeetCode #102.',
      'status': 'in_progress',
      'priority': 'high',
      'due_date': now.toIso8601String(),
      'scheduled_time': '19:30',
      'estimate_minutes': 60,
      'actual_minutes': 35,
      'project_id': projectId,
      'goal_id': goalId,
      'roadmap_topic_id': targetStudyTopicId,
      'is_top_priority': 1, // TOP 1 PRIORITY
      'recurrence': 'none',
      'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final task2Id = uuid.v4();
    await db.insert('tasks', {
      'id': task2Id,
      'title': '30-minute cardio & strength routine',
      'description': 'Bodyweight routine, pushups, pullups, core.',
      'status': 'todo',
      'priority': 'medium',
      'due_date': now.toIso8601String(),
      'scheduled_time': '17:30',
      'estimate_minutes': 30,
      'actual_minutes': 0,
      'is_top_priority': 1, // TOP 2 PRIORITY
      'recurrence': 'daily',
      'created_at': now.subtract(const Duration(hours: 6)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final task3Id = uuid.v4();
    await db.insert('tasks', {
      'id': task3Id,
      'title': 'Read 15 pages of Designing Data-Intensive Apps',
      'description': 'Chapter 3: Storage engines, B-Trees vs LSM-Trees.',
      'status': 'todo',
      'priority': 'medium',
      'due_date': now.toIso8601String(),
      'scheduled_time': '21:30',
      'estimate_minutes': 30,
      'actual_minutes': 0,
      'is_top_priority': 1, // TOP 3 PRIORITY
      'recurrence': 'daily',
      'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final task4Id = uuid.v4();
    await db.insert('tasks', {
      'id': task4Id,
      'title': 'Design & Implement LifeOS Schema Architecture',
      'description': 'Relational SQLite architecture connecting roadmaps, tasks, and habits.',
      'status': 'completed',
      'priority': 'urgent',
      'due_date': now.toIso8601String(),
      'estimate_minutes': 90,
      'actual_minutes': 85,
      'project_id': projectId,
      'goal_id': goalId,
      'is_top_priority': 0,
      'completed_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'created_at': now.subtract(const Duration(hours: 8)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final task5Id = uuid.v4();
    await db.insert('tasks', {
      'id': task5Id,
      'title': 'Organize backlog and weekly sprint milestones',
      'description': 'Categorize project tickets and review upcoming deliverables.',
      'status': 'inbox',
      'priority': 'low',
      'estimate_minutes': 20,
      'actual_minutes': 0,
      'is_top_priority': 0,
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    // Subtasks for Task 1
    await db.insert('subtasks', {
      'id': uuid.v4(),
      'task_id': task1Id,
      'title': 'Review tree traversal visualizer',
      'is_completed': 1,
      'position': 0,
    });
    await db.insert('subtasks', {
      'id': uuid.v4(),
      'task_id': task1Id,
      'title': 'Implement iterative preorder traversal',
      'is_completed': 0,
      'position': 1,
    });
    await db.insert('subtasks', {
      'id': uuid.v4(),
      'task_id': task1Id,
      'title': 'Solve LeetCode #102 Level Order',
      'is_completed': 0,
      'position': 2,
    });

    // 4. Habits & Habit Logs
    final h1 = uuid.v4();
    final h2 = uuid.v4();
    final h3 = uuid.v4();
    final h4 = uuid.v4();
    final h5 = uuid.v4();

    final habitStartDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 4)));

    await db.insert('habits', {
      'id': h1,
      'title': 'Morning Deep Work',
      'description': 'Uninterrupted 45 min focus block.',
      'category': 'Study',
      'tracking_type': 'boolean',
      'target_value': 1.0,
      'unit': 'session',
      'frequency': 'daily',
      'days_of_week': '[1,2,3,4,5,6,7]',
      'time_of_day': 'morning',
      'priority': 'high',
      'start_date': habitStartDate,
      'icon': 'bolt',
      'color': 0xFF6366F1,
      'is_archived': 0,
      'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
    });
    await db.insert('habits', {
      'id': h2,
      'title': 'Daily Physical Exercise',
      'description': 'Workout, run or brisk walk.',
      'category': 'Health',
      'tracking_type': 'boolean',
      'target_value': 1.0,
      'unit': 'session',
      'frequency': 'daily',
      'days_of_week': '[1,2,3,4,5,6,7]',
      'time_of_day': 'morning',
      'priority': 'medium',
      'start_date': habitStartDate,
      'icon': 'fitness_center',
      'color': 0xFF10B981,
      'is_archived': 0,
      'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
    });
    await db.insert('habits', {
      'id': h3,
      'title': 'Read Books & Papers',
      'description': 'Target at least 15 pages a day.',
      'category': 'Reading',
      'tracking_type': 'numeric',
      'target_value': 15.0,
      'unit': 'pages',
      'frequency': 'daily',
      'days_of_week': '[1,2,3,4,5,6,7]',
      'time_of_day': 'afternoon',
      'priority': 'medium',
      'start_date': todayStr,
      'icon': 'menu_book',
      'color': 0xFFA855F7,
      'is_archived': 0,
      'created_at': now.toIso8601String(),
    });
    await db.insert('habits', {
      'id': h4,
      'title': 'Hydration (Water Intake)',
      'description': 'Keep hydrated throughout the day.',
      'category': 'Health',
      'tracking_type': 'numeric',
      'target_value': 2.5,
      'unit': 'L',
      'frequency': 'daily',
      'days_of_week': '[1,2,3,4,5,6,7]',
      'time_of_day': 'afternoon',
      'priority': 'low',
      'start_date': todayStr,
      'icon': 'water_drop',
      'color': 0xFF0EA5E9,
      'is_archived': 0,
      'created_at': now.toIso8601String(),
    });
    await db.insert('habits', {
      'id': h5,
      'title': 'Evening Reflection & Review',
      'description': 'Reflect on wins, improvements and plan tomorrow.',
      'category': 'Meditation',
      'tracking_type': 'boolean',
      'target_value': 1.0,
      'unit': 'reflection',
      'frequency': 'daily',
      'days_of_week': '[1,2,3,4,5,6,7]',
      'time_of_day': 'evening',
      'priority': 'medium',
      'start_date': todayStr,
      'icon': 'auto_awesome',
      'color': 0xFF8B5CF6,
      'is_archived': 0,
      'created_at': now.toIso8601String(),
    });

    // Seed habit logs for today (3 of 5 completed)
    await db.insert('habit_logs', {
      'id': uuid.v4(),
      'habit_id': h1,
      'date_str': todayStr,
      'value': 1.0,
      'is_completed': 1,
      'status': 'done',
    });
    await db.insert('habit_logs', {
      'id': h4,
      'habit_id': h4,
      'date_str': todayStr,
      'value': 2.5,
      'is_completed': 1,
      'status': 'done',
    });
    await db.insert('habit_logs', {
      'id': uuid.v4(),
      'habit_id': h3,
      'date_str': todayStr,
      'value': 15.0,
      'is_completed': 1,
      'status': 'done',
    });

    // Seed habit logs for past 4 days so streak is visible
    for (int i = 1; i <= 4; i++) {
      final pastDate = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      await db.insert('habit_logs', {
        'id': uuid.v4(),
        'habit_id': h1,
        'date_str': pastDate,
        'value': 1.0,
        'is_completed': 1,
        'status': 'done',
      });
      await db.insert('habit_logs', {
        'id': uuid.v4(),
        'habit_id': h2,
        'date_str': pastDate,
        'value': 1.0,
        'is_completed': 1,
        'status': 'done',
      });
      await db.insert('habit_logs', {
        'id': uuid.v4(),
        'habit_id': h3,
        'date_str': pastDate,
        'value': 15.0,
        'is_completed': 1,
        'status': 'done',
      });
      await db.insert('habit_logs', {
        'id': uuid.v4(),
        'habit_id': h4,
        'date_str': pastDate,
        'value': 2.5,
        'is_completed': 1,
      });
    }

    // 5. Focus Sessions (e.g. 85 min total today)
    await db.insert('focus_sessions', {
      'id': uuid.v4(),
      'title': 'LifeOS Architecture & Database Model',
      'task_id': task4Id,
      'topic_id': null,
      'started_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'ended_at': now.subtract(const Duration(hours: 2, minutes: 10)).toIso8601String(),
      'duration_seconds': 50 * 60, // 50 mins
      'session_type': 'focus',
      'notes': 'Completed schemas, keys and relationships.',
      'is_completed': 1,
    });
    await db.insert('focus_sessions', {
      'id': uuid.v4(),
      'title': 'Binary Trees DFS Review',
      'task_id': task1Id,
      'topic_id': targetStudyTopicId,
      'started_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'ended_at': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      'duration_seconds': 35 * 60, // 35 mins
      'session_type': 'focus',
      'notes': 'Reviewed BST invariants and recursion paths.',
      'is_completed': 1,
    });

    // 6. Schedule Blocks (Time blocking)
    await db.insert('schedule_blocks', {
      'id': uuid.v4(),
      'task_id': null,
      'title': 'Morning Routine & Healthy Breakfast',
      'start_time': '07:00',
      'end_time': '07:45',
      'date_str': todayStr,
      'is_completed': 1,
    });
    await db.insert('schedule_blocks', {
      'id': uuid.v4(),
      'task_id': task4Id,
      'title': 'Deep Work: LifeOS Architecture',
      'start_time': '09:00',
      'end_time': '10:30',
      'date_str': todayStr,
      'is_completed': 1,
    });
    await db.insert('schedule_blocks', {
      'id': uuid.v4(),
      'task_id': task2Id,
      'title': 'Exercise & Stretching',
      'start_time': '17:30',
      'end_time': '18:15',
      'date_str': todayStr,
      'is_completed': 0,
    });
    await db.insert('schedule_blocks', {
      'id': uuid.v4(),
      'task_id': task1Id,
      'title': 'Study: Binary Trees & Problem Solving',
      'start_time': '19:30',
      'end_time': '20:30',
      'date_str': todayStr,
      'is_completed': 0,
    });
    await db.insert('schedule_blocks', {
      'id': uuid.v4(),
      'task_id': task3Id,
      'title': 'Reading & Evening Reflection',
      'start_time': '21:30',
      'end_time': '22:00',
      'date_str': todayStr,
      'is_completed': 0,
    });

    // 7. Journal Entry for Yesterday
    await db.insert('journal_entries', {
      'id': uuid.v4(),
      'date_str': yesterdayStr,
      'mood': 'great',
      'went_well': 'Maintained high focus on algorithms and made solid progress on personal roadmap.',
      'could_improve': 'Need to step away from screens earlier before bedtime.',
      'lessons_learned': 'Consistent daily micro-sessions beat occasional weekend marathons.',
      'random_thoughts': 'Connecting learning roadmaps directly to daily tasks is a game changer.',
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    });
  }
}

