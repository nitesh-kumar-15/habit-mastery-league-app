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

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Progress'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Missions'),
                  Tab(text: 'Badges'),
                ],
              ),
            ),
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
                : TabBarView(
                    children: [
                      _OverviewTab(
                        activeHabits: habits.length,
                        total: total,
                        week: week,
                        bestStreak: bestStreak,
                      ),
                      _MissionsTab(missions: missions),
                      _BadgesTab(badges: badges),
                    ],
                  ),
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.activeHabits,
    required this.total,
    required this.week,
    required this.bestStreak,
  });

  final int activeHabits;
  final int total;
  final int week;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Active habits',
                value: '$activeHabits',
                icon: Icons.track_changes,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Total check-ins',
                value: '$total',
                icon: Icons.task_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}

class _MissionsTab extends StatelessWidget {
  const _MissionsTab({required this.missions});

  final List<MissionItem> missions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: missions
          .map(
            (m) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (m.done)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('Done!'),
                          )
                        else
                          Text('${m.progress}/${m.target}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 9,
                        value: m.target == 0 ? 0 : m.progress / m.target,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.badges});

  final List<BadgeItem> badges;

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary,
              ],
            ),
          ),
          child: Text(
            '$unlocked / ${badges.length} badges unlocked',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        ...badges.map(
          (b) => Card(
            child: ListTile(
              leading: Icon(
                b.unlocked ? Icons.workspace_premium : Icons.lock_outline,
                color: b.unlocked ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(b.title),
              subtitle: Text(b.description),
              trailing: b.unlocked ? const Icon(Icons.check_circle) : null,
            ),
          ),
        ),
      ],
    );
  }
}
