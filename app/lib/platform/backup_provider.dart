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
    if (saveError != null) throw saveError!;
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
    if (pickError != null) throw pickError!;
    return nextPickFile;
  }
}

// ---------------------------------------------------------------- Interface cho Phần 7b (Google Drive)

class GoogleAuthAccount {
  final String id;
  final String email;

  const GoogleAuthAccount({required this.id, required this.email});
}

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
  const GoogleAuthFailed(this.reason);
}

/// Interface đăng nhập Google cho Google Drive `appDataFolder` (sẽ cài thật ở Phần 7b).
abstract interface class GoogleAuth {
  Future<GoogleAuthAccount?> currentUser();
  Future<GoogleAuthOutcome> signIn();
  Future<void> signOut();
}

class FakeGoogleAuth implements GoogleAuth {
  GoogleAuthAccount? _user;
  bool cancelled = false;
  String? failReason;

  @override
  Future<GoogleAuthAccount?> currentUser() async => _user;

  @override
  Future<GoogleAuthOutcome> signIn() async {
    if (cancelled) return const GoogleAuthCancelled();
    if (failReason != null) return GoogleAuthFailed(failReason!);
    _user = const GoogleAuthAccount(id: 'fake-user', email: 'test@example.com');
    return GoogleAuthSignedIn(_user!);
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}

class CloudBackupInfo {
  final String id;
  final DateTime modifiedAt;
  final int sizeBytes;

  const CloudBackupInfo({
    required this.id,
    required this.modifiedAt,
    required this.sizeBytes,
  });
}

/// Interface sao lưu đám mây (cài thật ở Phần 7b).
abstract interface class BackupProvider {
  Future<CloudBackupInfo?> latestBackup();
  Future<CloudBackupInfo> upload(Uint8List encryptedBackupBytes);
  Future<Uint8List> download(String id);
  Future<void> deleteAll();
}

class FakeBackupProvider implements BackupProvider {
  Uint8List? _stored;
  CloudBackupInfo? _info;
  Object? errorOnUpload;
  Object? errorOnDelete;

  @override
  Future<CloudBackupInfo?> latestBackup() async => _info;

  @override
  Future<CloudBackupInfo> upload(Uint8List encryptedBackupBytes) async {
    if (errorOnUpload != null) throw errorOnUpload!;
    _stored = Uint8List.fromList(encryptedBackupBytes);
    _info = CloudBackupInfo(
      id: 'fake-cloud-1',
      modifiedAt: DateTime.now(),
      sizeBytes: _stored!.length,
    );
    return _info!;
  }

  @override
  Future<Uint8List> download(String id) async {
    if (_stored == null) throw StateError('No cloud backup');
    return Uint8List.fromList(_stored!);
  }

  @override
  Future<void> deleteAll() async {
    if (errorOnDelete != null) throw errorOnDelete!;
    _stored = null;
    _info = null;
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
