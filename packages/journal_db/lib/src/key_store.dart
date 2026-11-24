/// Giữ khóa CSDL qua kho khóa của hệ điều hành (đặc tả encrypted-db, mục Khóa).
library;

import 'dart:math';
import 'dart:typed_data';

/// Độ dài khóa CSDL (byte).
const dbKeyLength = 32;

/// Kết quả đọc khóa: bốn trạng thái phân biệt, không gộp lỗi vào "không có khóa".
sealed class KeyReadResult {
  const KeyReadResult();
}

/// Có khóa.
final class KeyPresent extends KeyReadResult {
  final Uint8List key;
  const KeyPresent(this.key);
}

/// Không có bản khóa (Android) hoặc Keychain trả `errSecItemNotFound` (iOS).
final class KeyAbsent extends KeyReadResult {
  const KeyAbsent();
}

/// Có bản khóa nhưng không giải mã được vĩnh viễn. Android: alias Keystore không
/// còn, hoặc `KeyPermanentlyInvalidatedException`. Không có trường hợp nào khác.
final class KeyLost extends KeyReadResult {
  const KeyLost();
}

/// Mọi lỗi khác (máy đang khóa, lỗi Keystore riêng của hãng…): chờ rồi đọc lại.
final class KeyUnavailable extends KeyReadResult {
  const KeyUnavailable();
}

/// `createDbKey()` khi đã có khóa. Khóa cũ giữ nguyên.
class KeyAlreadyExistsException implements Exception {
  const KeyAlreadyExistsException();
  @override
  String toString() => 'KeyAlreadyExistsException';
}

/// Interface phụ thuộc nền tảng (AGENTS.md, quy tắc 4). Có bản giả để test.
abstract interface class SecureKeyStore {
  Future<KeyReadResult> readDbKey();

  /// Tạo khóa 32 byte ngẫu nhiên và lưu. Chỉ gọi ở bước Đồng ý.
  /// Ném [KeyAlreadyExistsException] nếu đã có khóa; không bao giờ ghi đè.
  Future<Uint8List> createDbKey();

  Future<void> deleteDbKey();

  /// Máy đã mở khóa (Android `KeyguardManager.isDeviceLocked() == false`).
  Future<bool> isDeviceUnlocked();
}

/// 32 byte ngẫu nhiên từ `Random.secure()`.
Uint8List generateDbKey([Random? random]) {
  final r = random ?? Random.secure();
  return Uint8List.fromList([for (var i = 0; i < dbKeyLength; i++) r.nextInt(256)]);
}

/// Bản giả để test: khóa trong bộ nhớ; có thể ép kết quả đọc.
class FakeSecureKeyStore implements SecureKeyStore {
  Uint8List? key;

  /// Có bản khóa nhưng mất khóa bọc (giả lập [KeyLost]).
  bool lost = false;

  /// Số lần đọc tiếp theo trả [KeyUnavailable] (âm = mãi mãi).
  int unavailableReads = 0;

  bool unlocked = true;
  int reads = 0;
  int creates = 0;
  int deletes = 0;

  FakeSecureKeyStore({this.key});

  @override
  Future<KeyReadResult> readDbKey() async {
    reads++;
    if (unavailableReads != 0) {
      if (unavailableReads > 0) unavailableReads--;
      return const KeyUnavailable();
    }
    if (lost) return const KeyLost();
    final k = key;
    return k == null ? const KeyAbsent() : KeyPresent(Uint8List.fromList(k));
  }

  @override
  Future<Uint8List> createDbKey() async {
    if (key != null || lost) throw const KeyAlreadyExistsException();
    creates++;
    final k = generateDbKey();
    key = k;
    return Uint8List.fromList(k);
  }

  @override
  Future<void> deleteDbKey() async {
    deletes++;
    key = null;
    lost = false;
  }

  @override
  Future<bool> isDeviceUnlocked() async => unlocked;
}
