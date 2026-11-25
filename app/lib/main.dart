import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:food_library/food_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:path_provider/path_provider.dart';

import 'platform/android_db_key_store.dart';
import 'platform/local_food_library_store.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'ui/data_status_screen.dart';
import 'ui/home_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pack = ReferencePack.fromJsonString(
      await rootBundle.loadString('assets/reference_pack.json'));
  final manifest = jsonDecode(
      await rootBundle.loadString('assets/food_library_manifest.json')) as Map<String, dynamic>;
  final AppState state;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Android: filesDir (không vào sao lưu tự động, xem AndroidManifest).
    final dir = await getApplicationSupportDirectory();
    final libVersion = manifest['libraryVersion'] as String;
    final libSha = manifest['sha256'] as String;
    state = AppState(
      pack: pack,
      opener: DbOpener(files: DbFiles(dir), keys: const AndroidDbKeyStore()),
      openFoodLibrary: () => SqliteFoodLibraryRepository.open(
        store: FlutterFoodLibraryAssetStore(supportDir: dir),
        libraryVersion: libVersion,
        expectedSha256: libSha,
      ),
    );
  } else {
    // iOS (Keychain, Application Support) làm khi có bản iOS.
    state = AppState.unsupportedPlatform(pack: pack);
  }
  runApp(WholeWellApp(state: state));
  unawaited(state.start());
}

class WholeWellApp extends StatefulWidget {
  final AppState state;
  const WholeWellApp({super.key, required this.state});

  @override
  State<WholeWellApp> createState() => _WholeWellAppState();
}

class _WholeWellAppState extends State<WholeWellApp> {
  late final AppLifecycleListener _lifecycle;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Máy đang khóa: đọc lại khóa khi app trở lại.
    _lifecycle = AppLifecycleListener(onResume: () {
      final s = widget.state.status;
      if (s == DataStatus.waitingForUnlock || s == DataStatus.lowStorage) widget.state.start();
    });
    widget.state.addListener(_onState);
  }

  void _onState() {
    final s = widget.state;
    if (s.saveFailed) {
      s.clearSaveFailed();
      _messenger.currentState?.showSnackBar(const SnackBar(content: Text('Chưa lưu được. Thử lại')));
    }
    if (s.readFailed) {
      s.clearReadFailed();
      _messenger.currentState?.showSnackBar(SnackBar(
        content: const Text('Chưa đọc được dữ liệu.'),
        action: SnackBarAction(label: 'Thử lại', onPressed: s.reload),
      ));
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'WholeWell',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messenger,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) => switch (state.status) {
            DataStatus.welcome => const ProfileScreen(firstRun: true),
            DataStatus.ready =>
              state.profile == null ? const ProfileScreen(firstRun: true) : const HomeScreen(),
            final s => DataStatusScreen(status: s),
          },
        ),
      ),
    );
  }
}
