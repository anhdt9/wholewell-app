# AGENTS.md – WholeWell

Tài liệu ngữ cảnh cho mọi agent (Claude Code, Gemini, Antigravity). `CLAUDE.md` và `GEMINI.md` chỉ trỏ về đây.
Plan đầy đủ: [docs/plan.md](docs/plan.md). Trạng thái và việc tiếp theo: [docs/status.md](docs/status.md).

## Giao tiếp

- Trả lời chủ dự án bằng **tiếng Việt, ngắn gọn, đi thẳng vào việc**. Ưu tiên đưa code hoặc tệp hoàn chỉnh thay vì giải thích dài.
- Giao diện app viết bằng tiếng Việt, dùng lời thường ("mục tiêu calo", "giới hạn an toàn"), không hiện tên viết tắt của chuẩn (RDA, UL, EER, AMDR) cho người dùng.

## Sản phẩm (đã chốt, không tự đổi)

- App tham chiếu dinh dưỡng cá nhân hóa cho người Việt từ **18 tuổi**: so lượng nạp vi chất từ thực phẩm và thực phẩm bổ sung với chuẩn Mỹ, quản lý kho và lịch uống bổ sung, cảnh báo khi vượt mức tối đa an toàn.
- **Không** chẩn đoán, kê đơn, gợi ý liều; không bán, gợi ý hay quảng cáo nhãn hàng bổ sung. Không kiểm tương tác thuốc, xét nghiệm, CGM, gen, vi sinh; không hồ sơ sức khỏe trẻ em.
- **Miễn phí toàn bộ.** MVP không có quảng cáo, không cài SDK quảng cáo (chỉ chừa chỗ trong bố cục). Về sau doanh thu chỉ từ AdMob: chỉ quảng cáo không cá nhân hóa; không đặt ở màn cảnh báo, thông báo, widget; yêu cầu quảng cáo không chứa dữ liệu sức khỏe.
- Thị trường đầu tiên: Việt Nam. Không thuê chuyên gia, không thuê luật sư: tự đối chiếu văn bản gốc, chỗ không chắc thì bỏ hoặc thu hẹp tính năng.

## Chuẩn tham chiếu (chỉ những chuẩn này)

| Nhóm | Chuẩn | Nguồn |
|---|---|---|
| Vi chất | RDA; chất chưa có RDA dùng AI và ghi "ước tính" | NASEM (báo cáo DRI gốc); NIH ODS để đối chiếu |
| Vi chất | UL (giới hạn an toàn), đúng phạm vi từng chất; cảnh báo khi **vượt** (lớn hơn UL) | NASEM (báo cáo DRI gốc); NIH ODS để đối chiếu |
| Vi chất | ODA, chỉ tham khảo, chỉ bật sau cổng 3 | Linus Pauling Institute |
| Năng lượng | Mục tiêu calo = EER (mức giữ cân), không có mục tiêu giảm cân | NASEM 2023 |
| Năng lượng | Tỷ lệ đạm, béo, bột đường = AMDR | NASEM |
| Năng lượng | Đường bổ sung ≤10% năng lượng/ngày, ≤10 g/bữa | Dietary Guidelines 2025–2030 |
| Vận động | MET | 2024 Adult Compendium |
| Vận động | Người lớn: 150–300 phút vận động vừa hoặc 75–150 phút vận động mạnh mỗi tuần (1 phút mạnh ≈ 2 phút vừa); tập tăng cơ ≥2 ngày/tuần | Physical Activity Guidelines for Americans, bản 2 (HHS) |
| Nhãn | Hệ số đổi đơn vị trên nhãn (IU, DFE, NE, RAE) | FDA (hướng dẫn đổi đơn vị 2019; 21 CFR 101.9, 101.36) |

**Không thêm chuẩn khác** (EAR, CDRR, mức đạm 1,2–1,6 g/kg của Dietary Guidelines…), không dùng dữ liệu Việt Nam. Muốn thêm thì hỏi chủ dự án trước.

## Nguồn và pháp lý

- Chỉ nguồn uy tín, **miễn phí, dùng hợp pháp trong app có quảng cáo**. Nhãn A: cơ quan chính phủ Mỹ (NIH ODS, FDA, USDA, CDC, HHS), số liệu trong báo cáo DRI của NASEM, 2024 Compendium. Nhãn B: LPI (chỉ cho ODA). Không dùng nguồn trả phí, giấy phép NC, dữ liệu cộng đồng (vd. Open Food Facts), ý kiến, video, nội dung quảng cáo.
- **Bài nghiên cứu (PubMed, PMC) không làm nguồn** cho quy tắc hay con số trong app; chỉ để hiểu, giải thích quyết định. **Nguồn không nói rõ thì không có quy tắc** (vd. không có quy tắc canxi–magie).
- **Chỉ lưu con số** theo cấu trúc riêng, kèm nguồn và link. Không chép văn bản hay bố cục bảng của NASEM, LPI. Tự viết lời giải thích.
- **Kiểm nguồn bằng Claude in Chrome** (trình duyệt thật), vì NIH ODS chặn truy cập tự động: mỗi khi thêm hay đổi số, quy tắc, và mỗi quý, agent mở trang nguồn, đối chiếu câu gốc, ghi ngày tra. CI không kiểm link; CI chỉ kiểm mỗi số và quy tắc có đủ link, câu gốc ngắn, ngày tra.
- **Quy tắc lịch là dữ liệu** trong `build_pack.py` (loại, chất, ngưỡng, nguồn); thêm quy tắc cùng loại không sửa code.
- Không dùng tên hay nội dung NIH ODS trong quảng cáo.
- Dữ liệu thực phẩm: USDA FoodData Central (CC0), NIH DSLD (CC0).

## Dữ liệu người dùng và quyền riêng tư

- Mọi dữ liệu ở trên máy, SQLite mã hóa (SQLite3MultipleCiphers qua drift, khóa trong flutter_secure_storage). Không máy chủ, không iCloud, không thiết bị đeo, không Health Connect / HealthKit. Hoạt động do người dùng tự nhập.
- Sao lưu: tệp mã hóa (mặc định); Google Drive appDataFolder là tùy chọn, mã hóa Argon2id, khóa chỉ người dùng giữ. Mọi client OAuth (Android, iOS, desktop) phải nằm trong **một dự án Google Cloud duy nhất**.
- **Gói dữ liệu (số liệu, quy tắc) đi kèm bản cài đã ký**, cập nhật qua cửa hàng ứng dụng; không tải từ máy chủ.
- **Không nhúng SDK phân tích hay báo lỗi** của bên thứ ba. Theo dõi crash qua Play Console / App Store Connect.
- AI chỉ chạy trên máy (Gemini Nano qua ML Kit GenAI; Apple Foundation Models, không dùng Private Cloud Compute). **AI không tính con số**: engine quyết định mọi số và cảnh báo; AI chỉ giải thích và gợi ý món. Có bản dự phòng giải thích theo mẫu.
- Chỉ dùng dữ liệu giả lập khi phát triển và kiểm thử.

## Cấu trúc repo

```
docs/                     plan.md, tools.md, status.md, specs/ (đặc tả), design/ (thiết kế UX + nguyên tắc)
tools/                    Python: nguồn số liệu và kiểm tra
  build_pack.py           NGUỒN SỐ LIỆU DUY NHẤT → sinh reference_pack.json (engine + app)
  verify_pack.py          kiểm cấu trúc + ô đối chiếu bảng NASEM gốc
  reference_engine.py     engine viết lại bằng Python → packages/health_engine/test/fixtures/cases.json
packages/health_engine/   engine thuần Dart (không I/O, không Flutter, không mạng) + test
app/                      app Flutter (dùng package:material_ui, không dùng package:flutter/material.dart)
.github/workflows/ci.yml  CI: build/verify pack, dart analyze + test, flutter analyze + test
```

## Lệnh

```bash
# Gói dữ liệu (chạy mỗi khi sửa tools/ hoặc logic engine)
python tools/build_pack.py && python tools/verify_pack.py && python tools/reference_engine.py

# Engine
cd packages/health_engine && dart pub get && dart analyze && dart test

# App
cd app && flutter pub get && flutter analyze && flutter test && flutter run
```

`flutter analyze` trong CI thất bại cả với mức info (vd. API đã ngừng dùng), nên phải sạch hoàn toàn.

## Quy tắc khi sửa code

1. **Số liệu chỉ sửa trong `tools/build_pack.py`**, không sửa tay `reference_pack.json` hay `cases.json`. Mỗi số mới phải có nguồn kiểm được; thêm ô đối chiếu vào `verify_pack.py`. Không đoán số: nếu nguồn chưa rõ, để engine trả `NotComputed` kèm lý do.
2. **Đổi logic engine thì đổi cả `tools/reference_engine.py`** và sinh lại fixtures; test Dart so với kết quả Python.
3. Tiêu chí bắt buộc: **0 vi phạm UL, 0 lỗi đơn vị**. UL đúng phạm vi: magie chỉ tính bổ sung; niacin, vitamin E chỉ tính từ bổ sung + thực phẩm tăng cường (theo nguồn, kể cả vitamin E tự nhiên trong viên); vitamin A chỉ retinol; folate chỉ axit folic. Thành phần bổ sung tính theo từng chất và dạng; dạng chưa rõ thì tính giới hạn theo cách thận trọng nhất.
4. Engine và giao diện chỉ gọi interface cho phần phụ thuộc nền tảng: NotificationScheduler, BackgroundJobs, SecureKeyStore, OcrEngine, BarcodeScanner, SpeechInput, GoogleAuth, BackupProvider, OnDeviceAi, HomeWidgetBridge, AdService. Mỗi interface có bản giả để test.
5. **Không code tính năng khi chưa có đặc tả và thiết kế UX đã duyệt** (xem mục "Quy trình bắt buộc" bên dưới). Chủ dự án duyệt và gộp; agent không tự gộp vào `main`, không tự phát hành.
6. Commit nhỏ, thông điệp tiếng Việt, mô tả việc đã làm.
7. Xong việc nào thì cập nhật `docs/status.md` trong cùng PR.

## Quy trình bắt buộc cho mỗi tính năng

Agent **dừng lại chờ chủ dự án duyệt** ở cuối bước 1 và bước 2. Không gộp các bước, không làm trước bước sau.

| Bước | Đầu ra | Dừng chờ duyệt |
|---|---|---|
| 1. Đặc tả | `docs/specs/<tính-năng>.md` theo `_template.md`: mục tiêu, ràng buộc, nguồn, thiết kế kỹ thuật (dữ liệu, interface, luồng xử lý), tiêu chí đạt, ngoài phạm vi | **Có** |
| 2. Thiết kế UX | `docs/design/<tính-năng>.md` theo `docs/design/_template.md`: luồng người dùng, danh sách màn hình, wireframe từng màn (ASCII hoặc Mermaid), mọi trạng thái (trống, đang tải, lỗi, cảnh báo), nội dung chữ tiếng Việt; tuân `docs/design/README.md` | **Có** |
| 3. Test | Chuyển tiêu chí đạt thành test (engine: thêm vào `reference_engine.py` và fixtures) | Không |
| 4. Code | Trên nhánh riêng, tới khi test và CI qua | Không |
| 5. PR | Mô tả liên kết đặc tả và thiết kế; chủ dự án duyệt và gộp | **Có** |

- Đặc tả và thiết kế được coi là đã duyệt khi dòng `Trạng thái` ở đầu tệp là `Đã duyệt` (chủ dự án đổi, hoặc agent đổi sau khi chủ dự án nói rõ "duyệt").
- Việc không cần bước 1–2: hạ tầng (CI, thư mục nền tảng, nâng phiên bản gói), sửa lỗi nhỏ không đổi giao diện hay hành vi, sửa tài liệu. Ghi rõ trong PR là việc loại này.
- Màn hình trong `app/lib/ui/` hiện tại là **khung tạm** để thử engine, chưa qua thiết kế UX; sẽ làm lại theo thiết kế đã duyệt.
- Khi được giao một tính năng mà chưa có đặc tả, câu trả lời đầu tiên của agent là bản nháp đặc tả, không phải code.

## Giới hạn đã biết

- **Chỉ làm dữ liệu cho người từ 18 tuổi.** NASEM xếp người 18 tuổi vào nhóm 14–18, nên app giữ RDA/UL của nhóm này cho người 18 tuổi, nhưng **không có mục tiêu calo** cho tuổi 18 (giới hạn đã chấp nhận; không làm phương trình EER cho dưới 19 tuổi).
- **Đối tượng mở rộng được bằng dữ liệu:** nhóm tham chiếu (tuổi, giới, mang thai, cho con bú) và việc nhóm nào có mục tiêu calo, khoảng AMDR, cách tính đạm được định nghĩa trong gói dữ liệu, không viết cứng mốc tuổi trong engine. Thêm đối tượng = thêm số liệu có nguồn, ô đối chiếu, ca test, chủ dự án duyệt, phát hành bản cập nhật. Hồ sơ dưới 18 tuổi vẫn cấm cho tới khi chủ dự án đổi quyết định sản phẩm.
- Mang thai dưới 19 tuổi: NASEM không có phương trình riêng → không tính calo.
- Gợi ý mức vận động từ buổi tập là **quy tắc của app**, không phải chuẩn (phút tương đương vừa/ngày: ≥30 nhẹ, ≥60 vừa, ≥120 nhiều); người dùng tự xác nhận.
- Prompt API của Gemini Nano chưa công bố hỗ trợ tiếng Việt → trên Android dùng giải thích theo mẫu làm mặc định.
