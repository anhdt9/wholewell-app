import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Tệp sao lưu được người dùng chọn qua SAF (hoặc bản giả trong test).
class PickedBackupFile {
  final String name;
  final Uint8List bytes;

  const PickedBackupFile({required this.name, required this.bytes});
}

/// Giao diện chọn/lưu tệp qua bộ chọn của hệ thống (Android SAF; không cần quyền bộ nhớ).
abstract interface class BackupFileProvider {
  /// Mở bộ chọn nơi lưu tệp. Trả về tên tệp đã lưu, hoặc `null` nếu người dùng hủy.
  Future<String?> saveFile({
    required String suggestedName,
    required String mimeType,
    required Uint8List bytes,
  });

  /// Mở bộ chọn tệp để đọc bản sao lưu. Trả về `null` nếu người dùng hủy.
  Future<PickedBackupFile?> pickFile();
}

/// Cài đặt SAF trên Android qua `MethodChannel`.
class AndroidBackupFileProvider implements BackupFileProvider {
  static const _channel = MethodChannel('vn.wholewell.app/backup_files');

  const AndroidBackupFileProvider();

  @override
  Future<String?> saveFile({
    required String suggestedName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    return _channel.invokeMethod<String>('saveFile', <String, Object?>{
      'suggestedName': suggestedName,
      'mimeType': mimeType,
      'bytes': bytes,
    });
  }

  @override
  Future<PickedBackupFile?> pickFile() async {
    final res = await _channel.invokeMapMethod<String, Object?>('pickFile');
    if (res == null) return null;
    final bytes = res['bytes'];
    if (bytes is! Uint8List) return null;
    final name = res['name'] as String? ?? 'backup.wwbackup';
    return PickedBackupFile(name: name, bytes: bytes);
  }
}

/// Bản ghi lưu tệp giả trong test giao diện.
class SavedFakeFile {
  final String suggestedName;
  final String mimeType;
  final Uint8List bytes;
  final String returnedName;

  SavedFakeFile({
    required this.suggestedName,
    required this.mimeType,
    required this.bytes,
    required this.returnedName,
  });
}

/// Bản giả cho test `BackupFileProvider`.
class FakeBackupFileProvider implements BackupFileProvider {
  String? nextSaveName;
  bool cancelSave = false;
  Object? saveError;
  PickedBackupFile? nextPickFile;
  Object? pickError;
  final List<SavedFakeFile> savedFiles = [];

  @override
  Future<String?> saveFile({
    required String suggestedName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (saveError != null) Error.throwWithStackTrace(saveError!, StackTrace.current);
    if (cancelSave) return null;
    final name = nextSaveName ?? suggestedName;
    savedFiles.add(
      SavedFakeFile(
        suggestedName: suggestedName,
        mimeType: mimeType,
        bytes: Uint8List.fromList(bytes),
        returnedName: name,
      ),
    );
    return name;
  }

  @override
  Future<PickedBackupFile?> pickFile() async {
    if (pickError != null) Error.throwWithStackTrace(pickError!, StackTrace.current);
    return nextPickFile;
  }
}

// ---------------------------------------------------------------- Interface cho Phần 7b (Google Drive)

class GoogleAuthAccount {
  final String id;
  final String email;

  const GoogleAuthAccount({required this.id, required this.email});
}

/// Kết quả kiểm tra hoặc đăng nhập Google.
sealed class GoogleAuthOutcome {
  const GoogleAuthOutcome();
}

final class GoogleAuthSignedIn extends GoogleAuthOutcome {
  final GoogleAuthAccount account;
  const GoogleAuthSignedIn(this.account);
}

final class GoogleAuthCancelled extends GoogleAuthOutcome {
  const GoogleAuthCancelled();
}

final class GoogleAuthFailed extends GoogleAuthOutcome {
  final String reason;
  final bool isNetworkError;
  const GoogleAuthFailed(this.reason, {this.isNetworkError = false});
}

/// Interface đăng nhập Google cho Google Drive `appDataFolder`.
abstract interface class GoogleAuth {
  Future<GoogleAuthAccount?> currentUser();
  Future<GoogleAuthOutcome> signIn();

  /// Thử khôi phục phiên im lặng khi mở app (dùng cho `DrivePendingDeleteStore`).
  /// Trả `null` nếu chưa đăng nhập / đã thu hồi quyền; ném lỗi nếu lỗi mạng tạm thời.
  Future<GoogleAuthAccount?> signInSilently();
  Future<void> signOut();

  /// Thu hồi quyền đã cấp cho ứng dụng và đăng xuất.
  Future<void> disconnect();

  /// Lấy header `Authorization` cho scope `drive.appdata`.
  Future<Map<String, String>?> authHeaders({bool interactive = false});
}

class FakeGoogleAuth implements GoogleAuth {
  GoogleAuthAccount? _user;
  bool cancelled = false;
  String? failReason;
  bool failNetworkOnSignIn = false;
  bool failNetworkOnSilent = false;
  bool silentRevoked = false;
  bool failOnDisconnect = false;
  int signInCalls = 0;
  int signInSilentlyCalls = 0;
  int signOutCalls = 0;
  int disconnectCalls = 0;
  Map<String, String>? fakeHeaders = const {'Authorization': 'Bearer fake-token'};

  FakeGoogleAuth({GoogleAuthAccount? initialUser}) : _user = initialUser;

  @override
  Future<GoogleAuthAccount?> currentUser() async => _user;

  @override
  Future<GoogleAuthOutcome> signIn() async {
    signInCalls++;
    if (cancelled) return const GoogleAuthCancelled();
    if (failNetworkOnSignIn) {
      return const GoogleAuthFailed('network', isNetworkError: true);
    }
    if (failReason != null) return GoogleAuthFailed(failReason!);
    _user ??= const GoogleAuthAccount(id: 'fake-user', email: 'test@example.com');
    silentRevoked = false;
    return GoogleAuthSignedIn(_user!);
  }

  @override
  Future<GoogleAuthAccount?> signInSilently() async {
    signInSilentlyCalls++;
    if (failNetworkOnSilent) throw const SocketException('offline');
    if (silentRevoked) {
      _user = null;
      return null;
    }
    return _user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    if (failOnDisconnect) throw const SocketException('offline');
    _user = null;
  }

  @override
  Future<Map<String, String>?> authHeaders({bool interactive = false}) async {
    if (_user == null) return null;
    return fakeHeaders;
  }
}

class CloudBackupInfo {
  final String id;
  final String name;
  final DateTime modifiedAt;
  final int sizeBytes;

  const CloudBackupInfo({
    required this.id,
    this.name = 'wholewell.wwbackup',
    required this.modifiedAt,
    required this.sizeBytes,
  });
}

/// Interface sao lưu đám mây (`appDataFolder`).
abstract interface class BackupProvider {
  Future<List<CloudBackupInfo>> listBackups();
  Future<CloudBackupInfo?> latestBackup();
  Future<CloudBackupInfo> upload(Uint8List encryptedBackupBytes);
  Future<Uint8List> download(String id);
  Future<void> deleteAll();
}

class _FakeBackupRecord {
  final CloudBackupInfo info;
  final Uint8List bytes;
  const _FakeBackupRecord(this.info, this.bytes);
}

class FakeBackupProvider implements BackupProvider {
  static const int maxRetainedBackups = 3;

  final List<_FakeBackupRecord> _records = [];
  int _seq = 1;
  Object? errorOnList;
  Object? errorOnUpload;
  Object? errorOnDownload;
  Object? errorOnDelete;
  int deleteAllCalls = 0;

  void seedBackup({
    required Uint8List bytes,
    DateTime? modifiedAt,
    String? id,
    String? name,
  }) {
    final idx = _seq++;
    final info = CloudBackupInfo(
      id: id ?? 'fake-cloud-$idx',
      name: name ?? 'wholewell-backup-$idx.wwbackup',
      modifiedAt: modifiedAt ?? DateTime.now(),
      sizeBytes: bytes.length,
    );
    _records.insert(0, _FakeBackupRecord(info, Uint8List.fromList(bytes)));
    _records.sort((a, b) => b.info.modifiedAt.compareTo(a.info.modifiedAt));
  }

  @override
  Future<List<CloudBackupInfo>> listBackups() async {
    if (errorOnList != null) Error.throwWithStackTrace(errorOnList!, StackTrace.current);
    return [for (final r in _records) r.info];
  }

  @override
  Future<CloudBackupInfo?> latestBackup() async {
    final list = await listBackups();
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<CloudBackupInfo> upload(Uint8List encryptedBackupBytes) async {
    if (errorOnUpload != null) Error.throwWithStackTrace(errorOnUpload!, StackTrace.current);
    final copy = Uint8List.fromList(encryptedBackupBytes);
    final idx = _seq++;
    final info = CloudBackupInfo(
      id: 'fake-cloud-$idx',
      name: 'wholewell-backup-$idx.wwbackup',
      modifiedAt: DateTime.now().add(Duration(milliseconds: idx)),
      sizeBytes: copy.length,
    );
    _records.insert(0, _FakeBackupRecord(info, copy));
    if (_records.length > maxRetainedBackups) {
      _records.removeRange(maxRetainedBackups, _records.length);
    }
    return info;
  }

  @override
  Future<Uint8List> download(String id) async {
    if (errorOnDownload != null) Error.throwWithStackTrace(errorOnDownload!, StackTrace.current);
    final rec = _records.cast<_FakeBackupRecord?>().firstWhere(
          (r) => r?.info.id == id,
          orElse: () => null,
        );
    if (rec == null) throw StateError('No cloud backup with id $id');
    return Uint8List.fromList(rec.bytes);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    if (errorOnDelete != null) Error.throwWithStackTrace(errorOnDelete!, StackTrace.current);
    _records.clear();
  }
}

/// Cờ chờ xóa bản sao lưu Drive nằm ngoài CSDL đã mã hóa (đồng bộ khi xóa sạch cục bộ).
abstract interface class DrivePendingDeleteStore {
  Future<bool> hasPendingDelete();
  Future<void> markPendingDelete();
  Future<void> clearPendingDelete();
}

class InMemoryDrivePendingDeleteStore implements DrivePendingDeleteStore {
  bool _pending = false;

  @override
  Future<bool> hasPendingDelete() async => _pending;

  @override
  Future<void> markPendingDelete() async {
    _pending = true;
  }

  @override
  Future<void> clearPendingDelete() async {
    _pending = false;
  }
}

class FileDrivePendingDeleteStore implements DrivePendingDeleteStore {
  final File file;

  const FileDrivePendingDeleteStore(this.file);

  @override
  Future<bool> hasPendingDelete() async {
    if (!file.existsSync()) return false;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map && decoded['pendingDelete'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> markPendingDelete() async {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({'pendingDelete': true}), flush: true);
  }

  @override
  Future<void> clearPendingDelete() async {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
