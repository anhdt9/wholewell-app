# Bàn giao công việc

Cập nhật 24/11/2026. Dành cho người (hoặc agent) nhận tiếp dự án WholeWell. Đọc theo thứ tự: tệp này → [AGENTS.md](../AGENTS.md) (quy tắc bắt buộc) → [status.md](status.md) (việc tiếp theo, chi tiết) → [plan.md](plan.md) → [design/mvp-overview.md](design/mvp-overview.md) → [specs/encrypted-db.md](specs/encrypted-db.md).

## 1. Dự án trong một đoạn

App tham chiếu dinh dưỡng, miễn phí, mọi dữ liệu nằm trên máy. App so lượng vi chất từ thức ăn và thực phẩm bổ sung với chuẩn Mỹ (NASEM: RDA/AI, UL, EER, AMDR; Dietary Guidelines 2025–2030 cho đường bổ sung; 2024 Compendium; Physical Activity Guidelines; hệ số đổi đơn vị của FDA). App cũng quản lý kho và lịch uống bổ sung, và cảnh báo khi vượt giới hạn an toàn.

- MVP: người khỏe mạnh từ 18 tuổi, không mang thai, không cho con bú. Người dùng thuốc theo chỉ định hoặc có bệnh mạn tính dùng **chế độ thận trọng**.
- Không AI tạo sinh, không máy chủ, không SDK bên thứ ba.

## 2. Đã xong

| Phần | Ở đâu | Trạng thái |
|---|---|---|
| Plan, quy trình (đặc tả → UX → test → code, có cổng duyệt) | `docs/plan.md`, `AGENTS.md` | Đã gộp |
| Gói dữ liệu: 40 chất × 16 nhóm, UL đúng phạm vi, kiểm đối chiếu | `tools/build_pack.py`, `verify_pack.py`, `reference_engine.py` | Đã gộp |
| Engine Dart, test so với fixtures Python | `packages/health_engine` | Đã gộp |
| Thiết kế UX tổng thể MVP | `docs/design/mvp-overview.md` | **Đã duyệt** 24/11/2026 |
| Đặc tả CSDL mã hóa | `docs/specs/encrypted-db.md` | **Đã duyệt** 24/11/2026 (PR #11 đã gộp) |
| CSDL mã hóa: code và test | PR #12, nhánh `feat/encrypted-db-v1` | **Đang mở, chờ chủ dự án gộp** |
| App Flutter | `app/` | **Khung tạm** để thử engine, chưa theo thiết kế UX |

### PR #12: CSDL mã hóa (đang mở)

- **Gói mới `packages/journal_db`** (thuần Dart): drift + SQLite3MultipleCiphers, cipher `chacha20`, nạp khóa thô.
  - Thứ tự kiểm khi mở: kiểm thư viện trên kết nối trong bộ nhớ → kiểm khóa → kiểm cipher.
  - Khóa có bốn trạng thái: có, không có, mất, chưa đọc được.
  - Mở theo bảng khóa × tệp.
  - Tạo CSDL ở tệp tạm, chỉ đổi tên khi đã ghi xong đồng ý.
  - Xóa toàn bộ: xóa khóa trước tệp; có dấu "đang xóa" để làm tiếp nếu bị ngắt.
  - Sao tệp nguyên byte trước khi di chuyển lược đồ.
  - Lược đồ v1 đủ bảng (kho, lịch, dòng chất).
  - Không sinh mã drift: SQL viết tay, vì `build_runner` không chạy được trên máy phát triển.
- **Android:**
  - `DbKeyStore.kt`: khóa bọc AES-GCM trong Keystore với `setUnlockedDeviceRequired`, chạy trên luồng nền chung.
  - `DbKeyRules.kt`: phân loại trạng thái khóa, có test JVM.
  - `minSdk = 28`; tắt sao lưu và chuyển máy.
- **App:**
  - `AppState` bất đồng bộ, có bộ đếm thế hệ cho mỗi lần đọc; `start()` gọi chồng thì dùng chung một lần mở.
  - Có màn trạng thái theo thiết kế (dòng "Toàn app").
  - Nền tảng khác Android báo "chưa hỗ trợ".
- **CI:**
  - Job `journal-db`.
  - Kiểm không kéo theo `sqlite3_flutter_libs`.
  - Test JVM cho Kotlin.
  - Lưu `app-debug.apk` vào Artifacts 14 ngày (tab Actions → lần chạy → Artifacts).
- **Hai chỉnh sửa đặc tả đã duyệt, chủ dự án đồng ý 24/11/2026:**
  - Thứ tự kiểm khi mở (lý do: SQLite 3.48).
  - Tệp bản khóa hỏng khi máy đang mở khóa thì coi là mất khóa.
- **Đã qua ba vòng review ngoài; mọi điểm đã sửa.**

## 3. Quyết định đã chốt (đừng tự đổi)

Chi tiết và lý do ở AGENTS.md, plan.md, đặc tả. Những điểm hay bị hỏi lại:

- **Chỉ chuẩn Mỹ**, không dữ liệu Việt Nam, không EFSA, WHO. Bài nghiên cứu không làm nguồn cho số liệu. Nguồn không nói rõ thì không có quy tắc.
- **Cảnh báo chỉ ghi số:** lượng, giới hạn, mức vượt (đơn vị và %), phạm vi, nguồn đóng góp, kèm dòng "Hỏi bác sĩ hoặc dược sĩ nếu cần."
- **ODA** (Linus Pauling Institute) chỉ để tham khảo, chỉ bật từ giai đoạn 3.
- **Đường bổ sung** chỉ có giới hạn ≤10 g mỗi bữa, không có giới hạn theo % năng lượng.
- **Dạng chưa rõ:** so mức khuyến nghị lấy số nhỏ nhất, tính giới hạn lấy số lớn nhất, ghi "chưa chắc". Đây là quy tắc của app.
- **Không AI tạo sinh**; không lưu tên bệnh, tên thuốc.
- **Lưu sẵn lượng chất mỗi lần ghi**, kèm dữ liệu gốc và `pack_version`.
- **Sửa lịch** có hiệu lực từ hôm nay; nếu hôm nay đã đánh dấu lần uống theo lịch cũ thì từ ngày mai.

## 4. Việc cần làm tiếp (theo thứ tự)

Danh sách đầy đủ ở [status.md](status.md), mục "Việc tiếp theo". Mỗi tính năng cần đặc tả đã duyệt, cần thêm thiết kế UX đã duyệt nếu có giao diện, rồi mới code.

1. **Gộp PR #12** (chủ dự án). Sau đó thử trên máy thật theo danh sách trong status.md, việc 1. Quan trọng nhất:
   - Khởi động lại máy rồi đọc khóa nhiều lần: không bao giờ được ra lỗi sai tag.
   - Khóa và mở khóa máy.
   - Đổi hoặc xóa mã khóa màn hình.
   - Tiến trình app được dựng lại khi máy đang khóa.
   - Đo tốc độ với 2 năm dữ liệu.
2. **Sửa engine (việc 2): phải xong trước mọi đường ghi sinh lượng tính giới hạn riêng** (Nhập theo nhãn, Ghi một lần, chụp nhãn, mã vạch). Gồm:
   - `IntakeItem` thêm bảng lượng tính giới hạn tùy chọn. Sau đó bật `engineSupportsUlAmounts` trong `packages/journal_db/lib/src/intake.dart` và đưa `ulAmounts` vào `_group`.
   - **Lỗi có sẵn:** vitamin E tổng hợp cần hệ số tính giới hạn riêng (1.000 mg ≈ 1.100 IU tổng hợp; đã đối chiếu NIH ODS 24/11/2026). Gói và engine đang dùng 0,45 mg/IU cho cả phía giới hạn, nên tính thiếu khoảng một nửa. Thêm hệ số vào `build_pack.py` sau khi đối chiếu báo cáo DRI gốc, kèm ô đối chiếu.
   - Test cho bảng "Quy tắc đổi một dòng thành khóa engine" trong đặc tả CSDL (mỗi hàng một ca).
   - Các mục khác trong status.md, việc 2: nhóm tuổi là dữ liệu, mốc tuổi lấy giới hạn thấp hơn, đường bổ sung theo bữa và nối chuỗi bữa phụ, đủ cờ, hai tổng, vận động.
3. **Thư viện món (việc 3):** USDA và FPED. Thêm hệ số beta-caroten trong thức ăn (IU → µg RAE) kèm nguồn. Tính lại món USDA khi sửa khẩu phần (CSDL đã có `replaceFoodLines`).
4. **Điều kiện dùng app, chế độ thận trọng (việc 4).** Gặp đồng ý `khung-tam-0` thì phải hỏi lại cả màn Điều kiện lẫn Đồng ý.
5. **Chụp nhãn, mã vạch, kho (việc 5):** tỷ lệ nguyên tố của hợp chất và tỷ lệ tocopherol của este vitamin E (acetat, succinat), kèm nguồn.
6. **Lịch uống, nhắc giờ (việc 6).** Thêm chữ "Lịch mới áp dụng từ ngày mai." vào thiết kế.
7. **Sao lưu (việc 7):** khi có tính năng này, nút [Khôi phục từ bản sao lưu] trên các màn lỗi mới bấm được.
8. **Cổng 2:** kiểm thử an toàn, pháp lý, thử nghiệm kín 12 người × 14 ngày.

## 5. Rủi ro và việc treo

- **Bản APK hiện tại chỉ để thử nội bộ, không phát cho người ngoài.** Khung tạm ghi một đồng ý `khung-tam-0` mà người dùng chưa cho, và câu thuốc, bệnh mặc định là "Không".
- Khung tạm vẫn cho chọn mang thai, cho con bú, nhưng CSDL v1 không lưu (đúng đặc tả MVP).
- Chưa có iOS: Keychain, Application Support.
- `_loadDay` trong `AppState` đọc tuần tự 7 ngày sau mỗi lần ghi. Tạm ổn; sau này nên truy vấn theo khoảng ngày.
- Nhánh cũ `feat/encrypted-db` (PR #5 đã đóng, làm theo đặc tả cũ) vẫn còn trên GitHub. **Chờ chủ dự án quyết có xóa không.**

## 6. Cách làm việc (thực tế trên máy này)

- **Giao tiếp:** tiếng Việt, ngắn gọn. Giao diện dùng lời thường, không hiện tên viết tắt của chuẩn.
- **Git:**
  - Mỗi lúc chỉ một PR mở. Trước khi đẩy lên nhánh của PR, kiểm PR còn mở không (`gh pr view <n> --json state`), vì chủ dự án gộp nhanh.
  - Không đẩy thẳng vào `main`. Agent không tự gộp.
  - Commit bằng tiếng Việt.
- **Máy Windows có Application Control:**
  - `dart test` bị chặn.
  - Test thuần Dart chạy trực tiếp được: `dart test/<tệp>_test.dart`.
  - Test cần SQLite3MultipleCiphers (build hook) chỉ chạy trên CI.
  - `dart analyze` chạy được.
  - Không có Flutter: phần app chỉ kiểm qua CI.
  - `gh` ở `/c/Program Files/GitHub CLI/gh.exe`.
- **Python:** chạy `python -I`. Script sửa nhiều dòng thì ghi ra tệp rồi chạy, vì heredoc trong bash hay lỗi.
- **Kiểm nguồn:** đọc NIH ODS bằng Claude in Chrome, vì trang chặn truy cập tự động. Ghi ngày tra.
- **CI:** xem log bằng `gh api --allow-escape-sequences repos/anhdt9/wholewell-app/actions/jobs/<id>/logs`.
