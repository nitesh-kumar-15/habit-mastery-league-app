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

  void _onRepo() {
    if (_repo == null) return;
    // refresh home data whenever repository notifies.
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
        title: const Text('Today'),
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
          // pull-to-refresh forces a fresh local query.
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
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (settings.showMotivationTips) CoachPanel(tips: data.tips),
                  ...data.habits.map((h) => _HabitTodayTile(habit: h)),
                ],
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(habit.title),
                  subtitle: Text('${habit.category} · ${habit.frequency}'),
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
                        // disable duplicate completed check-ins for today.
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
                        // disable duplicate missed check-ins for today.
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
