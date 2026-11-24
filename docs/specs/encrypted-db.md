# Đặc tả: CSDL mã hóa trên máy

Trạng thái: Nháp  <!-- Nháp | Đã duyệt -->
Thiết kế UX: không có màn riêng (hạ tầng). Các màn dùng dữ liệu theo [design/mvp-overview.md](../design/mvp-overview.md); trạng thái lỗi CSDL ở mục Trạng thái, dòng "Toàn app".
Thứ tự MVP: việc 1 trong [status.md](../status.md)

## Mục tiêu

Lưu mọi dữ liệu người dùng trên máy trong một CSDL mã hóa, thay `InMemoryJournalRepository`, để dữ liệu còn sau khi tắt app và làm nền cho kho, lịch uống, sao lưu. Lược đồ v1 đủ cho thiết kế đã duyệt để khỏi phải di chuyển lược đồ sớm.

## Người dùng và tình huống

- Người dùng không thấy CSDL. Họ chỉ thấy dữ liệu còn nguyên khi mở lại app, và thấy màn lỗi khi không mở được.
- Android trước (MVP); iOS dùng cùng thiết kế, khác cách giữ khóa.

## Ràng buộc

- Quy tắc trong AGENTS.md: dữ liệu chỉ ở máy, không máy chủ, không SDK phân tích hay báo lỗi.
- **Chưa đồng ý thì không ghi gì xuống đĩa** (thiết kế, luồng Lần đầu): câu trả lời màn Điều kiện chỉ ở bộ nhớ; CSDL và khóa chỉ được tạo sau khi đồng ý.
- **Khóa chỉ dùng được khi máy đã mở khóa** (chốt 24/11/2026). Nút "Đã uống" trên thông báo mở app, không ghi trong nền. **Mã chạy nền (nhắc giờ, khởi động máy, cập nhật app) không đọc khóa, không mở CSDL.**
- **Không bao giờ ghi đè hay tự xóa khóa đang có**, trừ khi người dùng xóa toàn bộ dữ liệu hoặc không còn tệp CSDL nào (xem Lỗi và biên).
- **Loại khỏi sao lưu tự động của hệ điều hành** và chuyển dữ liệu giữa máy; sao lưu chỉ qua tính năng Sao lưu của app.
- Chỉ lưu câu trả lời Có/Không về thuốc, bệnh; không lưu tên bệnh, tên thuốc.
- **Ngoài CSDL chỉ có dữ liệu không liên quan sức khỏe:** giao diện Theo máy / Sáng / Tối (màn Chào mừng và màn lỗi cần trước khi mở CSDL), dấu "đang xóa", dấu "cần xóa bản trên Drive", nội dung lưu kèm lịch nhắc (chỉ mã lần uống).
- **Không ghi dữ liệu người dùng ra log:** `logStatements` của drift chỉ bật trong test với dữ liệu giả; bản phát hành không `print` hay log câu SQL, giá trị, khóa.

## Nguồn

Đặc tả này không thêm con số hay quy tắc dinh dưỡng. Tài liệu kỹ thuật (kiểm lại phiên bản khi làm):

- drift, mã hóa: <https://drift.simonbinder.eu/platforms/encryption/>
- SQLite3MultipleCiphers, cipher ChaCha20-Poly1305: <https://utelle.github.io/SQLite3MultipleCiphers/docs/ciphers/cipher_chacha20/>
- SQLite3MultipleCiphers, PRAGMA (thứ tự, khóa thô) và hàm SQL: <https://utelle.github.io/SQLite3MultipleCiphers/docs/configuration/config_sql_pragmas/>, <https://utelle.github.io/SQLite3MultipleCiphers/docs/configuration/config_sql_functions/>
- Android, loại khỏi sao lưu: <https://developer.android.com/identity/data/autobackup>
- Android Keystore, `setUnlockedDeviceRequired` (API 28+): <https://developer.android.com/reference/android/security/keystore/KeyGenParameterSpec.Builder#setUnlockedDeviceRequired(boolean)>
- iOS Keychain, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: <https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly>

## Thiết kế kỹ thuật

### Mã hóa

- Bản SQLite liên kết vào app là SQLite3MultipleCiphers (không kéo theo `sqlite3_flutter_libs` hay bản SQLite thường; CI kiểm cây phụ thuộc).
- **Cipher chốt trong mã, không dùng mặc định của thư viện:** `chacha20` (ChaCha20-Poly1305, có mã xác thực mỗi trang), `legacy = 0`. Đổi cipher hay tham số về sau phải qua di chuyển (rekey) có test.
- **Nạp khóa dạng khóa thô**, không qua bước dẫn xuất từ mật khẩu: `PRAGMA key = "raw:<64 ký tự hex>"`. Khóa đổi sang hex ngay trong bộ nhớ, không qua chuỗi UTF-8.
- **Không để khóa lọt vào thông báo lỗi:** `SqliteException` của gói sqlite3 chứa câu SQL gây lỗi, nên câu `PRAGMA key` lọt vào báo cáo crash (Play Console) nếu lỗi không được bắt. Bắt mọi lỗi quanh `PRAGMA key` và ném lại `DbOpenException(stage: key)` không chứa câu lệnh hay thông báo gốc. Chuỗi hex của khóa chỉ sống trong hàm mở CSDL.
- **Thứ tự khi mở** (thư viện yêu cầu cipher và tham số trước khóa): `PRAGMA cipher = 'chacha20'` → `PRAGMA legacy = 0` → `PRAGMA key = …` → kiểm bản mã hóa → `PRAGMA journal_mode = WAL` → `PRAGMA foreign_keys = ON` → `PRAGMA temp_store = MEMORY` (để sắp xếp, chỉ mục tạm không ghi tệp tạm ra đĩa).
- **Kiểm bản mã hóa mỗi lần mở, trước mọi lần ghi:**
  - `SELECT sqlite3mc_config('cipher')` phải trả về `chacha20`. Hàm không tồn tại (bản SQLite thường) hoặc trả giá trị khác: đóng, không ghi gì, màn "Không mở được" (lỗi cài đặt, không có [Bắt đầu lại]).
  - `SELECT count(*) FROM sqlite_master` để biết khóa đúng (PRAGMA key luôn trả "ok" kể cả khi sai khóa).
  - Lần tạo CSDL: sau khi tạo bảng (chưa có dữ liệu người dùng), chạy `PRAGMA wal_checkpoint(TRUNCATE)` để dữ liệu ra tệp chính, rồi kiểm tệp `wholewell.db` dài ít nhất một trang (đọc `PRAGMA page_size`, không viết cứng) và 16 byte đầu không phải `SQLite format 3\0`. Không đạt thì xóa tệp và dừng như trên. Chỉ sau đó mới ghi đồng ý và hồ sơ.

### Khóa

- Khóa CSDL: 32 byte ngẫu nhiên từ `Random.secure()`, tạo một lần ở bước Đồng ý.
- Giữ khóa qua interface `SecureKeyStore` (có bản giả để test):
  - Android: khóa CSDL được mã hóa bằng một khóa AES trong Android Keystore tạo với `setUnlockedDeviceRequired(true)`; bản đã mã hóa lưu trong vùng riêng của app. flutter_secure_storage không có tùy chọn này nên viết phần native nhỏ.
  - iOS: Keychain với `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (không đồng bộ iCloud Keychain).
- **`readDbKey()` trả bốn trạng thái phân biệt**, không gộp lỗi vào "không có khóa":
  - `KeyPresent(key)`.
  - `KeyAbsent`: không có bản khóa đã mã hóa (Android) hoặc Keychain trả `errSecItemNotFound` (iOS).
  - `KeyLost`: **chỉ hai trường hợp** trên Android: có bản khóa đã mã hóa nhưng alias Keystore không còn, hoặc gặp `KeyPermanentlyInvalidatedException`. iOS không có trường hợp này.
  - `KeyUnavailable`: **mọi lỗi khác** (máy đang khóa, lỗi Keystore riêng của hãng, iOS `errSecInteractionNotAllowed`…). Chờ mở khóa rồi đọc lại.
- **Lối thoát khi `KeyUnavailable` kéo dài:** máy đã mở khóa (Android `KeyguardManager.isDeviceLocked() == false`, iOS `isProtectedDataAvailable`) mà vẫn lỗi sau 3 lần thử thì hiện "Chưa đọc được khóa dữ liệu trên máy này." + [Thử lại] [Khôi phục từ bản sao lưu]. Không có [Bắt đầu lại] ở màn này.
- `createDbKey()` chỉ gọi ở bước Đồng ý; nếu đã có khóa thì báo lỗi, không ghi đè.
- Khóa không bao giờ ghi ra log, tệp xuất hay bản sao lưu. Bản sao lưu của app dùng khóa riêng do người dùng giữ (đặc tả Sao lưu).

### Vị trí tệp và loại khỏi sao lưu

- Tệp `wholewell.db` (kèm `-wal`, `-shm`) trong thư mục dữ liệu riêng của app; iOS: Application Support (không dùng Documents).
- Android: `android:allowBackup="false"`, thêm `dataExtractionRules` (Android 12+) loại mọi dữ liệu khỏi sao lưu đám mây và chuyển máy. `minSdk = 28` (câu hỏi 1).
- iOS: đặt `isExcludedFromBackup` cho thư mục chứa CSDL.

### Lược đồ v1

- Thời điểm lưu dạng UTC kèm độ lệch múi giờ lúc ghi; cột `day` (YYYY-MM-DD theo giờ địa phương lúc uống, ăn) để truy vấn theo ngày, có chỉ mục.
- Lượng chất theo đơn vị chuẩn của gói dữ liệu.
- Khóa ngoại bật; xóa sản phẩm chỉ là lưu trữ (`archived`), không xóa dòng.

| Bảng | Trường chính | Ghi chú |
|---|---|---|
| `meta` | schema_version, created_at, onboarding_step (`body_profile`, `calorie_display`, `done`) | Mở lại sau khi đồng ý thì vào đúng bước đang dở |
| `consents` | id, kind (`health_data`, `notifications`, `drive`), content_version, granted_at, withdrawn_at | Bằng chứng đồng ý |
| `profile` | age_years, age_entered_on, caution (Có/Không), caution_answered_on; sex, height_cm, weight_kg, activity_level (được trống); updated_at | Một dòng. Bốn trường sau trống tới khi xong Hồ sơ cơ thể. Không có trường thai kỳ (giai đoạn 2 thêm bằng di chuyển lược đồ) |
| `settings` | hide_calories (được trống: chưa chọn), show_tip_card, wake, breakfast, lunch, dinner, sleep (phút từ 00:00), day_times_confirmed | Một dòng; giờ mặc định 06:00, 07:00, 12:00, 19:00, 22:30. Giao diện sáng/tối ở ngoài CSDL |
| `products` | id, name, count_unit (mã: `tablet`, `capsule`, `sachet`, `ml`, `g`…; chữ "viên", "gói" chỉ để hiện), units_per_serving (>0), created_at, archived | "1 khẩu phần = 2 viên": count_unit `tablet`, units_per_serving 2 |
| `ingredients` | id, product_id, nutrient_id hoặc free_name, form hoặc `unknown`, amount_per_serving, unit, label_amount, label_unit, is_compound, origin (`manual`, `barcode`, `ocr`), confirmed | Mỗi dòng một chất, một dạng. Ràng buộc: có nutrient_id hoặc free_name |
| `boxes` | id, product_id, remaining (≥0, theo count_unit), expiry_month (YYYY-MM), added_at | Số còn không âm (ràng buộc CHECK) |
| `schedules` | id, product_id, time_of_day (phút), servings, valid_from, valid_to (ngày, `valid_to` trống = đang dùng; khoảng [from, to)) | Sửa lịch: đóng dòng cũ, mở dòng mới (câu hỏi 3). Lịch của một ngày = các dòng có hiệu lực ngày đó |
| `dose_occurrences` | schedule_id, day, status (`taken`, `skipped`), dose_entry_id (trống khi `skipped`), updated_at | Khóa chính (schedule_id, day). Không có dòng = "Chưa đánh dấu". Bỏ đánh dấu = xóa dòng |
| `dose_entries` | id, at, tz_offset, day, product_id (trống khi Ghi một lần), name (trống được; ô "Tên (không bắt buộc)" của Ghi một lần), kind (`scheduled`, `extra`, `one_off`), servings, pack_version | Lần theo lịch gắn qua `dose_occurrences.dose_entry_id` (duy nhất) |
| `dose_box_deductions` | dose_entry_id, box_id, amount (>0, theo count_unit) | Một lần uống trừ 0, 1 hay nhiều hộp. Không có dòng = không trừ ([Không trừ] hoặc kho hết). Hoàn tác, xóa: cộng lại đúng các dòng này |
| `food_entries` | id, at, tz_offset, day, meal (`breakfast`, `lunch`, `dinner`, `snack`), name, food_ref (`usda:<id>`, `recipe:<id>`, `custom:<id>`, trống khi nhập theo nhãn không lưu), portion_unit, portion_qty, label_basis_qty, label_basis_unit (số trên nhãn tính cho bao nhiêu, vd. 100 ml; chỉ món theo nhãn), added_sugar_known, pack_version | Sửa mục đổi được [−] {n} [+]. `added_sugar_known = false`: "chưa rõ đường bổ sung", khác 0 g |
| `custom_foods` | id, name, portion_unit, label_basis_qty, label_basis_unit, created_at, archived | Món "Nhập theo nhãn" có "Lưu để dùng lại" |
| `custom_food_lines` | custom_food_id, nutrient_id, form, label_amount, label_unit, source (`food`, `fortified`) | Số trên nhãn của món tự lưu, tính cho label_basis |
| `intake_lines` | id, food_entry_id, dose_entry_id, day, nutrient_id hoặc free_name, source (`food`, `fortified`, `supplement`), form, uncertain, label_amount, label_unit, amounts (JSON), ul_amounts (JSON, trống được) | Lượng đã ghi của mỗi lần (mục dưới). Hai cột lần ghi có khóa ngoại `ON DELETE CASCADE`, CHECK đúng một cột có giá trị. `day` lặp từ lần ghi để truy vấn nhanh; sửa giờ, ngày của lần ghi thì cập nhật cùng giao dịch. Chỉ mục (day), (food_entry_id), (dose_entry_id) |
| `water_entries` | id, at, tz_offset, day, ml | |
| `workout_entries` | id, start_at, tz_offset, day, activity_code, minutes | |
| `ui_state` | key, value | Trong CSDL. Thẻ cảnh báo đã thu gọn, lưu ý lịch đã thu gọn, ngày ẩn thẻ "Bạn có biết" |

**Lượng đã ghi (`intake_lines`):**

- Mỗi lần ghi lưu một danh sách dòng, mỗi dòng một chất trên nhãn hoặc trong USDA, một nguồn, một dạng. Một món tăng cường có cả dòng `food` và dòng `fortified` cho cùng chất. Đạm, béo, bột đường, năng lượng, đường bổ sung cũng là dòng (nguồn `food`).
- `label_amount`, `label_unit`: số gốc trên nhãn cho một khẩu phần (bổ sung) hoặc cho `label_basis` (món theo nhãn); trống với số từ USDA.
- `amounts`: lượng theo **khóa của engine** (`IntakeItem.nutrients`), đã đổi đơn vị theo gói đang cài và đã nhân số khẩu phần. Một dòng có thể sinh nhiều khóa.
- `ul_amounts`: chỉ có khi lượng tính giới hạn khác lượng so mức khuyến nghị (vitamin E tổng hợp, dạng chưa rõ); chỉ chứa các khóa khác `amounts`. `ul_amounts` chỉ xét **dạng**; **phạm vi** (vd. magie từ thức ăn không tính) vẫn do `source` quyết định như engine hiện nay (`amountForUl`).
- `uncertain`: dòng "chưa chắc" (dạng chưa rõ, hoặc đổi đơn vị theo cách thận trọng).

**Nguyên tắc cho dạng chưa rõ** (câu hỏi 4): khi nhãn không đủ để biết dạng hay cách ghi, `amounts` lấy **số nhỏ nhất** có thể (không làm "đủ" giả), `ul_amounts` lấy **số lớn nhất** có thể (plan: tính giới hạn theo cách thận trọng nhất), dòng ghi `uncertain`. Phía giới hạn theo plan; phía mức khuyến nghị là **quy tắc của app**, không phải chuẩn.

**Quy tắc đổi một dòng thành khóa engine.** Hệ số lấy từ gói dữ liệu, không viết cứng trong app. Ký hiệu cho vitamin E (mg alpha-tocopherol mỗi IU): `e_rda(dạng)` để so mức khuyến nghị, `e_ul(dạng)` để tính giới hạn.

| Dòng trên nhãn | `amounts` | `ul_amounts` |
|---|---|---|
| Axit folic 400 µg (bổ sung, tăng cường) | `folate` 680 (µg DFE, ×1,7), `folicAcid` 400 | – |
| Folate ghi µg DFE kèm "(x µg axit folic)" | `folate` = số DFE, `folicAcid` = x | – |
| Folate chỉ ghi µg DFE, không rõ dạng | `folate` = số DFE, `folicAcid` = DFE ÷ 1,7 (coi toàn bộ là axit folic); `uncertain` | – |
| Vitamin A dạng retinol | `vitA` = µg RAE, `retinol` = µg RAE | – |
| Vitamin A dạng beta-caroten | `vitA` = µg RAE; không có `retinol` | – |
| Vitamin A ghi µg RAE, không rõ dạng | `vitA` = µg RAE, `retinol` = toàn bộ; `uncertain` | – |
| Vitamin A ghi IU, không rõ dạng, thực phẩm bổ sung | `vitA` = IU × 0,3, `retinol` = IU × 0,3 (retinol và beta-caroten bổ sung cùng hệ số); `uncertain` | – |
| Vitamin A ghi IU, không rõ dạng, món theo nhãn | `vitA` = IU × hệ số beta-caroten trong thức ăn (nhỏ nhất); `uncertain` | `retinol` = IU × hệ số retinol |
| Vitamin E ghi IU, biết dạng | `vitE` = IU × `e_rda(dạng)` | `vitE` = IU × `e_ul(dạng)` khi khác `amounts` (dạng tổng hợp) |
| Vitamin E ghi IU, không rõ dạng | `vitE` = IU × `e_rda(tổng hợp)` (nhỏ nhất); `uncertain` | `vitE` = IU × `e_ul(tổng hợp)` (lớn nhất) |
| Vitamin E ghi "mg alpha-tocopherol" (nhãn FDA mới, đã quy về dạng 2R), biết dạng | `vitE` = mg | `vitE` = mg ÷ `e_rda(dạng)` × `e_ul(dạng)` khi khác `amounts` |
| Vitamin E ghi mg khối lượng dạng tổng hợp (vd. "mg dl-alpha-tocopherol") | `vitE` = mg ÷ `e_ul(tổng hợp)` × `e_rda(tổng hợp)` | `vitE` = mg |
| Vitamin E ghi mg khối lượng este (vd. "dl-alpha tocopheryl acetate 30 mg", succinat) | đổi khối lượng este ra khối lượng tocopherol theo tỷ lệ của este trong gói (như hợp chất), rồi theo hàng trên đúng dạng d- hoặc dl- | `vitE` = khối lượng tocopherol đã đổi theo hàng trên |
| Vitamin E ghi mg, không rõ dạng hay cách ghi (vd. chỉ "Vitamin E 15 mg") | số nhỏ nhất trong ba cách hiểu: mg 2R dạng tự nhiên, mg 2R dạng tổng hợp, mg khối lượng dạng tổng hợp (không xét este); `uncertain` | số lớn nhất trong ba cách hiểu đó |
| Hợp chất, biết tên (vd. canxi carbonat) | khóa chất = khối lượng × tỷ lệ nguyên tố (ODS) | – |
| Không rõ là hợp chất hay nguyên tố | khóa chất = số trên nhãn × tỷ lệ nguyên tố nhỏ nhất trong các hợp chất của chất đó có trong gói; `uncertain` | khóa chất = số trên nhãn (coi là nguyên tố) |
| Chất khác | khóa chất = lượng đã đổi đơn vị | – |
| Chất không có trong gói | không có khóa (lưu để xem, không tính) | – |

- **Vitamin E: hai phía dùng hệ số khác nhau** (đối chiếu NIH ODS, fact sheet vitamin E cho chuyên gia, tra 24/11/2026): mức khuyến nghị chỉ tính dạng 2R, 1 IU tự nhiên = 0,67 mg, 1 IU tổng hợp = 0,45 mg (gói đã có). Giới hạn áp cho mọi dạng alpha-tocopherol bổ sung, gồm cả 8 đồng phân của dạng tổng hợp; 1.000 mg tương đương 1.500 IU tự nhiên hoặc 1.100 IU tổng hợp, tức `e_ul` ≈ 0,67 (tự nhiên) và ≈ 0,91 (tổng hợp). Gói và engine hiện dùng 0,45 cho cả hai phía nên **lượng tính giới hạn của vitamin E tổng hợp đang thiếu khoảng một nửa**: lỗi có sẵn, sửa ở việc 2 (thêm `e_ul` vào `build_pack.py` sau khi đối chiếu báo cáo DRI gốc, kèm ô đối chiếu).
- **Cách hiểu este chỉ dùng khi nhãn ghi tên este.** Nhãn chỉ ghi "Vitamin E {x} mg" thì đó là lượng vitamin E (nhãn FDA khai vitamin E theo mg alpha-tocopherol), nên không xét khối lượng este.
- Tỷ lệ tocopherol của este vitamin E (acetat, succinat) chưa có trong gói: thêm cùng tỷ lệ nguyên tố của hợp chất ở việc 5 (chụp nhãn), kèm nguồn và ô đối chiếu. Trước đó, dòng este hiện "chưa tính được" phía mức khuyến nghị (không có `vitE` trong `amounts`), còn phía giới hạn coi khối lượng este là khối lượng tocopherol (`ul_amounts.vitE` = mg, lớn hơn thật nên vẫn thận trọng).
- Hệ số beta-caroten trong thức ăn (IU → µg RAE) chưa có trong gói: thêm ở việc 3 (Thư viện món) kèm nguồn và ô đối chiếu. Trước đó, dòng này chỉ có `ul_amounts.retinol`; `amounts` không có `vitA` và dòng hiện "chưa tính được" phía mức khuyến nghị (không đoán số).

- **Đổi sang `IntakeItem`:** gộp các dòng của một lần ghi theo `source` thành một `IntakeItem` cho mỗi nguồn (`nutrients` = cộng `amounts`; lượng tính giới hạn = cộng `ul_amounts`, khóa nào không có thì lấy từ `amounts`). Engine chỉ đọc các bản này; đổi thành phần sản phẩm hay gói dữ liệu sau khi ghi không đổi lịch sử.
- **Phụ thuộc việc 2 (sửa engine):** engine hiện chưa có lượng tính giới hạn riêng (vitamin E tổng hợp và dạng chưa rõ cần hai số cho cùng một khóa) và chưa có hệ số `e_ul`. Việc 2 thêm vào `IntakeItem` một bảng lượng tính giới hạn tùy chọn, `amountForUl` dùng bảng này khi có; sửa cả `tools/reference_engine.py` và fixtures. CSDL lưu đủ dữ liệu ngay từ v1, không cần di chuyển khi việc 2 xong.
- **Điều kiện cứng: việc 2 xong trước mọi đường ghi có thể sinh `ul_amounts`**: Nhập theo nhãn, Ghi một lần, chụp nhãn, mã vạch, thành phần sản phẩm (hợp chất không rõ, vitamin A ghi IU, vitamin E, este). Nếu engine chưa đọc `ul_amounts` mà dòng đã có, phần đó bị bỏ qua và tính thiếu vào giới hạn (trái tiêu chí "0 vi phạm UL").
- **Chặn bỏ qua lặng lẽ:** cho tới khi việc 2 xong, hàm đổi dòng sang `IntakeItem` gặp `ul_amounts` không rỗng thì ném lỗi, và lệnh ghi một dòng như vậy bị từ chối. Việc 2 thay bằng đọc thật và đổi test tương ứng.
- **Sửa khẩu phần:** món theo nhãn tính lại từ `label_amount` × `portion_qty` ÷ `label_basis_qty` (cùng đơn vị; vd. nhãn cho 100 ml, đổi 180 ml thành 250 ml). Món USDA, công thức: tính lại theo gói đang cài và cập nhật `pack_version`. Lần uống: tính lại từ số trên nhãn × số khẩu phần theo gói đang cài và cập nhật `pack_version`.
- **Giữ cả dữ liệu gốc** (`food_ref`, khẩu phần, số lượng, gốc nhãn ở `food_entries`; số trên nhãn và dạng ở `intake_lines`) và `pack_version` để sau này tính lại có chủ đích khi gói sửa lỗi, vd. một hệ số đổi đơn vị sai (câu hỏi 2). Tính lại là việc của một đặc tả sau, có test, không tự chạy.

**Di chuyển lược đồ:** drift (`schemaVersion`, lưu bản lược đồ mỗi phiên bản, test di chuyển từ mọi bản cũ). Trước khi di chuyển: `PRAGMA wal_checkpoint(TRUNCATE)`, đóng kết nối, **sao chép tệp nguyên byte** thành `wholewell.db.pre-v{n}` (giữ nguyên mã hóa; không dùng `VACUUM INTO` hay API sao lưu của SQLite khi chưa kiểm bản tạo ra vẫn được mã hóa), rồi mở lại; di chuyển trong một giao dịch; xong và `PRAGMA integrity_check` đạt thì xóa bản sao (`integrity_check` chậm với CSDL lớn nhưng chỉ chạy lúc di chuyển).

### Interface

- `SecureKeyStore`: `Future<KeyReadResult> readDbKey()` (bốn trạng thái ở trên), `Future<Uint8List> createDbKey()` (lỗi nếu đã có), `Future<void> deleteDbKey()`, `Future<bool> isDeviceUnlocked()`.
- `JournalRepository` đổi sang bất đồng bộ (`Future`, `Stream` theo ngày) và mở rộng theo lược đồ trên; `DriftJournalRepository` thay `InMemoryJournalRepository`. Bản bộ nhớ giữ lại để test giao diện.
- Engine (`packages/health_engine`) không sửa trong việc này: app đọc các lần ghi, đổi thành `IntakeItem`, `WorkoutEntry` theo quy tắc ở trên rồi gọi engine. Lượng tính giới hạn riêng (`ul_amounts`) chỉ dùng được khi việc 2 xong; xem điều kiện cứng ở mục Lượng đã ghi.

### Luồng xử lý

1. **Lần đầu:** Điều kiện → Đồng ý. Bấm "Đồng ý và tiếp tục": `createDbKey()` → tạo CSDL, bảng → kiểm bản mã hóa → một giao dịch ghi `consents`, `profile` (tuổi, câu Có/Không), `meta.onboarding_step = body_profile`. Mỗi bước sau ghi tiếp và cập nhật bước.
2. **Mở app** (chỉ khi giao diện đã hiện, máy đã mở khóa):
   1. Có dấu "đang xóa" → làm tiếp luồng 4 → Chào mừng.
   2. `readDbKey()`, xét cùng việc có tệp hay không:

      | Khóa | Có tệp | Không có tệp |
      |---|---|---|
      | `KeyPresent` | Mở (bước 3) | Xóa khóa còn sót → Chào mừng |
      | `KeyAbsent` | Màn "Không mở được" | Chào mừng (lần đầu) |
      | `KeyUnavailable` | Màn chờ mở khóa, đọc lại khi app trở lại | Như bên trái |
      | `KeyLost` | Màn "Không mở được" | Xóa khóa còn sót → Chào mừng |

   3. Có bản `.pre-v{n}` còn sót (lần di chuyển trước lỗi hoặc bị ngắt, chưa có lần ghi nào sau đó): bỏ tệp hiện tại cùng `-wal`, `-shm`, khôi phục bản sao.
   4. Mở theo thứ tự ở mục Mã hóa → kiểm `schema_version`:
      - Bằng bản app biết: tải ngày đang xem.
      - Nhỏ hơn: di chuyển.
      - Lớn hơn (cài bản cũ hơn): màn "Cần cập nhật", không mở tiếp, không ghi.
3. **Ghi, sửa, xóa:** mỗi thao tác một giao dịch. Vd. "Đã uống" thêm `dose_entries`, `intake_lines`, `dose_occurrences`, `dose_box_deductions` và trừ `boxes` cùng giao dịch; xóa lần uống cộng lại kho theo `dose_box_deductions`, xóa `dose_occurrences`, còn `intake_lines` tự xóa theo khóa ngoại, cùng giao dịch. Sửa giờ hoặc ngày thì cập nhật `day` của các dòng `intake_lines` cùng giao dịch.
4. **Rút đồng ý, xóa toàn bộ:** ghi dấu "đang xóa" (ngoài CSDL) → đóng CSDL → **xóa khóa trước** (dữ liệu không đọc được ngay) → xóa tệp (`.db`, `-wal`, `-shm`, `.pre-v*`; `ui_state` nằm trong tệp) → xóa cài đặt giao diện ngoài CSDL → xóa dấu "đang xóa" → Chào mừng. App chết giữa chừng thì lần mở sau làm tiếp từ dấu. Bản trên Drive theo thiết kế (mục Quyền riêng tư).

### Lỗi và biên

| Tình huống | Xử lý |
|---|---|
| Có tệp, khóa `KeyAbsent` hoặc `KeyLost` (cài lại app có giữ dữ liệu, khóa Keystore bị xóa) | Màn "Không mở được dữ liệu đã lưu trên máy." + [Khôi phục từ bản sao lưu] [Bắt đầu lại] (gõ XÓA) |
| Khóa sai, tệp hỏng (`sqlite_master` lỗi, mã xác thực trang sai) | Như trên |
| `KeyUnavailable` (máy đang khóa, lỗi tạm) | "Mở khóa máy để xem dữ liệu." Đọc lại khi app trở lại hoặc máy mở khóa. **Không** dẫn tới màn có [Bắt đầu lại] |
| `KeyUnavailable` khi máy đã mở khóa, sau 3 lần thử | "Chưa đọc được khóa dữ liệu trên máy này." + [Thử lại] [Khôi phục từ bản sao lưu]; không có [Bắt đầu lại] |
| Lỗi khi nạp khóa (`PRAGMA key`) | `DbOpenException(stage: key)` không chứa câu lệnh; xử lý như "Khóa sai, tệp hỏng" |
| Bản SQLite không mã hóa, cipher sai | Không mở, không ghi; "Không mở được dữ liệu đã lưu trên máy. Hãy cài lại WholeWell từ cửa hàng ứng dụng." Không có [Bắt đầu lại] |
| Di chuyển lược đồ lỗi | Giao dịch hoàn tác, giữ nguyên tệp và bản `.pre-v{n}`; màn "Cần cập nhật". Không có [Bắt đầu lại]; lỗi giữ trong máy, không gửi đi. Bản app sửa lỗi sau đó di chuyển lại được |
| `schema_version` lớn hơn bản app biết | Màn "Cần cập nhật", không mở tiếp, không ghi |
| Hết dung lượng | "Chưa lưu được. Thử lại"; giao dịch hoàn tác, không mất dữ liệu cũ. Không đủ chỗ để sao trước khi di chuyển: không di chuyển, "Máy không còn đủ dung lượng. Hãy giải phóng bộ nhớ rồi mở lại." |
| Có khóa nhưng không có tệp | Xóa khóa còn sót → Chào mừng; không tạo CSDL mới (CSDL mới không có dòng đồng ý) |
| Tiến trình app được dựng lại khi máy đang khóa (báo thức, khởi động máy, cập nhật app) | Mã chạy nền không đọc khóa, không mở CSDL; lịch nhắc dùng dữ liệu riêng của thư viện nhắc giờ (chỉ mã lần uống) |

Màn "Cần cập nhật": "Cần cập nhật WholeWell. Dữ liệu của bạn vẫn còn nguyên trên máy. Hãy cập nhật app từ cửa hàng ứng dụng." Chữ này, "Mở khóa máy để xem dữ liệu." và "Chưa đọc được khóa dữ liệu trên máy này." thêm vào thiết kế tổng thể (dòng "Toàn app"); **thiết kế đó đang Đã duyệt nên chủ dự án cần đồng ý rõ thay đổi này** (câu hỏi 5).

## Tiêu chí đạt

**Khóa và mã hóa:**

- [ ] Trước khi bấm "Đồng ý và tiếp tục", thư mục dữ liệu của app không có tệp CSDL và chưa có khóa.
- [ ] 16 byte đầu tệp `wholewell.db` không phải `SQLite format 3`; mở bằng sqlite3 thường không đọc được bảng nào.
- [ ] Bản SQLite không có SQLite3MultipleCiphers (bản giả trong test) hoặc cipher khác `chacha20`: app từ chối mở, không tạo hay ghi tệp.
- [ ] Mở với khóa sai thì lỗi, không tạo dữ liệu mới, không ghi đè tệp.
- [ ] `readDbKey()` trả `KeyUnavailable`: không tạo khóa mới, không xóa gì, không hiện [Bắt đầu lại]; trả `KeyPresent` ở lần sau thì mở bình thường.
- [ ] `createDbKey()` khi đã có khóa thì lỗi, khóa cũ giữ nguyên.
- [ ] Phân loại khóa (bản giả của nền tảng): không có bản khóa → `KeyAbsent`; alias mất hoặc `KeyPermanentlyInvalidatedException` → `KeyLost`; mọi lỗi khác → `KeyUnavailable`.
- [ ] `KeyUnavailable` 3 lần khi máy đã mở khóa: hiện [Thử lại] [Khôi phục từ bản sao lưu], không có [Bắt đầu lại].
- [ ] Cố tình làm `PRAGMA key` lỗi: thông báo và `toString()` của lỗi ném ra không chứa chuỗi hex của khóa hay câu lệnh.
- [ ] Lần tạo CSDL: kiểm đầu tệp chạy sau `wal_checkpoint(TRUNCATE)`; tệp chính dài ít nhất `page_size` byte.
- [ ] Sau khi mở: `journal_mode = wal`, `foreign_keys = 1`, `temp_store = 2` (MEMORY).

**Dữ liệu:**

- [ ] Ghi hồ sơ, món, lần uống, nước, buổi tập; tắt hẳn app rồi mở lại: dữ liệu và báo cáo ngày giống hệt trước khi tắt.
- [ ] Thoát sau bước Đồng ý, mở lại: vào đúng bước đang dở (`onboarding_step`), hồ sơ chưa có giới tính, chiều cao, cân nặng.
- [ ] "Đã uống" 2 khẩu phần khi hộp đầu còn 1: trừ 1 hộp đầu, 1 hộp sau, có hai dòng `dose_box_deductions`; Hoàn tác trả đúng về hai hộp. Lỗi giữa chừng thì không có lần ghi nào và kho không đổi.
- [ ] [Không trừ] hoặc kho hết: lần uống vẫn được ghi và tính vào giới hạn, không có dòng trừ kho.
- [ ] Số còn trong `boxes` không âm (ràng buộc CSDL); trừ theo `units_per_serving` (1 khẩu phần = 2 viên thì trừ 2).
- [ ] [Bỏ qua] lưu `skipped`; bỏ đánh dấu về "Chưa đánh dấu".
- [ ] Đổi lịch 20:00 thành 21:00: ngày trước đó vẫn dùng lịch 20:00 khi ghi bù và khi tính tỷ lệ bỏ liều.
- [ ] Lượng đã ghi: đổi thành phần sản phẩm sau khi ghi không làm đổi tổng của ngày đã ghi.
- [ ] Mỗi hàng trong bảng "Quy tắc đổi một dòng thành khóa engine" có một ca test. Vd. axit folic 400 µg → `folate` 680, `folicAcid` 400; vitamin A µg RAE không rõ dạng → `retinol` bằng toàn bộ; vitamin E 100 IU tổng hợp → `amounts` 45 mg, `ul_amounts` theo `e_ul(tổng hợp)` (≈ 91 mg); vitamin E IU không rõ dạng → như dạng tổng hợp và `uncertain`; "Vitamin E 15 mg" không ghi dạng → `amounts` ≈ 7,4 mg, `ul_amounts` ≈ 30 mg, không xét este; không rõ hợp chất hay nguyên tố → `amounts` theo tỷ lệ nhỏ nhất, `ul_amounts` bằng số trên nhãn.
- [ ] Magie từ thức ăn (`source = food`) không tính vào giới hạn (phạm vi theo `source`).
- [ ] Khi engine chưa hỗ trợ lượng tính giới hạn riêng: đổi một dòng có `ul_amounts` sang `IntakeItem` thì ném lỗi; ghi một dòng như vậy bị từ chối, không bỏ qua lặng lẽ.
- [ ] Xóa một lần ghi thì không còn dòng `intake_lines` nào của nó; dòng có cả hai cột lần ghi hoặc không có cột nào bị CSDL từ chối.
- [ ] Sửa giờ, ngày của một món sang ngày khác: các dòng `intake_lines` có `day` mới, tổng của hai ngày đúng.
- [ ] Món không rõ đường bổ sung được đếm vào "Chưa tính đường bổ sung của {n} món", không tính là 0 g.
- [ ] Sửa món đổi số khẩu phần và tính lại các dòng của món đó: món theo nhãn cho 100 ml đổi 180 ml thành 250 ml thì mọi lượng × 250/180; món USDA tính theo gói đang cài và lưu `pack_version` mới.
- [ ] Ghi một lần có tên thì Nhật ký hiện tên đó.
- [ ] Bảng `profile` không có cột chứa tên bệnh, tên thuốc; câu thuốc, bệnh chỉ là Có/Không.

**Xóa, di chuyển, cấu hình:**

- [ ] Rút đồng ý, xóa toàn bộ: không còn `wholewell.db`, `-wal`, `-shm`, `.pre-v*`, không còn khóa; mở lại app ở màn Chào mừng.
- [ ] Ngắt app sau khi xóa khóa, trước khi xóa tệp: lần mở sau làm tiếp việc xóa, về Chào mừng (không hiện "Không mở được").
- [ ] Có khóa, không có tệp: xóa khóa, về Chào mừng, không có CSDL nào được tạo.
- [ ] Di chuyển lỗi (bản giả): tệp giữ nguyên, có bản `.pre-v{n}`, màn "Cần cập nhật", không có [Bắt đầu lại]. `schema_version` lớn hơn bản app: cũng vậy, tệp không đổi.
- [ ] Test di chuyển lược đồ chạy được từ v1 (khung cho các bản sau).
- [ ] AndroidManifest có `allowBackup="false"` và `dataExtractionRules` loại toàn bộ dữ liệu; `minSdk = 28` (kiểm bằng test tệp cấu hình).
- [ ] Cây phụ thuộc không có `sqlite3_flutter_libs` (CI).
- [ ] Bản phát hành: `logStatements` tắt; không có log chứa câu SQL hay giá trị (test cấu hình).

**Thử máy thật:**

- [ ] Truy vấn một ngày với 2 năm dữ liệu giả lập dưới 50 ms trên máy tầm trung.
- [ ] Android 12+: mở khóa và khóa máy, khởi động lại máy, cài đè bản mới.
- [ ] Máy không đặt khóa màn hình: tạo và đọc khóa được.
- [ ] Đổi mã khóa màn hình, xóa khóa màn hình: ghi lại khóa có còn đọc được không; nếu nền tảng vô hiệu khóa thì app ra `KeyLost` (màn "Không mở được"), không tự tạo khóa mới.
- [ ] Tiến trình app được dựng lại khi máy đang khóa (nhắc giờ, khởi động máy): không đọc khóa, không mở CSDL, không tạo khóa; mở khóa máy rồi mở app thì dữ liệu còn nguyên.

## Ngoài phạm vi

- Sao lưu tệp, Google Drive, khôi phục (đặc tả Sao lưu); xuất dữ liệu đọc được (đặc tả Quyền riêng tư).
- Giao diện kho, lịch uống, nhắc giờ, chụp nhãn (các đặc tả sau; lược đồ đã có bảng).
- Tính lại lượng đã ghi khi gói dữ liệu sửa lỗi (đặc tả sau; lược đồ đã giữ dữ liệu gốc).
- Trường thai kỳ, hồ sơ trẻ em, nhiều hồ sơ trên một máy (giai đoạn 2).
- Sửa engine (việc 2 trong status).
- iOS: chỉ ghi cách giữ khóa và vị trí tệp; làm khi có bản iOS.

## Câu hỏi còn mở

1. **Android tối thiểu API 28 (Android 9)?** `setUnlockedDeviceRequired` cần API 28. Hiện app dùng mặc định của Flutter (thấp hơn). Đề xuất đặt `minSdk = 28`; máy thấp hơn rất ít và không giữ được yêu cầu "khóa chỉ dùng khi máy mở khóa". Chờ chủ dự án chốt.
2. **Lưu sẵn lượng đã ghi, kèm dữ liệu gốc** (đề xuất ở trên) thay vì tính lại từ gói dữ liệu mỗi lần đọc. Lợi: lịch sử không đổi khi gói cập nhật; khi gói sửa lỗi thì vẫn tính lại được có chủ đích từ dữ liệu gốc. Chờ chủ dự án chốt.
3. **Sửa lịch có hiệu lực từ khi nào?** Đề xuất: từ hôm nay nếu hôm nay chưa đánh dấu lần nào của lịch cũ; nếu đã đánh dấu thì từ ngày mai, và màn Lịch báo "Lịch mới áp dụng từ ngày mai." (chữ mới, cần thêm vào thiết kế khi làm tính năng Lịch uống). Lược đồ không đổi theo câu trả lời. Chờ chủ dự án chốt.
4. **Nguyên tắc chung cho mọi dạng chưa rõ:** so mức khuyến nghị lấy số nhỏ nhất có thể, tính giới hạn lấy số lớn nhất có thể, ghi "chưa chắc"? Plan chỉ nói phía giới hạn; phía mức khuyến nghị là quy tắc của app. Áp đều cho vitamin E, vitamin A ghi IU, hợp chất hay nguyên tố, este (bảng quy tắc). **Hệ quả cần biết:** nhãn ở Việt Nam thường chỉ ghi "Vitamin E 15 mg", không ghi dạng. Theo nguyên tắc này, dòng đó tính khoảng 30 mg vào giới hạn (coi là dạng tổng hợp ghi theo 2R: 15 ÷ 0,45 × 0,91) và khoảng 7,4 mg vào mức khuyến nghị (coi là khối lượng dạng tổng hợp: 15 ÷ 0,91 × 0,45), kèm "chưa chắc". Như vậy phần lớn viên đa vitamin sẽ hiện vitamin E thấp hơn mức khuyến nghị và "chưa chắc". Chờ chủ dự án chốt.
5. **Thêm ba chữ vào thiết kế tổng thể đã duyệt** (dòng "Toàn app"): "Mở khóa máy để xem dữ liệu."; "Chưa đọc được khóa dữ liệu trên máy này." + [Thử lại] [Khôi phục từ bản sao lưu]; "Cần cập nhật WholeWell…". Chờ chủ dự án đồng ý.
