import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeSettings {
  final ThemeMode themeMode;
  final bool followDynamicColor;
  final Color accentColor;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.followDynamicColor = true,
    this.accentColor = AppColors.primary,
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? followDynamicColor,
    Color? accentColor,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      followDynamicColor: followDynamicColor ?? this.followDynamicColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const _keyThemeMode = 'theme_mode';
  static const _keyFollowDynamic = 'follow_dynamic_color';
  static const _keyAccentColor = 'custom_accent_color';

  @override
  ThemeSettings build() {
    _loadFromPrefs();
    return const ThemeSettings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final modeStr = prefs.getString(_keyThemeMode);
    ThemeMode mode = ThemeMode.system;
    if (modeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (modeStr == 'light') {
      mode = ThemeMode.light;
    }

    final followDynamic = prefs.getBool(_keyFollowDynamic) ?? true;
    final accentVal = prefs.getInt(_keyAccentColor);
    final accent = accentVal != null ? Color(accentVal) : AppColors.primary;

    state = ThemeSettings(
      themeMode: mode,
      followDynamicColor: followDynamic,
      accentColor: accent,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await prefs.setString(_keyThemeMode, val);
  }

  Future<void> setFollowDynamicColor(bool follow) async {
    state = state.copyWith(followDynamicColor: follow);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFollowDynamic, follow);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, color.toARGB32());
  }
}

final themeSettingsProvider = NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
