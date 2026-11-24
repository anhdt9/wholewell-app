# WholeWell – app sức khỏe cá nhân hóa (RDA, UL, ODA)

Mọi dữ liệu ở trên máy. Engine thuần Dart, không mạng, không I/O.

## Tài liệu

- [Plan: hướng tiếp cận và lộ trình](docs/plan.md)
- [Công cụ cần cho dự án](docs/tools.md)
- [Trạng thái và việc tiếp theo](docs/status.md)
- [AGENTS.md](AGENTS.md): ngữ cảnh và quy tắc cho agent (CLAUDE.md, GEMINI.md trỏ về đây)

## Làm việc với Claude Code trong Antigravity

1. Cài extension **Dart**, **Flutter**, **Claude Code** trong Antigravity; mở thư mục repo.
2. Đăng nhập Claude Code, rồi cài plugin Flutter chính thức trong terminal:
   ```bash
   claude plugin marketplace add flutter/agent-plugins
   claude plugin install dart-flutter@dart-flutter
   ```
3. Dart MCP server đã khai báo sẵn trong `.mcp.json` (Claude Code) và `.agents/mcp_config.json` (agent của Antigravity); chấp nhận khi được hỏi.
4. Câu mở đầu gợi ý: *"Đọc docs/status.md và làm việc tiếp theo."*

```
docs/                      plan, công cụ, trạng thái, specs/
tools/                     Python: sinh và kiểm tra gói dữ liệu, bản tham chiếu engine
  build_pack.py            nguồn số liệu (RDA/AI, UL, EER 2023, AMDR, đường bổ sung, MET)
  verify_pack.py           kiểm cấu trúc + 102 ô đối chiếu với bảng NASEM gốc
  reference_engine.py      engine viết lại bằng Python → test/fixtures/cases.json
packages/health_engine/    engine Dart + test (đọc fixtures do Python sinh)
app/                       MVP Flutter: hồ sơ, nhật ký ăn, bổ sung, buổi tập, tổng kết
```

## Chạy

```bash
# 1. Sinh và kiểm gói dữ liệu (mỗi khi sửa số liệu)
python3 tools/build_pack.py && python3 tools/verify_pack.py && python3 tools/reference_engine.py

# 2. Test engine
cd packages/health_engine && dart pub get && dart test

# 3. App (lần đầu tạo thư mục nền tảng)
cd app && flutter create --platforms=android,ios,windows,macos --org vn.wholewell . \
  && flutter pub get && flutter test && flutter run
```

## Engine làm gì

| Phần | Nguồn | Ghi chú |
|---|---|---|
| RDA/AI vi chất, 16 nhóm (14–18 tuổi đến >70, mang thai, cho con bú) | NASEM qua NIH ODS | AI hiển thị "ước tính"; đạm người 19+ = 0,8 g/kg |
| UL đúng phạm vi | NASEM | Magie: chỉ từ bổ sung. Niacin, vitamin E: dạng tổng hợp. Vitamin A: chỉ retinol. Folate: chỉ axit folic. Cờ theo ngày và trung bình 7 ngày |
| Mục tiêu calo (EER) | NASEM 2023 | Người 19+; mang thai quý 1 dùng phương trình nữ, quý 2–3 cộng năng lượng tích lũy theo BMI; cho con bú 0–6 tháng +540−140, 7–12 tháng +380 |
| Tỷ lệ đạm, béo, bột đường | AMDR (NASEM) | 19+: 10–35 / 20–35 / 45–65 %; 14–18: 10–30 / 25–35 / 45–65 % |
| Đường bổ sung | Dietary Guidelines 2025–2030 | ≤10 g mỗi bữa |
| Calo buổi tập, phút vừa/mạnh | 2024 Adult Compendium, PAG bản 2 | 57 hoạt động phổ biến |
| Gợi ý mức vận động | **Quy tắc của app** | Phút tương đương vừa/ngày (7 ngày): ≥30 nhẹ, ≥60 vừa, ≥120 nhiều. Người dùng tự xác nhận |
| Đổi đơn vị IU | NIH ODS | D: 0,025; A retinol và beta-caroten bổ sung: 0,3; E: 0,67 tự nhiên, 0,45 tổng hợp |

## Giới hạn hiện tại

- Người 18 tuổi: có RDA/UL (nhóm 14–18) nhưng **chưa có mục tiêu calo**. Phương trình 14–18 của NASEM 2023 có hệ số tuổi của nữ cần đối chiếu thêm, nên engine trả `NotComputed` thay vì đoán.
- App hướng tới người khỏe mạnh; người dùng thuốc theo chỉ định của bác sĩ hoặc có bệnh mạn tính dùng ở chế độ thận trọng. MVP: từ 18 tuổi, không mang thai, không cho con bú; giai đoạn 2: trẻ em từ 1 tuổi, mang thai, cho con bú. Nhóm mang thai, cho con bú đã có trong gói và engine.
- Lưu trữ đang ở bộ nhớ (`InMemoryJournalRepository`). Bước sau: drift + SQLite3MultipleCiphers.
- Chưa có cơ sở dữ liệu món ăn (USDA FoodData Central), OCR nhãn, mã vạch, sao lưu Drive, ODA.
- Code Dart chưa được biên dịch trong môi trường soạn (không cài được Dart SDK ở đó). Logic đã kiểm chéo qua bản Python; chạy `dart test` và `flutter test` là bước kiểm đầu tiên.
