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
    // load all persisted settings before app ui uses them.
    themeMode = await _prefs.getThemeMode();
    reminderMinutesFromMidnight = await _prefs.getReminderMinutesFromMidnight();
    showMotivationTips = await _prefs.getShowMotivationTips();
    loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // update memory first so ui responds immediately.
    themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setReminderMinutes(int minutes) async {
    // this mirrors time picker output as minutes-from-midnight.
    reminderMinutesFromMidnight = minutes;
    await _prefs.setReminderMinutesFromMidnight(minutes);
    notifyListeners();
  }

  Future<void> setShowMotivationTips(bool value) async {
    // this controls coach card visibility on home screen.
    showMotivationTips = value;
    await _prefs.setShowMotivationTips(value);
    notifyListeners();
  }

  TimeOfDay get reminderTimeOfDay {
    // convert stored minutes to picker-friendly time.
    final m = reminderMinutesFromMidnight;
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }
}
