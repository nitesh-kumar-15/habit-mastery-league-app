import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/shell_screen.dart';
import 'services/database_helper.dart';
import 'services/habit_repository.dart';
import 'services/prefs_service.dart';
import 'services/settings_controller.dart';

class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // keep app-wide state in one place for predictable rebuilds.
      providers: [
        ChangeNotifierProvider(
          create: (_) => HabitRepository(DatabaseHelper.instance),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(PrefsService())..load(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          if (!settings.loaded) {
            // wait for local preferences before drawing main ui.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return MaterialApp(
            title: 'Habit Mastery League',
            debugShowCheckedModeBanner: false,
            // theme mode comes from local preferences.
            themeMode: settings.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B4EE6),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFB8A4FF),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const ShellScreen(),
          );
        },
      ),
    );
  }
}
