import 'package:flutter/services.dart';
import 'package:journal_db/journal_db.dart';

/// [SecureKeyStore] trên Android: Keystore với `setUnlockedDeviceRequired`
/// (android/app/src/main/kotlin/vn/wholewell/app/DbKeyStore.kt).
///
/// Khóa không được ghi ra log; lỗi kênh không mang khóa.
class AndroidDbKeyStore implements SecureKeyStore {
  static const _channel = MethodChannel('vn.wholewell.app/db_key');

  const AndroidDbKeyStore();

  @override
  Future<KeyReadResult> readDbKey() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('read');
      return switch (m?['status']) {
        'present' => KeyPresent(m!['key']! as Uint8List),
        'absent' => const KeyAbsent(),
        'lost' => const KeyLost(),
        _ => const KeyUnavailable(),
      };
    } on Object {
      return const KeyUnavailable();
    }
  }

  @override
  Future<Uint8List> createDbKey() async {
    final key = generateDbKey();
    try {
      await _channel.invokeMethod<void>('create', {'key': key});
    } on PlatformException catch (e) {
      if (e.code == 'exists') throw const KeyAlreadyExistsException();
      throw StateError('Không tạo được khóa (${e.code})');
    }
    return key;
  }

  @override
  Future<void> deleteDbKey() async {
    try {
      await _channel.invokeMethod<void>('delete');
    } on PlatformException catch (e) {
      throw StateError('Không xóa được khóa (${e.code})');
    }
  }

  @override
  Future<bool> isDeviceUnlocked() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceUnlocked') ?? false;
    } on Object {
      return false;
    }
  }
}
