# ADR 0015: Làm mới dữ liệu

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 15.

## Quyết định

Stream thay đổi theo bảng: `journal_db` báo tập bảng đã đổi kèm `seq`; `JournalDbService` phát một stream cố định qua mọi kết nối; repository làm mới khi bảng mà truy vấn của nó đọc bị đổi; cache chỉ giữ mục đang có người nghe, mỗi mục nhớ `seq` lúc đọc để bỏ sự kiện cũ; chỉ phát sự kiện khi lần ghi xong (chi tiết ở 3.4)

## Không chọn

`watch()` của drift; làm mới thủ công sau mỗi lần ghi

## Lý do và hệ quả

`watch()` cần khai bảng cho drift, mà `journal_db` cố ý không có bảng nào (`allTables` rỗng, SQL viết tay theo ADR 7). Làm mới thủ công thì repository phải biết nhau, vì một lần ghi như `recordDose` đổi dữ liệu của JournalDay, Supplement và Schedule

## Thực hiện

PR 5a-1 (`journal_db`), 5a-2 (`JournalDbService`), 5a-3 (repository).

## Chi tiết (chép từ refactor-plan.md, mục 3.4, ngày 29/11/2026)

- **Báo thay đổi theo bảng (mức `journal_db`):** `DriftJournalRepository` đã có `Stream<void> changes` (bắn mỗi lần ghi) nhưng app chưa dùng. Nâng thành `Stream<JournalChange> changes`, mỗi sự kiện gồm `seq` và `tables`:
  - `tables`: đúng tập bảng đã đổi trong lần ghi đó, kể cả trong giao dịch, tính cả bảng bị xóa theo `ON DELETE CASCADE`.
  - `seq`: số thứ tự của kết nối, tăng **đồng bộ** trong `_changed()` trước khi phát sự kiện, nên khi hàm ghi trả về thì `lastChangeSeq` đã tăng.
  - `InMemoryJournalRepository` làm giống hệt.
- **Một stream cố định cho app (mức `JournalDbService`):** repository và `DiaryController` chỉ nghe `JournalDbService.changes`, không nghe thẳng kết nối. `seq` và `lastChangeSeq` cũng đọc từ service.
  - Mỗi kết nối là một **thế hệ**, có `base` = `lastChangeSeq` cũ của service cộng 1. Service đổi `seq` của sự kiện thành `base + seq`, và `lastChangeSeq` của service bằng `base` + `lastChangeSeq` của kết nối hiện tại, đọc đồng bộ. Như vậy `seq` tăng liên tục qua mọi kết nối.
  - **Không đánh số lúc nhận sự kiện.** Stream bất đồng bộ, nên sự kiện của chính lần ghi có thể tới sau khi `reload()` đã đọc `lastChangeSeq`. Nếu đánh số lúc nhận, sự kiện đó mang số lớn hơn số đã nhớ và gây reload thừa.
  - Thay kết nối theo thứ tự: hủy đăng ký kết nối cũ, gắn kết nối mới (thế hệ mới), rồi mới phát sự kiện "mọi bảng" mang số `base`. Service bỏ sự kiện tới muộn của thế hệ cũ.
  - Xóa toàn bộ: kết nối là `null` và service phát "mọi bảng". Repository nhận sự kiện này mà kết nối `null` thì coi là không có dữ liệu, không truy vấn.
- **Cache chỉ giữ mục đang có người nghe:** mỗi mục cache (vd. dữ liệu của một ngày ở JournalDay hay Schedule) phát một `Listenable` riêng cho ViewModel hoặc `AppCoordinator` đăng ký. Người nghe cuối cùng rời đi thì bỏ mục khỏi cache.
  - Repository không cần biết ngày nào đang được xem, chỉ cần biết mục nào đang dùng. Ngày đang xem luôn có ViewModel nghe; lịch của hôm nay và hôm qua thật luôn có `AppCoordinator` nghe (nhắc giờ).
  - Cache vì thế có giới hạn tự nhiên. Quay về một ngày vừa rời thì truy vấn lại ngày đó, vẫn nhẹ hơn hiện nay (`setDay()` chạy lại cả 23 truy vấn của `reload()`).
  - Chỗ chỉ đọc một lần mà không nghe thì truy vấn thẳng, không vào cache. Ví dụ: báo cáo của ngày khác khi sửa món sang ngày đó, báo cáo trước và sau khi ghi lần uống (hiện là `_reportForDay` trong `DiaryController`).
- **Bỏ qua sự kiện cũ bằng `seq`, theo từng mục cache, không dùng cờ:**
  - Mỗi mục cache nhớ `JournalDbService.lastChangeSeq` đọc ngay trước khi truy vấn mục đó. Khi có sự kiện, mục nào đọc bảng bị đổi và có `seq` đã nhớ nhỏ hơn `seq` của sự kiện thì làm mới ngay; mọi mục còn trong cache đều đang có người nghe.
  - Không dùng một số chung cho cả repository. Ví dụ JournalDay cache ngày 27 và 28: làm mới ngày 28 rồi bỏ mọi sự kiện có `seq` nhỏ hơn số đã nhớ thì lần ghi vào ngày 27 cũng bị bỏ, cache ngày 27 giữ số cũ. `DiaryController` chỉ có một bộ dữ liệu nên dùng một số.
  - Lần làm mới đã đọc dữ liệu mới nhất nên không sót gì, và lần ghi của chính nó không gây truy vấn hai lần. Cờ đơn giản không dùng được: stream bất đồng bộ nên sự kiện của chính lần ghi có thể tới sau khi đã làm mới.
- **Mỗi mục chỉ một truy vấn tại một thời điểm:** sự kiện tới khi mục đang truy vấn thì chỉ đánh dấu "cần làm lại"; truy vấn xong thì chạy lại đúng một lần. Như vậy kết quả cũ không đè lên kết quả mới. Code hiện tại tránh việc này bằng số thế hệ `_loadGen` ([diary_controller.dart:265](../../app/lib/state/diary_controller.dart#L265), [:321](../../app/lib/state/diary_controller.dart#L321)), nhưng cách đó vẫn chạy hai truy vấn song song rồi bỏ kết quả cũ.
  - Lời gọi làm mới (vd. sau khi ghi) chỉ trả về khi một truy vấn **bắt đầu sau lời gọi** đã xong. Nếu không, `LogFoodUseCase` có thể nhận kết quả của truy vấn đang chạy dở và so cờ vượt giới hạn trên số chưa có món vừa ghi.
  - Mỗi mục có cờ `disposed`. Người nghe cuối rời đi khi mục đang truy vấn thì kết quả trả về không được ghi vào cache, không báo cho ai, và mục không chạy lại dù đang mang dấu "cần làm lại"; nếu không, mục sống lại mà không còn người nghe.
  - Lời gọi làm mới đang chờ thì không được treo khi mục bị bỏ (vd. `LogFoodUseCase` đang chờ thì người dùng bấm quay lại). Lời gọi đó vẫn trả về bằng một truy vấn riêng, không ghi vào cache, như luật đọc một lần ở trên. Không trả `Result.error`: bên chờ thường cần số mới để báo vượt giới hạn an toàn sau khi ghi, và UI sẽ phải báo một lỗi không có thật.
  - Test ở 5a-3: sự kiện tới giữa lúc truy vấn; lời gọi làm mới chờ đúng truy vấn bắt đầu sau nó; mục bị bỏ giữa lúc truy vấn; mục bị bỏ khi có lời gọi làm mới đang chờ, lời gọi đó vẫn trả về số mới.
- **Chỉ phát sự kiện khi lần ghi xong:** `_changed()` chỉ chạy khi thân hàm ghi thành công, tức sau khi giao dịch đã xong ([drift_repository.dart:104](../../packages/journal_db/lib/src/drift_repository.dart#L104)); không phát theo từng câu lệnh.
  - Hàm ghi nhiều câu lệnh phải nằm trong `db.transaction`, để lần ghi lỗi giữa chừng không để lại dữ liệu ghi dở (vd. lần uống đã ghi mà kho chưa trừ) và không có sự kiện nào. Mọi hàm ghi nhiều câu lệnh trong 43 hàm `write: true` hiện đều theo luật này; test kiểm toán ở 5a-1 giữ luật.
  - Không phát "mọi bảng" khi ghi lỗi: cách đó chỉ làm cache khớp với dữ liệu ghi dở chứ không sửa dữ liệu, và bắt mọi repository truy vấn lại đúng lúc CSDL đang lỗi (vd. máy đầy bộ nhớ).
- **Tự kiểm bằng test:** `sameIsolateExecutor` cố định `setup` ([journal_database.dart:46](../../packages/journal_db/lib/src/journal_database.dart#L46)), nên test dùng một `ExecutorFactory` riêng: gọi `setUpConnection` rồi đăng ký `Database.updatesSync` (update hook của SQLite, có trong `sqlite3` 3.9.1; bản sync thu đủ sự kiện ngay sau mỗi lệnh ghi). Với mỗi phương thức ghi, test so tập bảng báo trong `changes` với tập bảng SQLite thực sự đổi, nên bảng ghi dưới đây không thể lệch khỏi code. Test của `JournalDbService` (5a-2) kiểm: thứ tự thay kết nối, bỏ sự kiện của thế hệ cũ, kết nối `null` khi xóa, và khi hàm ghi trả về thì `lastChangeSeq` của service đã tăng.
- **Chặn chỗ update hook không thấy:** SQLite không gọi update hook với bảng `WITHOUT ROWID`, với `DELETE FROM t` không có `WHERE`, và với dòng bị xóa do `REPLACE`. Code hiện chưa dùng trường hợp nào (`ON CONFLICT … DO UPDATE` vẫn được báo). Test kiểm toán quét lược đồ và SQL trong `journal_db`, cấm cả ba, để contract test không bỏ sót mà không báo lỗi.
- **Repository không biết nhau:** mỗi repository giữ cache và chỉ làm mới khi một bảng mà **truy vấn của chính nó đọc** bị đổi; gộp các lần báo trong cùng một microtask thành một lần làm mới. Không repository nào làm mới vì dữ liệu của repository khác.
- **ViewModel** nghe repository, gọi use case khi cần ghép, tính phần dẫn xuất một lần mỗi khi dữ liệu đổi, không tính trong `build()`. Mọi thao tác đi qua `Command`.

**Ghi gì thì đổi bảng nào** (contract test kiểm; PR 5a-1 hoàn thiện cho đủ mọi phương thức ghi):

| Thao tác ghi | Bảng bị đổi |
|---|---|
| Ghi, sửa, xóa món | `food_entries`, `intake_lines` (+ `custom_foods`, `custom_food_lines` khi lưu món) |
| `recordDose` / `updateDose` / xóa liều | `dose_entries`, `intake_lines`, `dose_box_deductions`, `boxes`, `dose_occurrences` |
| Sửa thành phần sản phẩm | `ingredients` |
| Tạo, sửa sản phẩm; thêm, sửa, xóa hộp | `products`, `boxes` |
| Lưu trữ sản phẩm | `products`, `schedules` (kết thúc lịch của sản phẩm) |
| Lịch: thêm, sửa, kết thúc | `schedules` |
| Bỏ qua, xóa đánh dấu, gắn lại lần uống vào lịch | `dose_occurrences` |
| Nước | `water_entries` |
| Buổi tập | `workout_entries` |
| Hồ sơ, chế độ thận trọng | `profile` (+ `consents` khi nâng cấp đồng ý) |
| Tự tăng tuổi | `profile`, `ui_state` (lời nhắc đã tăng tuổi) |
| Giờ trong ngày, ẩn calo, bật câu "Bạn có biết" | `settings` |
| Đồng ý nhắc giờ, đồng ý Drive | `consents` |
| `ui_state` (ẩn câu "Bạn có biết" hôm nay, đã đọc nhắc nhở, thời điểm sao lưu) | `ui_state` |
| Bước onboarding | `meta` |
| Khôi phục bản sao lưu, xóa toàn bộ | tất cả |

**Repository đọc bảng nào** (nháp; PR 5a-3 chốt theo truy vấn thật và khai trong code). Repository làm mới khi tập bảng bị đổi giao với tập bảng nó đọc:

| Repository | Bảng mà truy vấn của nó đọc |
|---|---|
| Session | **Không nghe `changes`**: stage chỉ đổi qua thao tác phiên. Đọc `consents`, `meta`, `profile` và `settings` (cờ ẩn calo, [db_session_controller.dart:96](../../app/lib/state/db_session_controller.dart#L96)) khi mở, tạo, nâng cấp đồng ý, xong hồ sơ, khôi phục, xóa. `_syncStageFromRepo` có ghi (`saveHideCalories`, `saveOnboardingStep`), nên phát `changes` và làm Settings làm mới; đúng như mong muốn, contract test tính cả hai lần ghi này |
| ViewedDay | Không đọc CSDL; chỉ giữ ngày đang xem trong bộ nhớ |
| JournalDay | `food_entries`, `dose_entries`, `intake_lines`, `dose_box_deductions`, `water_entries`, `workout_entries` |
| CustomFood | `custom_foods`, `custom_food_lines` |
| Supplement | `products`, `ingredients`, `boxes`; tóm tắt sản phẩm còn đọc `schedules`, `dose_entries`, `intake_lines`, `dose_box_deductions` (lịch đang chạy, mức dùng 14 ngày) |
| Schedule | `schedules`, `dose_occurrences` |
| Settings | `profile`, `consents`, `settings`, `ui_state` |

JournalDay và Schedule nhận `day` làm tham số và cache theo ngày (Schedule giữ ngày đang xem, cùng hôm nay và hôm qua thật cho nhắc giờ); ngày lấy từ ViewedDay do ViewModel hoặc use case truyền vào. Settings không nhận `day` và chỉ có một cache: việc so `hidden_tip_day` với ngày đang xem (câu "Bạn có biết") do ViewModel làm.

**Phần ghép ở use case** (không giữ state; ViewModel hoặc `AppCoordinator` nghe các repository liên quan rồi gọi):

| Use case | Ghép từ | Kết quả, nơi dùng |
|---|---|---|
| `DailyReportUseCase` | JournalDay + Settings (hồ sơ) | Báo cáo ngày và 7 ngày: Hôm nay, Chi tiết chất, phản hồi sau khi ghi |
| `ScheduleSafetyUseCase` | Schedule + Supplement (thành phần) + Settings (giờ bữa, câu "Bạn có biết") | Cờ vượt giới hạn theo lịch, câu nhắc lịch, câu "Bạn có biết" |
| `ReminderSyncUseCase` | Schedule + Supplement (tên sản phẩm) + Settings (đồng ý, tùy chọn hiện tên) | Đồng bộ nhắc giờ; `AppCoordinator` gọi (3.2) |
| `LogFoodUseCase`, `LogDoseUseCase` | JournalDay, Supplement, Schedule + `DailyReportUseCase` | Ghi rồi so cờ trước và sau để ra phản hồi |
