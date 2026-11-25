# Đặc tả: Điều kiện dùng app, chế độ thận trọng và nhập nước (việc 4)

Trạng thái: Đã duyệt  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/eligibility-caution-water.md](../design/eligibility-caution-water.md) *(bổ sung chi tiết màn nâng cấp `khung-tam-0`, sửa nước, tab `Tôi` trên khung [docs/design/mvp-overview.md](../design/mvp-overview.md))*
Thứ tự MVP: việc 4 trong [docs/status.md](../status.md)

## Mục tiêu

Hoàn thiện luồng kiểm tra điều kiện và xin đồng ý trước khi tạo khóa/CSDL mã hóa (`Chào mừng` → `Điều kiện` → `Chưa dùng được` hoặc `Đồng ý` → `Hồ sơ cơ thể` → `Hiển thị calo`), nâng cấp bắt buộc các CSDL có `khung-tam-0`, vận hành đúng **chế độ thận trọng** và quy tắc tự tăng tuổi hằng năm, đồng thời triển khai đầy đủ phần **nhập, sửa, xóa nước uống** ở cả lớp lưu trữ lẫn giao diện.

## Người dùng và tình huống

- **Người dùng mới (lần đầu mở app):** Đọc màn `Chào mừng`, sang `Điều kiện (1/4)` nhập tuổi và trả lời hai câu sàng lọc bắt buộc. Nếu dưới `18` tuổi hoặc đang mang thai/cho con bú → sang màn `Chưa dùng được` (không tạo CSDL hay khóa trên máy, có thể quay lại sửa nếu gõ nhầm). Nếu đủ điều kiện → đọc và đánh dấu `Đồng ý (2/4)`, tiếp tục điền `Hồ sơ cơ thể (3/4)` và chọn `Hiển thị calo (4/4)` rồi vào `Hôm nay`.
- **Người dùng đang dùng thuốc theo chỉ định hoặc có bệnh mạn tính:** Trả lời `Có` ở câu thứ hai tại `Điều kiện` (hoặc bật lại trong `Hồ sơ`) để sử dụng app ở **chế độ thận trọng**.
- **Người dùng bản thử nội bộ (`khung-tam-0`):** Khi cập nhật lên bản mới, app mở được CSDL nhưng phát hiện phiên bản đồng ý tạm `khung-tam-0`, yêu cầu trả lời lại `Điều kiện` và đánh dấu `Đồng ý` thật mà không làm mất nhật ký đã ghi.
- **Người dùng ghi nước trong ngày:** Chạm nhanh nút `+ 250 ml` (hoặc mức vừa ghi gần nhất) ngay trên thẻ `Nước` ở `Hôm nay`, hoặc mở `Ghi nước` chọn `150 ml` / `250 ml` / `500 ml` / nhập số khác; vào `Nhật ký` để xem các lần uống và sửa/xóa khi ghi nhầm.

## Ràng buộc

- **Không ghi đĩa và không tạo khóa trước khi đồng ý (`encrypted-db.md`, `plan.md`):** Toàn bộ trạng thái ở `Chào mừng`, `Điều kiện`, `Chưa dùng được` chỉ nằm trong RAM. Chỉ gọi `DbOpener.createNew(...)` khi người dùng đánh dấu đồng ý và bấm `[Đồng ý và tiếp tục]`.
- **Chỉ hỏi Có/Không (`encrypted-db.md`):** Câu về thuốc theo chỉ định của bác sĩ và bệnh mạn tính chỉ lưu `bool caution`; tuyệt đối không hỏi, không lưu tên bệnh hay tên thuốc.
- **Chế độ thận trọng (`AGENTS.md`, `plan.md`, `mvp-overview.md`):**
  - Không tự đổi số liệu RDA/UL/EER/AMDR trong engine.
  - Đổi toàn bộ nhãn chữ `"mức khuyến nghị"` / `"Mục tiêu calo"` sang `"mức tham chiếu"` / `"Mức calo tham chiếu"` theo đúng bảng ở `mvp-overview.md` (giữ nguyên `"ước tính"` / `"mức ước tính"`).
  - Hiện `SafetyNote` nhắc chung (không có nút thu gọn) ở đầu `Hôm nay`; giữ nguyên mọi cảnh báo vượt giới hạn an toàn (`WarningCard`). (Ẩn ODA thuộc giai đoạn 3).
- **Không hiện tên viết tắt chuẩn (`RDA`, `UL`, `EER`, `AMDR`)** và lời văn đánh giá/kê đơn cho người dùng cuối.
- **Nước uống không có mục tiêu và không so sánh (`plan.md`):** Chỉ cộng và hiển thị tổng `ml` (và số lần trong `Nhật ký`), không đặt mục tiêu ml/ngày, không có thanh tiến độ hay cảnh báo thiếu nước.
- **Tuổi tối thiểu MVP (`AGENTS.md`, `status.md`):** Đọc từ `pack.minProfileAge` (`18`). Vì app không lưu ngày sinh, `HealthEngine` đã tự lấy giới hạn an toàn thấp hơn khi ở trong 12 tháng trước mốc đổi nhóm (19, 31, 51, 71); phần app có trách nhiệm tự cộng `1` vào `age_years` sau mỗi 12 tháng kể từ `age_entered_on` và báo cho người dùng trên `Hôm nay`.
- **An toàn khi nâng cấp `khung-tam-0`:** Không tự động gán đồng ý mới thay người dùng, và không âm thầm xóa dữ liệu cũ của người dùng thử; nếu người dùng từ chối đồng ý mới thì giữ ở màn chặn/xác nhận, chỉ xóa khi người dùng tự chọn xóa.

## Nguồn

- **Nước uống không đặt mục tiêu ml/ngày:** National Academies of Sciences, Engineering, and Medicine (trước đây IOM), *Dietary Reference Intakes for Water, Potassium, Sodium, Chloride, and Sulfate*, Chương 6 (Water) — <https://www.nationalacademies.org/read/10925/chapter/6> (mức AI tính tổng nước từ cả thực phẩm lẫn đồ uống, thay đổi lớn theo môi trường và mức vận động; xem [docs/plan.md](../plan.md)).
- **Chuẩn cho người khỏe mạnh, phạm vi 18+, chế độ thận trọng và nhãn chữ:** NASEM DRI qua [docs/plan.md](../plan.md) và [docs/design/mvp-overview.md](../design/mvp-overview.md).
- **Đồng ý rõ ràng cho dữ liệu sức khỏe cá nhân nhạy cảm:** Luật Bảo vệ dữ liệu cá nhân `91/2025/QH15` và Nghị định `356/2025/NĐ-CP` (mục 5 [docs/plan.md](../plan.md)).

## Thiết kế kỹ thuật

### 1. Dữ liệu (`packages/journal_db`)

Lược đồ `schemaV1` giữ nguyên `schemaVersion = 1` vì `schema.dart` đã có sẵn các bảng và cột cần thiết (`consents`, `profile.age_years`, `profile.age_entered_on`, `profile.caution`, `profile.caution_answered_on`, `settings.hide_calories`, `water_entries`, `ui_state`).

Cập nhật lớp dữ liệu và `JournalRepository` + `DriftJournalRepository` + `InMemoryJournalRepository`:

- **Phiên bản đồng ý và thông tin đồng ý:**
  - Định nghĩa hằng phiên bản đồng ý thật của MVP, vd. `mvpConsentVersion = 'mvp-1'` (tách biệt với `khungTamConsentVersion = 'khung-tam-0'`).
  - Thêm kiểu `HealthConsentStatus(String contentVersion, DateTime grantedAt)` và hàm `Future<HealthConsentStatus?> latestHealthConsent()`: truy vấn bản ghi mới nhất có `kind = 'health_data'` và `withdrawn_at IS NULL` theo `granted_at DESC, id DESC`.
- **Nâng cấp từ `khung-tam-0` & cập nhật chế độ thận trọng:**
  - Mở rộng `loadConsentProfile()` (hoặc trả thêm `cautionAnsweredOn`) để đọc `ageYears`, `ageEnteredOn`, `caution`, `cautionAnsweredOn`.
  - Thêm `Future<void> upgradeHealthConsent({required String contentVersion, required int ageYears, required bool caution})`: chạy trong 1 giao dịch — đánh dấu `withdrawn_at` cho các dòng `health_data` cũ có `withdrawn_at IS NULL`, chèn dòng `consents` mới (`kind = 'health_data'`, `content_version`, `granted_at`), cập nhật `profile.caution`, `profile.caution_answered_on` (hôm nay), `profile.updated_at`, và nếu `ageYears` khác giá trị cũ thì cập nhật `age_years` + `age_entered_on`.
  - Thêm `Future<void> saveProfileWithCaution(Profile p, {required bool caution})` (hoặc mở rộng `saveProfile` có tham số tùy chọn `{bool? caution}`): cập nhật thêm `caution` và `caution_answered_on` (chỉ cập nhật `caution_answered_on` khi đổi câu trả lời hoặc khi truyền tường minh) trong cùng giao dịch lưu `profile`.
- **Tự tăng tuổi mỗi 12 tháng & `ui_state`:**
  - Đưa `getUiState(String key)`, `setUiState(String key, String value)` và bổ sung `deleteUiState(String key)` lên interface `JournalRepository` (hiện `DriftJournalRepository` mới có `getUiState`/`setUiState`, chưa có `deleteUiState` và chưa khai báo trên `JournalRepository`). Cài đặt đầy đủ cho cả `DriftJournalRepository` và `InMemoryJournalRepository`.
  - Thêm hàm trên repository `Future<int?> bumpAgeIfDue(DateTime now)`:
    - Đọc `age_years` và `age_entered_on` (`YYYY-MM-DD`).
    - Tính số chu kỳ `12` tháng dương lịch trọn vẹn đã qua từ `age_entered_on` tới ngày địa phương của `now` (vd. `2025-11-25` → `2026-11-25` là `1`; xử lý `29/02` sang năm không nhuận vào `28/02`).
    - Nếu `cycles >= 1` (và giữ trần hợp lệ `<= 120`): trong 1 giao dịch tăng `age_years` thêm `cycles`, tịnh tiến `age_entered_on` thêm `cycles * 12` tháng (giữ ngày neo ban đầu), ghi `ui_state['age_bumped_notice'] = '<tuổi mới>'`, và trả về tuổi mới; ngược lại trả `null`.
  - Thêm `Future<int?> loadAgeBumpedNotice()` và `Future<void> clearAgeBumpedNotice()` đọc/xóa khóa `age_bumped_notice` trong `ui_state` (dùng `deleteUiState`).
- **Tương thích test cũ trên `InMemoryJournalRepository`:**
  - `InMemoryJournalRepository` mặc định khởi tạo sẵn đồng ý `mvpConsentVersion` (và `caution: false`, `ageEnteredOn` ngày hiện tại) để không làm gãy các test giao diện/state cũ đang dùng `AppState.withRepository(..., repo: InMemoryJournalRepository())`.
  - Cho phép truyền tham số tùy chọn ở constructor (vd. `initialConsentVersion: khungTamConsentVersion` hoặc `null`, `initialCaution`) để kiểm thử đầy đủ luồng nâng cấp `khung-tam-0` và onboarding.
- **Nước uống trên `JournalRepository`:**
  - Đưa lên interface `JournalRepository` và cài cho cả `DriftJournalRepository` lẫn `InMemoryJournalRepository`:
    - `Future<int> addWater(DateTime at, double ml)`
    - `Future<void> updateWater(int id, {required DateTime at, required double ml})`
    - `Future<void> deleteWater(int id)`
    - `Future<List<WaterRecord>> waterOn(String day)`
    - `Future<List<WaterRecord>> waterBetween(String fromDay, String toDay)` *(giữ trên repository cho sao lưu/xuất dữ liệu sau này)*
    - `Future<double?> lastWaterMl()` (lấy `ml` của bản ghi mới nhất theo `at DESC, id DESC`)

### 2. State & Interface (`app/lib/state/`)

- **`DbSessionController` (`db_session_controller.dart`) & `AppState` (`app_state.dart`):**
  - Bỏ việc `saveProfile` tự tạo CSDL bằng `khungTamConsentVersion`.
  - Bổ sung giai đoạn phiên làm việc (`SessionStage` hoặc mở rộng trạng thái kết hợp với `DataStatus`):
    1. `welcome` (chưa có khóa/CSDL)
    2. `upgradeRequired` (CSDL mở thành công nhưng `latestHealthConsent() == null` hoặc `contentVersion == khungTamConsentVersion`)
    3. `onboardingBodyProfile` (đã có đồng ý hợp lệ, `onboardingStep == bodyProfile` hoặc `loadProfile() == null`)
    4. `onboardingCalorieDisplay` (`onboardingStep == calorieDisplay` hoặc `loadHideCalories() == null`)
    5. `ready` (`onboardingStep == done`, đủ hồ sơ và tùy chọn calo)
  - Lưu bản nháp câu trả lời `Điều kiện` trong RAM (`PendingConsentDraft(ageYears, caution)`) khi đi qua `1/4` → `2/4`; khi bấm `[Đồng ý và tiếp tục]` mới gọi `opener.createNew(ConsentInput(contentVersion: mvpConsentVersion, ageYears: draft.ageYears, caution: draft.caution))`, rồi chuyển thẳng vào `Hồ sơ cơ thể (3/4)`.
  - Với `upgradeRequired`: lưu trạng thái hoàn tất khi người dùng qua lại `Điều kiện` → `Đồng ý` bằng `repo.upgradeHealthConsent(...)`. Nếu hồ sơ cơ thể và `hideCalories` đã có sẵn từ bản cũ thì vào thẳng `ready` (`Hôm nay`), ngược lại tiếp tục bước còn thiếu (`3/4` hoặc `4/4`).
  - Thêm `Future<void> withdrawConsentAndReset()` gọi `session.startOver(...)` — trong đó truyền rõ `opener.startOver(openRepository: session.repo)` để đóng kết nối SQLite trước khi xóa khóa và tệp CSDL theo đúng luồng 4 của `encrypted-db.md` — xóa trạng thái trong RAM và đưa về `DataStatus.welcome`.
- **`DiaryController` (`diary_controller.dart`):**
  - Mở rộng `DayJournalData` thêm `List<WaterRecord> waters`. Trong `_loadDayAndWindow`, nước không dùng cho trung bình 7 ngày của `health_engine`, nên chỉ gọi `repo.waterOn(toDay)` là đủ.
  - Bổ sung trường: `bool caution`, `double lastWaterMl` (mặc định `250.0` khi repository trả `null`), `int? ageBumpedNotice`.
  - Tách `bumpAgeIfDue(DateTime.now())` khỏi `reload()`: vì `reload()` chạy sau mỗi lần ghi/đổi ngày, **không** chạy hàm ghi `bumpAgeIfDue` trong `reload()`; chỉ chạy 1 lần khi phiên chuyển sang trạng thái `ready` (trong `AppState.start()` / `onResume`). `reload()` chỉ đọc `loadConsentProfile()` và `loadAgeBumpedNotice()`.
  - Thêm các hành động nước:
    - `Future<int?> addWater(DateTime at, double ml)`
    - `Future<int?> quickAddWater()` (ghi `lastWaterMl` vào ngày đang xem: nếu là hôm nay dùng `DateTime.now()`, nếu là ngày khác dùng `12:00` của ngày đó)
    - `Future<bool> updateWater(int id, {required DateTime at, required double ml})`
    - `Future<bool> deleteWater(int id)`
  - Thêm `Future<void> dismissAgeBumpedNotice()` (gọi `deleteUiState`) và `Future<void> saveProfileFromSettings(Profile p, {required bool caution})` (khi lưu từ `Hồ sơ`, nếu sửa `Tuổi` hoặc cập nhật hồ sơ thì gọi luôn `clearAgeBumpedNotice()` để không sót dòng nhắc tuổi cũ).
- **Hàm chuỗi chế độ thận trọng dùng chung (`app/lib/ui/labels.dart`):**
  - Tách bộ trợ giúp định dạng chuỗi theo `bool caution` (ví dụ `CautionLabels`) để bảo đảm `TodayScreen` và các màn tiếp theo không viết lặp `if (caution)` rải rác và khớp đúng bảng đổi chữ trong `mvp-overview.md` (dòng 788).
  - Gộp câu `NotComputedReason.eerUnderAge19` đang hardcode trong `reasonLabel` (`labels.dart`) vào `CautionLabels` / `reasonLabel(r, caution: ...)` để đổi đồng bộ theo `mvp-overview.md`: `"Chưa có mục tiêu calo cho người 18 tuổi."` (thường) ↔ `"Chưa có mức calo tham chiếu cho người 18 tuổi."` (thận trọng).

### 3. Luồng xử lý

1. **Lần đầu dùng app:**
   - `Chào mừng` *(tạm ẩn nút `Khôi phục từ bản sao lưu` cho tới việc 7)* → bấm `[Bắt đầu]` → `Điều kiện (1/4)` (bàn phím số tuổi `1–120`, 2 câu hỏi Có/Không **không chọn sẵn**).
   - Nếu `tuổi < 18` (dùng `pack.minProfileAge`) hoặc câu 1 (`mang thai/cho con bú`) là `Có`: chuyển sang màn `Chưa dùng được`. Màn này không lưu gì; bấm `[Quay lại]` về `1/4` vẫn còn giá trị đã nhập trong RAM để người dùng sửa.
   - Nếu `tuổi >= 18` và câu 1 là `Không`: sang màn `Đồng ý (2/4)`. Ô đồng ý không đánh sẵn; nút `[Đồng ý và tiếp tục]` bị vô hiệu hóa tới khi đánh dấu.
   - Bấm `[Không đồng ý]`: hiện thông báo `"App cần đồng ý này để tính toán. Bạn có thể quay lại bất cứ lúc nào."` kèm nút quay lại `Điều kiện` hoặc về `Chào mừng`, không tạo CSDL.
   - Bấm `[Đồng ý và tiếp tục]`: hiện vòng xoay trên nút chính → `DbOpener.createNew(...)` → thành công sang `Hồ sơ cơ thể (3/4)` (giới tính, chiều cao, cân nặng, mức vận động; không hiện lại ô tuổi hay câu mang thai vì đã hỏi ở `1/4`) → lưu và chuyển `onboarding_step = calorie_display` → `Hiển thị calo (4/4)` (hai lựa chọn không chọn sẵn, nút `[Xong]`) → lưu `hide_calories` + `onboarding_step = done` → `Hôm nay`.
2. **Mở lại khi thoát giữa chừng:**
   - Thoát ở `Chào mừng`, `1/4`, `Chưa dùng được`, `2/4`: chưa có CSDL nên mở lại về `Chào mừng`.
   - Thoát ở `3/4` hoặc `4/4`: mở CSDL thấy `onboarding_step` tương ứng, đưa thẳng vào đúng bước đang dở.
3. **Nâng cấp CSDL `khung-tam-0`:**
   - Mở CSDL thấy `contentVersion == 'khung-tam-0'` → không cho vào `Hôm nay`, mở luồng hỏi lại `Điều kiện` (điền sẵn `ageYears` từ hồ sơ cũ nhưng **không chọn sẵn** 2 câu Có/Không) →
     - Nếu không đủ điều kiện (`< 18` hoặc mang thai/cho con bú = `Có`): sang màn `Chưa dùng được` kèm `[Quay lại]` (nếu bấm nhầm) và nút `[Xóa toàn bộ dữ liệu]` (xác nhận gõ `XÓA`, gọi `withdrawConsentAndReset()`) để người dùng không bị kẹt với tệp CSDL cũ.
     - Nếu đủ điều kiện: sang màn `Đồng ý`, yêu cầu đánh dấu đồng ý mới; `[Không đồng ý]` giữ nguyên tại bước xác nhận (kèm lựa chọn rút đồng ý & xóa dữ liệu); `[Đồng ý và tiếp tục]` ghi dòng `mvp-1` và `caution`, giữ nguyên toàn bộ món/bổ sung/buổi tập/nước đã ghi trước đó và đưa vào `Hôm nay` (hoặc bước `3/4`/`4/4` nếu hồ sơ cũ chưa hoàn tất).
4. **Chế độ thận trọng & tự cập nhật tuổi trên `Hôm nay`:**
   - Khi phiên chuyển sang trạng thái `ready` (`start()` / `onResume`), app gọi `bumpAgeIfDue(DateTime.now())` đúng 1 lần (không chạy trong `reload()`).
   - Thứ tự đầu màn `Hôm nay`: `WarningCard` (nếu vượt UL) → `SafetyNote` thận trọng (nếu `caution == true`, không có nút thu gọn) → dòng nhắc `"Tuổi trong hồ sơ đã được cập nhật thành {n}. Sửa"` (nếu có `age_bumped_notice`; chạm `Sửa` mở `Hồ sơ`, và đóng/xóa cờ nhắc qua `deleteUiState`).
   - Khi `caution == true`: áp dụng bảng đổi chữ (`"{x}% mức tham chiếu"`, `"Mức calo tham chiếu"`, `"mức tham chiếu {g}"`, `"Chưa có mức calo tham chiếu cho người 18 tuổi."`, `reasonLabel` cho `eerUnderAge19`...), giữ nguyên `"mức ước tính"` và `"Chưa đủ dữ liệu để đặt mức khuyến nghị chính thức; đây là mức ước tính."`.
5. **Điều hướng `HomeScreen`, tab `Tôi` và màn `Hồ sơ`:**
   - Cập nhật `HomeScreen` thành 3 tab: `Hôm nay` · `Nhật ký` · `Tôi` (đổi nhãn tab `Tổng kết` → `Hôm nay`; tab `Bổ sung` hoàn chỉnh thêm ở việc 5–6).
   - Trong `Tôi`: gồm `Hồ sơ`, `Hiển thị` (chứa công tắc `Ẩn số calo` đọc/lưu `hide_calories` để kiểm thử khép kín sau bước `4/4`), và `Xóa toàn bộ dữ liệu` (xác nhận gõ `XÓA`).
   - Trong `Hồ sơ`: bỏ bộ câu hỏi mang thai/cho con bú của khung tạm; hiện ô `Tuổi` (tối thiểu `pack.minProfileAge` = `18`), giới tính, chiều cao, cân nặng, mức vận động, nút `[Lưu]` (khi lưu gọi luôn `clearAgeBumpedNotice()` để không sót dòng nhắc tuổi cũ).
   - Cuối màn `Hồ sơ`: câu Có/Không về thuốc theo chỉ định / bệnh mạn tính (chọn sẵn theo `caution` hiện tại; đổi và bấm `[Lưu]` cập nhật `caution`, `caution_answered_on` và cập nhật lại toàn bộ thẻ trên `Hôm nay`) cùng khung nhắc thai kỳ có nút `[Xóa toàn bộ dữ liệu]` và ghi chú tính năng xuất dữ liệu sẽ có ở bản cập nhật sau (việc 7; không đặt nút chết trên UI).
6. **Ghi, sửa, xóa nước uống:**
   - Trên `Hôm nay`: thẻ `Nước` luôn hiển thị (nằm dưới phần `Vi chất`). Khi chưa ghi hôm nay hiện `"Chưa ghi nước hôm nay"`, khi đã ghi hiện `"Đã uống {tổng ml}"` (vd. `1.250 ml`), bên phải là nút `[+{lastWaterMl} ml]`. Chạm nút cộng ghi ngay một lần uống vào **ngày đang xem** (`DateTime.now()` nếu là hôm nay, `12:00` ngày đó nếu đang xem ngày cũ) và hiện `UndoSnack` (`"Đã ghi {ml} ml nước · Hoàn tác"`, 7 giây); chạm phần thân thẻ mở màn `Ghi nước`.
   - Màn `Ghi nước`: tiêu đề `Ghi nước · {HH:mm}` (chạm giờ để đổi; nếu xem ngày khác hôm nay thì hiện ngày ở đầu màn), ba nút chọn nhanh `[150 ml] [250 ml] [500 ml]`, ô `Số khác [ ] ml` (nhập số khác sẽ bỏ chọn 3 nút nhanh và ngược lại), nút `[Lưu]`.
   - Màn `Nhật ký`: có bộ lọc `Tất cả / Món ăn / Bổ sung / Nước / Buổi tập`; hiện dòng `Nước  {tổng ml} ({n} lần)` và cho xem danh sách từng lần uống để chạm vào sửa lượng (`ml`), đổi giờ hoặc xóa (có hộp thoại xác nhận xóa).

### 4. Lỗi và biên

- **Tuổi nhập sai:** Rỗng, không phải số nguyên, `< 1` hoặc `> 120` tại `Điều kiện` → nhắc lỗi dưới ô, khóa nút `[Tiếp tục]`. Trong `Hồ sơ`, nhập `< 18` hoặc `> 120` → nhắc lỗi dưới ô, không cho lưu (`< 18` nhắc app hiện chỉ hỗ trợ từ 18 tuổi).
- **Chiều cao, cân nặng ngoài khoảng hợp lý:** Chiều cao ngoài `120–220 cm` hoặc cân nặng ngoài `30–250 kg` → hiện dòng nhắc kiểm tra lại nhưng **không chặn lưu** (vẫn chặn giá trị `<= 0` hoặc vượt giới hạn vật lý như `> 300`).
- **Lượng nước không hợp lệ:** `ml <= 0` hoặc `ml > 5000` trong một lần ghi → nhắc dưới ô, không cho lưu (tránh nhập nhầm lít hoặc số âm).
- **Ngày `29/02` khi tăng tuổi:** Nếu `age_entered_on` là `29/02` của năm nhuận, mốc 12 tháng vào năm không nhuận là `28/02`; chu kỳ tiếp theo giữ lại ngày `28` hoặc ngày gốc — dùng hàm cộng tháng chuẩn hóa ngày cuối tháng nhất quán và neo về ngày gốc nếu dùng cộng năm.
- **Lỗi tạo CSDL / đầy bộ nhớ (`StorageFullException`, `JournalStorageException`):**
  - Ở bước `Đồng ý`: nếu `createNew` lỗi, màn hình giữ nguyên ở bước `Đồng ý`, không để sót khóa mồ côi và hiện `"Chưa lưu được. Thử lại"` (hoặc `"Máy không còn đủ dung lượng..."` nếu `LowStorage`).
  - Ở bước lưu hồ sơ hoặc ghi/sửa/xóa nước: giao dịch hoàn tác, state giữ nguyên dữ liệu cũ, hiện snackbar `"Chưa lưu được. Thử lại"`.

## Tiêu chí đạt

- [ ] Trước khi đánh dấu và bấm `[Đồng ý và tiếp tục]`, thư mục app không có tệp `wholewell.db` và `SecureKeyStore` chưa có khóa; bấm `[Không đồng ý]` hay đi qua `Chưa dùng được` cũng không tạo tệp hay khóa; màn `Chào mừng` chưa hiện nút `Khôi phục từ bản sao lưu`.
- [ ] Trên `Điều kiện`: không chọn sẵn 2 câu; nhập tuổi `17` hoặc chọn `Đang mang thai hoặc cho con bú: Có` → chuyển `Chưa dùng được`; bấm `[Quay lại]` giữ nguyên các giá trị vừa chọn để sửa được.
- [ ] Hoàn thành `1/4` → `2/4` → `3/4` → `4/4`: bảng `consents` có dòng `kind = 'health_data'`, `content_version = 'mvp-1'`, `withdrawn_at IS NULL`; thoát ở `3/4` hoặc `4/4` rồi mở lại vào đúng bước đang dở; `4/4` không chọn sẵn phương án calo; vào được tab `Hôm nay · Nhật ký · Tôi` và đổi lại được `Ẩn số calo` trong `Tôi → Hiển thị`.
- [ ] Nâng cấp CSDL có `khung-tam-0`: giữ nguyên món/bổ sung/buổi tập cũ, bắt buộc đi qua `Điều kiện` và `Đồng ý` mới vào được `Hôm nay`; nếu chọn `< 18` hoặc mang thai/cho con bú trong luồng nâng cấp → hiện `[Xóa toàn bộ dữ liệu]` (gõ `XÓA`) cạnh `[Quay lại]`; sau khi đồng ý có dòng consent `mvp-1` và `profile.caution` đúng theo câu trả lời mới; rút đồng ý/xóa gọi `opener.startOver(openRepository: session.repo)` đóng SQLite trước khi xóa khóa và tệp; các test UI/state dùng `InMemoryJournalRepository()` mặc định vẫn chạy bình thường.
- [ ] Chế độ thận trọng (`caution == true`): đầu `Hôm nay` có `SafetyNote` không thu gọn; mọi chuỗi `"mức khuyến nghị"` / `"Mục tiêu calo"` (gồm cả `reasonLabel` cho `eerUnderAge19`) đổi sang `"mức tham chiếu"` / `"Mức calo tham chiếu"`, `"ước tính"` giữ nguyên; vượt UL vẫn hiện `WarningCard`; đổi lại `Có`/`Không` trong `Hồ sơ` cập nhật ngay trên `Hôm nay`.
- [ ] Tự tăng tuổi: kiểm thử `bumpAgeIfDue` qua 0 tháng (`null`), 11 tháng (`null`), 12 tháng (`+1`), 25 tháng (`+2`, `age_entered_on` tiến 24 tháng), và trường hợp `29/02`; chỉ chạy 1 lần khi phiên vào `ready` (không chạy trong `reload()`); trên UI hiện dòng thông báo tuổi mới và biến mất sau khi người dùng mở `Sửa` hoặc tự sửa `Tuổi` rồi bấm `Lưu` trong `Hồ sơ` (`deleteUiState`).
- [ ] Nước uống (`packages/journal_db` cả `InMemory` và `Drift` qua SQLite3MultipleCiphers + `DiaryController` + UI): thêm/sửa/xóa/truy vấn đúng theo `day`; `lastWaterMl` trả đúng lượng lần uống gần nhất (mặc định `250 ml` khi chưa ghi); nút cộng 1 chạm trên `Hôm nay` ghi vào ngày đang xem (`12:00` nếu ngày cũ) kèm `UndoSnack`; `Ghi nước` và `Nhật ký` (lọc `Nước`, sửa/xóa) hoạt động đúng và tuyệt đối không hiển thị mục tiêu hay cảnh báo thiếu nước.
- [ ] `dart analyze`, `dart test` (`health_engine`, `journal_db`), `flutter analyze`, `flutter test` đều pass sạch (0 lỗi, 0 cảnh báo, 0 info).

## Ngoài phạm vi

- Tính năng **Sao lưu tệp mã hóa / Google Drive**, nút `Khôi phục từ bản sao lưu`, `[Xuất dữ liệu]` và màn **Quyền riêng tư** đầy đủ (việc 7).
- Các màn **Chi tiết chất**, **Chi tiết cảnh báo**, **Nguồn số liệu**, **Giới thiệu**, **Giờ trong ngày** đầy đủ, cũng như luồng **Kho / Lịch uống bổ sung / Chụp nhãn** và tab **Bổ sung** (việc 5–6).
- Mục tiêu calo/DRI cho người dưới 18 tuổi, mang thai, cho con bú (giai đoạn 2) và ODA (LPI, cổng 3).

## Câu hỏi còn mở

- Không còn câu hỏi mở (5 điểm đã được chủ dự án chốt ngày 25/11/2026).
