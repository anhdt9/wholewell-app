/// Mở/giải nén `food_library.db` từ asset Flutter ra thư mục cục bộ và kiểm SHA-256.
library;

import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:food_library/food_library.dart';

class FlutterFoodLibraryAssetStore implements FoodLibraryAssetStore {
  final Directory supportDir;
  final AssetBundle bundle;
  final String assetPath;

  FlutterFoodLibraryAssetStore({
    required this.supportDir,
    AssetBundle? bundle,
    this.assetPath = 'assets/food_library.db',
  }) : bundle = bundle ?? rootBundle;

  @override
  Future<String> prepareDatabaseFile({required String libraryVersion, required String expectedSha256}) async {
    try {
      await supportDir.create(recursive: true);
      final targetName = 'food_library_$libraryVersion.db';
      final targetFile = File('${supportDir.path}/$targetName');

      // Xóa các bản thư viện phiên bản cũ nếu còn sót.
      await for (final entity in supportDir.list()) {
        if (entity is File) {
          final base = entity.uri.pathSegments.isEmpty ? '' : entity.uri.pathSegments.last;
          if (base.startsWith('food_library_') && base.endsWith('.db') && base != targetName) {
            await entity.delete();
          }
        }
      }

      // Nếu bản đúng phiên bản đã tồn tại, trả về ngay để `SqliteFoodLibraryRepository`
      // kiểm tra SHA-256 đúng một lần duy nhất khi mở chỉ đọc.
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }

      final bytes = await bundle.load(assetPath);
      final tmp = File('${targetFile.path}.tmp');
      await tmp.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
      if (await targetFile.exists()) await targetFile.delete();
      await tmp.rename(targetFile.path);
      return targetFile.path;
    } on FoodLibraryIntegrityException {
      rethrow;
    } on Object catch (e) {
      throw FoodLibraryIntegrityException('Không giải nén được thư viện món: $e');
    }
  }
}
