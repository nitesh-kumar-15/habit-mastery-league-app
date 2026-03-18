import '../utils/app_dates.dart';
import 'habit_repository.dart';

class MissionItem {
  const MissionItem({
    required this.title,
    required this.progress,
    required this.target,
    required this.done,
  });

  final String title;
  final int progress;
  final int target;
  final bool done;
}

class BadgeItem {
  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

class MissionsService {
  const MissionsService();

  Future<List<MissionItem>> missions(HabitRepository repo) async {
    final week = await repo.completionsThisWeek();
    final habits = await repo.getAllHabits();
    final today = AppDates.today();

    var bestStreak = 0;
    for (final h in habits) {
      final s = await repo.streakEndingOn(h.id, today);
      if (s > bestStreak) bestStreak = s;
    }

    return [
      MissionItem(
        title: 'Complete 5 check-ins this week',
        progress: week.clamp(0, 5),
        target: 5,
        done: week >= 5,
      ),
      MissionItem(
        title: 'Reach a 7-day streak on any habit',
        progress: bestStreak.clamp(0, 7),
        target: 7,
        done: bestStreak >= 7,
      ),
    ];
  }

  Future<List<BadgeItem>> badges(HabitRepository repo) async {
    final habits = await repo.getAllHabits();
    final today = AppDates.today();
    final total = await repo.totalCompletionsAllHabits();

    var bestStreak = 0;
    for (final h in habits) {
      final s = await repo.streakEndingOn(h.id, today);
      if (s > bestStreak) bestStreak = s;
    }

    return [
      BadgeItem(
        id: 'first_log',
        title: 'First step',
        description: 'Complete your first check-in.',
        unlocked: total >= 1,
      ),
      BadgeItem(
        id: 'streak_7',
        title: 'Week warrior',
        description: '7-day streak on any habit.',
        unlocked: bestStreak >= 7,
      ),
      BadgeItem(
        id: 'ten_completions',
        title: 'Ten strong',
        description: '10 total completions across all habits.',
        unlocked: total >= 10,
      ),
    ];
  }
}
