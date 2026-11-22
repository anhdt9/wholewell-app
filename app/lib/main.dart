import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:health_engine/health_engine.dart';

import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'state/journal_repository.dart';
import 'ui/home_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pack = ReferencePack.fromJsonString(
      await rootBundle.loadString('assets/reference_pack.json'));
  runApp(SucKhoeApp(state: AppState(pack: pack, repo: InMemoryJournalRepository())));
}

class SucKhoeApp extends StatelessWidget {
  final AppState state;
  const SucKhoeApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Sức khỏe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) =>
              state.profile == null ? const ProfileScreen(firstRun: true) : const HomeScreen(),
        ),
      ),
    );
  }
}
