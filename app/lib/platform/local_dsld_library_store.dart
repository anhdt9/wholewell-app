/// Giải nén `dsld_library.db.gz` từ asset Flutter ra thư mục cục bộ và kiểm SHA-256.
library;

import 'dart:io';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

class FlutterDsldLibraryAssetStore implements DsldLibraryAssetStore {
  final Directory supportDir;
  final AssetBundle bundle;
  final String assetPath;

  FlutterDsldLibraryAssetStore({
    required this.supportDir,
    AssetBundle? bundle,
    this.assetPath = 'assets/dsld_library.db.gz',
  }) : bundle = bundle ?? rootBundle;

  @override
  Future<String> prepareDatabaseFile({
    required String libraryVersion,
    required String expectedSha256,
  }) async {
    try {
      await supportDir.create(recursive: true);
      final targetName = 'dsld_library_$libraryVersion.db';
      final targetFile = File('${supportDir.path}/$targetName');

      // Xóa các bản thư viện nhãn phiên bản cũ nếu còn sót.
      await for (final entity in supportDir.list()) {
        if (entity is File) {
          final base = entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
          if (base.startsWith('dsld_library_') && base.endsWith('.db') && base != targetName) {
            await entity.delete();
          }
        }
      }

      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }

      final gzBytes = await bundle.load(assetPath);
      final compressed = gzBytes.buffer.asUint8List(
        gzBytes.offsetInBytes,
        gzBytes.lengthInBytes,
      );
      final decoded = gzip.decode(compressed);
      final tmp = File('${targetFile.path}.tmp');
      await tmp.writeAsBytes(decoded, flush: true);
      if (await targetFile.exists()) await targetFile.delete();
      await tmp.rename(targetFile.path);
      return targetFile.path;
    } on DsldLibraryIntegrityException {
      rethrow;
    } on Object catch (e) {
      throw DsldLibraryIntegrityException('Không giải nén được thư viện nhãn: $e');
    }
  }
}
