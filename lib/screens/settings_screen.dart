import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Text('🎓', style: TextStyle(fontSize: 22)),
              ),
              title: const Text(
                'Student Tracker',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Local-first habit workflow'),
            ),
          ),
          _SectionHeader(title: 'Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  s.setThemeMode(set.first);
                }
              },
            ),
          ),
          _SectionHeader(title: 'Notifications'),
          ListTile(
            title: const Text('Daily reminder time'),
            subtitle: Text(
              '${s.reminderTimeOfDay.hour.toString().padLeft(2, '0')}:'
              '${s.reminderTimeOfDay.minute.toString().padLeft(2, '0')} (saved locally)',
            ),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: s.reminderTimeOfDay,
              );
              if (picked != null) {
                final minutes = picked.hour * 60 + picked.minute;
                await s.setReminderMinutes(minutes);
              }
            },
          ),
          _SectionHeader(title: 'Coach & tips'),
          SwitchListTile(
            title: const Text('Show coach tips on Home'),
            subtitle: const Text('Hide the rule-based coach panel if you prefer a calmer Today screen.'),
            value: s.showMotivationTips,
            onChanged: (v) => s.setShowMotivationTips(v),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
