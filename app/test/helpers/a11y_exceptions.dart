/// Màn chưa đạt hướng dẫn trợ năng của Flutter (docs/refactor-plan.md, mục 3.6).
///
/// **Danh sách chỉ được giảm.** Sửa xong một màn thì xóa dòng của nó và giảm
/// `maxA11yExceptions`; test kiểm toán chặn việc thêm.
library;

import 'package:flutter_test/flutter_test.dart';

enum A11yGuideline {
  androidTapTarget,
  labeledTapTarget,
  textContrast;

  AccessibilityGuideline get guideline => switch (this) {
    A11yGuideline.androidTapTarget => androidTapTargetGuideline,
    A11yGuideline.labeledTapTarget => labeledTapTargetGuideline,
    A11yGuideline.textContrast => textContrastGuideline,
  };
}

/// Tên màn (kiểu widget) → các hướng dẫn chưa đạt.
/// Lập ngày 29/11/2026 (PR 0c) bằng `A11Y_DISCOVER`; xem `expectA11yGuidelines`.
const Map<String, Set<A11yGuideline>> a11yExceptions = {
  // Có nút bấm được nhưng chưa có nhãn cho trình đọc màn hình.
  'DiaryScreen': {A11yGuideline.labeledTapTarget},
  'EditFoodScreen': {A11yGuideline.labeledTapTarget},
  'FoodPortionScreen': {A11yGuideline.labeledTapTarget},
  // Nút chọn ngày ("Hôm qua, 28/11") cao 36 dp, dưới 48 dp.
  'HomeScreen': {A11yGuideline.androidTapTarget},
};

/// Tổng số cặp (màn, hướng dẫn) được miễn. Chỉ được giảm.
const maxA11yExceptions = 4;
