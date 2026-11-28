/// Model của nhật ký WholeWell: không mở CSDL, không repository, không sao lưu.
///
/// Widget và ViewModel chỉ import thư viện này, không import `journal_db.dart`
/// (docs/refactor-plan.md, mục 3.3). Không re-export lại ở nơi khác để lách luật.
library;

export 'src/models.dart';
