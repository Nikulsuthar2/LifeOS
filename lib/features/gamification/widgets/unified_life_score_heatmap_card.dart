import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/gamification_provider.dart';
import '../screens/gamification_screen.dart';

class UnifiedLifeScoreHeatmapCard extends ConsumerWidget {
  const UnifiedLifeScoreHeatmapCard({super.key});

  Color _getHeatmapColor(int count, bool isDark) {
    if (count == 0) {
      return isDark ? const Color(0xFF26262E) : const Color(0xFFE5E7EB);
    } else if (count <= 2) {
      return const Color(0xFF86EFAC); // Light green
    } else if (count <= 5) {
      return const Color(0xFF22C55E); // Medium green
    } else {
      return const Color(0xFF15803D); // Deep emerald
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lifeScoreAsync = ref.watch(dailyLifeScoreProvider);
    final heatmapAsync = ref.watch(activityHeatmapProvider);
    final profileAsync = ref.watch(gamificationProfileProvider);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const GamificationScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A22) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Life Score + Level & Freezes
            Row(
              children: [
                // Life Score Ring
                lifeScoreAsync.when(
                  data: (score) => SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 5,
                          backgroundColor: isDark ? const Color(0xFF2C2C36) : const Color(0xFFE5E5EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                        ),
                        Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(width: 52, height: 52, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, _) => const SizedBox(width: 52, height: 52, child: Icon(Icons.speed_rounded)),
                ),
                const SizedBox(width: 14),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Daily Life Score',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          profileAsync.when(
                            data: (profile) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LVL ${profile.currentLevel}',
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      profileAsync.when(
                        data: (p) => Text(
                          '${p.rankTitle} • ${p.streakFreezes} Streak Freezes ❄',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Heatmap Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consistency Grid (Last 12 Weeks)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                Text(
                  'Details →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            heatmapAsync.when(
              data: (data) {
                final daysList = data.entries.toList().reversed.toList(); // Oldest to newest
                // 12 columns x 7 rows
                final totalDays = daysList.length;
                final weeksCount = (totalDays / 7).ceil();

                return Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(weeksCount, (weekIdx) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Column(
                              children: List.generate(7, (dayIdx) {
                                final itemIdx = weekIdx * 7 + dayIdx;
                                if (itemIdx >= totalDays) {
                                  return const SizedBox(width: 10, height: 10);
                                }
                                final entry = daysList[itemIdx];
                                final count = entry.value;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getHeatmapColor(count, isDark),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Less ', style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ...[0, 2, 4, 7].map((c) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getHeatmapColor(c, isDark),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )),
                        Text(' More', style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5))),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
