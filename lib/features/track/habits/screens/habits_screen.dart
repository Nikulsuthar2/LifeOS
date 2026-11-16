import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_week_calendar_bar.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final habitsAsync = ref.watch(filteredHabitsListProvider);
    final selectedFilter = ref.watch(selectedHabitTimeOfDayFilterProvider);
    final viewMode = ref.watch(habitViewModeProvider);

    final timeOfDayFilters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'morning', 'label': 'Morning 🌅'},
      {'id': 'afternoon', 'label': 'Afternoon ☀️'},
      {'id': 'evening', 'label': 'Evening 🌙'},
      {'id': 'night', 'label': 'Night 🌌'},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Habits',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            icon: Icon(
              viewMode == HabitViewMode.expanded
                  ? CupertinoIcons.rectangle_grid_1x2
                  : CupertinoIcons.list_bullet,
              size: 20,
              color: primary,
            ),
            tooltip: viewMode == HabitViewMode.expanded
                ? 'Switch to Compact View'
                : 'Switch to Detailed View',
            onPressed: () {
              ref.read(habitViewModeProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.add, size: 22, color: primary),
            tooltip: 'Create Habit',
            onPressed: () {
              HabitDetailScreen.open(context, isNew: true);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Week Calendar Bar (snappy 7 days Mon - Sun, expandable to month)
          const HabitWeekCalendarBar(),

          const SizedBox(height: 6),

          // 2. Category / Time of Day Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: timeOfDayFilters.map((f) {
                final isSelected = selectedFilter == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedHabitTimeOfDayFilterProvider.notifier).setFilter(f['id']!);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : (isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Habits List
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (habits) {
                if (habits.isEmpty) {
                  return EmptyState(
                    icon: CupertinoIcons.flame,
                    title: selectedFilter == 'all'
                        ? 'No habits tracked yet'
                        : 'No $selectedFilter habits',
                    message: 'Build daily rituals that stick and track consistency.',
                    buttonText: 'Create Habit',
                    onButtonPressed: () {
                      HabitDetailScreen.open(context, isNew: true);
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    return HabitCard(habitWithStatus: habits[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
