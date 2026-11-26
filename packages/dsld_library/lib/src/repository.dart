/// Interface đọc thư viện thực phẩm bổ sung NIH DSLD và giải nén/chuẩn bị tệp.
library;

import 'models.dart';

abstract interface class DsldLibraryAssetStore {
  Future<String> prepareDatabaseFile({
    required String libraryVersion,
    required String expectedSha256,
  });
}

abstract interface class DsldLibraryRepository {
  DsldLibraryMeta get meta;

  /// Tra các bản ghi On Market khớp mã vạch (tự thử cả dạng UPC-A 12 số và EAN-13 13 số thêm 0 đầu).
  Future<List<DsldProductDetail>> findByBarcode(String barcode);

  /// Tìm sản phẩm theo tên sản phẩm hoặc tên hãng (FTS5).
  Future<List<DsldProductSummary>> searchByName(String query, {int limit = 30});

  /// Lấy chi tiết đầy đủ một sản phẩm theo `dsldId`.
  Future<DsldProductDetail?> getDetail(int dsldId);

  void close();
}
