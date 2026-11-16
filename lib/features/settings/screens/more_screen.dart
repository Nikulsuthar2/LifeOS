import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../goals/providers/goal_provider.dart';
import '../../goals/screens/goals_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../learning/providers/roadmap_provider.dart';
import '../../learning/screens/roadmaps_screen.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/focus/screens/focus_screen.dart';
import 'settings_screen.dart';

/// Material 3 Expressive "More" Hub for Life OS.
/// Serves as the central command center for deep Life Modules:
/// - Focus & Pomodoro Timer
/// - Goals & Long-Term Projects
/// - Learning Roadmaps & Skill Trees
/// - Daily Journal & Reflection
/// At the bottom, presents a dedicated gateway to the separate Settings screen.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final focusMinutesAsync = ref.watch(todayFocusMinutesProvider);
    final focusMin = focusMinutesAsync.value ?? 0;
    final roadmapsAsync = ref.watch(roadmapsListProvider);
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'More & Modules',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
        children: [
          // 1. Welcome / Expressive Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        primary.withValues(alpha: 0.18),
                        const Color(0xFF141418),
                      ]
                    : [
                        primary.withValues(alpha: 0.12),
                        Colors.white,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Life Architecture',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Interconnected modules connecting tasks, goals, focus, and skills.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 2. Life Modules Section Header
          Text(
            'LIFE MODULES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Modules Container
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                // Focus & Pomodoro
                _buildModuleTile(
                  context: context,
                  icon: CupertinoIcons.timer,
                  iconColor: primary,
                  title: 'Focus & Pomodoro Timer',
                  subtitle: 'Deep work sessions, stopwatch & intervals',
                  trailingBadge: focusMin > 0 ? '$focusMin min today' : null,
                  badgeColor: primary,
                  onTap: () => FocusScreen.open(context),
                  isDark: isDark,
                ),
                _buildDivider(isDark),

                // Goals & Projects
                _buildModuleTile(
                  context: context,
                  icon: CupertinoIcons.flag,
                  iconColor: AppColors.high,
                  title: 'Goals & Projects',
                  subtitle: 'Long-term direction, milestones & roadmaps',
                  trailingBadge: goalsAsync.maybeWhen(
                    data: (goals) => goals.isNotEmpty ? '${goals.length} goals' : null,
                    orElse: () => null,
                  ),
                  badgeColor: AppColors.high,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),

                // Learning & Skills
                _buildModuleTile(
                  context: context,
                  icon: CupertinoIcons.book,
                  iconColor: AppColors.accent,
                  title: 'Learning & Skill Trees',
                  subtitle: 'Visual computer science & technical roadmaps',
                  trailingBadge: roadmapsAsync.maybeWhen(
                    data: (rms) => rms.isNotEmpty ? '${rms.length} active' : null,
                    orElse: () => null,
                  ),
                  badgeColor: AppColors.accent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RoadmapsScreen()));
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),

                // Journal & Reflection
                _buildModuleTile(
                  context: context,
                  icon: CupertinoIcons.pencil_ellipsis_rectangle,
                  iconColor: AppColors.secondary,
                  title: 'Journal & Daily Reflection',
                  subtitle: 'Wins, improvements, lessons learned & notes',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalScreen()));
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 3. Settings & Preferences Gateway (At the very end of More section)
          Text(
            'SYSTEM & PREFERENCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings_outlined, color: primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings & Appearance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Theme, dynamic colors, data backup & privacy',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 58,
      color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
    );
  }

  Widget _buildModuleTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    Color? badgeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null && badgeColor != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingBadge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}
