# ADR 0012: Flavor

Trạng thái: Đã duyệt (28/11/2026). Nguồn: [refactor-plan.md](../refactor-plan.md), mục 2, dòng 12.

## Quyết định

`dev` (`vn.wholewell.app.dev`, "WholeWell Dev") và `prod`. Bản dev cần **thêm một Android OAuth client** (package + SHA-1 của khóa debug và khóa ký dev) **trong cùng dự án Google Cloud**

## Không chọn

Một bản duy nhất

## Lý do và hệ quả

Thiếu client thì Drive không chạy trên bản dev

## Thực hiện

PR 0f.
