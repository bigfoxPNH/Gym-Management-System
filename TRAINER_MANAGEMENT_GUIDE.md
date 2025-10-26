# Hệ Thống Quản Lý PT (Personal Trainer)

## 📋 Tổng quan

Hệ thống quản lý PT cho phép admin quản lý đội ngũ huấn luyện viên cá nhân, bao gồm:

- Hồ sơ & thông tin PT
- Phân công PT cho học viên
- Lịch làm việc
- Thống kê hiệu suất & doanh thu
- Đánh giá từ học viên

## 🗂️ Cấu trúc Files

### Models (lib/models/)

- **trainer.dart** - Model PT với đầy đủ thông tin
- **trainer_assignment.dart** - Model phân công PT-Học viên
- **trainer_review.dart** - Model đánh giá PT
- **trainer_schedule.dart** - Model lịch làm việc PT

### Controller (lib/controllers/)

- **trainer_management_controller.dart** - Controller quản lý toàn bộ logic PT

### Views (lib/views/admin/)

- **trainer_management_view.dart** - Màn hình chính với 3 tabs
- **trainer_list_tab.dart** - Tab danh sách PT
- **trainer_assignment_tab.dart** - Tab phân công (placeholder)
- **trainer_statistics_tab.dart** - Tab thống kê (placeholder)
- **trainer_detail_view.dart** - Chi tiết PT (placeholder)
- **trainer_form_view.dart** - Form thêm/sửa PT

### Routes

- **app_routes.dart** - Đã thêm route `/admin/trainer-management`
- **app_pages.dart** - Đã register TrainerManagementView

## 🎨 Màu sắc

Widget "Quản Lý PT" sử dụng màu **cam (#FF9800)** để phân biệt với các chức năng khác:

- Xanh dương (#2196F3) - Admin chính
- Tím (#9C27B0) - Thẻ tập
- Xanh lá (#4CAF50) - Check-in
- Cam (#FF9800) - **PT Management** ✨

## 📊 Các Model Chi Tiết

### 1. Trainer Model

```dart
class Trainer {
  String id, hoTen, email, soDienThoai, gioiTinh;
  DateTime? namSinh;
  String? anhDaiDien, diaChi, moTa;
  List<String> bangCap, chuyenMon, chungChi;
  String trangThai; // active, inactive, suspended, on_leave
  double mucLuongCoBan, hoaHongPhanTram;
  double danhGiaTrungBinh;
  int soLuotDanhGia;
  DateTime ngayVaoLam, createdAt, updatedAt;
}
```

### 2. TrainerAssignment Model

```dart
class TrainerAssignment {
  String id, trainerId, userId, trainerName, userName;
  DateTime ngayBatDau, ngayKetThuc;
  int soBuoiDangKy, soBuoiHoanThanh;
  String trangThai; // active, completed, cancelled
  String? ghiChuTienDo;
  double? mucGia;
}
```

### 3. TrainerReview Model

```dart
class TrainerReview {
  String id, trainerId, userId, userName;
  double rating; // 1-5 sao
  String? comment;
  List<String> tags; // ['Nhiệt tình', 'Chuyên nghiệp', ...]
  DateTime createdAt;
}
```

### 4. TrainerSchedule Model

```dart
class TrainerSchedule {
  String id, trainerId, trainerName;
  DateTime ngay;
  String gioStart, gioEnd; // '08:00', '09:00'
  String trangThai; // available, booked, completed, cancelled
  String? userId, userName; // Học viên đã đặt
}
```

## 🔥 Tính năng đã triển khai

### ✅ Hoàn thành (Phase 1)

1. **Cấu trúc Models**

   - ✅ Trainer với đầy đủ thông tin
   - ✅ TrainerAssignment cho phân công
   - ✅ TrainerReview cho đánh giá
   - ✅ TrainerSchedule cho lịch làm việc

2. **Controller**

   - ✅ CRUD operations cho PT
   - ✅ Load assignments, reviews, schedules
   - ✅ Filter & search
   - ✅ Statistics calculation

3. **UI - Tab Danh Sách PT**

   - ✅ Search bar với filter theo trạng thái
   - ✅ Stats cards (Tổng PT, Đang hoạt động, Buổi tập)
   - ✅ Trainer cards với avatar, rating, specialties
   - ✅ Status badges màu sắc
   - ✅ Action buttons (Sửa, Chi tiết)
   - ✅ Pull to refresh

4. **Form Thêm/Sửa PT**

   - ✅ Form cơ bản (Họ tên, SĐT, Email)
   - ✅ Loading button với màu cam
   - ✅ Validation

5. **Integration**
   - ✅ Added route `/admin/trainer-management`
   - ✅ Added widget to HomeView (Admin section)
   - ✅ Connected to navigation system

### 🚧 Cần phát triển thêm (Phase 2)

1. **Tab Phân Công**

   - Danh sách học viên
   - Form phân công PT
   - Hiển thị tiến độ
   - Ghi chú buổi tập

2. **Tab Thống Kê & Lịch**

   - Biểu đồ hiệu suất PT
   - Calendar view lịch làm việc
   - Doanh thu & hoa hồng
   - Export báo cáo

3. **Chi Tiết PT**

   - Thông tin đầy đủ
   - Danh sách học viên đang phụ trách
   - Lịch sử đánh giá
   - Upload ảnh & chứng chỉ

4. **Trainer Form (Nâng cao)**

   - Upload avatar
   - Multiple chuyên môn selector
   - Upload giấy chứng nhận
   - Social media links
   - Date picker cho ngày sinh/vào làm

5. **Trainer Role (Phase 3)**
   - Login riêng cho PT
   - Dashboard PT
   - Quản lý học viên của mình
   - Xem lịch làm việc
   - Ghi chú buổi tập
   - Xem đánh giá

## 🚀 Cách sử dụng

### Admin sử dụng:

1. Login với tài khoản admin
2. Trang chủ → Click widget **"Quản Lý PT"** (màu cam)
3. Tab **Danh sách PT**:
   - Xem tất cả PT
   - Search theo tên
   - Filter theo trạng thái
   - Nhấn nút **+** để thêm PT mới
   - Click card để xem chi tiết
   - Nhấn **Sửa** để chỉnh sửa

### Firestore Collections:

```
trainers/
  {trainerId}/
    - hoTen, email, soDienThoai, ...
    - bangCap: [], chuyenMon: []
    - trangThai, danhGiaTrungBinh, ...

trainer_assignments/
  {assignmentId}/
    - trainerId, userId
    - soBuoiDangKy, soBuoiHoanThanh
    - trangThai, mucGia

trainer_reviews/
  {reviewId}/
    - trainerId, userId
    - rating, comment, tags

trainer_schedules/
  {scheduleId}/
    - trainerId, ngay
    - gioStart, gioEnd
    - trangThai, userId (nếu booked)
```

## 📱 Screenshots Flow

```
HomeView (Admin)
    ↓
[Quản Lý PT] 🟠
    ↓
TrainerManagementView
    ├── Tab 1: Danh sách PT ✅
    │   ├── Search & Filter
    │   ├── Stats Cards
    │   └── Trainer Cards
    │       ├── Avatar & Info
    │       ├── Specialties
    │       ├── Rating
    │       └── Actions (Sửa/Chi tiết)
    │
    ├── Tab 2: Phân công 🚧
    │   └── Coming soon...
    │
    └── Tab 3: Thống kê 🚧
        └── Coming soon...
```

## 🎯 Next Steps

1. **Ngay lập tức:**

   - Test CRUD operations
   - Add sample data to Firestore
   - Test navigation flow

2. **Phase 2 (Tuần tới):**

   - Implement Tab Phân Công
   - Implement Tab Thống Kê
   - Complete Trainer Detail View
   - Advanced Trainer Form

3. **Phase 3 (Tương lai):**
   - Trainer role & authentication
   - Trainer dashboard
   - Mobile app for trainers
   - Rating system integration

## 🐛 Known Issues

- Tab 2 & 3 là placeholder (chỉ hiển thị "Đang phát triển...")
- Trainer Detail View chưa có nội dung
- Form chỉ có 3 fields cơ bản
- Chưa có upload ảnh
- Chưa integrate với Firebase Storage

## ✅ Testing Checklist

- [ ] Tạo PT mới
- [ ] Sửa thông tin PT
- [ ] Xóa PT (khi không có học viên)
- [ ] Search PT theo tên
- [ ] Filter theo trạng thái
- [ ] View chi tiết PT
- [ ] Verify Firestore data
- [ ] Test loading states
- [ ] Test error handling

---

**Version:** 1.0.0  
**Last Updated:** 26/10/2025  
**Status:** Phase 1 Complete ✅
