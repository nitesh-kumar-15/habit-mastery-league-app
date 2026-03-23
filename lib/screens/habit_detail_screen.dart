import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/habit_repository.dart';
import '../utils/app_dates.dart';
import 'habit_form_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HabitRepository>();

    return FutureBuilder(
      // fetch habit, logs, and streak together for one render pass.
      future: Future.wait([
        repo.getHabit(habitId),
        repo.getLogsForHabit(habitId),
        repo.streakEndingOn(habitId, AppDates.today()),
      ]),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 8),
                    const Text('Could not load habit details.'),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final habit = snap.data![0] as Habit?;
        final logs = snap.data![1] as List<HabitLog>;
        final streak = snap.data![2] as int;
        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: const Center(child: Text('Habit not found')),
          );
        }

        final completed = logs.where((l) => l.status == 'completed').length;
        final missed = logs.where((l) => l.status == 'missed').length;
        final denom = completed + missed;
        // completion rate ignores days without a check-in.
        final pct = denom == 0 ? 0.0 : (100 * completed / denom);

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HabitFormScreen(habitId: habit.id),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete habit?'),
                      content: Text('Remove "${habit.title}" and its logs?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await repo.deleteHabit(habit.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (habit.description.isNotEmpty)
                Text(habit.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: logs.isEmpty ? '0' : '$streak days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Completion',
                      value: denom == 0 ? '—' : '${pct.round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Recent check-ins', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                Text(
                  'No check-ins yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                ...logs.take(14).map(
                      (l) => ListTile(
                        dense: true,
                        title: Text(DateFormat.yMMMd().format(AppDates.parseDate(l.date))),
                        trailing: Icon(
                          l.status == 'completed' ? Icons.check_circle : Icons.cancel,
                          color: l.status == 'completed'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
