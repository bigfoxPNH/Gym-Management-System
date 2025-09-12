# QR Check-in/Checkout Feature

## Tổng quan

Tính năng QR Check-in/Checkout cho phép thành viên sử dụng mã QR để check-in/checkout tại phòng gym một cách nhanh chóng và an toàn.

## Cách hoạt động

### 1. QR Code cho thành viên

- Mỗi thành viên có một QR code duy nhất chứa thông tin:
  - User ID
  - Email
  - Timestamp tạo QR
  - Type: "gym_checkin"

### 2. Quy trình Check-in/Checkout

1. Thành viên mở app → Profile → QR Code → Tab "Check-in"
2. Hiển thị QR code cho nhân viên quét
3. Nhân viên sử dụng trang Admin → Checkin/Checkout
4. Chọn "QR Check-in" hoặc "QR Check-out"
5. Quét QR code của thành viên
6. Hệ thống tự động:
   - Kiểm tra tính hợp lệ của QR
   - Xác minh thành viên có thẻ tập đang hoạt động
   - Ghi nhận vào Firebase
   - Hiển thị thông báo kết quả

## Files liên quan

### 1. Services

- `lib/services/qr_checkin_service.dart`: Xử lý logic QR và Firebase

### 2. UI Components

- `lib/widgets/qr_scanner_widget.dart`: Widget quét QR code
- `lib/views/profile/profile_view.dart`: Hiển thị QR cho user
- `lib/views/admin/checkin_checkout_view.dart`: Giao diện admin

### 3. Dependencies

- `mobile_scanner: ^5.2.3`: Package quét QR code
- `qr_flutter: ^4.1.0`: Package tạo QR code

## Cấu trúc dữ liệu

### QR Data Format

```json
{
  "type": "gym_checkin",
  "userId": "user123",
  "email": "user@example.com",
  "timestamp": 1694518800000
}
```

### Checkin Record Format

```json
{
  "userId": "user123",
  "userName": "Nguyễn Văn A",
  "userEmail": "user@example.com",
  "type": "checkin", // hoặc "checkout"
  "method": "qr_scan",
  "membershipId": "membership123",
  "membershipName": "Hội viên cơ bản 1",
  "membershipEndDate": "2025-12-31T23:59:59Z",
  "timestamp": "server_timestamp",
  "createdAt": "server_timestamp",
  "notes": ""
}
```

## Validation Logic

### 1. QR Code Validation

- Kiểm tra format JSON hợp lệ
- Xác minh `type` = "gym_checkin"
- Kiểm tra `userId` tồn tại

### 2. Membership Validation

- Query collection `membership_purchases`
- Lọc theo `userId` và `status` = "active"
- Kiểm tra `endDate` > hiện tại
- Trả về thông tin membership đầu tiên còn hạn

### 3. Error Handling

- QR không hợp lệ
- User không tồn tại
- Không có thẻ tập hoạt động
- Lỗi kết nối Firebase

## Quyền truy cập

### User (Member)

- Xem QR code của chính mình
- Không thể quét QR của người khác

### Admin/Staff

- Quét QR code của tất cả thành viên
- Xem lịch sử check-in/checkout
- Thống kê theo ngày

## Bảo mật

### 1. QR Code Security

- Chứa timestamp để tránh replay attack
- Không chứa thông tin nhạy cảm
- Chỉ có thể sử dụng với thẻ tập còn hạn

### 2. Firebase Security

- Rules kiểm tra quyền truy cập
- Validate dữ liệu trước khi ghi
- Audit trail cho mọi giao dịch

## Thống kê

### Daily Stats

- Tổng số check-in trong ngày
- Tổng số check-out trong ngày
- Số lượng khách unique
- Tổng số record

### Usage

```dart
final stats = await QRCheckinService.getTodayCheckinStats();
print('Check-ins: ${stats['totalCheckins']}');
print('Check-outs: ${stats['totalCheckouts']}');
print('Unique visitors: ${stats['uniqueVisitors']}');
```

## Troubleshooting

### QR Scanner không hoạt động

1. Kiểm tra quyền camera
2. Đảm bảo có ánh sáng đủ
3. QR code không bị mờ/hỏng

### Validation thất bại

1. Kiểm tra kết nối internet
2. Xác minh thẻ tập còn hạn
3. Kiểm tra format QR code

### Performance

- QR scanner tự động tạm dừng sau khi quét
- Cache membership data để giảm API calls
- Batch writes cho multiple checkins
