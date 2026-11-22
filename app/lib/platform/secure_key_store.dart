import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kho khóa bí mật của hệ điều hành (Android Keystore, Windows Credential
/// Manager, Keychain). Engine và giao diện chỉ gọi interface này.
abstract class SecureKeyStore {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
  Future<void> delete(String name);
}

/// Bản thật, qua flutter_secure_storage.
class FlutterSecureKeyStore implements SecureKeyStore {
  final FlutterSecureStorage _storage;

  FlutterSecureKeyStore()
      : _storage = const FlutterSecureStorage(
          // Chỉ máy này, không đồng bộ iCloud Keychain.
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
        );

  @override
  Future<String?> read(String name) => _storage.read(key: name);

  @override
  Future<void> write(String name, String value) => _storage.write(key: name, value: value);

  @override
  Future<void> delete(String name) => _storage.delete(key: name);
}

/// Bản giả cho test. [failing] = true thì mọi lệnh ném lỗi (giả lập kho khóa hỏng).
class InMemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> values = {};
  bool failing = false;

  void _check() {
    if (failing) throw StateError('kho khóa giả đang lỗi');
  }

  @override
  Future<String?> read(String name) async {
    _check();
    return values[name];
  }

  @override
  Future<void> write(String name, String value) async {
    _check();
    values[name] = value;
  }

  @override
  Future<void> delete(String name) async {
    _check();
    values.remove(name);
  }
}
