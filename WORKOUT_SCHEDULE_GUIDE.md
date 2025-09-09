# Hướng Dẫn Sử Dụng Tính Năng Lịch Trình Tập Luyện

## Tổng Quan

Hệ thống lịch trình tập luyện cho phép admin tạo các lịch trình tập tổng thể và user có thể chọn lịch trình phù hợp với mình để theo dõi tiến độ tập luyện.

## Dành Cho Admin

### 1. Quản Lý Lịch Trình

- **Truy cập**: Home > Quản Lý Lịch Trình (card màu cam)
- **Route**: `/admin/schedule-management`

### 2. Tính Năng Admin

- ✅ **Tạo lịch trình mới** với các thông tin:

  - Tên lịch trình
  - Mô tả chi tiết
  - Loại lịch trình (Giảm cân, Tăng cơ, Giữ dáng, Tăng sức mạnh)
  - Độ khó (Dễ, Trung bình, Khó, Chuyên nghiệp)
  - Danh mục (Cardio, Sức mạnh, Yoga, v.v.)
  - Chọn bài tập từ danh sách có sẵn
  - Thời gian ước tính (phút)

- ✅ **Chỉnh sửa lịch trình** hiện có
- ✅ **Xóa lịch trình** không cần thiết
- ✅ **Xem thống kê sử dụng** lịch trình
- ✅ **Lọc và tìm kiếm** lịch trình

## Dành Cho User

### 1. Chọn Lịch Trình

- **Truy cập**: Home > Lịch Trình (card màu teal)
- **Route**: `/user/schedule-selection`

### 2. Xem Lịch Sử

- **Truy cập**: Home > Lịch Sử Lịch Trình (card màu xanh lá)
- **Route**: `/user/schedule-history`

### 3. Tính Năng User

- ✅ **Xem danh sách lịch trình** có sẵn
- ✅ **Lọc theo loại, độ khó, danh mục**
- ✅ **Xem chi tiết lịch trình** và danh sách bài tập
- ✅ **Tham gia lịch trình** (assign cho bản thân)
- ✅ **Theo dõi tiến độ** hàng ngày
- ✅ **Đánh dấu hoàn thành** từng ngày tập
- ✅ **Xem lịch sử** các lịch trình đã tham gia
- ✅ **Đánh giá và feedback** lịch trình

## Database Structure

### Collections

1. **workout_schedules** - Lưu trữ template lịch trình
2. **user_schedules** - Lưu trữ lịch trình được assign cho user cụ thể

### Models

- `WorkoutSchedule` - Template lịch trình
- `UserSchedule` - Lịch trình của user với tracking progress

## Navigation Routes

### Admin Routes

- `/admin/schedule-management` - Quản lý lịch trình
- `/admin/create-schedule` - Tạo lịch trình mới
- `/admin/edit-schedule/:id` - Chỉnh sửa lịch trình

### User Routes

- `/user/schedule-selection` - Chọn lịch trình
- `/user/schedule-detail/:id` - Chi tiết lịch trình và tracking
- `/user/schedule-history` - Lịch sử lịch trình

## Technical Implementation

### Controllers

- `ScheduleManagementController` - Quản lý cho admin
- `WorkoutScheduleController` - Chức năng cho user

### Services

- `WorkoutScheduleService` - Firebase integration và business logic

### State Management

- Sử dụng GetX cho reactive state management
- Observable variables cho real-time updates

## ⚠️ Firebase Index Requirements

### Lỗi phổ biến: "The query requires an index"

Khi sử dụng các query phức tạp với multiple where clauses và orderBy, Firebase Firestore yêu cầu tạo composite indexes.

### Cách khắc phục:

1. **Truy cập Firebase Console**:

   - Vào https://console.firebase.google.com/
   - Chọn project `gympro-2026`
   - Vào **Firestore Database** > **Indexes**

2. **Tạo Composite Indexes cho workout_schedules**:

   ```
   Collection: workout_schedules
   Fields:
   - category: Ascending
   - isActive: Ascending
   - createdAt: Descending
   ```

   ```
   Collection: workout_schedules
   Fields:
   - difficulty: Ascending
   - isActive: Ascending
   - createdAt: Descending
   ```

   ```
   Collection: workout_schedules
   Fields:
   - type: Ascending
   - isActive: Ascending
   - createdAt: Descending
   ```

3. **Tạo Index cho user_schedules**:
   ```
   Collection: user_schedules
   Fields:
   - userId: Ascending
   - status: Ascending
   - createdAt: Descending
   ```

### Giải pháp tạm thời:

- Service hiện tại đã được optimize để sử dụng client-side filtering
- Tất cả data được load về client và filter trong code thay vì Firestore
- Performance có thể chậm hơn với dataset lớn nhưng hoạt động ổn định

## Features Status

✅ **Hoàn thành 100%** - Tất cả tính năng đã được implement và test
✅ **UI/UX hoàn chỉnh** - Material 3 design với responsive layout
✅ **Firebase integration** - Real-time sync với Firestore
✅ **Error handling** - Comprehensive error handling và validation
✅ **Navigation** - Routes đã được thêm vào app routing system
