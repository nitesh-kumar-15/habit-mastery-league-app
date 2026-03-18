import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/app_dates.dart';
import 'database_helper.dart';

class HabitRepository extends ChangeNotifier {
  HabitRepository(this._helper);

  final DatabaseHelper _helper;

  Future<Database> get _db async => _helper.database;
  static const _allowedFrequencies = {'daily', 'weekdays', 'weekly'};
  static const _allowedStatuses = {'completed', 'missed'};

  // keep date strings stable for sqlite filters.
  String _normalizeDate(String ymd) => AppDates.formatDate(AppDates.parseDate(ymd));

  Future<List<Habit>> getAllHabits() async {
    final db = await _db;
    final rows = await db.query('habits', orderBy: 'updated_at DESC');
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final db = await _db;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Habit.fromMap(rows.first);
  }

  Future<int> insertHabit({
    required String title,
    required String description,
    required String category,
    required String frequency,
    required String startDate,
  }) async {
    // enforce basic input safety at data layer too.
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    if (!_allowedFrequencies.contains(frequency)) {
      throw ArgumentError('invalid frequency: $frequency');
    }
    final normalizedStart = _normalizeDate(startDate);
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert(
      'habits',
      {
        ...Habit.toInsertMap(
          title: cleanTitle,
          description: description.trim(),
          category: category,
          frequency: frequency,
          startDate: normalizedStart,
          createdAt: now,
          updatedAt: now,
        ),
      },
    );
    notifyListeners();
    return id;
  }

  Future<void> updateHabit(Habit habit) async {
    if (habit.title.trim().isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    if (!_allowedFrequencies.contains(habit.frequency)) {
      throw ArgumentError('invalid frequency: ${habit.frequency}');
    }
    final db = await _db;
    await db.update(
      'habits',
      {
        ...habit.copyWith(
          title: habit.title.trim(),
          description: habit.description.trim(),
          startDate: _normalizeDate(habit.startDate),
        ).toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    notifyListeners();
  }

  Future<void> deleteHabit(int id) async {
    final db = await _db;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) async {
    final db = await _db;
    final rows = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return rows.map(HabitLog.fromMap).toList();
  }

  Future<HabitLog?> getLogForDay(int habitId, String date) async {
    final db = await _db;
    final rows = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HabitLog.fromMap(rows.first);
  }

  Future<void> upsertLog({
    required int habitId,
    required String date,
    required String status,
    String notes = '',
  }) async {
    if (!_allowedStatuses.contains(status)) {
      throw ArgumentError('invalid status: $status');
    }
    final normalizedDate = _normalizeDate(date);
    final db = await _db;
    await db.insert(
      'habit_logs',
      {
        'habit_id': habitId,
        'date': normalizedDate,
        'status': status,
        'notes': notes.trim(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> deleteLog(int logId) async {
    final db = await _db;
    await db.delete('habit_logs', where: 'id = ?', whereArgs: [logId]);
    notifyListeners();
  }

  /// streak of consecutive completed days ending at [end] (inclusive).
  Future<int> streakEndingOn(int habitId, String endDate) async {
    final logs = await getLogsForHabit(habitId);
    final completed = logs.where((l) => l.status == 'completed').map((l) => l.date).toSet();
    if (completed.isEmpty) return 0;
    var d = AppDates.parseDate(endDate);
    var streak = 0;
    while (completed.contains(AppDates.formatDate(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<int> totalCompletionsAllHabits() async {
    final db = await _db;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM habit_logs WHERE status = ?',
      ['completed'],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> completionsThisWeek() async {
    final db = await _db;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startStr = AppDates.formatDate(DateTime(start.year, start.month, start.day));
    final rows = await db.rawQuery(
      '''
SELECT COUNT(*) as c FROM habit_logs
WHERE status = ? AND date >= ?
''',
      ['completed', startStr],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> missedInLast7Days(int habitId) async {
    final db = await _db;
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));
    final startStr = AppDates.formatDate(DateTime(start.year, start.month, start.day));
    final rows = await db.rawQuery(
      '''
SELECT COUNT(*) as c FROM habit_logs
WHERE habit_id = ? AND status = ? AND date >= ? AND date <= ?
''',
      [habitId, 'missed', startStr, AppDates.today()],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> weekdayCompletionsCount(int habitId) async {
    final logs = await getLogsForHabit(habitId);
    var n = 0;
    for (final l in logs.where((x) => x.status == 'completed')) {
      final d = AppDates.parseDate(l.date);
      if (AppDates.isWeekday(d)) n++;
    }
    return n;
  }

  Future<int> weekendCompletionsCount(int habitId) async {
    final logs = await getLogsForHabit(habitId);
    var n = 0;
    for (final l in logs.where((x) => x.status == 'completed')) {
      final d = AppDates.parseDate(l.date);
      if (!AppDates.isWeekday(d)) n++;
    }
    return n;
  }

  /// habits that should appear for [day] based on start date and frequency.
  Future<List<Habit>> habitsForDay(DateTime day) async {
    final all = await getAllHabits();
    final dayStr = AppDates.formatDate(day);
    final out = <Habit>[];
    for (final h in all) {
      if (h.startDate.compareTo(dayStr) > 0) continue;
      switch (h.frequency) {
        case 'weekdays':
          if (!AppDates.isWeekday(day)) continue;
          break;
        case 'weekly':
          // weekly means once per week on the start-date weekday.
          final startWeekday = AppDates.parseDate(h.startDate).weekday;
          if (day.weekday != startWeekday) continue;
          break;
        case 'daily':
          break;
        default:
          break;
      }
      out.add(h);
    }
    return out;
  }
}
