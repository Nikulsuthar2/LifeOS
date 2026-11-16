import 'package:flutter/material.dart';
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
      ),
      body: const FocusView(),
    );
  }
}
