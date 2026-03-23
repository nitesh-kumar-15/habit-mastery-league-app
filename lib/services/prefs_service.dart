import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  // keys stay centralized to avoid typos across screens.
  static const _themeMode = 'theme_mode';
  static const _reminderMinutes = 'daily_reminder_time_minutes';
  static const _showTips = 'show_motivation_tips';

  Future<ThemeMode> getThemeMode() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_themeMode);
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    // persist enum as readable string values.
    final s = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await p.setString(_themeMode, s);
  }

  /// minutes from midnight [0, 1439] for reminder; default 9:00.
  Future<int> getReminderMinutesFromMidnight() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_reminderMinutes) ?? (9 * 60);
  }

  Future<void> setReminderMinutesFromMidnight(int minutes) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_reminderMinutes, minutes.clamp(0, 1439));
  }

  Future<bool> getShowMotivationTips() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_showTips) ?? true;
  }

  Future<void> setShowMotivationTips(bool show) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_showTips, show);
  }
}
