import 'package:flutter/material.dart';

/// Premium, minimal color tokens for Life OS.
/// Calm, sophisticated, functional palette with restrained accents.
/// Dark theme is deep neutral pitch charcoal (zero bluish tint).
class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF6366F1); // Muted Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryMuted = Color(0x266366F1); // 15% opacity

  static const Color secondary = Color(0xFF0EA5E9); // Muted Sky / Slate Blue
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryMuted = Color(0x260EA5E9);

  static const Color accent = Color(0xFF10B981); // Emerald Green (Habits & Consistency)

  // Semantic Status Colors (Restrained)
  static const Color success = Color(0xFF10B981); // Emerald (Completed)
  static const Color successMuted = Color(0x2610B981);

  static const Color warning = Color(0xFFF59E0B); // Warm Amber
  static const Color warningMuted = Color(0x26F59E0B);

  static const Color urgent = Color(0xFFEF4444); // Crimson (Urgent / Destructive only)
  static const Color urgentMuted = Color(0x26EF4444);

  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Priority Tokens
  static const Color high = Color(0xFFF97316); // Burnt Orange
  static const Color medium = Color(0xFFF59E0B); // Amber
  static const Color low = Color(0xFF71717A); // Neutral Zinc Muted
  static const Color highPriority = high;
  static const Color mediumPriority = medium;
  static const Color lowPriority = low;

  // Focus & Timer
  static const Color pomodoro = Color(0xFF6366F1); // Indigo focus
  static const Color shortBreak = Color(0xFF10B981);
  static const Color longBreak = Color(0xFF0EA5E9);

  // Dark Theme Palette (True Deep Charcoal / Pitch Dark, Zero Bluish Tint)
  static const Color darkBackground = Color(0xFF09090B); // Pure deep charcoal zinc
  static const Color darkSurface = Color(0xFF121214); // Deep neutral surface
  static const Color darkCard = Color(0xFF121214); // Deep neutral card
  static const Color darkCardElevated = Color(0xFF18181B); // Raised elements, chips, inputs
  static const Color darkBorder = Color(0xFF27272A); // Hair-line neutral border
  static const Color darkBorderSubtle = Color(0xFF1E1E22);
  static const Color darkTextPrimary = Color(0xFFF4F4F5); // Crisp neutral white
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Clean neutral zinc gray
  static const Color darkTextMuted = Color(0xFF71717A); // Subdued muted zinc

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightBorderSubtle = Color(0xFFF4F4F5);
  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFFA1A1AA);
}
