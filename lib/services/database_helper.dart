import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    // store db file inside the app documents directory.
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'habit_mastery_league.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // keep relational deletes consistent for habit logs.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // habits table keeps user-defined routines.
        await db.execute('''
CREATE TABLE habits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'General',
  frequency TEXT NOT NULL DEFAULT 'daily',
  start_date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''');
        // logs table stores daily status by habit.
        await db.execute('''
CREATE TABLE habit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  status TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
);
''');
        // one status per habit per date.
        await db.execute(
          'CREATE UNIQUE INDEX idx_habit_logs_habit_date ON habit_logs(habit_id, date);',
        );
      },
    );
    return _db!;
  }

  Future<void> closeDb() async {
    await _db?.close();
    _db = null;
  }
}
