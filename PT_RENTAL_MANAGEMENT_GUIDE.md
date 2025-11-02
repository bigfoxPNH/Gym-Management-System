# PT Rental Management - Hướng dẫn sử dụng

## 📋 Tổng quan

Đã thêm tính năng **Quản lý đơn thuê PT** vào PT Dashboard. PT có thể:

- ✅ Xem tất cả đơn thuê PT (pending/approved/active/completed/cancelled)
- ✅ Chấp nhận hoặc từ chối đơn thuê
- ✅ Gửi phản hồi cho học viên
- ✅ Xem chi tiết đơn thuê
- ✅ Liên hệ học viên (sẵn sàng mở rộng)

## 📁 Files đã tạo/sửa

### Files mới

1. **lib/views/pt/pt_rental_management_tab.dart**

   - Tab quản lý đơn thuê PT
   - UI hiển thị danh sách đơn thuê
   - Chức năng approve/reject
   - Detail view

2. **lib/views/pt/pt_dashboard_tabs_view.dart**
   - PT Dashboard với TabBar (2 tabs)
   - Tab 1: Tổng quan (Dashboard gốc)
   - Tab 2: Quản lý đơn thuê PT

### Files đã sửa

1. **lib/routes/app_pages.dart**

   - Thay đổi route `/pt/dashboard` từ `PTDashboardView` → `PTDashboardTabsView`

2. **firestore.indexes.json**
   - Thêm composite index cho `trainer_rentals`:
     ```json
     {
       "collectionGroup": "trainer_rentals",
       "queryScope": "COLLECTION",
       "fields": [
         { "fieldPath": "trainerId", "order": "ASCENDING" },
         { "fieldPath": "createdAt", "order": "DESCENDING" }
       ]
     }
     ```

## 🎯 Cách sử dụng

### 1. Truy cập tính năng

- Đăng nhập với tài khoản PT
- Dashboard sẽ hiển thị với 2 tabs:
  - **Tổng quan**: Thống kê, học viên, đánh giá
  - **Đơn thuê PT**: Quản lý đơn thuê

### 2. Xem đơn thuê

- Click tab **"Đơn thuê PT"**
- Filter theo trạng thái:
  - **Tất cả**: Hiển thị tất cả đơn
  - **Chờ duyệt** (pending): Đơn mới cần xét duyệt
  - **Đã duyệt** (approved): Đơn đã chấp nhận
  - **Đang hoạt động** (active): Đơn đang thực hiện
  - **Hoàn thành** (completed): Đơn đã hoàn tất
  - **Đã hủy** (cancelled): Đơn bị từ chối/hủy

### 3. Xem chi tiết đơn

- Click vào card đơn thuê
- Modal hiển thị:
  - Thông tin học viên
  - Chi tiết đơn thuê (ngày, giờ, gói, giá)
  - Ghi chú từ học viên
  - Phản hồi của PT (nếu có)

### 4. Chấp nhận đơn thuê

- Với đơn **"Chờ duyệt"**, click nút **"Chấp nhận"**
- Dialog hiển thị:
  - Nhập phản hồi (tùy chọn)
  - Ví dụ: "Tôi đã nhận được đơn, hãy liên hệ để lên lịch buổi đầu tiên"
- Click **"Xác nhận"**
- Trạng thái đơn → **"Đã duyệt"** (approved)

### 5. Từ chối đơn thuê

- Với đơn **"Chờ duyệt"**, click nút **"Từ chối"**
- Dialog hiển thị:
  - Nhập lý do từ chối (bắt buộc)
  - Ví dụ: "Lịch tập của tôi đã đầy trong khoảng thời gian này"
- Click **"Từ chối"**
- Trạng thái đơn → **"Đã hủy"** (cancelled)

### 6. Liên hệ học viên

- Với đơn **"Đã duyệt"** hoặc **"Đang hoạt động"**
- Click nút **"Liên hệ học viên"**
- Chọn phương thức:
  - 📞 Gọi điện
  - 💬 Nhắn tin
  - _(Chức năng sẽ được bổ sung sau)_

## 🔧 Cấu trúc dữ liệu

### TrainerRental Model

```dart
class TrainerRental {
  String id;                    // Document ID
  String userId;                // ID học viên
  String userName;              // Tên học viên
  String trainerId;             // ID PT (document ID)
  String trainerName;           // Tên PT

  DateTime startDate;           // Ngày bắt đầu
  DateTime endDate;             // Ngày kết thúc
  int soGio;                    // Số giờ thuê
  double tongTien;              // Tổng tiền
  String goiTap;                // Gói: personal/group/online

  String trangThai;             // pending/approved/active/completed/cancelled
  String? ghiChu;               // Ghi chú từ học viên
  String? phanHoi;              // Phản hồi từ PT

  List<TrainerSession> sessions; // Các buổi tập
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Trạng thái (trangThai)

- **pending**: Đơn mới, chờ PT xét duyệt
- **approved**: PT đã chấp nhận
- **active**: Đang thực hiện các buổi tập
- **completed**: Hoàn thành tất cả buổi tập
- **cancelled**: Bị từ chối hoặc hủy

## 🔐 Firestore Rules

Đã có trong `firestore.rules`:

```javascript
match /trainer_rentals/{rentalId} {
  // Đọc: Học viên, PT liên quan, hoặc Admin
  allow read: if isSignedIn() &&
    (resource.data.userId == request.auth.uid ||
     resource.data.trainerId == request.auth.uid ||
     isAdmin());

  // Tạo: Học viên đã đăng nhập
  allow create: if isSignedIn() &&
    request.resource.data.userId == request.auth.uid;

  // Cập nhật: PT hoặc Admin
  allow update: if isSignedIn() &&
    (resource.data.trainerId == request.auth.uid || isAdmin());

  // Xóa: Chỉ Admin
  allow delete: if isAdmin();
}
```

**⚠️ Lưu ý**: Do `trainerId` lưu document ID (không phải auth UID), rule update có thể không khớp. Có 2 giải pháp:

1. Cho phép tất cả signed-in users update (với validation logic ở client)
2. Thêm trường `trainerAuthUid` trong document để match với `request.auth.uid`

## 📊 Composite Index

Đã deploy composite index cho query:

```dart
.collection('trainer_rentals')
  .where('trainerId', isEqualTo: trainerId)
  .orderBy('createdAt', descending: true)
```

Index:

- **Collection**: trainer_rentals
- **Fields**: trainerId (ASC) + createdAt (DESC)
- **Status**: ✅ Đã deploy

## 🧪 Test Cases

### Test 1: Xem danh sách đơn thuê

1. Login với PT account
2. Click tab "Đơn thuê PT"
3. Kiểm tra: Hiển thị tất cả đơn thuê có `trainerId` = PT document ID
4. Pull-to-refresh để reload

### Test 2: Filter theo trạng thái

1. Ở tab "Đơn thuê PT"
2. Click từng filter chip: Chờ duyệt, Đã duyệt, etc.
3. Kiểm tra: Chỉ hiển thị đơn có trạng thái tương ứng

### Test 3: Chấp nhận đơn

1. Tạo đơn thuê với member account (trainerId = PT document ID, trangThai = 'pending')
2. Login PT, vào tab "Đơn thuê PT"
3. Click "Chấp nhận" trên đơn pending
4. Nhập phản hồi (optional), click "Xác nhận"
5. Kiểm tra Firestore: trangThai = 'approved', phanHoi updated

### Test 4: Từ chối đơn

1. Có đơn pending
2. Click "Từ chối"
3. Nhập lý do (required)
4. Kiểm tra Firestore: trangThai = 'cancelled', phanHoi = lý do

### Test 5: Xem chi tiết

1. Click vào card bất kỳ
2. Modal hiển thị đầy đủ thông tin
3. Kiểm tra action buttons tùy theo trạng thái

## 🚀 Triển khai

### 1. Deploy Indexes (Đã xong)

```bash
firebase deploy --only firestore:indexes
```

### 2. Hot Reload/Restart App

- Press `R` trong terminal Flutter đang chạy
- Hoặc restart app

### 3. Kiểm tra

- Login PT
- Xem 2 tabs hiển thị đúng
- Test các chức năng

## 📝 TODO - Mở rộng

1. **Liên hệ học viên**

   - Tích hợp gọi điện: `tel:` URI
   - Tích hợp nhắn tin: In-app chat hoặc SMS
   - Hiển thị thông tin liên lạc (phone, email)

2. **Thông báo**

   - Push notification khi có đơn mới
   - Badge count trên tab "Đơn thuê PT"

3. **Lịch tập**

   - Xem sessions trong đơn thuê
   - Đánh dấu buổi tập hoàn thành
   - Cập nhật tiến độ

4. **Thống kê**

   - Tổng đơn thuê trong tháng
   - Doanh thu từ đơn thuê
   - Tỷ lệ approve/reject

5. **Export**
   - Export danh sách đơn thuê ra Excel/PDF
   - Báo cáo thu nhập

## 🐛 Known Issues

1. **Firestore Rule Warning**:

   - `trainerId` trong document là document ID, không phải auth UID
   - Update rule có thể không match nếu không thêm `trainerAuthUid`
   - Giải pháp tạm: Client-side validation

2. **Index Building**:
   - Composite index mới cần vài phút để build
   - Nếu query fail, đợi 2-5 phút rồi thử lại

## 📞 Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra console logs
2. Verify Firestore Rules
3. Verify composite indexes đã build xong
4. Kiểm tra dữ liệu test trong Firestore

---

**Version**: 1.0  
**Created**: 2025-11-01  
**Last Updated**: 2025-11-01
