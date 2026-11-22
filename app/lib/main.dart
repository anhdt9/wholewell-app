import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:health_engine/health_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/drift_journal_repository.dart';
import 'data/open_database.dart';
import 'platform/secure_key_store.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'ui/database_error_screen.dart';
import 'ui/home_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pack = ReferencePack.fromJsonString(
      await rootBundle.loadString('assets/reference_pack.json'));
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, dbFileName));
  runApp(StartupGate(pack: pack, file: file, keys: FlutterSecureKeyStore()));
}

/// Mở CSDL mã hóa rồi mới vào app; lỗi thì hiện [DatabaseErrorScreen].
class StartupGate extends StatefulWidget {
  final ReferencePack pack;
  final File file;
  final SecureKeyStore keys;
  const StartupGate({super.key, required this.pack, required this.file, required this.keys});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  AppState? _state;
  DatabaseOpenFailure? _failure;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _failure = null);
    try {
      final db = await openAppDatabase(file: widget.file, keys: widget.keys);
      final state = await AppState.load(pack: widget.pack, repo: DriftJournalRepository(db, widget.pack));
      if (mounted) setState(() => _state = state);
    } on DatabaseOpenError catch (e) {
      if (mounted) setState(() => _failure = e.reason);
    }
  }

  /// Chỉ chạy sau khi người dùng xác nhận hai lần trên [DatabaseErrorScreen].
  Future<void> _reset() async {
    if (widget.file.existsSync()) widget.file.deleteSync();
    await widget.keys.delete(dbKeyName);
    await _open();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state != null) return WholeWellApp(state: state);
    return MaterialApp(
      title: 'WholeWell',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: _failure == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : DatabaseErrorScreen(failure: _failure!, onRetry: _open, onReset: _reset),
    );
  }
}

final _theme = ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true);

class WholeWellApp extends StatelessWidget {
  final AppState state;
  const WholeWellApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'WholeWell',
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) =>
              state.profile == null ? const ProfileScreen(firstRun: true) : const HomeScreen(),
        ),
      ),
    );
  }
}
