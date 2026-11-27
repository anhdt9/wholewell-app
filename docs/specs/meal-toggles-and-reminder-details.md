# Đặc tả: Bật/tắt từng bữa ăn (#26), Bỏ màn ẩn/hiện calo lúc setup (#27) và Tùy chọn hiện tên trên thông báo (#28)

Trạng thái: Đã duyệt (27/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/meal-toggles-and-reminder-details.md](../design/meal-toggles-and-reminder-details.md)
Thứ tự MVP: Bổ sung sau Cổng 2 (Issue [#26](https://github.com/anhdt9/wholewell-app/issues/26), [#27](https://github.com/anhdt9/wholewell-app/issues/27), [#28](https://github.com/anhdt9/wholewell-app/issues/28))

## Mục tiêu
1. **Tắt từng bữa (#26):** Cho phép người dùng bỏ ăn sáng, trưa hoặc tối (kể cả tắt cả 3 bữa chính và chỉ giữ `Phụ`) trong `Giờ trong ngày`, đồng thời ẩn bữa đã tắt khỏi các bước chọn nhanh mặc định mà vẫn giữ nguyên `Phụ` và lịch sử đã ghi.
2. **Rút gọn luồng setup còn 3 bước (#27):** Bỏ màn `4/4 Hiển thị calo` khi thiết lập mới; mặc định hiện số calo (`hideCalories = false`) ngay sau bước `3/3 Hồ sơ cơ thể`, người dùng vẫn tắt/bật bất kỳ lúc nào tại `Tôi → Hiển thị`.
3. **Hiện tên sản phẩm trên thông báo nhắc giờ (#28, Phương án B):** Cho phép người dùng tự nguyện bật công tắc trong `Tôi → Nhắc giờ` (**tắt mặc định**) để thông báo nhắc giờ (kể cả trên màn hình khóa) hiện `"Đến giờ uống: <tên sản phẩm>"`, kèm cảnh báo rõ rủi ro lộ thông tin sức khỏe.

## Người dùng và tình huống
- **Người không ăn sáng (hoặc bỏ bữa trưa/tối):** Vào `Tôi → Giờ trong ngày` (hoặc hộp thoại `Giờ trong ngày` lần đầu khi đặt lịch) tắt `Bữa sáng`. Từ đó:
  - Màn `Đặt lịch uống` không gợi ý chip `"Sáng 07:00"` và không khuyên `"dùng cùng bữa sáng"` cho vitamin D / canxi carbonat.
  - Màn `Ghi món` / `Nhập theo nhãn` chỉ hiện các bữa đang bật (và `Phụ`), chọn bữa mặc định khớp với giờ hiện tại trong số các bữa còn bật.
- **Người muốn nhìn nhanh cần uống gì từ thông báo:** Vào `Tôi → Nhắc giờ`, đọc cảnh báo về màn hình khóa và tự gạt bật `"Hiện chi tiết sản phẩm trên thông báo"`. Khi đến giờ, thông báo hiện tên sản phẩm/vi chất thay vì chỉ `"Đến giờ uống"`. Người không bật vẫn giữ nguyên mặc định riêng tư `"Đến giờ uống"`.

## Ràng buộc
- **Dữ liệu ở máy & quyền riêng tư (`AGENTS.md`, Nghị định 356/2025/NĐ-CP):**
  - Công tắc hiện chi tiết thông báo **mặc định tắt (`false`)**.
  - Khi công tắc tắt, tệp cấu hình thông báo ngoài CSDL (`SharedPreferences` `wholewell_reminders_meta`) **tuyệt đối không** lưu tên sản phẩm hay tên chất; nếu người dùng vừa bật rồi tắt lại, phải đồng bộ lại ngay để xóa sạch chuỗi tên khỏi `SharedPreferences`.
  - Khi công tắc bật, thông báo nhắc giờ trên Android vẫn chỉ dùng dữ liệu cục bộ, không gửi đi đâu, và giao diện `Nhắc giờ` + [docs/privacy-policy.md](../privacy-policy.md) + [docs/legal-checklist.md](../legal-checklist.md) ghi rõ rủi ro hiển thị trên màn hình khóa khi người dùng tự chọn bật.
- **Chuẩn tham chiếu (`AGENTS.md`):**
  - Đường bổ sung (`≤ 10 g/bữa`, Dietary Guidelines 2025–2030) vẫn áp dụng cho từng lần/bữa ghi trong nhật ký, không phụ thuộc số bữa chính đang bật.
  - 5 quy tắc lịch từ NIH ODS (`take_with_meal`) vẫn giữ nguyên nguồn; khi người dùng tắt hết bữa chính thì chỉ bỏ qua gợi ý gắn bữa chính, giữ nguyên 3 quy tắc còn lại (`>500 mg canxi`, `canxi & sắt`, `sắt ≥25 mg & kẽm`).
- **Tương thích ngược dữ liệu:**
  - Bản sao lưu `.wwbackup` (lược đồ v1/v2) khi khôi phục sang v3 tự gán `has_breakfast = 1`, `has_lunch = 1`, `has_dinner = 1`, `reminder_show_details = 0`.
  - Món đã ghi trước đây thuộc bữa nay đã tắt (vd. `Meal.breakfast`) vẫn hiển thị bình thường ở `Nhật ký`, tính đúng vào `Hôm nay`, và sửa được ở `Sửa món`.

## Nguồn
- **5 quy tắc lịch (`scheduleRules`):** NIH ODS Health Professional Fact Sheets (Calcium, Iron, Zinc, Vitamin D), giữ nguyên từ [schedule-reminders.md](schedule-reminders.md).
- **Giới hạn đường bổ sung ≤ 10 g/bữa:** Dietary Guidelines for Americans 2025–2030, giữ nguyên từ [engine-v2.md](engine-v2.md).

## Thiết kế kỹ thuật

### 1. Dữ liệu (`packages/journal_db`)
- **Di chuyển lược đồ `v2 → v3` (`schema.dart`):**
  - Bảng `settings` bổ sung 4 cột:
    - `has_breakfast INTEGER NOT NULL DEFAULT 1 CHECK (has_breakfast IN (0, 1))`
    - `has_lunch INTEGER NOT NULL DEFAULT 1 CHECK (has_lunch IN (0, 1))`
    - `has_dinner INTEGER NOT NULL DEFAULT 1 CHECK (has_dinner IN (0, 1))`
    - `reminder_show_details INTEGER NOT NULL DEFAULT 0 CHECK (reminder_show_details IN (0, 1))`
  - Cập nhật `currentSchemaVersion = 3` và `schemaCurrent` + `defaultDbMigrations[2]`.
- **`DayTimesSettings` (`models.dart`):**
  - Thêm `bool hasBreakfast` (mặc định `true`), `bool hasLunch` (`true`), `bool hasDinner` (`true`), `bool reminderShowDetails` (`false`) vào `DayTimesSettings`, `copyWith`, `DriftJournalRepository`, `InMemoryJournalRepository` và `exportReadableJson()`.

### 2. Engine (`packages/health_engine` & `tools/reference_engine.py`)
- **`MealTimes` (`schedule.dart`):**
  - Đổi `breakfast`, `lunch`, `dinner` từ `int` sang `int?` (`null` nghĩa là bữa đó đã tắt).
  - Trong `evaluateScheduleRules(...)`, quy tắc loại `take_with_meal` chỉ xét danh sách các bữa khác `null` (`[if (m.breakfast != null) m.breakfast!, if (m.lunch != null) m.lunch!, if (m.dinner != null) m.dinner!]`). Nếu cả 3 đều `null` thì không phát thông báo `take_with_meal`.
- Đồng bộ `tools/reference_engine.py` nếu cần ca kiểm `MealTimes` có bữa `null` vào `cases.json`.

### 3. Interface nền tảng & Android (`app/`)
- **`NotificationScheduler` (`notification_scheduler.dart`):**
  - Thêm `final String? detailText;` (tùy chọn) vào `ScheduledReminderSlot`, ánh xạ sang `'detailText'` trong `toMap()`.
  - `DiaryController.buildReminderSlots()`: khi `dayTimesSettings.reminderShowDetails == false` → luôn đặt `detailText = null`. Khi `true` → ghép danh sách tên sản phẩm (+ tối đa 2 chất/sản phẩm hoặc tên sản phẩm gọn từ bảng sản phẩm) trong khung giờ đó thành `detailText`.
- **Android Kotlin (`ReminderLogic.kt`, `ReminderScheduler.kt`):**
  - `ReminderSlotMeta` thêm `val detailText: String? = null`; `encodeSlots`/`decodeSlots` mã hóa an toàn ký tự xuống dòng/dấu phẩy (vd. JSON `JSONArray`/`JSONObject` hoặc Base64/escape).
  - `ReminderLogic.formatNotificationBody(itemCount, detailText)`: nếu `detailText` khác null/rỗng → hiển thị `"Đến giờ uống: $detailText"` (kèm `Notification.BigTextStyle` nếu dài > 1 dòng); ngược lại giữ nguyên `"Đến giờ uống"` / `"Đến giờ uống, X loại"`.
  - Giữ nguyên `Notification.VISIBILITY_PUBLIC` (Phương án B theo chốt của chủ dự án).
  - Bật/tắt công tắc `reminderShowDetails` hoặc `startOver()`/`withdrawConsentAndReset()` gọi ngay `syncNotifications()` để cập nhật/xóa `wholewell_reminders_meta`.

### 4. Luồng xử lý (`app/`)
- **`Giờ trong ngày` (`day_times_screen.dart`):**
  - `Thức dậy` và `Đi ngủ` giữ nguyên giờ.
  - `Bữa sáng`, `Bữa trưa`, `Bữa tối` mỗi dòng có công tắc bật/tắt; khi tắt thì ẩn hoặc làm mờ nút giờ (không xóa giờ cũ để bật lại vẫn giữ giờ trước đó).
  - Tab `Tôi`: dòng phụ đề `Giờ trong ngày` chỉ liệt kê các bữa đang bật (vd. `"Trưa 12:00 · Tối 19:00"`, hoặc `"Chỉ bữa phụ"` nếu tắt cả 3).
- **Chọn bữa (`DiaryController.defaultMealFor`, `add_food_screen.dart`, `label_food_screen.dart`, `edit_food_screen.dart`, `edit_schedule_screen.dart`):**
  - `defaultMealFor(now, settings)` chỉ xét các bữa đang bật theo giờ đã cài trong `settings` (khung ±90 phút quanh `breakfast`/`lunch`/`dinner`), không khớp hoặc tất cả đã tắt → trả `Meal.snack`.
  - `Ghi món` / `Nhập theo nhãn`: `SegmentedButton<Meal>` chỉ hiện các bữa đang bật + `Phụ`. (Riêng `Sửa món`: nếu món cũ đang thuộc bữa đã tắt, vẫn hiện segment bữa đó để tránh mất trạng thái khi mở sửa).
  - `Đặt lịch uống` (`edit_schedule_screen.dart`): chỉ hiện `ActionChip` chọn nhanh cho các bữa đang bật; giờ khởi tạo mặc định lấy bữa đang bật đầu tiên hoặc giờ hiện tại / `breakfast` cũ nếu tắt cả 3.
- **Công tắc trong `Tôi → Nhắc giờ` (`notification_settings_screen.dart`):**
  - Khi thông báo nhắc giờ đang bật (`notificationsEnabled == true`), hiện thêm `SwitchListTile`: `"Hiện tên sản phẩm trên thông báo"` (mặc định tắt) ngay dưới công tắc chính.
  - Luôn hiện `SafetyNote` giải thích: khi tắt chỉ hiện `"Đến giờ uống"`; khi bật, tên sản phẩm sẽ hiện trên thanh thông báo và màn hình khóa.

- **Onboarding rút gọn 3 bước (#27):**
  - `onboarding_flow.dart`: đổi nhãn bước `1/4`, `2/4`, `3/4` thành `1/3` (`Điều kiện`), `2/3` (`Đồng ý`), `3/3` (`Hồ sơ cơ thể`, nút chính `"Xong"`).
  - `AppState.saveOnboardingBodyProfile(...)` (hoặc `DiaryController.completeBodyProfileOnboarding`): khi lưu xong hồ sơ cơ thể lần đầu, tự lưu `hide_calories = false` (nếu chưa từng đặt) và `onboarding_step = done`, đưa người dùng thẳng vào `SessionStage.ready` (`Hôm nay`).
  - `DbSessionController._syncStageFromRepo()`: với các CSDL cũ đang kẹt ở `OnboardingStep.calorieDisplay` hoặc `hide == null` khi đã có hồ sơ, tự mặc định `hide_calories = false` và nâng lên `OnboardingStep.done` (vẫn giữ nút `Tôi → Hiển thị → Ẩn số calo`).

### 5. Lỗi và biên
- Người dùng tắt cả 3 bữa `Sáng`, `Trưa`, `Tối`: app vẫn hoạt động bình thường, mọi món mới mặc định vào `Phụ`, không crash `SegmentedButton` (luôn còn ≥ 1 segment là `Phụ`).
- Tắt `Bữa sáng` khi đang xem món cũ ghi ở `Bữa sáng` trong `Sửa món`: vẫn mở sửa được bình thường.
- Bật công tắc chi tiết thông báo khi chưa có lịch uống nào: không crash, áp dụng ngay khi tạo lịch kế tiếp; tắt công tắc sau khi đã có lịch: gọi `syncNotifications()` ghi đè `wholewell_reminders_meta` xóa sạch tên sản phẩm ngay lập tức.
- Chuỗi tên sản phẩm chứa dấu `,` / `\n` / ký tự tiếng Việt có dấu / dài > 100 ký tự: dùng JSON chuẩn trong `ReminderLogic` để không làm hỏng `decodeSlots`.

## Tiêu chí đạt
- [ ] `packages/journal_db`: migrate `v2 → v3` qua trên `SQLite3MultipleCiphers`; khôi phục `.wwbackup` từ `v1`/`v2` tự gán đúng giá trị mặc định; `exportReadableJson()` và `InMemory` đồng bộ đủ 4 trường mới.
- [ ] `packages/health_engine`: `MealTimes` hỗ trợ `int?`; test `evaluateScheduleRules` khi tắt 1 bữa hoặc cả 3 bữa không phát thông báo `take_with_meal` cho bữa đã tắt nhưng giữ 3 quy tắc còn lại.
- [ ] `app/` & Kotlin (`ReminderLogicTest`): tắt công tắc → payload và `encodeSlots` không chứa tên sản phẩm/chất; bật công tắc → thông báo hiện tên sản phẩm đúng và tắt công tắc là xóa sạch ngay khỏi metadata; widget test `Giờ trong ngày`, `Ghi món`, `Đặt lịch`, `Sửa món` và `Tôi → Nhắc giờ` đạt 100%.
- [ ] Toàn bộ `verify_pack.py`, `dart analyze/test`, `flutter analyze/test`, `./gradlew :app:testDebugUnitTest` đều qua.
- [ ] Onboarding người dùng mới: `1/3` → `2/3` → `3/3` (`Hồ sơ cơ thể`) → thẳng vào `Hôm nay` với `hideCalories == false`; vẫn tắt/bật được trong `Tôi → Hiển thị`.

## Ngoài phạm vi
- Không cho phép tự thêm tên bữa tùy chỉnh ngoài 4 loại (`Sáng`, `Trưa`, `Tối`, `Phụ`) trong đợt này (chỉ bật/tắt 3 bữa chính).
- Không đổi hành vi thông báo cảnh báo giới hạn an toàn chung (`"Có thông tin mới cần xem trong WholeWell"`): vẫn giữ ẩn chi tiết vì mang thông tin vượt ngưỡng nhạy cảm hơn.

## Quyết định đã chốt (27/11/2026)
1. **#28:** Khi bật công tắc, thông báo chỉ hiện **tên sản phẩm** (vd. `"Đến giờ uống: Vitamin C 500 mg"`, ghép các tên sản phẩm nếu nhiều loại), không kèm tên chất.
2. **#26:** Cho phép tắt tối đa cả 3 bữa chính `Sáng`, `Trưa`, `Tối` (luôn giữ `Phụ`).
3. **#27:** Gộp bỏ màn `4/4 Hiển thị calo` vào cùng đợt này (`3/3` là bước cuối, mặc định hiện calo).
