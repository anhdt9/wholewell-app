# Đặc tả: Lịch uống, nhắc giờ Android, nút "Đã uống"

Trạng thái: Đã duyệt (26/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/schedule-reminders.md](../design/schedule-reminders.md)
Thứ tự MVP: Việc 6 trong [docs/status.md](../status.md)

## Mục tiêu
Cho phép người dùng đặt lịch uống cố định theo giờ cho các sản phẩm bổ sung, nhận lưu ý/gợi ý khoa học trước khi lưu lịch (cảnh báo vượt giới hạn theo lịch và 5 quy tắc lịch từ NIH ODS), nhận thông báo nhắc giờ trên Android bảo mật thông tin sức khỏe, và đánh dấu "Đã uống" / "Bỏ qua" gắn đúng khung giờ ±2 giờ (kể cả qua nửa đêm).

## Người dùng và tình huống
- Người dùng mở chi tiết một sản phẩm bổ sung → bấm **Đặt lịch uống** (chọn giờ trong ngày và số đơn vị mỗi lần). Nếu là lần đầu bật nhắc giờ, app nhắc xác nhận **Giờ trong ngày** (`day_times_confirmed` trong `settings`) và lưu đồng ý thông báo (`consents.kind = 'notifications'`). Trước khi lưu lịch, app kiểm tra giới hạn an toàn theo lịch và 5 quy tắc lịch.
- Hằng ngày, trên màn **Hôm nay** hiện thẻ **Lần uống tới** / danh sách **Lần uống hôm nay** (chưa uống, đã uống, bỏ qua, chưa đánh dấu) và thẻ **"Bạn có biết"** ở cuối màn (chỉ hiện khi không có cảnh báo vượt giới hạn và `settings.show_tip_card == 1`).
- Khi đến giờ, điện thoại Android hiện thông báo chung (không lộ tên chất/sản phẩm); người dùng chạm thông báo hoặc nút **"Đã uống"** để mở app ghi nhận ngay (luôn tính vào giới hạn dù kho = 0; nếu chỉ còn hộp hết hạn vẫn hỏi `"Trừ vào hộp đã hết hạn?"`). Sau 2 giờ (hết khung), Android tự gỡ thông báo bằng `setTimeoutAfter`.

## Ràng buộc
- **Dữ liệu ở máy & quyền riêng tư (`AGENTS.md`, `docs/design/README.md`, `docs/design/mvp-overview.md`):**
  - Thông báo trên màn hình khóa chỉ hiện chữ chung (ví dụ `"Đến giờ uống"` hoặc `"Đến giờ uống, 2 loại"`), **không** hiện tên chất, tên sản phẩm hay liều lượng. Nếu lần vừa ghi làm vượt giới hạn an toàn, gửi thêm thông báo chung `"Có thông tin mới cần xem trong WholeWell"`, chạm mở Chi tiết cảnh báo.
  - Siêu dữ liệu lịch nhắc lưu ngoài CSDL mã hóa (cho `AlarmManager` / `NotificationScheduler`) chỉ chứa `timeOfDay`, số lượng loại ở khung giờ đó và danh sách mã lịch (`scheduleId`); không chứa tên sản phẩm hay chất sức khỏe.
  - Nút **"Đã uống"** trên thông báo **mở app** (để người dùng mở khóa máy nếu đang khóa) rồi mới ghi; không ghi trong nền (vì Android Keystore `setUnlockedDeviceRequired` yêu cầu máy mở khóa).
- **Quy tắc lịch là dữ liệu (`AGENTS.md`):**
  - 5 quy tắc lịch được định nghĩa thành dữ liệu trong `tools/build_pack.py` (`scheduleRules`), thêm quy tắc cùng loại không phải sửa code engine.
  - **Không** thêm quy tắc canxi–magie, canxi–kẽm hay khoảng cách giờ cụ thể (vì nguồn không nêu). Vitamin C tăng hấp thu sắt chỉ là thông tin ở chi tiết chất, không thành gợi ý lịch.
- **Không chặn lưu lịch / ghi lần uống:** Khi vượt giới hạn theo lịch hoặc chạm quy tắc lịch, app cảnh báo/lưu ý rõ ràng nhưng vẫn cho người dùng tự quyết định lưu.
- **Giao diện tiếng Việt thường ngày:** Không hiện viết tắt chuẩn (RDA, UL, EER, AMDR).

## Nguồn
Tất cả 5 quy tắc lịch lấy từ fact sheet Health Professional của **NIH Office of Dietary Supplements (ODS)** (đã đối chiếu qua Chrome ngày 23/11/2026, `docs/plan.md` mục 4; bổ sung đủ vào `SOURCES` của `tools/build_pack.py` để `verify_pack.py` kiểm tham chiếu):
1. **Canxi mỗi lần >500 mg:** hấp thu cao nhất khi mỗi lần ≤500 mg — [NIH ODS Calcium](https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/)
2. **Canxi cùng bữa ăn (canxi carbonat):** hấp thu tốt hơn cùng thức ăn; canxi carbonat cần bữa ăn với người ít axit dạ dày; citrat uống lúc đói được — [NIH ODS Calcium](https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/)
3. **Canxi & sắt cùng giờ:** chuyên gia khuyên uống khác giờ; tác động chưa xác lập chắc chắn — [NIH ODS Iron](https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/)
4. **Sắt ≥25 mg & kẽm cùng giờ:** sắt bổ sung ≥25 mg uống cùng lúc với kẽm bổ sung làm giảm hấp thu kẽm — [NIH ODS Zinc](https://ods.od.nih.gov/factsheets/Zinc-HealthProfessional/)
5. **Vitamin D cùng bữa ăn:** chất béo trong bữa giúp hấp thu vitamin D; không có vẫn hấp thu một phần — [NIH ODS Vitamin D](https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/)

*(Quy tắc của app: **"cùng bữa"** = ±1 giờ quanh giờ một bữa chính trong bảng `settings`; **"cùng giờ"** cho quy tắc 3 & 4 = hai lịch có `|t1 - t2| ≤ 60 phút`; **khung khớp lần uống** = ±2 giờ quanh giờ lịch.)*

## Thiết kế kỹ thuật

### 1. Gói dữ liệu (`tools/build_pack.py`, `verify_pack.py`, `reference_engine.py`)
- Bổ sung các nguồn NIH ODS (Calcium, Iron, Zinc, Vitamin D Health Professional, ngày tra 23/11/2026) vào `SOURCES` nếu chưa có.
- Bổ sung mảng `scheduleRules` vào `reference_pack.json`, mỗi phần tử gồm:
  - `id`, `type`, `severity` (`notice` cho quy tắc 1, 3, 4; `suggestion` cho quy tắc 2, 5), `nutrients`, `forms` (nếu có), `threshold` / `unit` (nếu có), `windowMinutes` (`60` cho cùng giờ, `60` cho quanh bữa), `uncertain` (`bool`), `messageVi` (câu lưu ý/gợi ý hiển thị khi đặt lịch/trên Hôm nay), `tipVi` (câu hiển thị ở thẻ `"Bạn có biết"`), `source`, `url`, `accessedDate`, `quote`.
- 4 loại `type` tổng quát chạy bằng dữ liệu:
  - `single_dose_max` (quy tắc 1: tổng `calcium` bổ sung trong một khung giờ / một lần > 500 mg → lưu ý).
  - `take_with_meal` (quy tắc 2: `calcium` dạng `calcium_carbonate` → gợi ý xếp vào ±60 phút quanh `breakfast`/`lunch`/`dinner`; quy tắc 5: `vitD` → gợi ý nhẹ xếp vào bữa).
  - `co_timing_caution` (quy tắc 3: `calcium` + `iron` bổ sung chênh lệch ≤ 60 phút, `uncertain: true` → lưu ý `"chưa chắc chắn"`).
  - `co_timing_threshold` (quy tắc 4: `iron` bổ sung ≥ 25 mg + `zinc` bổ sung chênh lệch ≤ 60 phút → lưu ý).
- Cập nhật `verify_pack.py` để kiểm mọi phần tử trong `scheduleRules` có đủ `source` hợp lệ trong `SOURCES`, `url`, `quote`, `accessedDate`, `messageVi`, `tipVi`.

### 2. Engine (`packages/health_engine` & `tools/reference_engine.py`)
- Đọc `scheduleRules` từ `ReferencePack` kèm mô hình `ScheduleRule`, `MealTimes` (lấy `breakfast`, `lunch`, `dinner` từ bảng `settings`), `ScheduledDoseInput`, `ScheduleNotice`.
- `evaluateScheduleRules(pack, mealTimes, scheduledDoses)`: xử lý hoàn toàn dựa trên dữ liệu `scheduleRules` (không viết cứng quy tắc cho từng cặp chất), hỗ trợ cả tính gộp nhiều sản phẩm uống cùng khung giờ (vd. 2 viên canxi uống cùng 08:00 tổng 600 mg > 500 mg).
- `matchDoseToScheduleWindow(doseAt, schedules, occurrencesOfDay, occurrencesOfPrevDay)`:
  - Chỉ xét các lần theo lịch **chưa đánh dấu** (`unmarked`: chưa có `Occurrence` trạng thái `taken` hay `skipped`) trong khung **±2 giờ** quanh giờ lịch của ngày ghi `D` **và** các lịch của ngày `D - 1` có khung ±2 giờ vắt qua nửa đêm (ví dụ lịch 23:00 ngày `D - 1` khớp lần uống 00:30 ngày `D`).
  - Nếu nhiều khung chồng nhau, chọn lần có khoảng cách thời gian `|doseAt - scheduledAt|` nhỏ nhất.
  - Khi người dùng sửa giờ hoặc đổi ngày của một lần uống, tính lại liên kết khớp (xóa `Occurrence` cũ nếu rời khung và gắn `Occurrence` mới nếu vào khung chưa đánh dấu).
- Dùng lại `checkUlSchedule(pack, profile, scheduledDailyItems)` để kiểm tra vượt giới hạn theo lịch trước khi lưu lịch.

### 3. CSDL (`packages/journal_db`)
- Giữ nguyên lược đồ `v2` (`schedules`, `dose_occurrences`, `settings`, `consents` đã có đủ bảng và cột).
- Đưa các phương thức lịch vốn đã cài trên `DriftJournalRepository` lên interface `JournalRepository` và cài đặt đầy đủ trên `InMemoryJournalRepository`:
  - `addSchedule`, `updateSchedule`, `schedulesOn`, `occurrencesOn`, `skipOccurrence`, `clearOccurrence` (không tạo `recordScheduledDose` riêng vì `recordDose` đã nhận `DoseInput.occurrence`).
  - Bổ sung `endSchedule(int id, {required String validTo})` trên cả `Drift` và `InMemory` (đặt `valid_to = validTo` để ẩn lịch từ ngày đó mà không làm mất liên kết lịch sử `dose_occurrences` cũ).
  - Cập nhật `InMemoryJournalRepository.listProducts` dùng `schedulesOn(today)` thật thay cho `activeSchedules: const []` hiện tại (để dự kiến ngày hết kho tính cả lịch đang hoạt động trong test).
  - Đọc/ghi `settings` (`wake`, `breakfast`, `lunch`, `dinner`, `sleep`, `day_times_confirmed`, `show_tip_card`) và `consents` (`kind = 'notifications'`, `granted` / `withdrawn`) qua `JournalRepository` để phục vụ bước Giờ trong ngày và bật/tắt nhắc giờ.

### 4. Interface nền tảng (`NotificationScheduler`) & Android (`app/`)
- **Khuyến nghị kỹ thuật Android:** Dùng Kotlin `AlarmManager` + `NotificationCompat` qua `MethodChannel` (nhẹ, không kéo thêm thư viện ngoài, kiểm soát trực tiếp `setTimeoutAfter` và quyền `SCHEDULE_EXACT_ALARM` trên Android 14+).
- Interface `NotificationScheduler` trong `app/lib/platform/notification_scheduler.dart` + `FakeNotificationScheduler`:
  - `Future<bool> requestPermission()` (kiểm/xin `POST_NOTIFICATIONS` trên Android 13+).
  - `Future<void> syncSchedules(List<ScheduledReminderSlot> slots)` (nhóm theo `timeOfDay`, chỉ truyền `timeOfDay`, `itemCount`, danh sách `scheduleIds`).
  - `Future<void> cancelWindow(int timeOfDayMinutes)` (hủy thông báo đang hiện khi đã ghi/bỏ qua hết khung đó).
  - `Future<void> showUlAlertNotice()` (thông báo chung `"Có thông tin mới cần xem trong WholeWell"` khi lần ghi từ nhắc giờ vượt giới hạn).
  - `Stream<NotificationAction> get onNotificationAction` **và** `Future<NotificationAction?> takePendingNotificationAction()` để xử lý **cold start** (app đang tắt hẳn được mở từ nút `"Đã uống"` trên thông báo: giữ payload chờ đến khi CSDL mở khóa xong).
- **Xử lý Android cụ thể:**
  - Dùng `NotificationCompat.Builder.setTimeoutAfter(120 * 60 * 1000L)` (tương thích `minSdk = 28`) để tự gỡ thông báo đúng sau 2 giờ mà không cần alarm hủy riêng.
  - Trên Android 14+ (API 34+), kiểm `AlarmManager.canScheduleExactAlarms()`: nếu chưa cấp thì fallback sang `setAndAllowWhileIdle(...)` (inexact alarm) thay vì ném `SecurityException`.
- **Luồng nút `"Đã uống"` / hộp hết hạn:**
  - Nếu khung giờ có nhiều hơn 1 sản phẩm đang chờ: mở sheet xác nhận nhanh danh sách các loại trong khung (mặc định chọn tất cả, cho bỏ tick từng loại) và bấm 1 chạm `[Ghi đã chọn]`.
  - Mọi lần ghi từ thẻ lịch hoặc thông báo đều qua `DiaryController.recordDose`: vẫn tính vào giới hạn dù kho = 0, và nếu `recordDose` trả `DoseNeedsExpiredChoice` (chỉ còn hộp hết hạn) thì mở hộp thoại `"Trừ vào hộp đã hết hạn?"` giống `AddSupplementScreen`.

### 5. Lỗi và biên
- **Từ chối quyền thông báo:** không crash, không chặn dùng lịch trong app; hiện trạng thái `"Chưa bật quyền thông báo"` kèm nút `[Mở cài đặt]`.
- **Khung qua nửa đêm (22:00–23:59 hoặc 00:00–01:59):** lần uống lúc 00:30 ngày `D` khớp được với lịch 23:00 ngày `D - 1` nếu chưa `taken`/`skipped`, nhưng lượng nạp vẫn tính vào ngày `D` (ngày uống thực tế).
- **Thẻ `"Bạn có biết"` trên Hôm nay:** mỗi ngày 1 câu luân phiên từ các quy tắc lịch có chất đang có trong kho; chữ đứng yên; ẩn ngay khi đang có bất kỳ cảnh báo vượt giới hạn nào hoặc khi người dùng tắt `show_tip_card`.

## Tiêu chí đạt
- [ ] `tools/build_pack.py` + `verify_pack.py` + `reference_engine.py` có đủ 5 `scheduleRules` (kèm `messageVi`, `tipVi`, nguồn trong `SOURCES`) và fixtures đối chiếu.
- [ ] `packages/health_engine` đọc `scheduleRules` (dữ liệu thuần), cài `evaluateScheduleRules` + `matchDoseToScheduleWindow` (kèm ca 23:00 → 00:30, nhiều khung chồng nhau, chỉ xét `unmarked`), và `dart analyze && dart test` pass.
- [ ] `packages/journal_db` đưa đủ API lịch lên `JournalRepository`, cài `InMemoryJournalRepository` (dùng lịch thật trong `listProducts`), `endSchedule`, đọc/ghi `settings` & `consents.kind = 'notifications'`, toàn bộ test qua SQLite3MultipleCiphers pass.
- [ ] `app/` có `NotificationScheduler` + `AndroidNotificationScheduler` (`MethodChannel` + Kotlin `AlarmManager`/`NotificationCompat` kèm unit test JVM & `setTimeoutAfter` + fallback API 34+) + `FakeNotificationScheduler` (có `takePendingNotificationAction` cho cold start), luồng Đặt lịch + `Giờ trong ngày` + cảnh báo UL theo lịch + lưu ý 5 quy tắc + `Lần uống hôm nay` + `"Bạn có biết"` + xử lý `NeedsExpiredChoice`, và toàn bộ `flutter analyze && flutter test` pass.

## Ngoài phạm vi
- **Nhắc giờ iOS (`UNUserNotificationCenter`):** làm ở giai đoạn iOS sau MVP.
- **Lịch cách ngày / theo thứ trong tuần (ví dụ 2-4-6):** MVP chỉ hỗ trợ lịch hằng ngày theo giờ (`time_of_day`).

## Quyết định chờ duyệt
1. Dùng **Kotlin `AlarmManager` + `NotificationCompat` qua `MethodChannel`** cho Android.
2. Định nghĩa **"cùng giờ"** cho quy tắc 3 & 4 là **`|t1 - t2| ≤ 60 phút`**.
3. Khi bấm **"Đã uống"** từ thông báo ở khung có nhiều loại: mở sheet xác nhận nhanh danh sách các loại trong khung để ghi 1 chạm (vẫn hỏi nếu chỉ còn hộp hết hạn).
