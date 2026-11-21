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
      is_all_day INTEGER DEFAULT 0,
      recurrence TEXT DEFAULT 'none',
      end_date TEXT,
      recurrence_end_date TEXT,
      completed_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS task_templates (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      priority TEXT DEFAULT 'medium',
      estimate_minutes INTEGER DEFAULT 30,
      is_all_day INTEGER DEFAULT 0,
      category TEXT DEFAULT 'General',
      subtasks_json TEXT,
      created_at TEXT NOT NULL
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
      category TEXT DEFAULT 'Health',
      tracking_type TEXT DEFAULT 'boolean',
      target_value REAL DEFAULT 1.0,
      unit TEXT DEFAULT 'times',
      frequency TEXT DEFAULT 'daily',
      days_of_week TEXT DEFAULT '[1,2,3,4,5,6,7]',
      time_of_day TEXT DEFAULT 'all',
      priority TEXT DEFAULT 'medium',
      start_date TEXT,
      end_date TEXT,
      icon TEXT DEFAULT 'bolt',
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
      status TEXT DEFAULT 'pending',
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
      tags TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS notes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT NOT NULL DEFAULT '',
      folder TEXT DEFAULT 'General',
      tags TEXT DEFAULT '[]',
      is_pinned INTEGER DEFAULT 0,
      color INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_vitals (
      id TEXT PRIMARY KEY,
      date_str TEXT NOT NULL,
      height_cm REAL,
      weight_kg REAL,
      bmi REAL,
      blood_type TEXT,
      blood_sugar REAL,
      blood_pressure_systolic INTEGER,
      blood_pressure_diastolic INTEGER,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_water_logs (
      id TEXT PRIMARY KEY,
      date_str TEXT NOT NULL,
      glasses_drank INTEGER DEFAULT 0,
      target_glasses INTEGER DEFAULT 8,
      updated_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_sleep_logs (
      id TEXT PRIMARY KEY,
      date_str TEXT NOT NULL,
      bed_time TEXT NOT NULL,
      wake_time TEXT NOT NULL,
      duration_minutes INTEGER DEFAULT 480,
      quality_rating INTEGER DEFAULT 4,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_workouts (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      type TEXT DEFAULT 'Strength',
      duration_minutes INTEGER DEFAULT 45,
      exercises_json TEXT DEFAULT '[]',
      date_str TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      dosage_or_routine TEXT,
      time_of_day TEXT DEFAULT 'all',
      is_active INTEGER DEFAULT 1,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_product_logs (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      date_str TEXT NOT NULL,
      is_taken INTEGER DEFAULT 1,
      taken_at TEXT NOT NULL,
      FOREIGN KEY (product_id) REFERENCES health_products (id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS health_meals (
      id TEXT PRIMARY KEY,
      date_str TEXT NOT NULL,
      meal_type TEXT NOT NULL,
      title TEXT NOT NULL,
      calories INTEGER DEFAULT 0,
      protein_g REAL DEFAULT 0,
      carbs_g REAL DEFAULT 0,
      fats_g REAL DEFAULT 0,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS routines_24h (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      color INTEGER DEFAULT 4284704497,
      category TEXT DEFAULT 'Productive',
      days_of_week TEXT DEFAULT '[1,2,3,4,5,6,7]',
      notes TEXT,
      is_active INTEGER DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS polymath_skills (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      domain TEXT NOT NULL,
      level INTEGER DEFAULT 1,
      status TEXT DEFAULT 'active',
      xp INTEGER DEFAULT 0,
      notes TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS bucket_list (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      status TEXT DEFAULT 'wishlist',
      rating REAL DEFAULT 0.0,
      target_date TEXT,
      completed_at TEXT,
      notes TEXT,
      cover_url TEXT,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gamification_profile (
      id TEXT PRIMARY KEY,
      total_xp INTEGER DEFAULT 0,
      level INTEGER DEFAULT 1,
      streak_freezes INTEGER DEFAULT 2,
      updated_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gamification_badges (
      id TEXT PRIMARY KEY,
      code TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      icon TEXT NOT NULL,
      unlocked_at TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gamification_xp_logs (
      id TEXT PRIMARY KEY,
      source_type TEXT NOT NULL,
      source_id TEXT,
      xp_amount INTEGER NOT NULL,
      description TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS project_features (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      title TEXT NOT NULL,
      status TEXT DEFAULT 'upcoming',
      priority TEXT DEFAULT 'medium',
      position INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
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
    'CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(is_pinned);',
    'CREATE INDEX IF NOT EXISTS idx_health_vitals_date ON health_vitals(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_health_water_date ON health_water_logs(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_health_sleep_date ON health_sleep_logs(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_health_workouts_date ON health_workouts(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_health_products_cat ON health_products(category);',
    'CREATE INDEX IF NOT EXISTS idx_health_meals_date ON health_meals(date_str);',
    'CREATE INDEX IF NOT EXISTS idx_polymath_skills_domain ON polymath_skills(domain);',
    'CREATE INDEX IF NOT EXISTS idx_bucket_category ON bucket_list(category);',
    'CREATE INDEX IF NOT EXISTS idx_bucket_status ON bucket_list(status);',
    'CREATE INDEX IF NOT EXISTS idx_project_features_project ON project_features(project_id);',
  ];
}

