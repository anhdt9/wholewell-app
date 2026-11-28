import 'dart:io';
import 'dart:math';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_library/food_library.dart';
import 'package:wholewell/platform/bundled_db_asset_store.dart';

class _MemoryBundle extends CachingAssetBundle {
  final Map<String, Uint8List> assets;
  int loads = 0;
  _MemoryBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final a = assets[key];
    if (a == null) throw StateError('Không có asset $key');
    return ByteData.sublistView(a);
  }
}

void main() {
  late Directory dir;
  // 3 MB dữ liệu giả, đủ nhiều khối 1 MB.
  final raw = Uint8List.fromList(List.generate(3 * 1024 * 1024 + 17, (i) => Random(i ~/ 4096).nextInt(256)));

  setUp(() => dir = Directory.systemTemp.createTempSync('bundled_db_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('asset .gz được giải nén theo luồng ra đúng nội dung, xóa bản phiên bản cũ', () async {
    File('${dir.path}/dsld_library_old.db').writeAsStringSync('cũ');
    final bundle = _MemoryBundle({'assets/dsld_library.db.gz': Uint8List.fromList(gzip.encode(raw))});
    final store = BundledDbAssetStore.dsldLibrary(supportDir: dir, bundle: bundle);

    final path = await store.prepareDatabaseFile(libraryVersion: 'v2', expectedSha256: 'x');

    expect(path, endsWith('dsld_library_v2.db'));
    expect(File(path).readAsBytesSync(), raw);
    expect(File('${dir.path}/dsld_library_old.db').existsSync(), isFalse);
    expect(File('$path.tmp').existsSync(), isFalse);
  });

  test('asset không nén được chép nguyên; tệp đã có thì không đọc asset lại', () async {
    final bundle = _MemoryBundle({'assets/food_library.db': raw});
    final store = BundledDbAssetStore.foodLibrary(supportDir: dir, bundle: bundle);

    final path = await store.prepareDatabaseFile(libraryVersion: 'v1', expectedSha256: 'x');
    expect(File(path).readAsBytesSync(), raw);
    await store.prepareDatabaseFile(libraryVersion: 'v1', expectedSha256: 'x');
    expect(bundle.loads, 1);
  });

  test('lỗi khi chuẩn bị tệp báo đúng loại lỗi của từng thư viện', () async {
    final empty = _MemoryBundle({});
    await expectLater(
      BundledDbAssetStore.foodLibrary(
        supportDir: dir,
        bundle: empty,
      ).prepareDatabaseFile(libraryVersion: 'v1', expectedSha256: 'x'),
      throwsA(isA<FoodLibraryIntegrityException>()),
    );
    await expectLater(
      BundledDbAssetStore.dsldLibrary(
        supportDir: dir,
        bundle: empty,
      ).prepareDatabaseFile(libraryVersion: 'v1', expectedSha256: 'x'),
      throwsA(isA<DsldLibraryIntegrityException>()),
    );
  });
}
