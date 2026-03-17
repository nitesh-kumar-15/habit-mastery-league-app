import 'package:flutter/material.dart';

import 'prefs_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final PrefsService _prefs;

  ThemeMode themeMode = ThemeMode.system;
  int reminderMinutesFromMidnight = 9 * 60;
  bool showMotivationTips = true;
  bool loaded = false;

  Future<void> load() async {
    themeMode = await _prefs.getThemeMode();
    reminderMinutesFromMidnight = await _prefs.getReminderMinutesFromMidnight();
    showMotivationTips = await _prefs.getShowMotivationTips();
    loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setReminderMinutes(int minutes) async {
    reminderMinutesFromMidnight = minutes;
    await _prefs.setReminderMinutesFromMidnight(minutes);
    notifyListeners();
  }

  Future<void> setShowMotivationTips(bool value) async {
    showMotivationTips = value;
    await _prefs.setShowMotivationTips(value);
    notifyListeners();
  }

  TimeOfDay get reminderTimeOfDay {
    final m = reminderMinutesFromMidnight;
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }
}
