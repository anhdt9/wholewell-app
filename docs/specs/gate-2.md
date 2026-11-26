# Đặc tả: Cổng 2 — Kiểm thử an toàn, Pháp lý, Chính sách quyền riêng tư & Lời văn đồng ý

Trạng thái: Đã duyệt (26/11/2026)  <!-- Nháp | Đã duyệt -->
Thiết kế UX: [docs/design/gate-2.md](../design/gate-2.md)
Thứ tự MVP: Việc 8 trong [docs/status.md](../status.md)

## Mục tiêu
Hoàn tất toàn bộ điều kiện **Cổng 2** trước khi thử nghiệm kín 12 người × 14 ngày và phát hành MVP Android: chứng minh **0 vi phạm giới hạn an toàn (UL), 0 lỗi đơn vị**, hoàn thiện **Chính sách quyền riêng tư**, chuẩn hóa **lời văn các màn đồng ý**, và lập **Bảng tự kiểm pháp lý + an toàn OWASP / Google Play**.

## Người dùng và tình huống
- **Người dùng lần đầu / xem quyền riêng tư:** Đọc lời văn đồng ý rõ ràng (biết dữ liệu ở máy, quyền sửa ở `Tôi → Hồ sơ`, quyền xuất/rút đồng ý/xóa ở `Tôi → Quyền riêng tư`) và có thể mở xem toàn văn **Chính sách quyền riêng tư** ngay trong app khi không có mạng.
- **Chủ dự án trước thử nghiệm kín & phát hành Play Console:** Có đủ bộ test an toàn Cổng 2 chạy trong CI, chính sách quyền riêng tư bản chuẩn để gắn link lên Play Console / Google Cloud OAuth Consent Screen, bảng tự kiểm Luật 91/2025/QH15 + Google Play Data safety/Health apps + OWASP Mobile Top 10, và checklist thử nghiệm trên máy thật.

## Ràng buộc
- **AGENTS.md & `docs/plan.md` mục 4, 7:**
  - Tiêu chí bắt buộc: **0 vi phạm UL, 0 lỗi đơn vị**.
  - Không thay đổi chuẩn tham chiếu, không thêm quảng cáo hay SDK phân tích/báo lỗi.
  - Tự đối chiếu văn bản gốc; chỗ không chắc thì bỏ hoặc thu hẹp; minh bạch dữ liệu nhạy cảm theo Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP.
  - Đổi chữ hiển thị / thêm mục xem Chính sách quyền riêng tư trên giao diện phải qua bước thiết kế UX (`docs/design/gate-2.md`) duyệt trước khi sửa code UI.

## Nguồn
- **Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15** & **Nghị định 356/2025/NĐ-CP** (`docs/plan.md` mục 4)
- **Nghị định 98/2021/NĐ-CP** (phân định tham chiếu dinh dưỡng chung, không phải trang thiết bị y tế)
- **Luật Sở hữu trí tuệ Điều 15** (chỉ lưu con số của NASEM, LPI)
- **USDA DRI Calculator** (đối chiếu giá trị mẫu engine): https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator
- **Google Play Data safety & Health apps** (`docs/plan.md` mục 7): https://support.google.com/googleplay/answer/11416267 · https://support.google.com/googleplay/android-developer/answer/16555673
- **OWASP Mobile Top 10:** https://owasp.org/www-project-mobile-top-10/

## Thiết kế kỹ thuật

### 1. Bộ kiểm thử an toàn Cổng 2 (`packages/health_engine` & `app/test`)
- **`packages/health_engine/test/gate2_safety_test.dart`:**
  - Đối chiếu kết quả `HealthEngine` (`eerKcal`, `protein`, `amdr`, `ul` và `rda/ai` của toàn bộ 40 chất) cho các hồ sơ đại diện (nam/nữ ở mốc 18, 19, 30, 31, 50, 51, 70, 71 tuổi, các mức vận động) với bảng đối chiếu chuẩn trong gói & mẫu tính toán DRI Calculator.
  - Kiểm tra **0 lỗi đơn vị & 0 vi phạm UL** trên toàn bộ ma trận biên:
    - Vitamin A: `retinol` (IU/µg RAE) tính vào UL; `betaCarotene` bổ sung/thức ăn không tính vào UL; dạng chưa rõ tính thận trọng vào UL và `"chưa chắc"` ở phía RDA.
    - Vitamin E: tổng hợp `dl-alpha-tocopherol` (0,45 mg RDA / 0,90 mg UL mỗi IU) vs tự nhiên `d-alpha-tocopherol` (0,67 mg mỗi IU cho cả RDA & UL); chỉ tính bổ sung + thực phẩm tăng cường.
    - Niacin (`NE` / `axit nicotinic` / `niacinamide`): chỉ tính bổ sung + tăng cường.
    - Folate (`DFE` bổ sung/tăng cường `× 0,6` sang µg axit folic cho UL; thức ăn tự nhiên không tính UL).
    - Magie: chỉ tính từ bổ sung (`UL = 350 mg/ngày`).
    - Tỷ lệ nguyên tố hợp chất canxi (`carbonate 40%`, `citrate 21%`) và sắt (`fumarate 33%`, `sulfate 20%`, `gluconate 12%`).
    - Mốc 12 tháng trước 19, 31, 51, 71 tuổi lấy UL thấp hơn giữa 2 nhóm.
    - Đường bổ sung: tách từng bữa chính ≤ 10 g, gộp chuỗi bữa phụ cách nhau < 30 phút.
- **Kiểm tra cấu hình & riêng tư trong `app/test/gate2_privacy_audit_test.dart`:**
  - Rà `AndroidManifest.xml`, `pubspec.yaml`, `ReminderLogic.kt`: không có quyền `READ_EXTERNAL_STORAGE`/`WRITE_EXTERNAL_STORAGE`, không có SDK phân tích/quảng cáo (`firebase`, `sentry`, `crashlytics`, `admob`), `allowBackup="false"`, `ReminderLogic` không bao giờ đưa tên sản phẩm/vi chất lên thông báo màn hình khóa.
  - Kiểm tra mọi dòng OCR chưa `confirmed` không bao giờ được lưu vào `ingredients` hay `dose_entries`.

### 2. Chính sách quyền riêng tư & Lời văn đồng ý (`docs/privacy-policy.md`, `app/`)
- Tạo tài liệu [docs/privacy-policy.md](../privacy-policy.md) (bản hoàn chỉnh tiếng Việt, cùng nội dung để xuất bản web tĩnh / dán lên Play Console và nhúng qua asset hoặc màn đọc trong app).
- Trong `Tôi → Quyền riêng tư`: thêm mục `Chính sách quyền riêng tư ›` mở màn đọc toàn văn offline (không cần trình duyệt/mạng).
- Rà & cập nhật lời văn màn Đồng ý (`onboarding_flow.dart`):
  - Sửa chỗ chỉ ghi `"xóa ở tab Tôi"` thành `"xóa ở Tôi → Quyền riêng tư"` (khớp cấu trúc màn mới sau Việc 7).
  - Bổ sung rõ mục đích xử lý dữ liệu, dữ liệu nhạy cảm được lưu mã hóa trên máy, tùy chọn sao lưu `.wwbackup` / Google Drive `appDataFolder` do người dùng tự bật riêng, và quyền sửa/xuất/rút đồng ý/xóa toàn bộ.
  - Tăng `mvpConsentVersion` hay giữ nguyên `'mvp-1'`? Nếu chưa phát hành ra ngoài (mới thử nội bộ), giữ `'mvp-1'` nếu không đổi bản chất đồng ý, hoặc nâng `'mvp-2'` nếu muốn ép máy thử cũ đồng ý lại bản chữ mới — cần chốt ở mục Câu hỏi còn mở!

### 3. Tài liệu tự kiểm pháp lý, OWASP & Thử nghiệm máy thật
- **`docs/legal-checklist.md`:** Bảng tự kiểm theo từng điều khoản của Luật 91/2025/QH15 + Nghị định 356/2025/NĐ-CP (kèm mẫu Hồ sơ đánh giá tác động xử lý dữ liệu cá nhân nhạy cảm tự lập), Nghị định 98/2021/NĐ-CP, Luật SHTT Điều 15, Google Play Data safety & Health apps, Google API `drive.appdata`, và OWASP Mobile Top 10 (M1–M10).
- **`docs/closed-beta-checklist.md`:** Kịch bản test tay trên máy thật Android & checklist thử nghiệm kín 12 người × 14 ngày theo `docs/plan.md` mục 6–7 (BFU, khóa màn hình, 30 nhãn thật, 50 mã vạch VN, nhắc giờ 7 ngày đa hãng, sao lưu SAF & Google Drive thật với OAuth SHA-1).

## Tiêu chí đạt
- [ ] `packages/health_engine/test/gate2_safety_test.dart`: kiểm đủ 0 vi phạm UL, 0 lỗi đơn vị, đối chiếu đủ mẫu DRI Calculator; `tools/verify_pack.py` & `reference_engine.py` qua 100%.
- [ ] `app/test/gate2_privacy_audit_test.dart`: kiểm tự động quyền Android, không SDK phân tích/quảng cáo, nội dung thông báo ẩn tên chất/sản phẩm, và màn đọc `Chính sách quyền riêng tư` offline trong `Tôi → Quyền riêng tư`.
- [ ] Hoàn thiện `docs/privacy-policy.md`, `docs/legal-checklist.md`, `docs/closed-beta-checklist.md`, cập nhật `docs/status.md`.
- [ ] Toàn bộ `tools/verify_pack.py`, `dart analyze/test`, `flutter analyze/test`, và `:app:testDebugUnitTest` pass 100%.

## Ngoài phạm vi
- Phát hành trực tiếp lên Google Play Store hoặc viết backend web host trang chính sách quyền riêng tư (chủ dự án tự đẩy `docs/privacy-policy.md` lên GitHub Pages hoặc trang riêng khi điền Play Console).
- Tính năng Giai đoạn 2 (trẻ em < 18 tuổi, mang thai, cho con bú, giọng nói nếu chưa ổn định, widget, quảng cáo AdMob).

## Câu hỏi còn mở
1. **Phiên bản đồng ý (`mvpConsentVersion`):** Đã chốt giữ `'mvp-1'` cho MVP (`packages/journal_db/lib/src/models.dart`); nâng `'mvp-2'` khi thay đổi mục đích hoặc phạm vi xử lý dữ liệu ở Giai đoạn 2.
2. **Thông tin liên hệ trong Chính sách quyền riêng tư (`docs/privacy-policy.md`):** Đã chốt: nhà phát triển **Đặng Thế Anh**, email **wholewell.apps@gmail.com**.
3. **Cách hiển thị Chính sách quyền riêng tư trong app:** Đã chốt: đọc toàn văn trực tiếp trên màn mới trong `Tôi → Quyền riêng tư → Chính sách quyền riêng tư` (offline 100%, không cần mở trình duyệt/mạng).
