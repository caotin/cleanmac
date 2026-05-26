# macOS Dev Cleanup App

## Summary
- Xây dựng một `native macOS app` standalone/notarized cho dev cleanup, với UX nhanh từ toolbar/menu bar và dữ liệu máy hiện tại đọc trực tiếp từ hệ thống.
- V1 vẫn giữ 3 trụ cột: `memory cleanup`, `node_modules cleanup`, `Docker cleanup`, nhưng bổ sung thao tác nhanh để dùng hằng ngày.

## Key Changes
- Toolbar và truy cập nhanh
  - Thêm toolbar có các action chính: `Optimize`, `Clean`, `Settings`.
  - Dùng kiểu `action + menu` để giữ toolbar gọn, nhưng vẫn có menu xổ xuống cho thao tác phụ.
  - `Settings` mở nhanh từ toolbar để chỉnh rule, ignore list, quyền truy cập, và preset cleanup.
  - Các action trên toolbar phải phản hồi ngay cả khi scan đang chạy, miễn là không xung đột trạng thái.

- Machine overview
  - Bổ sung màn hình “Current Machine” đọc dữ liệu máy hiện tại theo kiểu local, read-only.
  - V1 hiển thị: model máy, chip/CPU, RAM, macOS version, disk free/used, memory pressure, uptime, thermal state, network basic, và trạng thái Docker.
  - Dữ liệu này phục vụ cả dashboard lẫn cảnh báo trước khi cleanup.
  - Cần có refresh thủ công và refresh nền theo chu kỳ ngắn để số liệu không bị stale.

- Core cleanup flows
  - `Memory cleanup`: hybrid mode, vừa chẩn đoán vừa optimize an toàn, có trước/sau để người dùng thấy tác động.
  - `Node modules cleanup`: scan toàn bộ `node_modules`, nhóm theo project/path/size/last modified, cho phép chọn folder để xóa.
  - `Docker cleanup`: tách riêng `images`, `stopped containers`, `volumes unused`, `build cache`, cho phép chọn từng nhóm.

- Safety
  - Mặc định `preview + confirm`.
  - Log toàn bộ cleanup.
  - Chỉ xóa theo batch sau khi người dùng xác nhận rõ.
  - Các mục có rủi ro cao phải có cảnh báo riêng.

## Test Plan
- Kiểm tra toolbar actions mở đúng màn hình và không bị lỗi trạng thái khi scan đang chạy.
- Kiểm tra `Settings` mở nhanh, lưu được preset/rule/ignore list, và không làm mất trạng thái app.
- Kiểm tra module đọc machine info trên nhiều máy/config khác nhau: Intel, Apple Silicon, laptop, desktop.
- Kiểm tra số liệu máy refresh đúng, không block UI, và có fallback khi một API hệ thống không đọc được.
- Kiểm tra lại luồng scan/xóa cho `node_modules`, Docker, và memory optimize theo mô hình preview/confirm.

## Assumptions
- Toolbar `action + menu` là lựa chọn mặc định vì cân bằng giữa tốc độ và độ gọn UI.
- `Machine overview` là read-only, lấy từ local APIs của macOS, không gửi dữ liệu ra ngoài.
- `Full overview` nghĩa là app ưu tiên nhiều thông số hữu ích cho dev cleanup hơn là chỉ vài thống kê cơ bản.
- V1 ưu tiên độ an toàn, tính giải thích được, và thao tác nhanh từ toolbar hơn là tự động xóa mạnh tay.
