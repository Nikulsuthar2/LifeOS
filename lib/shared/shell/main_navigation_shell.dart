import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/settings/screens/more_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/track/habits/screens/habits_screen.dart';
import '../widgets/quick_action_grid_sheet.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TasksScreen(),
    SizedBox.shrink(), // Index 2 is the center action trigger
    HabitsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF09090B).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.0,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding > 0 ? bottomPadding : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  primary: primary,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.check_circle_outline_rounded,
                  selectedIcon: Icons.check_circle_rounded,
                  label: 'Tasks',
                  isSelected: _currentIndex == 1,
                  primary: primary,
                  isDark: isDark,
                ),
                // Center Prominent Add Button (Bigger, elevated, hidden label)
                _buildCenterAddButton(
                  context: context,
                  primary: primary,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.bolt_outlined,
                  selectedIcon: Icons.bolt_rounded,
                  label: 'Habits',
                  isSelected: _currentIndex == 3,
                  primary: primary,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.more_horiz_rounded,
                  selectedIcon: Icons.more_horiz_rounded,
                  label: 'More',
                  isSelected: _currentIndex == 4,
                  primary: primary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required Color primary,
    required bool isDark,
  }) {
    return InkResponse(
      onTap: () => setState(() => _currentIndex = index),
      radius: 28,
      highlightShape: BoxShape.rectangle,
      splashColor: primary.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? primary.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 22,
                color: isSelected
                    ? primary
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton({
    required BuildContext context,
    required Color primary,
  }) {
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.light
        ? const Color(0xFF141416)
        : Colors.white;

    return Tooltip(
      message: 'Create new',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => QuickActionGridSheet.show(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
