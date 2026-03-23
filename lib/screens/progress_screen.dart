import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../services/missions_service.dart';
import '../utils/app_dates.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HabitRepository>();
    const missionsSvc = MissionsService();

    return FutureBuilder(
      future: Future.wait([
        repo.getAllHabits(),
        repo.totalCompletionsAllHabits(),
        repo.completionsThisWeek(),
        missionsSvc.missions(repo),
        missionsSvc.badges(repo),
        _bestStreak(repo),
      ]),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Progress')),
            body: const Center(child: Text('Could not load progress right now.')),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Progress')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final habits = snap.data![0] as List<Habit>;
        final total = snap.data![1] as int;
        final week = snap.data![2] as int;
        final missions = snap.data![3] as List<MissionItem>;
        final badges = snap.data![4] as List<BadgeItem>;
        final bestStreak = snap.data![5] as int;

        return Scaffold(
          appBar: AppBar(title: const Text('Progress & missions')),
          body: habits.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 48),
                    Icon(Icons.insights_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Start tracking to see your stats.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Best streak',
                            value: '$bestStreak days',
                            icon: Icons.local_fire_department,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'This week',
                            value: '$week check-ins',
                            icon: Icons.calendar_view_week,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatTile(
                      label: 'Total completions',
                      value: '$total',
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 24),
                    Text('Missions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...missions.map(
                      (m) => Card(
                        child: ListTile(
                          title: Text(m.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: m.target == 0 ? 0 : m.progress / m.target,
                                ),
                              ),
                            ],
                          ),
                          trailing: m.done
                              ? Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary)
                              : Text('${m.progress}/${m.target}'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...badges.map(
                      (b) => ListTile(
                        dense: true,
                        title: Text(b.title),
                        subtitle: Text(b.description),
                        trailing: b.unlocked ? const Icon(Icons.check) : null,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

Future<int> _bestStreak(HabitRepository repo) async {
  final habits = await repo.getAllHabits();
  final today = AppDates.today();
  var best = 0;
  // compute one global streak for quick overview cards.
  for (final h in habits) {
    final s = await repo.streakEndingOn(h.id, today);
    if (s > best) best = s;
  }
  return best;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
