import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/focus_session.dart';
import '../repositories/focus_repository.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository();
});

final todayFocusMinutesProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(focusRepositoryProvider);
  return await repo.getTodayFocusMinutes();
});

final weeklyFocusTrendProvider = FutureProvider<List<DailyFocusMetric>>((ref) async {
  final repo = ref.watch(focusRepositoryProvider);
  return await repo.getWeeklyFocusTrend();
});

final recentSessionsProvider = FutureProvider<List<FocusSession>>((ref) async {
  final repo = ref.watch(focusRepositoryProvider);
  return await repo.getRecentSessions();
});

class FocusTimerState {
  final bool isRunning;
  final bool isPaused;
  final int totalSeconds;
  final int remainingSeconds;
  final String sessionType; // 'focus', 'short_break', 'long_break'
  final String? linkedTaskId;
  final String? linkedTaskTitle;
  final String? linkedTopicId;
  final String? linkedTopicTitle;

  FocusTimerState({
    this.isRunning = false,
    this.isPaused = false,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.sessionType = 'focus',
    this.linkedTaskId,
    this.linkedTaskTitle,
    this.linkedTopicId,
    this.linkedTopicTitle,
  });

  double get progress => totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

  String get formattedTime {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  FocusTimerState copyWith({
    bool? isRunning,
    bool? isPaused,
    int? totalSeconds,
    int? remainingSeconds,
    String? sessionType,
    String? linkedTaskId,
    String? linkedTaskTitle,
    String? linkedTopicId,
    String? linkedTopicTitle,
  }) {
    return FocusTimerState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionType: sessionType ?? this.sessionType,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      linkedTaskTitle: linkedTaskTitle ?? this.linkedTaskTitle,
      linkedTopicId: linkedTopicId ?? this.linkedTopicId,
      linkedTopicTitle: linkedTopicTitle ?? this.linkedTopicTitle,
    );
  }
}

class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _timer;

  @override
  FocusTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return FocusTimerState();
  }

  void setPreset(int minutes, String sessionType) {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
      sessionType: sessionType,
    );
  }

  void linkTask(String? id, String? title) {
    state = state.copyWith(linkedTaskId: id, linkedTaskTitle: title);
  }

  void linkTopic(String? id, String? title) {
    state = state.copyWith(linkedTopicId: id, linkedTopicTitle: title);
  }

  void start() {
    if (state.isRunning && !state.isPaused) return;

    state = state.copyWith(isRunning: true, isPaused: false);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        completeSession();
      }
    });
  }

  void startTimer() => start();

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      remainingSeconds: state.totalSeconds,
    );
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    final elapsedSeconds = state.totalSeconds - state.remainingSeconds;
    final durationToRecord = elapsedSeconds > 60 ? elapsedSeconds : state.totalSeconds;

    String title = 'Focus Session';
    if (state.linkedTopicTitle != null) {
      title = 'Study: ${state.linkedTopicTitle}';
    } else if (state.linkedTaskTitle != null) {
      title = state.linkedTaskTitle!;
    } else if (state.sessionType == 'short_break') {
      title = 'Short Break';
    } else if (state.sessionType == 'long_break') {
      title = 'Long Break';
    }

    final session = FocusSession(
      id: '',
      title: title,
      taskId: state.linkedTaskId,
      topicId: state.linkedTopicId,
      startedAt: DateTime.now().subtract(Duration(seconds: durationToRecord)),
      endedAt: DateTime.now(),
      durationSeconds: durationToRecord,
      sessionType: state.sessionType,
      isCompleted: true,
    );

    final repo = ref.read(focusRepositoryProvider);
    await repo.saveFocusSession(session);

    ref.invalidate(todayFocusMinutesProvider);
    ref.invalidate(weeklyFocusTrendProvider);
    ref.invalidate(recentSessionsProvider);

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      remainingSeconds: state.totalSeconds,
    );
  }
}

final focusTimerProvider = NotifierProvider<FocusTimerNotifier, FocusTimerState>(FocusTimerNotifier.new);
