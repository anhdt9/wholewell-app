import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_initializer.dart';
import 'core/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppInitializer.initialize();
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(database)], child: const WholeWellApp()));
}
