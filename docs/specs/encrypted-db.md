# Đặc tả: CSDL mã hóa và lược đồ dữ liệu

Thứ tự code MVP, mục 2 ([plan.md](../plan.md) “Thứ tự code cho MVP”, “Lưu dữ liệu trên máy”).

## Mục tiêu

Mọi dữ liệu người dùng (hồ sơ, nhật ký ăn, buổi tập, nước, sản phẩm, kho, lịch uống) được lưu bền trên máy trong một tệp SQLite mã hóa. Tắt app, mở lại vẫn còn. Ai lấy được tệp mà không có khóa thì không đọc được.

## Ràng buộc

- Không máy chủ, không mạng. Khóa không bao giờ rời kho bảo mật của hệ điều hành; không ghi khóa vào log, tệp, thông báo lỗi.
- CSDL và khóa **không** vào sao lưu tự động của hệ điều hành (Android Auto Backup / chuyển thiết bị). Sao lưu chỉ qua bước 7 của MVP.
- Phụ thuộc nền tảng chỉ qua interface `SecureKeyStore` (AGENTS.md, quy tắc 4); có bản giả `InMemorySecureKeyStore` để test.
- Engine (`packages/health_engine`) không đổi, không biết CSDL. Lưu trữ nằm trong `app/lib/data/`.
- Chỉ dữ liệu giả lập trong test.

## Công nghệ

| Phần | Chọn | Ghi chú |
|---|---|---|
| ORM | `drift` ^2.35, `drift_dev` + `build_runner` (dev) | Mã hóa sẵn từ 2.32, không cần `sqlcipher_flutter_libs` |
| SQLite | `sqlite3` ^3.9 với hook `source: sqlite3mc` | Khai báo trong `app/pubspec.yaml`, mục `hooks.user_defines.sqlite3.source` |
| Mở CSDL | `NativeDatabase.createInBackground(file, setup: …)` | Không dùng `driftDatabase()` của drift_flutter, vì cần `setup` để đặt khóa |
| Khóa | `flutter_secure_storage` sau `SecureKeyStore` | Android Keystore, Windows Credential Manager, Keychain |
| Vị trí tệp | `getApplicationSupportDirectory()/wholewell.db` (`path_provider`) | Không dùng thư mục Documents |

Phiên bản cụ thể ghim khi thêm vào pubspec (plan, mục “Phiên bản”).

## Khóa

1. Lần đầu: sinh 32 byte bằng `Random.secure()`, mã hóa hex (64 ký tự), ghi vào `SecureKeyStore` với tên `wholewell.db.key.v1`.
2. Các lần sau: đọc lại đúng khóa đó. Không bao giờ sinh khóa mới khi đã có tệp CSDL.
3. Đặt khóa bằng `PRAGMA hexkey = '<64 hex>'` (không qua bước dẫn xuất từ mật khẩu, không có vấn đề trích dẫn ký tự).
4. Trong `setup`, trước khi đặt khóa: chạy `PRAGMA cipher;`; kết quả rỗng nghĩa là bản SQLite không có mã hóa → **dừng, không mở CSDL** (kiểm cả bản phát hành, không chỉ `assert`).
5. Sau khi đặt khóa: bật `PRAGMA foreign_keys = ON`, đọc `sqlite_master` để xác nhận khóa đúng.

## Lỗi khi mở

`openAppDatabase()` trả về CSDL hoặc ném `DatabaseOpenError` với một trong các lý do:

| Lý do | Khi nào | Giao diện |
|---|---|---|
| `cipherUnavailable` | `PRAGMA cipher` rỗng | “Không mở được dữ liệu an toàn trên máy này.” Không cho dùng tiếp |
| `keyStoreUnavailable` | Kho khóa ném lỗi | “Không đọc được khóa bảo mật.” Nút thử lại |
| `keyMissing` | Có tệp CSDL nhưng không còn khóa (vd. cài lại, xóa dữ liệu kho khóa) | Nút “Xóa dữ liệu và bắt đầu lại” (xác nhận 2 lần). Khôi phục từ bản sao lưu thêm ở bước 7 |
| `wrongKeyOrCorrupt` | Khóa không mở được tệp, hoặc tệp hỏng | Như `keyMissing` |

App không tự xóa dữ liệu trong bất kỳ trường hợp nào.

## Lược đồ (phiên bản 1)

Quy ước: ngày là `TEXT` dạng `YYYY-MM-DD` theo giờ máy; thời điểm là `INTEGER` mili giây UTC; id là `INTEGER` tự tăng. Lượng chất luôn lưu kèm đơn vị.

| Bảng | Cột chính | Dùng ở bước |
|---|---|---|
| `people` | id, display_name, is_primary, created_at | 2 |
| `profiles` | person_id (PK, FK people), age_years, sex, height_cm, weight_kg, stage, gestation_week?, pre_pregnancy_bmi?, months_postpartum?, activity_level, updated_at | 2 |
| `settings` | key (PK), value | 2 |
| `intake_entries` | id, person_id, day, label, source (`food`/`fortified`/`supplement`), meal_id?, product_id?, dose_log_id?, created_at | 2 |
| `intake_nutrients` | entry_id (FK, xóa theo), nutrient_id, amount, unit; PK (entry_id, nutrient_id) | 2 |
| `workouts` | id, person_id, day, activity_code, minutes, created_at | 2 |
| `water_logs` | id, person_id, day, ml, created_at | 4 (nhập nước) |
| `products` | id, short_name, full_name?, dosage_form, units_per_serving, servings_per_container?, barcode?, label_photo_path?, confirmed, created_at | 5 |
| `product_nutrients` | product_id (FK, xóa theo), nutrient_id, chemical_form?, amount_per_serving, unit, source (`supplement`/`fortified`) | 5 |
| `inventory_boxes` | id, product_id, units_remaining, opened_on?, expires_on?, discarded, created_at | 5 |
| `regimens` | id, person_id, kind (`supplement`/`water`), product_id?, units_per_dose?, water_ml?, minute_of_day (0–1439), with_meal, weekdays (bitmask, 127 = mọi ngày), remind_repeat, remind_interval_min, active, created_at | 6 |
| `dose_logs` | id, regimen_id, day, minute_of_day, status (`taken`/`skipped`/`late`), taken_at?, box_id?, intake_entry_id?; UNIQUE (regimen_id, day, minute_of_day) | 6 |

- `people` gồm cả người không có hồ sơ (trẻ em chỉ được tính vào kho, plan mục “An toàn người dùng”); `profiles` chỉ cho người từ 18 tuổi.
- MVP chỉ có một người chính (`is_primary = 1`); nhiều hồ sơ người lớn là giai đoạn 2.
- Các bảng của bước 4–6 tạo ngay trong phiên bản 1 nhưng chưa có giao diện. Trước bản phát hành công khai đầu tiên, lược đồ có thể sửa thẳng trong phiên bản 1. Sau đó, mọi thay đổi cần bước chuyển đổi kèm test (plan, “Đổi lược đồ CSDL”).

### Đơn vị

- `unit` lấy từ gói dữ liệu khi ghi (`nutrients[].unit`), cộng ba khóa năng lượng không có trong danh sách chất: `energyKcal` → `kcal`, `fat` → `g`, `addedSugar` → `g`.
- Khi đọc, nếu `unit` trong CSDL khác đơn vị hiện tại của gói, repository ném `UnitMismatch` thay vì trả số sai (tiêu chí 0 lỗi đơn vị).
- Khóa chất không có trong bảng đơn vị → không ghi, ném `UnknownNutrient`.

## Repository

`JournalRepository` chuyển sang bất đồng bộ (`Future`), và xóa theo id thay vì theo vị trí:

```dart
abstract class JournalRepository {
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile p);
  Future<bool> loadHideCalories();
  Future<void> saveHideCalories(bool v);

  Future<List<Stored<IntakeItem>>> itemsBetween(DateTime from, DateTime to); // gồm cả hai đầu
  Future<int> addItem(DateTime day, IntakeItem it);
  Future<void> removeItem(int id);

  Future<List<Stored<WorkoutEntry>>> workoutsBetween(DateTime from, DateTime to);
  Future<int> addWorkout(DateTime day, WorkoutEntry w);
  Future<void> removeWorkout(int id);
}
```

- `Stored<T>`: `id`, `day`, `value`.
- `DriftJournalRepository` (thật) và `InMemoryJournalRepository` (giả, giữ cho test giao diện) cùng qua một bộ test hợp đồng.
- `AppState` giữ bộ đệm 7 ngày tính đến ngày đang xem, nạp lại khi đổi ngày hoặc sau mỗi lần ghi; giao diện giữ nguyên API đồng bộ hiện có (`todayItems`, `report()`…). Có cờ `loading` cho lần nạp đầu.

## Loại khỏi sao lưu hệ điều hành

- Android (`AndroidManifest.xml`): `android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:dataExtractionRules="@xml/data_extraction_rules"` với `<cloud-backup>` và `<device-transfer>` loại trừ mọi miền (`root`, `file`, `database`, `sharedpref`, `external`). Cần thư mục `android/` (việc tiếp theo, mục 1).
- iOS (khi có Mac): đặt `isExcludedFromBackup` cho tệp CSDL; flutter_secure_storage dùng `KeychainAccessibility.first_unlock_this_device` (không đồng bộ iCloud Keychain).

## Nguồn

- drift, mã hóa: <https://drift.simonbinder.eu/platforms/encryption/>
- sqlite3, hook chọn bản SQLite: <https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html>
- SQLite3MultipleCiphers, `PRAGMA cipher`, `hexkey`: <https://utelle.github.io/SQLite3MultipleCiphers/docs/configuration/config_sql_pragmas/>
- Android Auto Backup: <https://developer.android.com/identity/data/autobackup>
- flutter_secure_storage: <https://pub.dev/documentation/flutter_secure_storage/latest/>

## Tiêu chí đạt

Mỗi dòng là một test (`app/test/data/`), chạy bằng `flutter test` trên máy phát triển và trong CI.

- [ ] `PRAGMA cipher` trả về giá trị khác rỗng trong bản SQLite mà test dùng (chứng minh hook `sqlite3mc` có hiệu lực).
- [ ] 16 byte đầu tệp CSDL **không** phải `SQLite format 3\0`, và không đọc được tên bảng hay chuỗi đã ghi (vd. nhãn món) trong nội dung thô của tệp.
- [ ] Mở lại cùng tệp với khóa khác → `DatabaseOpenError(wrongKeyOrCorrupt)`; có tệp mà không có khóa → `keyMissing`; cả hai trường hợp tệp vẫn còn nguyên.
- [ ] Khóa sinh một lần: dài 64 ký tự hex, lần mở thứ hai dùng lại đúng khóa đó.
- [ ] Hồ sơ, cờ ẩn calo, món ăn (đủ các chất, `source`, `mealId`), buổi tập: ghi, đóng CSDL, mở lại, đọc ra **bằng hệt** (test hợp đồng chạy với cả bản drift và bản trong bộ nhớ).
- [ ] Xóa một món thì các dòng `intake_nutrients` của nó cũng mất.
- [ ] Đơn vị trong CSDL khác gói → `UnitMismatch`; khóa chất lạ → `UnknownNutrient`.
- [ ] Mỗi bảng trong lược đồ phiên bản 1 tồn tại, khóa ngoại được bật (`PRAGMA foreign_keys` = 1).
- [ ] `AppState` dùng `DriftJournalRepository`: thêm món, mở lại app, `report()` cho cùng kết quả UL và calo như trước khi đóng.
- [ ] 30 ngày × 20 món × 15 chất: đọc khoảng 7 ngày dưới 200 ms trên máy phát triển (in số đo; trong CI chỉ chặn ở mức 2 s để tránh dao động).
- [ ] `AndroidManifest.xml` có `allowBackup="false"` và `dataExtractionRules` loại trừ đủ các miền (test đọc tệp, chạy sau khi có thư mục `android/`).

## Ngoài phạm vi

- Sao lưu, khôi phục, xuất tệp (MVP mục 7).
- Khóa app bằng sinh trắc học (tùy chọn, sau).
- Đổi khóa (`PRAGMA rekey`), chuyển từ CSDL chưa mã hóa: chưa có dữ liệu cũ nên không cần.
- Giao diện cho nước, sản phẩm, kho, lịch uống (bước 4–6); lần này chỉ tạo bảng.
- Nhiều hồ sơ người lớn (giai đoạn 2).

## Câu hỏi mở cho chủ dự án

- **Tuổi:** hồ sơ đang lưu số tuổi, sang năm sẽ sai. Đề xuất lưu **năm sinh** (hoặc tháng/năm) và tính tuổi khi dùng; cần đổi màn hồ sơ. Chưa đổi khi chưa được duyệt.
