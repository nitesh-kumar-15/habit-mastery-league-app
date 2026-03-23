import 'package:flutter/material.dart';

import 'app.dart';
import 'services/database_helper.dart';

Future<void> main() async {
  // ensure plugin services are ready before opening sqlite.
  WidgetsFlutterBinding.ensureInitialized();
  // warm up db once to avoid first-use delay on initial screens.
  await DatabaseHelper.instance.database;
  runApp(const HabitMasteryApp());
}
