import 'package:flutter/material.dart';
import '../screens/create_task_screen.dart';

/// Legacy alias / wrapper pointing to the full [CreateTaskScreen].
class CreateTaskSheet extends StatelessWidget {
  final DateTime? initialDate;
  final String? initialTime;

  const CreateTaskSheet({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    String? initialTime,
  }) {
    return CreateTaskScreen.open(
      context,
      initialDate: initialDate,
      initialTime: initialTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreateTaskScreen(
      initialDate: initialDate,
      initialTime: initialTime,
    );
  }
}
