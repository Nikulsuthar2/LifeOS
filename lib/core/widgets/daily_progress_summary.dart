import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Compact, single-surface daily progress summary for the Life OS dashboard.
/// Replaces oversized 2x2 KPI grids with an action-focused, typography-led momentum bar.
class DailyProgressSummary extends StatelessWidget {
  final int tasksCompleted;
  final int tasksTotal;
  final int focusMinutes;
  final int habitsCompleted;
  final int habitsTotal;
  final double roadmapProgress;
  final VoidCallback? onTasksTap;
  final VoidCallback? onFocusTap;
  final VoidCallback? onHabitsTap;
  final VoidCallback? onRoadmapTap;

  const DailyProgressSummary({
    super.key,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.focusMinutes,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.roadmapProgress,
    this.onTasksTap,
    this.onFocusTap,
    this.onHabitsTap,
    this.onRoadmapTap,
  });

  double get overallMomentum {
    double totalWeight = 0;
    double earnedWeight = 0;

    if (tasksTotal > 0) {
      totalWeight += 0.4;
      earnedWeight += 0.4 * (tasksCompleted / tasksTotal);
    }
    if (habitsTotal > 0) {
      totalWeight += 0.4;
      earnedWeight += 0.4 * (habitsCompleted / habitsTotal);
    }
    // Focus target: 50 mins = 100% of focus factor (0.2 weight)
    totalWeight += 0.2;
    earnedWeight += 0.2 * (focusMinutes >= 50 ? 1.0 : focusMinutes / 50.0);

    if (totalWeight == 0) return 0.0;
    return (earnedWeight / totalWeight).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final momentumPercent = (overallMomentum * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Daily Momentum percentage & status label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: momentumPercent >= 80
                          ? AppColors.success
                          : (momentumPercent >= 40 ? AppColors.primaryLight : AppColors.medium),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'DAILY MOMENTUM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '$momentumPercent%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Sleek progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: overallMomentum,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                momentumPercent >= 80 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metric pills row (horizontal compact scannable strip)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryPill(
                  icon: Icons.check_circle_outline,
                  label: '$tasksCompleted/$tasksTotal Tasks',
                  color: tasksTotal > 0 && tasksCompleted == tasksTotal
                      ? AppColors.success
                      : AppColors.primaryLight,
                  onTap: onTasksTap,
                ),
                const SizedBox(width: AppSpacing.sm),
                _SummaryPill(
                  icon: Icons.timer_outlined,
                  label: '$focusMinutes min Focus',
                  color: AppColors.secondary,
                  onTap: onFocusTap,
                ),
                const SizedBox(width: AppSpacing.sm),
                _SummaryPill(
                  icon: Icons.bolt,
                  label: '$habitsCompleted/$habitsTotal Habits',
                  color: habitsTotal > 0 && habitsCompleted == habitsTotal
                      ? AppColors.success
                      : AppColors.accent,
                  onTap: onHabitsTap,
                ),
                const SizedBox(width: AppSpacing.sm),
                _SummaryPill(
                  icon: Icons.school_outlined,
                  label: '${(roadmapProgress * 100).round()}% Learn',
                  color: AppColors.primaryLight,
                  onTap: onRoadmapTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
