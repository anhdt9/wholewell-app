/// Chép thư viện SQLite chỉ đọc đi kèm app (asset) ra thư mục cục bộ để mở (thư viện món, thư viện DSLD).
///
/// Asset `.gz` được giải nén theo luồng trong isolate nền, ghi thẳng ra tệp: không giữ cả tệp đã giải nén
/// trong RAM và không chặn giao diện. SHA-256 do repository kiểm khi mở (cũng trong isolate nền).
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:food_library/food_library.dart';

class BundledDbAssetStore implements FoodLibraryAssetStore, DsldLibraryAssetStore {
  final Directory supportDir;
  final AssetBundle bundle;
  final String assetPath;

  /// Tiền tố tên tệp cục bộ: `<filePrefix><phiên bản>.db`.
  final String filePrefix;

  /// Lỗi riêng của từng thư viện (để repository báo đúng loại).
  final Exception Function(String message) integrityError;

  BundledDbAssetStore({
    required this.supportDir,
    required this.assetPath,
    required this.filePrefix,
    required this.integrityError,
    AssetBundle? bundle,
  }) : bundle = bundle ?? rootBundle;

  /// Thư viện món: `assets/food_library.db` (không nén).
  BundledDbAssetStore.foodLibrary({required Directory supportDir, AssetBundle? bundle})
    : this(
        supportDir: supportDir,
        bundle: bundle,
        assetPath: 'assets/food_library.db',
        filePrefix: 'food_library_',
        integrityError: (m) => FoodLibraryIntegrityException('Không giải nén được thư viện món: $m'),
      );

  /// Thư viện nhãn NIH DSLD: `assets/dsld_library.db.gz`.
  BundledDbAssetStore.dsldLibrary({required Directory supportDir, AssetBundle? bundle})
    : this(
        supportDir: supportDir,
        bundle: bundle,
        assetPath: 'assets/dsld_library.db.gz',
        filePrefix: 'dsld_library_',
        integrityError: (m) => DsldLibraryIntegrityException('Không giải nén được thư viện nhãn: $m'),
      );

  @override
  Future<String> prepareDatabaseFile({required String libraryVersion, required String expectedSha256}) async {
    try {
      await supportDir.create(recursive: true);
      final targetName = '$filePrefix$libraryVersion.db';
      final targetFile = File('${supportDir.path}/$targetName');

      // Xóa các bản phiên bản cũ nếu còn sót.
      await for (final entity in supportDir.list()) {
        if (entity is File) {
          final base = entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
          if (base.startsWith(filePrefix) && base.endsWith('.db') && base != targetName) {
            await entity.delete();
          }
        }
      }

      // Bản đúng phiên bản đã có: trả về ngay, repository kiểm SHA-256 một lần khi mở.
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }

      final data = await bundle.load(assetPath);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final tmpPath = '${targetFile.path}.tmp';
      if (assetPath.endsWith('.gz')) {
        await Isolate.run(() => gunzipToFile(bytes, tmpPath));
      } else {
        await File(tmpPath).writeAsBytes(bytes, flush: true);
      }
      if (await targetFile.exists()) await targetFile.delete();
      await File(tmpPath).rename(targetFile.path);
      return targetFile.path;
    } on FoodLibraryIntegrityException {
      rethrow;
    } on DsldLibraryIntegrityException {
      rethrow;
    } on Object catch (e) {
      throw integrityError('$e');
    }
  }
}

/// Giải nén gzip [compressed] theo từng khối 1 MB, ghi thẳng ra [path].
void gunzipToFile(Uint8List compressed, String path) {
  final file = File(path).openSync(mode: FileMode.write);
  try {
    final decoder = gzip.decoder.startChunkedConversion(_FileSink(file));
    const chunk = 1 << 20;
    for (var i = 0; i < compressed.length; i += chunk) {
      decoder.add(Uint8List.sublistView(compressed, i, math.min(i + chunk, compressed.length)));
    }
    decoder.close();
    file.flushSync();
  } finally {
    file.closeSync();
  }
}

class _FileSink implements Sink<List<int>> {
  final RandomAccessFile file;
  _FileSink(this.file);

  @override
  void add(List<int> data) => file.writeFromSync(data);

  @override
  void close() {}
}
