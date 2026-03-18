import '../utils/app_dates.dart';
import 'habit_repository.dart';

class CoachTip {
  const CoachTip({required this.title, required this.body, this.habitId});

  final String title;
  final String body;
  final int? habitId;
}

/// rule-based coach using only local sqlite history (proposal).
class CoachService {
  const CoachService();

  Future<List<CoachTip>> tipsForUser(HabitRepository repo) async {
    final habits = await repo.getAllHabits();
    if (habits.isEmpty) {
      return const [
        CoachTip(
          title: 'Welcome',
          body: 'Add a habit to get personalized tips based on your check-ins.',
        ),
      ];
    }

    final tips = <CoachTip>[];
    final today = AppDates.today();

    for (final h in habits) {
      final missed = await repo.missedInLast7Days(h.id);
      if (missed >= 3) {
        tips.add(
          CoachTip(
            habitId: h.id,
            title: 'Ease up on "${h.title}"',
            body:
                'You marked this missed $missed times in the last 7 days. Try a smaller goal or a different time of day.',
          ),
        );
      }

      final streak = await repo.streakEndingOn(h.id, today);
      if (streak >= 10) {
        tips.add(
          CoachTip(
            habitId: h.id,
            title: 'Level up "${h.title}"',
            body:
                'You have a $streak-day streak. Consider an advanced mission or a slightly higher target.',
          ),
        );
      }

      final wk = await repo.weekdayCompletionsCount(h.id);
      final we = await repo.weekendCompletionsCount(h.id);
      if (wk + we >= 5 && wk >= we * 3 && we <= 2) {
        tips.add(
          CoachTip(
            habitId: h.id,
            title: 'Weekday rhythm',
            body:
                'Most of your completions for "${h.title}" land on weekdays. You could mark it as weekdays-only to reduce guilt on weekends.',
          ),
        );
      }
    }

    if (tips.isEmpty) {
      tips.add(
        const CoachTip(
          title: 'Keep going',
          body: 'Complete a few more days to unlock tailored suggestions.',
        ),
      );
    }

    return tips.take(5).toList();
  }
}
