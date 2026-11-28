# Thiết kế UX: Chụp nhãn, mã vạch, kho, hạn dùng

Trạng thái: Đã duyệt (25/11/2026; Bổ sung 1: 28/11/2026)  <!-- Nháp | Đã duyệt -->
Đặc tả: [docs/specs/label-scan-inventory.md](../specs/label-scan-inventory.md)

## Luồng người dùng

```mermaid
flowchart LR
  BS[Tab Bổ sung] -->|"+ Thêm sản phẩm"| QMV[Quét mã vạch]
  QMV -->|Khớp sản phẩm đã lưu| CTSP[Chi tiết sản phẩm]
  QMV -->|Chưa có / Bỏ qua| CN[Chụp hoặc chọn ảnh nhãn]
  QMV -->|Nhập tay| XNT[Xác nhận thành phần]
  CN -->|OCR xong| XNT
  XNT -->|Đã xác nhận mọi dòng| TTSP[Thông tin sản phẩm & hộp đầu]
  TTSP -->|Lưu| CTSP

  CTSP -->|Sửa thành phần| XNT
  CTSP -->|Hộp ›| QLH[Quản lý hộp]
  CTSP -->|Ghi lần uống| G1[Ghi bổ sung]

  FAB[Nút Ghi] -->|2: Bổ sung| GBS[Chọn sản phẩm / Ghi một lần]
  GBS -->|3: Sản phẩm| G1
  G1 -->|Chỉ còn hộp hết hạn| HD[Hỏi trừ hộp hết hạn]
  HD -->|Trừ / Không trừ| KQ{Vượt giới hạn?}
  G1 -->|Còn hạn hoặc kho = 0| KQ
  KQ -->|Không vượt| SN[Thông báo ngắn + Hoàn tác]
  KQ -->|Vượt giới hạn| BC[Bảng cảnh báo giới hạn]
```

## Danh sách màn hình

| Màn | Mục đích | Vào từ | Ra tới |
|---|---|---|---|
| **Bổ sung** (Tab 3/4) | Xem danh sách sản phẩm trong tủ, số còn lại, sắp hết, hết hạn | Thanh điều hướng dưới | Quét mã vạch, Chi tiết sản phẩm |
| **Quét mã vạch** | Tìm nhanh sản phẩm đã lưu bằng mã vạch | Tab Bổ sung | Chi tiết sản phẩm, Chụp/chọn ảnh nhãn, Xác nhận thành phần |
| **Chụp / chọn ảnh nhãn** | Chụp bằng camera hoặc chọn ảnh bảng thành phần từ thư viện | Quét mã vạch, Chi tiết sản phẩm | Xác nhận thành phần |
| **Xác nhận thành phần** | Rà soát dòng OCR / nhập tay, sửa chất-dạng-lượng-đơn vị, xác nhận từng dòng | Ảnh nhãn, Nhập tay, Chi tiết sản phẩm | Thông tin sản phẩm, Chi tiết sản phẩm |
| **Thông tin sản phẩm** | Nhập tên, đơn vị đếm, số đơn vị/khẩu phần, hộp đầu tiên | Xác nhận thành phần, Chi tiết sản phẩm | Chi tiết sản phẩm |
| **Chi tiết sản phẩm** | Xem thành phần chuẩn hóa + số gốc, hộp, ghi lần uống, lưu trữ | Tab Bổ sung, Quét mã vạch | Xác nhận thành phần, Quản lý hộp, Ghi bổ sung |
| **Quản lý hộp** | Xem, thêm, sửa, xóa hộp (số còn lại, hạn dùng `MM/YYYY`) | Chi tiết sản phẩm | Chi tiết sản phẩm |
| **Ghi bổ sung / Sửa lần uống** | Ghi nhanh 1 lần uống (sản phẩm có sẵn hoặc ghi một lần) hoặc sửa trong Nhật ký | Bảng `Ghi`, Chi tiết sản phẩm, Nhật ký | Màn trước; Bảng cảnh báo (nếu vượt) |

## Wireframe

### 1. Tab Bổ sung & Thanh điều hướng 4 tab

```
┌──────────────────────────────┐
│ Bổ sung                      │
├──────────────────────────────┤
│ Canxi D3                     │
│ Còn 42 viên · HSD 08/2027  › │
│ ──────────────────────────── │
│ Vitamin tổng hợp             │
│ Còn 5 viên · Sắp hết       › │
│ ──────────────────────────── │
│ Magie                        │
│ Kho đã hết · Đã hết hạn: 10› │
│                              │
│             [+ Thêm sản phẩm]│
├──────────────────────────────┤
│ Hôm nay  Nhật ký  Bổ sung Tôi│
└──────────────────────────────┘
```

- Nhãn thanh điều hướng dưới giữ ≤7 ký tự (`Hôm nay`, `Nhật ký`, `Bổ sung`, `Tôi`).
- Khi chưa có sản phẩm nào: hiện `EmptyState` `"Chưa có sản phẩm bổ sung nào."` + nút `[+ Thêm sản phẩm]`.
- Sản phẩm còn hạn: hiện `"Còn {n} {đơn vị}"`; nếu có dự kiến ngày hết ≤7 ngày hiện kèm `"· Sắp hết"`; nếu chưa đủ dữ liệu ước lượng (chưa có lịch & 14 ngày qua chưa uống) thì chỉ hiện `"Còn {n} {đơn vị}"` và HSD sớm nhất (nếu có).
- Nếu có hộp đã hết hạn: hiện `"Đã hết hạn: {n} {đơn vị}"` bằng chữ; không dùng link cửa hàng.

### 2. Quét mã vạch & Lấy ảnh nhãn

```
┌──────────────────────────────┐
│ ←  Thêm sản phẩm             │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │                          │ │
│ │   Khung quét mã vạch     │ │
│ │                          │ │
│ └──────────────────────────┘ │
│ Đưa mã vạch vào khung để tìm │
│ sản phẩm đã lưu.             │
│                              │
│ [ Chụp ảnh bảng thành phần ] │
│ [ Chọn ảnh từ thư viện ]     │
│      Nhập tay từng dòng      │
└──────────────────────────────┘
```

- Quét trúng mã vạch khớp `productByBarcode`: mở ngay **Chi tiết sản phẩm** (hiện dòng ngắn `"Đã tìm thấy sản phẩm đã lưu."`, người dùng có thể bấm `Hộp ›` để thêm hộp mới).
- Quét chưa thấy sản phẩm: hiện dòng `"Chưa có sản phẩm với mã vạch này. Hãy chụp hoặc chọn ảnh nhãn."` (giữ lại chuỗi `barcode` để gắn khi lưu sản phẩm mới).
- **Từ chối quyền Camera:** Không kẹt màn hình; hiện thông báo ngắn `"Chưa có quyền máy ảnh."` kèm nút `[Mở cài đặt]`, giữ nguyên hai nút `[Chọn ảnh từ thư viện]` và `Nhập tay từng dòng`.
- Bấm `[Chụp ảnh bảng thành phần]` → mở camera chụp nhãn → chạy OCR trên máy (`Đang đọc chữ trên nhãn...`). Bấm `[Chọn ảnh từ thư viện]` → chọn ảnh → chạy OCR tương tự.

### 3. Xác nhận thành phần (từng dòng)

```
┌──────────────────────────────┐
│ ←  Xác nhận thành phần       │
├──────────────────────────────┤
│ Kiểm tra và đánh dấu xác nhận│
│ từng dòng trước khi lưu.     │
│                              │
│ [✓] Vitamin D3               │
│     25 µg (nhãn: 1.000 IU)   │
│     cholecalciferol      Sửa │
│ ──────────────────────────── │
│ [ ] Canxi                    │
│     Nhãn: canxi carbonat     │
│     1.250 mg → nguyên tố     │
│     500 mg               Sửa │
│ ──────────────────────────── │
│ [ ] Sắt (⚠ Kiểm lại đơn vị)  │
│     100 mg · cao hơn giới    │
│     hạn an toàn 1 lần    Sửa │
│ ──────────────────────────── │
│ [+ Thêm dòng thành phần]     │
│                              │
│ [ Tiếp tục (1/3 đã xác nhận) ]│
└──────────────────────────────┘
```

- **Chạm `Sửa` hoặc `[+ Thêm dòng thành phần]`** mở bảng sửa dòng:
  - Chọn chất trong danh sách gói dữ liệu hoặc chọn `"Chất khác (không tính giới hạn)"` để nhập tên tự do (`free_name`).
  - Lượng trên nhãn + Đơn vị (`mg`, `µg`, `IU`, `g`).
  - Loại số trên nhãn (khi chất là khoáng chất có bảng hợp chất, hoặc vitamin E/A):
    - `Nguyên tố` (`CompoundKind.elemental`)
    - `Hợp chất` (`CompoundKind.compound` → chọn dạng như `Canxi carbonat (40%)`, `Sắt fumarat (33%)`, ...)
    - `Chưa rõ dạng` (`CompoundKind.unknown` → ghi chú `"Tính giới hạn theo cách thận trọng nhất; so mức khuyến nghị là chưa chắc."`)
  - Nếu nghi nhầm `mg` ↔ `µg` hoặc 1 khẩu phần vượt giới hạn an toàn: hiện cảnh báo vàng hổ phách ngay trong dòng và bảng sửa `"Số này khá lớn so với mức thông thường, hãy kiểm lại đơn vị mg/µg trên nhãn."` (không tự ý sửa số, vẫn cho lưu nếu người dùng xác nhận).
- Nút chính `[Tiếp tục]` **chỉ bật** khi có ít nhất 1 dòng và **mọi dòng đều đã được đánh dấu xác nhận `[✓]`**.

### 4. Thông tin sản phẩm & hộp đầu tiên

```
┌──────────────────────────────┐
│ ←  Thông tin sản phẩm        │
├──────────────────────────────┤
│ Tên sản phẩm *               │
│ [ Vitamin tổng hợp         ] │
│ Mã vạch (tùy chọn)           │
│ [ 8935...                  ] │
│ Đơn vị đếm                   │
│ [ Viên ▾ ]                   │
│ Số đơn vị mỗi khẩu phần *    │
│ [ 1                        ] │
│                              │
│ Hộp đang mở (tùy chọn)       │
│ Số còn lại       Hạn dùng    │
│ [ 60         ]   [ 08/2027 ] │
│                              │
│ [ Lưu sản phẩm ]             │
└──────────────────────────────┘
```

- Đơn vị đếm (`CountUnit`): `Viên`, `Viên nang`, `Viên nang mềm`, `Gói`, `Giọt`, `ml`, `g`.
- Hạn dùng nhập `MM/YYYY` (kiểm hợp lệ tháng `01..12`, năm 4 chữ số), đổi sang `YYYY-MM` khi lưu. Để trống nếu không ghi hạn dùng. Bàn phím số; gõ đủ 2 số tháng thì app tự thêm `/`, chỉ cần gõ tiếp năm (số đầu từ 2 đến 9 thì thêm `0` phía trước: `8` thành `08/`); xóa lùi qua `/` không bị thêm lại (chủ dự án yêu cầu 28/11/2026).

### 5. Chi tiết sản phẩm & Quản lý hộp

```
┌──────────────────────────────┐  ┌──────────────────────────────┐
│ ←  Canxi D3              [⋮] │  │ ←  Hộp: Canxi D3             │
├──────────────────────────────┤  ├──────────────────────────────┤
│ 1 khẩu phần = 1 viên         │  │ Còn hạn                      │
│ Còn 42 viên · HSD 08/2027  › │  │  Hộp #1 · Còn 42 viên        │
│ (Chạm để xem / thêm hộp)     │  │  HSD 08/2027          Sửa ›  │
│                              │  │ ──────────────────────────── │
│ Thành phần mỗi khẩu phần (2) │  │ Đã hết hạn                   │
│ Canxi               500 mg   │  │  Hộp #2 · Còn 10 viên        │
│  canxi carbonat (nhãn 1.250) │  │  HSD 09/2026          Sửa ›  │
│ Vitamin D3          10 µg    │  │                              │
│  nhãn 400 IU                 │  │                              │
│                              │  │                              │
│ [ Sửa thành phần ]           │  │                              │
│ [ Ghi lần uống ]             │  │ [+ Thêm hộp]                 │
└──────────────────────────────┘  └──────────────────────────────┘
```

- Menu `[⋮]` của Chi tiết sản phẩm: `Sửa thông tin sản phẩm`, `Lưu trữ sản phẩm` (hỏi xác nhận `"Ẩn sản phẩm khỏi danh sách? Dữ liệu lịch sử đã uống vẫn được giữ."`).
- Không có nút `Ảnh nhãn ›` (ngoài phạm vi Việc 5).
- Sửa thành phần có ghi chú nhỏ: `"Thay đổi thành phần chỉ áp dụng cho lần uống mới."`
- Bấm `Sửa ›` trên hộp cho phép sửa số còn lại (≥ 0), sửa hạn dùng `MM/YYYY`, hoặc xóa hộp.

### 6. Ghi bổ sung / Ghi một lần & Sửa lần uống

```
┌──────────────────────────────┐
│ ←  Ghi bổ sung               │
├──────────────────────────────┤
│ Chọn sản phẩm                │
│  Canxi D3 (Còn 42 viên)    › │
│  Vitamin tổng hợp (Còn 5)  › │
│  Magie (Kho đã hết)        › │
│ ──────────────────────────── │
│  Ghi một lần (không lưu tủ)› │
└──────────────────────────────┘
```

- Chạm một sản phẩm → màn xác nhận ngắn (mặc định `1 khẩu phần`, `Giờ [ 14:05 ]` là một hàng chạm ≥ 48 dp trong thân màn giống Ghi nước) → bấm `[Lưu]` (đủ **3 chạm** từ nút nổi `Ghi`: `Ghi` → `Bổ sung` → chọn sản phẩm & `Lưu` hoặc `Ghi bổ sung`).
- Nếu `recordDose` / `updateDose` trả về `NeedsExpiredChoice`: hiện hộp thoại:
  - Tiêu đề: `"Trừ vào hộp đã hết hạn?"`
  - Nội dung: `"Sản phẩm này không còn hộp còn hạn. Bạn muốn trừ vào hộp đã hết hạn hay chỉ ghi lần uống?"`
  - Nút: `[Không trừ]` (`ExpiredBoxChoice.skip`), `[Trừ]` (`ExpiredBoxChoice.deduct`).
- Phản hồi sau khi lưu (`DoseRecorded`):
  - Không vượt giới hạn & `shortfall == 0`: `UndoSnack` `"Đã ghi {tên}"` + `[Hoàn tác]`.
  - Không vượt giới hạn & `shortfall > 0`: `UndoSnack` `"Đã ghi {tên} · Kho đã hết"` + `[Thêm hộp]` + `[Hoàn tác]`.
  - **Vượt giới hạn an toàn (kể cả khi `shortfall > 0`):** chỉ hiện **1 phản hồi chính** là bảng cảnh báo giới hạn an toàn (`FoodFeedbackSheet`); nếu `shortfall > 0`, chèn thêm một hàng nhắc trung tính `"Kho đã hết · Thêm hộp"` (kèm nút chữ `Thêm hộp`) gọn bên trong bảng cảnh báo.
- Sửa / Xóa lần uống từ **Nhật ký**: cho sửa số khẩu phần (`updateDose`), giờ uống (`Giờ [ HH:mm ]` trong thân màn), hoặc xóa (`deleteDose`, hoàn trả số viên đã trừ vào hộp).

## Trạng thái

| Màn | Trống | Đang xử lý | Lỗi | Cảnh báo |
|---|---|---|---|---|
| Bổ sung | `"Chưa có sản phẩm bổ sung nào."` + `[+ Thêm sản phẩm]` | Khung tải | `ErrorState` + `[Thử lại]` | Chữ `"Sắp hết"`, `"Đã hết hạn"` |
| Quét mã vạch / Ảnh nhãn | Chưa quét: khung hướng dẫn | `"Đang đọc chữ trên nhãn..."` | Không có quyền camera → nút `[Chọn ảnh từ thư viện]` / `Nhập tay`; OCR không đọc được chữ → `"Không đọc được chữ rõ trên ảnh. Hãy chụp lại hoặc nhập tay."` | Trùng mã vạch đã lưu → mở ngay Chi tiết sản phẩm |
| Xác nhận thành phần | `"Chưa có dòng thành phần nào."` + `[+ Thêm dòng thành phần]` | — | Chưa xác nhận hết dòng → nút Tiếp tục vô hiệu + nhắc `"Hãy đánh dấu xác nhận từng dòng."` | Nghi nhầm `mg`/`µg` hoặc vượt UL 1 khẩu phần → màu vàng hổ phách trên dòng |
| Quản lý hộp | `"Chưa có hộp nào."` + `[+ Thêm hộp]` | — | Hạn dùng sai định dạng → `"Nhập hạn dùng theo tháng/năm (MM/YYYY), tháng từ 01 đến 12."`; số lượng âm → `"Số còn lại không được âm."` | Tách nhóm `Đã hết hạn` |
| Ghi bổ sung | `"Chưa có sản phẩm nào trong tủ."` + nút `Ghi một lần` | `"Đang lưu..."` | Số khẩu phần ≤ 0 → `"Nhập số khẩu phần lớn hơn 0."` | Hộp thoại `Trừ vào hộp đã hết hạn?`; Bảng cảnh báo vượt giới hạn (kèm `"Kho đã hết · Thêm hộp"` nếu `shortfall > 0`) |

## Nội dung chữ

| Vị trí | Chữ hiển thị |
|---|---|
| Tab dưới 3/4 | `Bổ sung` |
| Chưa xác nhận hết dòng | `Kiểm tra và đánh dấu xác nhận từng dòng trước khi lưu.` |
| Cảnh báo đơn vị / UL ở dòng OCR | `Số này khá lớn so với mức thông thường, hãy kiểm lại đơn vị mg/µg trên nhãn.` |
| Hỏi trừ hộp hết hạn | `Trừ vào hộp đã hết hạn?` / `Sản phẩm này không còn hộp còn hạn. Bạn muốn trừ vào hộp đã hết hạn hay chỉ ghi lần uống?` / `[Không trừ]` / `[Trừ]` |
| Kho hết (không vượt giới hạn) | `Đã ghi {tên} · Kho đã hết` (`[Thêm hộp]`, `[Hoàn tác]`) |
| Kho hết (trong bảng cảnh báo vượt giới hạn) | `Kho đã hết · Thêm hộp` |
| Lưu ý sửa thành phần | `Thay đổi thành phần chỉ áp dụng cho lần uống mới.` |
| Dòng chưa rõ dạng | `Chưa rõ dạng: tính giới hạn theo cách thận trọng nhất; so mức khuyến nghị là chưa chắc.` |

## Kiểm theo nguyên tắc (`docs/design/README.md`)

- [x] Lời lẽ đúng vai tham chiếu, không viết tắt chuẩn (không hiện RDA, UL, EER, AMDR trên màn hình)
- [x] Ẩn số calo được tôn trọng (bổ sung không hiện calo)
- [x] Tối đa 3 lần chạm cho thao tác chính (`Ghi` → `Bổ sung` → chọn sản phẩm & `Lưu`)
- [x] Cỡ chữ 200%, vùng chạm 48 dp (`Giờ [ HH:mm ]` là hàng chạm riêng trong thân màn), tương phản AA, không dùng chỉ màu truyền nghĩa
- [x] Không quảng cáo ở màn cảnh báo

## Bổ sung 1: An toàn khi AI đọc nhãn (PR 1)

Trạng thái phần này: Đã duyệt 28/11/2026. Đặc tả: mục "Bổ sung 1" trong [docs/specs/label-scan-inventory.md](../specs/label-scan-inventory.md).

Các màn khác của phần gốc không đổi. Màn `Thêm sản phẩm` không đổi giao diện; chỉ không còn lúc chờ tải mô hình AI.

### B1. Luồng đọc nhãn

```mermaid
flowchart LR
  A[Bấm Đọc thông tin] --> B[Đọc chữ trên ảnh]
  B --> C[Bộ đọc chữ tách dòng]
  B --> D{Mô hình AI có sẵn trên máy?}
  D -->|Không| E[Dùng dòng của bộ đọc chữ]
  D -->|Có| F[AI gợi ý dòng]
  F --> G[So từng dòng AI với chữ trên ảnh, thêm chất AI bỏ sót]
  C --> E
  C --> G
  E --> H[Xác nhận thành phần]
  G --> H
  H -->|Dòng cần kiểm| I[Bảng sửa dòng]
  I -->|Xác nhận dòng này| H
  H -->|Mọi dòng đã xác nhận| J[Thông tin sản phẩm]
```

- Máy chưa có mô hình (hay mô hình đang tải): dùng ngay dòng của bộ đọc chữ, không có thêm lúc chờ, không hiện thông báo gì thêm.

### B2. Màn và trạng thái thay đổi

| Màn | Thay đổi |
|---|---|
| **Xác nhận thành phần** | Dòng ghi chú khi có gợi ý của AI; dòng "cần kiểm" khóa ô đánh dấu, có lời nhắc; dòng đếm số dòng cần kiểm; `Chọn tất cả` / `Xác nhận tất cả` chỉ hiện khi không còn dòng cần kiểm |
| **Bảng sửa dòng** | Đơn vị không chọn sẵn; lời nhắc khi dòng chưa khớp chữ trên ảnh; báo lỗi ngay dưới ô khi thiếu đơn vị hay lượng |
| **Chọn khẩu phần** (món đã lưu) | Trạng thái lỗi khi số liệu đã lưu không đọc được (hiếm, chỉ khi dữ liệu hỏng) |

### B3. Wireframe

#### Xác nhận thành phần (có gợi ý của AI)

```
┌──────────────────────────────┐
│ ←  Xác nhận thành phần       │
├──────────────────────────────┤
│ Kiểm tra và đánh dấu xác nhận│
│ từng dòng trước khi lưu.     │
│ ⓘ Gợi ý do AI trên máy tách  │
│ từ chữ trên ảnh. Hãy so từng │
│ số với nhãn.                 │
│ ⚠ Còn 3 dòng cần kiểm. Bấm   │
│ Sửa ở từng dòng.             │
│                              │
│ [✓] Vitamin D                │
│     25 µg                Sửa │
│ ──────────────────────────── │
│ [–] Vitamin B6               │
│     5 mg                     │
│     ⚠ Chưa thấy số này trong │
│     chữ đọc từ ảnh. Bấm Sửa  │
│     để so với nhãn.      Sửa │
│ ──────────────────────────── │
│ [–] Folate                   │
│     667 · Chưa rõ đơn vị     │
│     ⚠ Chưa đọc được đơn vị.  │
│     Bấm Sửa và chọn đơn vị   │
│     theo nhãn.           Sửa │
│ ──────────────────────────── │
│ [–] Magie                    │
│     ⚠ Chưa có lượng. Bấm Sửa │
│     và nhập theo nhãn.   Sửa │
│ ──────────────────────────── │
│ [+ Thêm dòng thành phần]     │
│ ▸ Chữ đã đọc từ ảnh (24 dòng)│
│                              │
│[ Tiếp tục (1/4 đã xác nhận) ]│
└──────────────────────────────┘
```

- `[–]` là ô đánh dấu bị khóa. Chạm vào dòng bị khóa không làm gì; người dùng bấm `Sửa`. Trình đọc màn hình đọc ô khóa là "Cần kiểm, bấm Sửa".
- **Dòng ghi chú AI** chỉ hiện khi danh sách có gợi ý của AI. Không hiện với kết quả của bộ đọc chữ, thư viện nhãn hay nhập tay.
- **Dòng đếm** `Còn {n} dòng cần kiểm. Bấm Sửa ở từng dòng.` hiện khi `n > 0`, ở chỗ của `Chọn tất cả` / `Xác nhận tất cả`. Hết dòng cần kiểm thì dòng đếm ẩn và nút hiện lại như hiện nay.
- Mỗi dòng hiện **một** lời nhắc, theo thứ tự ưu tiên:
  1. chưa có lượng;
  2. chưa rõ đơn vị;
  3. đơn vị chưa phù hợp với chất (đã có);
  4. chưa khớp chữ trên ảnh;
  5. số khá lớn so với mức thông thường (đã có).

  Lời nhắc 1, 2, 4 dùng khung vàng hổ phách như lời nhắc 5 (`warningContainer`); lời nhắc 3 giữ khung lỗi như hiện nay. Mọi lời nhắc có biểu tượng `⚠` và chữ, không chỉ dùng màu.
- Dòng do bộ đọc chữ thêm vì AI bỏ sót hiện như dòng thường, không có nhãn riêng.
- Sửa xong một dòng qua bảng sửa thì dòng đó được đánh dấu xác nhận và hết lời nhắc 4. Nếu số vẫn khá lớn thì lời nhắc 5 vẫn hiện, như hiện nay.

#### Bảng sửa dòng

```
┌──────────────────────────────┐
│ Sửa dòng thành phần          │
│ ⚠ Chưa thấy số này trong chữ │
│ đọc từ ảnh. So số và đơn vị  │
│ với nhãn rồi bấm Xác nhận    │
│ dòng này.                    │
│                              │
│ Chất dinh dưỡng              │
│ [ Folate                  ▾ ]│
│ Lượng mỗi khẩu phần  Đơn vị  │
│ [ 667             ] [Chọn ▾] │
│                Chọn đơn vị   │
│                theo nhãn.    │
│                              │
│ [     Xác nhận dòng này     ]│
└──────────────────────────────┘
```

- Lời nhắc ở đầu bảng chỉ hiện với dòng AI chưa khớp chữ trên ảnh.
- Ô đơn vị để trống (`Chọn`) với dòng mới, dòng chưa rõ đơn vị, và khi đổi sang chất mà đơn vị cũ không hợp. Không tự chọn đơn vị đầu danh sách.
- Bấm `Xác nhận dòng này`:
  - thiếu đơn vị: chữ lỗi `Chọn đơn vị theo nhãn.` dưới ô đơn vị;
  - lượng trống, bằng 0 hay không phải số: chữ lỗi `Nhập lượng lớn hơn 0.` dưới ô lượng;
  - bảng không đóng; hiện nay bảng lặng lẽ không đóng mà không báo gì.
- Ô đơn vị có nhãn đọc được `Đơn vị`; vùng chạm ≥ 48 dp.

#### Chọn khẩu phần: món đã lưu không đọc được (hiếm)

```
┌──────────────────────────────┐
│ ←  Bánh yến mạch             │
├──────────────────────────────┤
│                              │
│      (biểu tượng cảnh báo)   │
│ Không đọc được số liệu của   │
│ món đã lưu này. Hãy nhập lại │
│ món theo nhãn.               │
│                              │
│ [ Lưu ]  (khóa)              │
└──────────────────────────────┘
```

- Dùng `ErrorState` có sẵn, không có nút `Thử lại` (thử lại vẫn ra cùng kết quả).
- Chỉ xảy ra khi tệp dữ liệu hỏng. Mọi đường ghi món đều lưu đơn vị đọc lại được (có test khứ hồi).

### B4. Trạng thái

| Màn | Trống | Đang xử lý | Lỗi | Cảnh báo |
|---|---|---|---|---|
| Thêm sản phẩm (đọc ảnh) | Như phần gốc | `Đang đọc chữ trên {n} ảnh...`, không còn lúc chờ tải mô hình | Như phần gốc | — |
| Xác nhận thành phần | Như phần gốc | — | Còn dòng cần kiểm: `Tiếp tục` khóa, dòng đếm số dòng cần kiểm | Lời nhắc trên từng dòng theo thứ tự ưu tiên ở B3 |
| Bảng sửa dòng | Dòng mới: chưa chọn chất, đơn vị trống | — | `Chọn đơn vị theo nhãn.`, `Nhập lượng lớn hơn 0.`, `Đơn vị này không phù hợp với chất đã chọn.` (đã có) | Lời nhắc chưa khớp chữ trên ảnh ở đầu bảng |
| Chọn khẩu phần | — | — | Món đã lưu không đọc được: `ErrorState`, `Lưu` khóa | — |

### B5. Nội dung chữ

| Vị trí | Chữ hiển thị |
|---|---|
| Ghi chú khi có gợi ý của AI | `Gợi ý do AI trên máy tách từ chữ trên ảnh. Hãy so từng số với nhãn.` |
| Dòng đếm | `Còn {n} dòng cần kiểm. Bấm Sửa ở từng dòng.` |
| Dòng chưa có lượng | `Chưa có lượng. Bấm Sửa và nhập theo nhãn.` |
| Dòng chưa rõ đơn vị (dòng phụ) | `{lượng} · Chưa rõ đơn vị` |
| Dòng chưa rõ đơn vị (lời nhắc) | `Chưa đọc được đơn vị. Bấm Sửa và chọn đơn vị theo nhãn.` |
| Dòng chưa khớp chữ trên ảnh | `Chưa thấy số này trong chữ đọc từ ảnh. Bấm Sửa để so với nhãn.` |
| Ô đánh dấu bị khóa (trình đọc màn hình) | `Cần kiểm, bấm Sửa` |
| Đầu bảng sửa dòng (dòng chưa khớp) | `Chưa thấy số này trong chữ đọc từ ảnh. So số và đơn vị với nhãn rồi bấm Xác nhận dòng này.` |
| Ô đơn vị trống | `Chọn` (nhãn ô: `Đơn vị`) |
| Lỗi thiếu đơn vị | `Chọn đơn vị theo nhãn.` |
| Lỗi lượng | `Nhập lượng lớn hơn 0.` |
| Món đã lưu không đọc được | `Không đọc được số liệu của món đã lưu này. Hãy nhập lại món theo nhãn.` |

Mục B1.8 của đặc tả (lượng trên bảng Supplement Facts là lượng nguyên tố) làm trong PR 1 và không thêm chữ mới. Dòng chưa rõ dạng hiện `Chưa rõ dạng · …` và lời nhắc `Chưa rõ dạng: tính giới hạn theo cách thận trọng nhất; so mức khuyến nghị là chưa chắc.` như phần gốc.

### B6. Kiểm theo nguyên tắc (`docs/design/README.md`)

- [x] Lời lẽ đúng vai tham chiếu, không viết tắt chuẩn. "AI" không phải tên chuẩn; ghi rõ "AI trên máy".
- [x] Ẩn số calo được tôn trọng (bổ sung không hiện calo; màn Chọn khẩu phần ở trạng thái lỗi không hiện số).
- [x] Tối đa 3 lần chạm cho thao tác chính: ghi lần uống không đổi. Thêm sản phẩm có thêm chạm cho dòng cần kiểm; chấp nhận được vì đây là bước an toàn, không phải thao tác ghi hằng ngày.
- [x] Cỡ chữ 200%, vùng chạm 48 dp, tương phản AA, không dùng chỉ màu truyền nghĩa (lời nhắc có `⚠` và chữ; ô khóa có nhãn cho trình đọc màn hình).
- [x] Không quảng cáo ở màn cảnh báo.
- [x] Mọi dòng do OCR hay AI đọc đều phải được người dùng xác nhận trước khi lưu.
