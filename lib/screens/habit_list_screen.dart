import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final _search = TextEditingController();
  String _category = 'All';

  static const _categories = ['All', 'Study', 'Health', 'Productivity', 'Finance', 'General'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HabitRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All habits'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add habit',
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const HabitFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by title',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final c = _categories[i];
                final selected = _category == c;
                return FilterChip(
                  selected: selected,
                  label: Text(c),
                  onSelected: (_) => setState(() => _category = c),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Habit>>(
              future: repo.getAllHabits(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 8),
                          const Text('Could not load habits.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var list = snap.data!;
                // keep filters lightweight for quick local search.
                final q = _search.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  list = list.where((h) => h.title.toLowerCase().contains(q)).toList();
                }
                if (_category != 'All') {
                  list = list.where((h) => h.category == _category).toList();
                }
                if (list.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 48),
                      Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        snap.data!.isEmpty ? 'Add your first habit' : 'No habits match filters',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (snap.data!.isEmpty)
                        Center(
                          child: FilledButton(
                            onPressed: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(builder: (_) => const HabitFormScreen()),
                              );
                            },
                            child: const Text('Add habit'),
                          ),
                        ),
                    ],
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final h = list[i];
                    return Card(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: ListTile(
                        leading: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Center(
                            child: Text(_iconForCategory(h.category), style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        title: Text(
                          h.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _TagChip(text: h.category),
                              _TagChip(text: h.frequency),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: h.id)),
                          );
                        },
                        onLongPress: () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Edit'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push<void>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HabitFormScreen(habitId: h.id),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                    title: const Text('Delete'),
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Delete habit?'),
                                          content: Text('Remove "${h.title}" and its logs?'),
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
                                        await repo.deleteHabit(h.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
