import 'package:flutter/material.dart';
import 'ambient_focus_screen.dart';
import 'focus_view.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FocusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Pomodoro & Sessions', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Ambient Distraction-Free Mode',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: () => AmbientFocusScreen.open(context),
          ),
        ],
      ),
      body: const FocusView(),
    );
  }
}
