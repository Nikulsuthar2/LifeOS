import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../bucket_list/screens/bucket_list_screen.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/screens/gamification_screen.dart';
import '../../goals/providers/goal_provider.dart';
import '../../goals/screens/goals_screen.dart';
import '../../health/screens/health_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../learning/providers/roadmap_provider.dart';
import '../../learning/screens/roadmaps_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../projects/screens/projects_screen.dart';
import '../../routine/screens/routine_screen.dart';
import '../../skills/screens/skills_screen.dart';
import '../../tasks/screens/eisenhower_matrix_screen.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/focus/screens/focus_screen.dart';
import 'settings_screen.dart';

/// Material 3 Expressive "More" Hub for Life OS.
/// Serves as the central command center for all core LifeOS modules:
/// - Productivity (Focus Pomodoro, 24h Routine, Eisenhower Matrix, Notes)
/// - Growth & Polymath (Goals, Projects, Polymath Skills, Roadmaps, Journal, Bucket List)
/// - Health Suite (Vitals, Water, Workouts, Diet, Sleep, Products)
/// - Gamification (Levels, XP, Streak Freezes, Badges)
/// - Settings (Appearance, Data & Privacy)
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
    final profileAsync = ref.watch(gamificationProfileProvider);

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
          // 1. Life Gamification Level Banner
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const GamificationScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF2E1065).withOpacity(0.8),
                          const Color(0xFF141418),
                        ]
                      : [
                          const Color(0xFFEDE9FE),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.4 : 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech_rounded, color: Color(0xFF8B5CF6), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            profileAsync.when(
                              data: (p) => Text(
                                'Level ${p.currentLevel} • ${p.rankTitle}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              loading: () => const Text('Life Gamification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              error: (_, _) => const Text('Life Gamification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        profileAsync.when(
                          data: (p) => Text(
                            '${p.currentXp}/${p.targetXp} XP • ${p.streakFreezes} Streak Freezes available ❄',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 2. PRODUCTIVITY & ROUTINE
          _buildSectionHeader('PRODUCTIVITY & ROUTINE', isDark),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.timer,
                iconColor: primary,
                title: 'Focus & Pomodoro Timer',
                subtitle: 'Deep work sessions, ambient mode & stopwatch',
                trailingBadge: focusMin > 0 ? '$focusMin min today' : null,
                badgeColor: primary,
                onTap: () => FocusScreen.open(context),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.time,
                iconColor: const Color(0xFFF59E0B),
                title: '24-Hour Routine',
                subtitle: 'Circadian day schedule & active time blocks',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RoutineScreen()));
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.square_grid_2x2,
                iconColor: const Color(0xFFEF4444),
                title: 'Eisenhower Matrix',
                subtitle: 'Priority triage: Do First, Schedule, Delegate, Eliminate',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EisenhowerMatrixScreen()));
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.doc_text,
                iconColor: const Color(0xFF06B6D4),
                title: 'Notes & Knowledge',
                subtitle: 'Organized folders, tags, search & pin',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
                },
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. GROWTH, POLYMATH & PROJECTS
          _buildSectionHeader('GROWTH, POLYMATH & PROJECTS', isDark),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.flag,
                iconColor: AppColors.high,
                title: 'Life Goals & Milestones',
                subtitle: 'Long-term direction, milestones & progress',
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
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.layers,
                iconColor: const Color(0xFF6366F1),
                title: 'Project Management',
                subtitle: 'Kanban boards, upcoming, in-progress & feature checklists',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsScreen()));
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.bolt_horizontal_circle,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Polymath Skills Matrix',
                subtitle: 'Multi-domain mastery levels (Novice to Master) & practice XP',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SkillsScreen()));
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.book,
                iconColor: AppColors.accent,
                title: 'Learning & Skill Trees',
                subtitle: 'Visual roadmaps, prerequisites & lesson tracks',
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
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.pencil_ellipsis_rectangle,
                iconColor: AppColors.secondary,
                title: 'Journal & Daily Reflection',
                subtitle: 'Mood tracking, past reflections timeline & prompts',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalScreen()));
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.star_circle,
                iconColor: const Color(0xFFEC4899),
                title: 'Bucket List & Media',
                subtitle: 'Movies, games, books, travel & experience wishlist',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BucketListScreen()));
                },
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 4. HEALTH & WELLNESS
          _buildSectionHeader('HEALTH & WELLNESS', isDark),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.heart_fill,
                iconColor: const Color(0xFFEF4444),
                title: 'Health Suite & Vitals',
                subtitle: 'Height, weight, BMI, water, sleep, workouts & diet',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthScreen()));
                },
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 5. SYSTEM & PREFERENCES
          _buildSectionHeader('SYSTEM & PREFERENCES', isDark),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildModuleTile(
                context: context,
                icon: CupertinoIcons.gear_alt,
                iconColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                title: 'Settings & Preferences',
                subtitle: 'Appearance, dynamic theme, data backup & privacy',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
          width: 0.8,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 56,
      color: isDark ? const Color(0xFF222226) : const Color(0xFFF0F0F4),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
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
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? iconColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailingBadge,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? iconColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
