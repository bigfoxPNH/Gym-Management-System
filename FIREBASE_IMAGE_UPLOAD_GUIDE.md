# Hướng Dẫn Sử Dụng Tính Năng Upload Ảnh với Firebase Storage

## Tính Năng Mới

- **Upload ảnh trực tiếp từ thiết bị** lên Firebase Storage
- **Không còn phụ thuộc vào link ảnh bên ngoài** (tránh lỗi CORS)
- **Giao diện thân thiện** với preview ảnh ngay lập tức
- **Hỗ trợ cả chụp ảnh và chọn từ thư viện**

## Cách Sử Dụng

### 1. Tạo Tin Tức Mới

- Vào **Admin Panel** → **Quản Lý Bản Tin** → **Tạo Mới**
- Phần **Hình Ảnh Chính**: Click vào khung "Nhấn để chọn ảnh"
- Chọn nguồn ảnh:
  - **Thư viện ảnh**: Chọn từ thiết bị
  - **Chụp ảnh**: Chụp trực tiếp (chỉ trên mobile)

### 2. Upload Ảnh

- Sau khi chọn ảnh, hệ thống sẽ tự động:
  - Upload lên Firebase Storage
  - Tạo URL an toàn
  - Hiển thị preview ngay lập tức
- Có thể thay đổi ảnh bằng nút "Thay đổi ảnh"
- Xóa ảnh bằng nút "X" ở góc ảnh

### 3. Lưu Tin Tức

- Điền đầy đủ thông tin khác
- Nhấn **Lưu** để hoàn tất

## Ưu Điểm

✅ **Không còn lỗi CORS** - ảnh được lưu trực tiếp trên Firebase
✅ **Tốc độ tải nhanh** - CDN của Google Firebase
✅ **Bảo mật cao** - chỉ ảnh được phép mới hiển thị
✅ **Giao diện trực quan** - thấy ngay ảnh đã chọn
✅ **Tự động resize** - tối ưu chất lượng và dung lượng

## Lưu Ý Kỹ Thuật

- Ảnh được tự động nén xuống chất lượng 85%
- Kích thước tối đa: 1920x1080px
- Định dạng hỗ trợ: JPG, PNG
- Lưu trữ trong thư mục: `news_images/` trên Firebase Storage

## Khắc Phục Sự Cố

- **Không upload được**: Kiểm tra kết nối internet
- **Ảnh không hiển thị**: Đợi vài giây để Firebase xử lý
- **Lỗi permission**: Kiểm tra cấu hình Firebase Storage rules

---

**Phiên bản**: 1.0.0
**Ngày cập nhật**: Hôm nay
**Tương thích**: Web Chrome, Mobile Android/iOS
