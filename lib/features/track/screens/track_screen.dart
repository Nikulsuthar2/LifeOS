import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_capture_sheet.dart';
import '../focus/screens/focus_view.dart';
import '../habits/screens/habits_view.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Track & Consistency'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Habit',
              onPressed: () => QuickCaptureSheet.show(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.darkTextSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.bolt, size: 20), text: 'Habits'),
              Tab(icon: Icon(Icons.timer_outlined, size: 20), text: 'Focus Pomodoro'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HabitsView(),
            FocusView(),
          ],
        ),
      ),
    );
  }
}

