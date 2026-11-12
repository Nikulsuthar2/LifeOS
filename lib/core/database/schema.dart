class DatabaseSchema {
  static const List<String> createTables = [
    '''
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      status TEXT NOT NULL DEFAULT 'todo',
      priority TEXT NOT NULL DEFAULT 'medium',
      due_date TEXT,
      scheduled_time TEXT,
      estimate_minutes INTEGER DEFAULT 30,
      actual_minutes INTEGER DEFAULT 0,
      project_id TEXT,
      goal_id TEXT,
      roadmap_topic_id TEXT,
      is_top_priority INTEGER DEFAULT 0,
      recurrence TEXT DEFAULT 'none',
      completed_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS subtasks (
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      title TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      position INTEGER DEFAULT 0,
      FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS habits (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      category TEXT DEFAULT 'General',
      tracking_type TEXT DEFAULT 'boolean',
      target_value REAL DEFAULT 1.0,
      unit TEXT DEFAULT 'times',
      frequency TEXT DEFAULT 'daily',
      icon TEXT DEFAULT 'check_circle_outline',
      color INTEGER DEFAULT 4284704497,
      is_archived INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS habit_logs (
      id TEXT PRIMARY KEY,
      habit_id TEXT NOT NULL,
      date_str TEXT NOT NULL,
      value REAL DEFAULT 0.0,
      is_completed INTEGER DEFAULT 0,
      notes TEXT,
      FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS focus_sessions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      task_id TEXT,
      topic_id TEXT,
      started_at TEXT NOT NULL,
      ended_at TEXT,
      duration_seconds INTEGER DEFAULT 1500,
      session_type TEXT DEFAULT 'focus',
      notes TEXT,
      is_completed INTEGER DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS roadmaps (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      category TEXT DEFAULT 'Tech',
      color INTEGER DEFAULT 4284704497,
      icon TEXT DEFAULT 'school',
      status TEXT DEFAULT 'active',
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS roadmap_stages (
      id TEXT PRIMARY KEY,
      roadmap_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      position INTEGER DEFAULT 0,
      FOREIGN KEY (roadmap_id) REFERENCES roadmaps (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS topics (
      id TEXT PRIMARY KEY,
      stage_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      position INTEGER DEFAULT 0,
      status TEXT DEFAULT 'available',
      estimated_hours REAL DEFAULT 2.0,
      actual_minutes_spent INTEGER DEFAULT 0,
      prerequisite_topic_id TEXT,
      FOREIGN KEY (stage_id) REFERENCES roadmap_stages (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS lessons (
      id TEXT PRIMARY KEY,
      topic_id TEXT NOT NULL,
      title TEXT NOT NULL,
      position INTEGER DEFAULT 0,
      is_completed INTEGER DEFAULT 0,
      FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS topic_resources (
      id TEXT PRIMARY KEY,
      topic_id TEXT NOT NULL,
      title TEXT NOT NULL,
      resource_type TEXT DEFAULT 'url',
      url TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS goals (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      category TEXT DEFAULT 'Career',
      target_date TEXT,
      status TEXT DEFAULT 'active',
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS milestones (
      id TEXT PRIMARY KEY,
      goal_id TEXT NOT NULL,
      title TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      due_date TEXT,
      FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      category_id TEXT,
      goal_id TEXT,
      status TEXT DEFAULT 'active',
      target_date TEXT,
      color INTEGER DEFAULT 4284704497,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS schedule_blocks (
      id TEXT PRIMARY KEY,
      task_id TEXT,
      title TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      date_str TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS journal_entries (
      id TEXT PRIMARY KEY,
      date_str TEXT NOT NULL,
      mood TEXT DEFAULT 'good',
      went_well TEXT,
      could_improve TEXT,
      lessons_learned TEXT,
      random_thoughts TEXT,
      created_at TEXT NOT NULL
    );
    '''
  ];

  static const List<String> createIndices = [
    'CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);',
    'CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);',
    'CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);',
    'CREATE INDEX IF NOT EXISTS idx_subtasks_task ON subtasks(task_id);',
    'CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_focus_sessions_started ON focus_sessions(started_at);',
    'CREATE INDEX IF NOT EXISTS idx_topics_stage ON topics(stage_id);',
    'CREATE INDEX IF NOT EXISTS idx_lessons_topic ON lessons(topic_id);',
    'CREATE INDEX IF NOT EXISTS idx_schedule_blocks_date ON schedule_blocks(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date_str);',
  ];
}

