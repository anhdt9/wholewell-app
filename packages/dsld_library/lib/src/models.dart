/// Mô hình dữ liệu cho thư viện thực phẩm bổ sung NIH DSLD.
library;

class DsldLibraryIntegrityException implements Exception {
  final String message;
  const DsldLibraryIntegrityException(this.message);

  @override
  String toString() => 'DsldLibraryIntegrityException: $message';
}

class DsldLibraryMeta {
  final String libraryVersion;
  final String dsldRelease;
  final String builtAt;
  final int productCount;
  final int factCount;
  final String sha256;

  const DsldLibraryMeta({
    required this.libraryVersion,
    required this.dsldRelease,
    required this.builtAt,
    required this.productCount,
    required this.factCount,
    required this.sha256,
  });
}

class DsldProductSummary {
  final int dsldId;
  final String barcode;
  final String productName;
  final String brandName;
  final String servingSize;
  final String supplementForm;

  const DsldProductSummary({
    required this.dsldId,
    required this.barcode,
    required this.productName,
    required this.brandName,
    required this.servingSize,
    required this.supplementForm,
  });
}

class DsldFact {
  final String ingredient;
  final String category;
  final String amount;
  final String unit;
  final String dvPercent;
  final String dvGroup;

  const DsldFact({
    required this.ingredient,
    required this.category,
    required this.amount,
    required this.unit,
    required this.dvPercent,
    required this.dvGroup,
  });
}

class DsldProductDetail {
  final int dsldId;
  final String barcode;
  final String productName;
  final String brandName;
  final String servingSize;
  final String supplementForm;
  final String netContents;
  final String suggestedUse;
  final String otherIngredients;
  final List<DsldFact> facts;

  const DsldProductDetail({
    required this.dsldId,
    required this.barcode,
    required this.productName,
    required this.brandName,
    required this.servingSize,
    required this.supplementForm,
    required this.netContents,
    required this.suggestedUse,
    required this.otherIngredients,
    required this.facts,
  });
}
