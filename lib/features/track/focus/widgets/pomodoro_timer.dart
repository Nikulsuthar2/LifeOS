import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/focus_provider.dart';

class PomodoroTimerWidget extends ConsumerWidget {
  const PomodoroTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerState = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);

    Color themeColor;
    if (timerState.sessionType == 'short_break') {
      themeColor = AppColors.shortBreak;
    } else if (timerState.sessionType == 'long_break') {
      themeColor = AppColors.longBreak;
    } else {
      themeColor = AppColors.pomodoro;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Presets Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PresetChip(
                label: '25m Focus',
                isSelected: timerState.sessionType == 'focus' && timerState.totalSeconds == 25 * 60,
                onTap: () => notifier.setPreset(25, 'focus'),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: '50m Deep',
                isSelected: timerState.sessionType == 'focus' && timerState.totalSeconds == 50 * 60,
                onTap: () => notifier.setPreset(50, 'focus'),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: '5m Break',
                isSelected: timerState.sessionType == 'short_break',
                onTap: () => notifier.setPreset(5, 'short_break'),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: '15m Break',
                isSelected: timerState.sessionType == 'long_break',
                onTap: () => notifier.setPreset(15, 'long_break'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Linked target banner (Task or Topic)
          if (timerState.linkedTopicTitle != null || timerState.linkedTaskTitle != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    timerState.linkedTopicTitle != null ? Icons.school : Icons.task_alt,
                    size: 14,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timerState.linkedTopicTitle ?? timerState.linkedTaskTitle ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      notifier.linkTask(null, null);
                      notifier.linkTopic(null, null);
                    },
                    child: const Icon(Icons.close, size: 14, color: AppColors.primaryLight),
                  ),
                ],
              ),
            ),

          // Circular countdown indicator
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0 - timerState.progress,
                  strokeWidth: 8,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerState.formattedTime,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        timerState.sessionType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset
              IconButton.outlined(
                onPressed: notifier.reset,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset',
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              const SizedBox(width: 16),

              // Play / Pause
              FilledButton.icon(
                onPressed: () {
                  if (timerState.isRunning && !timerState.isPaused) {
                    notifier.pause();
                  } else {
                    notifier.start();
                  }
                },
                icon: Icon(
                  timerState.isRunning && !timerState.isPaused ? Icons.pause : Icons.play_arrow,
                  size: 22,
                ),
                label: Text(
                  timerState.isRunning && !timerState.isPaused ? 'Pause' : 'Start Focus',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 16),

              // Complete Now
              IconButton.outlined(
                onPressed: () async {
                  await notifier.completeSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Focus session recorded successfully!')),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 20, color: AppColors.success),
                tooltip: 'Complete & Save',
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

