import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'backup_provider.dart';

/// Scope tối thiểu chỉ truy cập thư mục ẩn `appDataFolder` của riêng app.
const driveAppDataScope = drive.DriveApi.driveAppdataScope;

/// Cài đặt [GoogleAuth] thật qua `google_sign_in` v7 (dùng 1 Google Cloud Project duy nhất).
class GoogleSignInAuth implements GoogleAuth {
  final String? serverClientId;
  Future<void>? _initFuture;
  GoogleSignInAccount? _account;

  GoogleSignInAuth({this.serverClientId});

  Future<void> _ensureInitialized() => _initFuture ??= GoogleSignIn.instance.initialize(serverClientId: serverClientId);

  static GoogleAuthAccount _toAccount(GoogleSignInAccount acc) => GoogleAuthAccount(id: acc.id, email: acc.email);

  @override
  Future<GoogleAuthAccount?> currentUser() async {
    await _ensureInitialized();
    final acc = _account;
    return acc == null ? null : _toAccount(acc);
  }

  @override
  Future<GoogleAuthOutcome> signIn() async {
    await _ensureInitialized();
    try {
      final acc = await GoogleSignIn.instance.authenticate(scopeHint: const [driveAppDataScope]);
      // Yêu cầu quyền scope drive.appdata ngay nếu chưa cấp.
      await acc.authorizationClient.authorizeScopes(const [driveAppDataScope]);
      _account = acc;
      return GoogleAuthSignedIn(_toAccount(acc));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        return const GoogleAuthCancelled();
      }
      final desc = (e.description ?? '').toLowerCase();
      final isNet = desc.contains('network') || desc.contains('socket') || desc.contains('timeout');
      return GoogleAuthFailed(e.description ?? e.code.name, isNetworkError: isNet);
    } on SocketException catch (e) {
      return GoogleAuthFailed(e.message, isNetworkError: true);
    } on Object catch (e) {
      return GoogleAuthFailed(e.toString());
    }
  }

  @override
  Future<GoogleAuthAccount?> signInSilently() async {
    await _ensureInitialized();
    try {
      final cached = _account;
      if (cached != null) {
        final authz = await cached.authorizationClient.authorizationForScopes(const [driveAppDataScope]);
        if (authz != null) {
          return _toAccount(cached);
        }
      }
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication(reportAllExceptions: true);
      final acc = attempt == null ? null : await attempt;
      if (acc == null) {
        _account = null;
        return null;
      }
      final authz = await acc.authorizationClient.authorizationForScopes(const [driveAppDataScope]);
      if (authz == null) {
        _account = null;
        return null;
      }
      _account = acc;
      return _toAccount(acc);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      final desc = (e.description ?? '').toLowerCase();
      if (desc.contains('network') || desc.contains('timeout') || desc.contains('connection')) {
        throw SocketException(e.description ?? e.code.name);
      }
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    _account = null;
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> disconnect() async {
    await _ensureInitialized();
    _account = null;
    await GoogleSignIn.instance.disconnect();
  }

  @override
  Future<Map<String, String>?> authHeaders({bool interactive = false}) async {
    await _ensureInitialized();
    final client = _account?.authorizationClient ?? GoogleSignIn.instance.authorizationClient;
    return client.authorizationHeaders(const [driveAppDataScope], promptIfNecessary: interactive);
  }
}

class _GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// Cài đặt [BackupProvider] qua Google Drive API v3 (`spaces: 'appDataFolder'`), giữ tối đa 3 bản.
class GoogleDriveBackupProvider implements BackupProvider {
  static const int maxRetainedBackups = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration transferTimeout = Duration(seconds: 60);

  final GoogleAuth auth;

  const GoogleDriveBackupProvider({required this.auth});

  Future<T> _withDrive<T>(Future<T> Function(drive.DriveApi api) fn) async {
    final headers = await auth.authHeaders(interactive: false).timeout(requestTimeout);
    if (headers == null) {
      throw StateError('Chưa có quyền truy cập Google Drive.');
    }
    final client = _GoogleAuthHttpClient(headers);
    try {
      return await fn(drive.DriveApi(client));
    } finally {
      client.close();
    }
  }

  static CloudBackupInfo _toInfo(drive.File f) => CloudBackupInfo(
    id: f.id ?? '',
    name: f.name ?? 'wholewell.wwbackup',
    modifiedAt: (f.modifiedTime ?? DateTime.now()).toLocal(),
    sizeBytes: int.tryParse(f.size ?? '') ?? 0,
  );

  @override
  Future<List<CloudBackupInfo>> listBackups() => _withDrive((api) async {
    final list = await api.files
        .list(
          spaces: 'appDataFolder',
          orderBy: 'modifiedTime desc',
          pageSize: 10,
          $fields: 'files(id, name, modifiedTime, size)',
        )
        .timeout(requestTimeout);
    final files = list.files ?? const <drive.File>[];
    return [
      for (final f in files)
        if (f.id != null) _toInfo(f),
    ];
  });

  @override
  Future<CloudBackupInfo?> latestBackup() async {
    final all = await listBackups();
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<CloudBackupInfo> upload(Uint8List encryptedBackupBytes) => _withDrive((api) async {
    final n = DateTime.now().toUtc();
    String p2(int v) => v.toString().padLeft(2, '0');
    final fileName =
        'wholewell-${n.year}${p2(n.month)}${p2(n.day)}-${p2(n.hour)}${p2(n.minute)}${p2(n.second)}.wwbackup';
    final meta = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder']
      ..mimeType = 'application/octet-stream';
    final created = await api.files
        .create(
          meta,
          uploadMedia: drive.Media(Stream<List<int>>.value(encryptedBackupBytes), encryptedBackupBytes.length),
          $fields: 'id, name, modifiedTime, size',
        )
        .timeout(transferTimeout);

    // Chỉ giữ tối đa 3 bản gần nhất sau khi đã tải lên thành công bản mới.
    final list = await api.files
        .list(spaces: 'appDataFolder', orderBy: 'modifiedTime desc', pageSize: 20, $fields: 'files(id, modifiedTime)')
        .timeout(requestTimeout);
    final existing = list.files ?? const <drive.File>[];
    if (existing.length > maxRetainedBackups) {
      for (final old in existing.skip(maxRetainedBackups)) {
        final oldId = old.id;
        if (oldId != null && oldId != created.id) {
          try {
            await api.files.delete(oldId).timeout(requestTimeout);
          } on Object {
            // Không làm hỏng thao tác tải lên chính nếu dọn bản thừa thất bại nhẹ.
          }
        }
      }
    }
    return _toInfo(created);
  });

  @override
  Future<Uint8List> download(String id) => _withDrive((api) async {
    final res = await api.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia).timeout(transferTimeout);
    if (res is! drive.Media) {
      throw StateError('Không tải được dữ liệu tệp sao lưu.');
    }
    final builder = BytesBuilder(copy: false);
    await (() async {
      await for (final chunk in res.stream) {
        builder.add(chunk);
      }
    })().timeout(transferTimeout);
    return builder.takeBytes();
  });

  @override
  Future<void> deleteAll() => _withDrive((api) async {
    String? pageToken;
    do {
      final list = await api.files
          .list(spaces: 'appDataFolder', pageSize: 100, pageToken: pageToken, $fields: 'nextPageToken, files(id)')
          .timeout(requestTimeout);
      for (final f in list.files ?? const <drive.File>[]) {
        final id = f.id;
        if (id != null) {
          await api.files.delete(id).timeout(requestTimeout);
        }
      }
      pageToken = list.nextPageToken;
    } while (pageToken != null);
  });
}
