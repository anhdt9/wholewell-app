/// Mã hóa / giải mã tệp sao lưu `.wwbackup` bằng Argon2id + ChaCha20-Poly1305 (chạy trong Isolate.run).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupWrongSecretException implements Exception {
  const BackupWrongSecretException();
  @override
  String toString() => 'BackupWrongSecretException';
}

class BackupCorruptedException implements Exception {
  final String reason;
  const BackupCorruptedException([this.reason = 'corrupted']);
  @override
  String toString() => 'BackupCorruptedException($reason)';
}

class BackupSchemaTooNewException implements Exception {
  final int foundVersion;
  final int supportedVersion;
  const BackupSchemaTooNewException(this.foundVersion, this.supportedVersion);
  @override
  String toString() => 'BackupSchemaTooNewException($foundVersion > $supportedVersion)';
}

class DecryptedBackupSnapshot {
  final Uint8List plainSqliteBytes;
  final int schemaVersion;
  const DecryptedBackupSnapshot({required this.plainSqliteBytes, required this.schemaVersion});
}

/// Định dạng nhị phân `.wwbackup`:
/// - `0..8`: Magic `WWBKUP01`
/// - `8..10`: formatVersion (uint16 = 1)
/// - `10..12`: schemaVersion (uint16)
/// - `12..16`: argon2 memoryKiB (uint32)
/// - `16..20`: argon2 iterations (uint32)
/// - `20..22`: argon2 parallelism (uint16)
/// - `22..38`: salt (16 bytes)
/// - `38..50`: nonce (12 bytes)
/// - `50..end-16`: ciphertext gzip(sqlite)
/// - `end-16..end`: Poly1305 MAC tag (16 bytes)
class BackupCodec {
  BackupCodec._();

  static const _magic = [0x57, 0x57, 0x42, 0x4B, 0x55, 0x50, 0x30, 0x31]; // WWBKUP01
  static const int formatVersion = 1;
  static const int headerLength = 50;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  static const int defaultMemoryKiB = 19456; // ~19 MiB (OWASP khuyến nghị cho di động)
  static const int defaultIterations = 2;
  static const int defaultParallelism = 1;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Sinh mã khôi phục 24 ký tự (120 bit entropy), nhóm 4 ký tự bằng dấu `-`.
  static String generateRecoveryKey() {
    final rng = Random.secure();
    final chars = List<String>.generate(24, (_) => _alphabet[rng.nextInt(_alphabet.length)]);
    final groups = <String>[for (var i = 0; i < 24; i += 4) chars.sublist(i, i + 4).join()];
    return groups.join('-');
  }

  static Future<Uint8List> encryptSnapshot({
    required Uint8List plainSqliteBytes,
    required int schemaVersion,
    required String secret,
    int memoryKiB = defaultMemoryKiB,
    int iterations = defaultIterations,
    int parallelism = defaultParallelism,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'Không được rỗng');
    }
    final compressed = Uint8List.fromList(gzip.encode(plainSqliteBytes));
    final rng = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(_saltLength, (_) => rng.nextInt(256)));
    final nonce = Uint8List.fromList(List<int>.generate(_nonceLength, (_) => rng.nextInt(256)));

    return Isolate.run(
      () => _encryptInIsolate(
        compressedPayload: compressed,
        schemaVersion: schemaVersion,
        secretBytes: Uint8List.fromList(utf8.encode(secret)),
        memoryKiB: memoryKiB,
        iterations: iterations,
        parallelism: parallelism,
        salt: salt,
        nonce: nonce,
      ),
    );
  }

  static Future<DecryptedBackupSnapshot> decryptSnapshot({required Uint8List backupBytes, required String secret}) {
    if (secret.isEmpty) {
      return Future.error(const BackupWrongSecretException());
    }
    return Isolate.run(
      () => _decryptInIsolate(backupBytes: backupBytes, secretBytes: Uint8List.fromList(utf8.encode(secret))),
    );
  }

  static Future<Uint8List> _encryptInIsolate({
    required Uint8List compressedPayload,
    required int schemaVersion,
    required Uint8List secretBytes,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
    required Uint8List salt,
    required Uint8List nonce,
  }) async {
    final header = Uint8List(headerLength);
    header.setRange(0, 8, _magic);
    final bd = ByteData.sublistView(header);
    bd.setUint16(8, formatVersion);
    bd.setUint16(10, schemaVersion);
    bd.setUint32(12, memoryKiB);
    bd.setUint32(16, iterations);
    bd.setUint16(20, parallelism);
    header.setRange(22, 38, salt);
    header.setRange(38, 50, nonce);

    final kdf = Argon2id(memory: memoryKiB, iterations: iterations, parallelism: parallelism, hashLength: 32);
    final key = await kdf.deriveKey(secretKey: SecretKey(secretBytes), nonce: salt);
    secretBytes.fillRange(0, secretBytes.length, 0);

    final aead = Chacha20.poly1305Aead();
    final box = await aead.encrypt(compressedPayload, secretKey: key, nonce: nonce, aad: header);
    final out = Uint8List(headerLength + box.cipherText.length + _macLength);
    out.setRange(0, headerLength, header);
    out.setRange(headerLength, headerLength + box.cipherText.length, box.cipherText);
    out.setRange(headerLength + box.cipherText.length, out.length, box.mac.bytes);
    return out;
  }

  static Future<DecryptedBackupSnapshot> _decryptInIsolate({
    required Uint8List backupBytes,
    required Uint8List secretBytes,
  }) async {
    if (backupBytes.length < headerLength + _macLength + 1) {
      throw const BackupCorruptedException('too_short');
    }
    for (var i = 0; i < 8; i++) {
      if (backupBytes[i] != _magic[i]) {
        throw const BackupCorruptedException('bad_magic');
      }
    }
    final header = Uint8List.sublistView(backupBytes, 0, headerLength);
    final bd = ByteData.sublistView(header);
    final fmtVer = bd.getUint16(8);
    if (fmtVer != formatVersion) {
      throw const BackupCorruptedException('unsupported_format');
    }
    final schemaVer = bd.getUint16(10);
    final memoryKiB = bd.getUint32(12);
    final iterations = bd.getUint32(16);
    final parallelism = bd.getUint16(20);
    if (memoryKiB < 8 || iterations < 1 || parallelism < 1) {
      throw const BackupCorruptedException('bad_params');
    }
    final salt = Uint8List.sublistView(header, 22, 38);
    final nonce = Uint8List.sublistView(header, 38, 50);
    final cipherEnd = backupBytes.length - _macLength;
    final cipherText = Uint8List.sublistView(backupBytes, headerLength, cipherEnd);
    final macBytes = Uint8List.sublistView(backupBytes, cipherEnd);

    final kdf = Argon2id(memory: memoryKiB, iterations: iterations, parallelism: parallelism, hashLength: 32);
    final key = await kdf.deriveKey(secretKey: SecretKey(secretBytes), nonce: salt);
    secretBytes.fillRange(0, secretBytes.length, 0);

    final aead = Chacha20.poly1305Aead();
    final List<int> compressed;
    try {
      compressed = await aead.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: key,
        aad: header,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupWrongSecretException();
    }

    try {
      final plain = Uint8List.fromList(gzip.decode(compressed));
      return DecryptedBackupSnapshot(plainSqliteBytes: plain, schemaVersion: schemaVer);
    } on Object {
      throw const BackupCorruptedException('bad_gzip');
    }
  }
}
