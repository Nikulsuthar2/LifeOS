#  LifeOS

<p align="center">
  <strong>The Personal Operating System for Your Life, Goals, and Learning.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/Riverpod-3.5-0D47A1?logo=flutter&logoColor=white" alt="Riverpod"></a>
  <a href="https://www.sqlite.org"><img src="https://img.shields.io/badge/SQLite-Local--First-003B57?logo=sqlite&logoColor=white" alt="SQLite"></a>
  <a href="https://m3.material.io"><img src="https://img.shields.io/badge/Design-Material%203-7C3AED" alt="Material 3"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

---

## 💡 What is LifeOS?

Most productivity applications treat your life as disconnected silos:
- You track tasks in **Todoist** or **TickTick**,
- You track habits in a separate habit tracker,
- You track study hours in **Forest**,
- You plan skills in **Notion** or markdown files,
- ...and you lose the sequence when life gets busy.

**LifeOS solves this by uniting your daily actions with your lifelong trajectory.** 

One activity updates multiple relevant areas automatically without double data entry:
```text
Goal: Become an AI/ML Engineer
 └── Project: Master Machine Learning
      └── Learning Roadmap: ML & Computer Science
           └── Topic: Linear Regression & Gradient Descent
                └── Task: "Study DSA & ML today" (30 min)
                     └── Focus Session: Pomodoro (25 min)
                          ▼
            [Automatic Updates Triggered]
  • Task Completed               • Topic Progress Incremented
  • Actual Learning Hours Logged • Habit Streak Preserved
  • Goal Milestone Advanced      • Dashboard Metrics Updated
```

---

## ✨ Key Features & Modules

### 1. 🧭 Unified Personal Dashboard
- **Daily Context**: Dynamic greeting, daily motto, and quick date navigation.
- **Live 4-Metric Grid**: Real-time counters for Tasks Completed, Focus Time, Learning Sessions, and Habit Consistency.
- **Today's Priorities**: Dedicated spotlight card for your top high-impact commitments.
- **Active Learning Spotlight**: Displays your current roadmap stage, lesson progress, and 1-tap "Study Today" action.
- **Time-Blocked Daily Schedule**: Visual timeline of planned focus blocks and commitments.

### 2. 🗺️ Learning Roadmap Builder *(Core Differentiator)*
Never lose your learning sequence again. Designed specifically for developers, self-learners, and engineers.
- **Multi-Stage Roadmaps**: Hierarchical breakdown from Roadmap ➔ Stages ➔ Topics ➔ Lessons & Subtasks.
- **Sequential Learning & Prerequisites**: Clear indicators of Not Started, In Progress, Completed, or Paused.
- **Estimated vs. Actual Time**: Track projected learning hours against real Pomodoro study sessions.
- **Topic Resources & Notes**: Attach documentation links, YouTube courses, and study notes directly to topics.
- **1-Click Task Generation**: Tap *"Study Today"* on any active topic to automatically schedule a linked task on your dashboard.
- **Included Default Curriculum**: Ships with a comprehensive, 6-stage **Computer Science & AI/ML Foundations** roadmap.

### 3. ✅ Smart Tasks & To-Do Management
- **Views**: *Today*, *Upcoming*, and *Completed* task filtering.
- **Priorities**: Four urgency tiers (**Urgent**, **High**, **Medium**, **Low**) with visual color coding.
- **Subtasks & Checklists**: Interactive subtask items with completion ratios.
- **Pomodoro Integration**: 1-tap button to launch a timed focus session directly from any task.
- **Roadmap & Project Linking**: Tasks can belong directly to a learning topic or long-term project.

### 4. 🔁 Habit Tracker & Consistency Engine
- **Non-Punishing Consistency**: Build positive momentum without streak-anxiety.
- **7-Day Visual Consistency Dots**: High-density weekly progress visualization.
- **Categorization**: Health, Learning, Mind, Routine, and Career tags.
- **1-Tap Toggles**: Fast daily check-offs directly from your feed.

### 5. ⏱️ Focus & Pomodoro Sessions
- **Multiple Intervals**: Pre-configured **25/5** (Classic Pomodoro), **50/10** (Deep Work), or custom durations.
- **Task & Topic Linking**: Track exact focus minutes against specific goals or lessons.
- **Distraction Logging**: Capture fleeting thoughts without derailing your focus.
- **Weekly Analytics**: Interactive 7-day focus trend bar charts powered by `fl_chart`.

### 6. 🎯 Goals & Projects
- **Top-Down Clarity**: Connect high-level aspirations (Career, Health, Financial) to actionable projects.
- **Milestone Tracking**: Break ambitious projects into concrete milestones with target deadlines.

### 7. 📔 Journal & Daily Reflection
- **Daily Prompts**: Guided reflection questions:
  - *What went well today?*
  - *What didn't go as planned?*
  - *What lessons did you learn?*
- **Mood Tracking**: Track mood trends across your journey.

### 8. 🔒 100% Local-First & Privacy Preserving
- **Zero Cloud Lock-in**: All data resides in an encrypted, offline SQLite database on your device.
- **Instant JSON Export**: Backup your entire life history to a single human-readable `.json` file at any time.
- **JSON Restore**: Seamlessly import your data or transfer it to a new device.
- **Zero Tracking / Zero Telemetry**: Your thoughts, habits, and tasks belong entirely to you.

---

## 🛠️ Architecture & Technology Stack

LifeOS is crafted with an offline-first, clean architectural design:

```text
lib/
├── core/
│   ├── database/        # SQLite schema (15 relational tables), seed data & migrations
│   ├── models/          # Strongly-typed domain models (Task, Habit, Roadmap, etc.)
│   ├── theme/           # Material 3 Dark/Light design tokens (Slate + Indigo/Teal)
│   └── widgets/         # Reusable design components (MetricCard, PriorityBadge, etc.)
└── features/
    ├── dashboard/       # Central command center & daily metrics
    ├── tasks/           # Task management, subtasks & priority filters
    ├── learning/        # Learning roadmaps, stage timelines & topic details
    ├── track/
    │   ├── habits/      # Habit tracking, streaks & consistency
    │   └── focus/       # Pomodoro timer engine & focus analytics
    ├── goals/           # Long-term goals & project milestones
    ├── journal/         # Daily reflection & mood tracker
    └── settings/        # Local-first JSON backup/restore & preferences
```

### Key Technologies
| Component | Technology | Purpose |
|---|---|---|
| **Framework** | [Flutter](https://flutter.dev) (v3.47+) | Cross-platform UI for Android, iOS, Desktop & Web |
| **Language** | [Dart](https://dart.dev) (v3.13+) | Null-safe, high-performance client language |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) (v3.5+) | Type-safe, modern `Notifier` and `NotifierProvider` state |
| **Database** | [sqflite](https://pub.dev/packages/sqflite) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | Cross-platform SQLite engine (mobile & desktop/tests) |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) (v1.3+) | High-performance interactive data visualizations |
| **Design System** | Google Fonts ([Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)) + Material 3 | Modern, dark-mode native aesthetics |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.47.0` or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `^3.13.0` or later
- **Android Studio** / **VS Code** with Flutter and Dart extensions
- (For Android) **Android SDK Platform 35** with USB Debugging enabled on your phone

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/LifeOS.git
   cd LifeOS
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify analyzer & test suite:**
   ```bash
   flutter analyze
   flutter test
   ```

4. **Run on your connected Android device:**
   ```bash
   # List connected devices
   flutter devices

   # Run on your target device (e.g. physical phone or emulator)
   flutter run -d <device_id>
   ```

5. **Run on Desktop (Windows / macOS / Linux) or Web:**
   ```bash
   # Windows Desktop
   flutter run -d windows

   # Chrome Web
   flutter run -d chrome
   ```

---

## 🧪 Testing

LifeOS includes automated unit and widget test suites covering the core database, repositories, and UI widgets:

```bash
# Run all tests
flutter test

# Run repository & domain integration tests
flutter test test/lifeos_core_test.dart

# Run widget component tests
flutter test test/widget_test.dart
```

---

## 📅 Roadmap & Upcoming Features

- [x] **Phase 1: Foundation** — Dashboard, local SQLite architecture, task hierarchy, priority filtering.
- [x] **Phase 2: Consistency** — Habit tracker, streaks, 7-day consistency view.
- [x] **Phase 3: Focus** — 25/5 and 50/10 Pomodoro timer, task/topic linking, weekly analytics.
- [x] **Phase 4: Learning** — Roadmaps, stages, topics, subtasks, resources, auto-task generator.
- [x] **Phase 5: Reflection & Goals** — Goals, project milestones, daily journal with mood tracking.
- [x] **Phase 6: Data Ownership** — Complete offline JSON backup & restore.
- [ ] **Phase 7: Cloud & Peer Sync (Optional)** — Optional end-to-end encrypted WebDAV / self-hosted sync.
- [ ] **Phase 8: Home Screen Widgets** — Android Glance / iOS WidgetKit priorities widget.
- [ ] **Phase 9: AI Daily Planning Assistant** — Local on-device LLM morning summary and schedule suggestions.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

<p align="center">
  Built with ❤️ for lifelong learners and productive builders.
</p>
