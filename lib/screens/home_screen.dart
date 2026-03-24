import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/coach_service.dart';
import '../services/habit_repository.dart';
import '../services/settings_controller.dart';
import '../utils/app_dates.dart';
import '../widgets/coach_panel.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class _HomeData {
  _HomeData(this.habits, this.tips);

  final List<Habit> habits;
  final List<CoachTip> tips;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HabitRepository? _repo;
  Future<_HomeData>? _future;
  var _listenerAdded = false;

  Future<_HomeData> _load(HabitRepository repo) async {
    // load today's feed and coach tips together.
    final habits = await repo.habitsForDay(DateTime.now());
    final tips = await const CoachService().tipsForUser(repo);
    return _HomeData(habits, tips);
  }

  Future<int> _completedToday(HabitRepository repo, List<Habit> habits) async {
    final today = AppDates.today();
    final logs = await Future.wait(habits.map((h) => repo.getLogForDay(h.id, today)));
    return logs.where((l) => l?.status == 'completed').length;
  }

  void _onRepo() {
    if (_repo == null) return;
    setState(() {
      _future = _load(_repo!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= context.read<HabitRepository>();
    if (!_listenerAdded) {
      _listenerAdded = true;
      _repo!.addListener(_onRepo);
      _future = _load(_repo!);
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onRepo);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || _future == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Today')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 8),
                    const Text(
                      'Could not load today view.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _future = _load(context.read<HabitRepository>());
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final data = snap.data!;
        final repo = context.read<HabitRepository>();
        return _buildBody(context, repo, settings, data);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HabitRepository repo,
    SettingsController settings,
    _HomeData data,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitFlow'),
        actions: [
          IconButton(
            tooltip: 'Add habit',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const HabitFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load(repo);
          });
          await _future;
        },
        child: data.habits.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add your first habit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Build streaks, missions, and offline progress—start with one small habit.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(builder: (_) => const HabitFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add habit'),
                    ),
                  ),
                ],
              )
            : FutureBuilder<int>(
                future: _completedToday(repo, data.habits),
                builder: (context, completeSnap) {
                  final doneCount = completeSnap.data ?? 0;
                  final totalCount = data.habits.length;
                  final pct = totalCount == 0 ? 0.0 : doneCount / totalCount;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDates.today(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$doneCount of $totalCount habits completed',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                value: pct,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (settings.showMotivationTips) CoachPanel(tips: data.tips),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Text(
                          "Today's habits",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      ...data.habits.map((h) => _HabitTodayTile(habit: h)),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _HabitTodayTile extends StatelessWidget {
  const _HabitTodayTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HabitRepository>();
    final today = AppDates.today();

    return FutureBuilder<HabitLog?>(
      future: repo.getLogForDay(habit.id, today),
      builder: (context, snap) {
        final log = snap.data;
        final status = log?.status;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Center(
                      child: Text(
                        _iconForCategory(habit.category),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    habit.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaChip(text: habit.category),
                      _MetaChip(text: habit.frequency),
                    ],
                  ),
                  trailing: status == 'completed'
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : status == 'missed'
                          ? Icon(Icons.cancel, color: Theme.of(context).colorScheme.error)
                          : null,
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HabitDetailScreen(habitId: habit.id),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: status == 'completed'
                            ? null
                            : () async {
                          try {
                            await repo.upsertLog(
                              habitId: habit.id,
                              date: today,
                              status: 'completed',
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Could not save. Please try again.'),
                                  action: SnackBarAction(
                                    label: 'Retry',
                                    onPressed: () async {
                                      try {
                                        await repo.upsertLog(
                                          habitId: habit.id,
                                          date: today,
                                          status: 'completed',
                                        );
                                      } catch (_) {}
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Done'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status == 'missed'
                            ? null
                            : () async {
                          try {
                            await repo.upsertLog(
                              habitId: habit.id,
                              date: today,
                              status: 'missed',
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not save. Please try again.'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Miss'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _iconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'study':
      return '📚';
    case 'health':
      return '🍎';
    case 'productivity':
      return '⚡';
    case 'finance':
      return '💰';
    default:
      return '🎯';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
