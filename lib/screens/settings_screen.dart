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
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Theme follows Material; pick light, dark, or system.'),
          ),
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
          const Divider(),
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
