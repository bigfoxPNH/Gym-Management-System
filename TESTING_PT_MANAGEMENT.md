# 🧪 Hướng Dẫn Test PT Management System

## 📋 Checklist Trước Khi Test

- [ ] Flutter app đang chạy
- [ ] Firebase đã được cấu hình
- [ ] Đã đăng nhập với tài khoản admin
- [ ] Internet connection stable

---

## 🚀 Bước 1: Add Sample Data

### Option 1: Chạy trong Flutter App

Thêm code sau vào một button hoặc initState của một màn hình test:

```dart
import 'package:gympro/scripts/add_sample_trainers.dart';

// Trong một button onPressed hoặc initState
ElevatedButton(
  onPressed: () async {
    await addAllSampleData();
    Get.snackbar('Thành công', 'Đã thêm dữ liệu mẫu!');
  },
  child: const Text('Add Sample Trainers'),
)
```

### Option 2: Tạo Test Screen Tạm Thời

Tạo file `lib/test/trainer_test_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../scripts/add_sample_trainers.dart';

class TrainerTestScreen extends StatelessWidget {
  const TrainerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PT Management Test'),
        backgroundColor: const Color(0xFFFF9800),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test PT Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  Get.dialog(
                    const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );

                  await addAllSampleData();

                  Get.back(); // Close loading
                  Get.snackbar(
                    'Thành công',
                    'Đã thêm 7 PT, 2 assignments, 2 reviews!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (e) {
                  Get.back();
                  Get.snackbar(
                    'Lỗi',
                    'Không thể thêm dữ liệu: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Add All Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  Get.dialog(
                    const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );

                  await addSampleTrainers();

                  Get.back();
                  Get.snackbar(
                    'Thành công',
                    'Đã thêm 7 trainers!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.back();
                  Get.snackbar('Lỗi', '$e', backgroundColor: Colors.red);
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Trainers Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Thêm route trong `app_pages.dart`:

```dart
GetPage(
  name: '/test/trainers',
  page: () => const TrainerTestScreen(),
),
```

Navigate từ màn hình nào đó:

```dart
Get.toNamed('/test/trainers');
```

---

## ✅ Bước 2: Test Cases

### 1. **Tab 1: Trainer List**

#### Test Search

```
1. Vào tab "Danh sách PT"
2. Nhập "Nguyễn" vào search bar
3. Verify: Hiển thị "Nguyễn Văn Mạnh", "Nguyễn Quang Huy"
4. Xóa search
5. Verify: Hiển thị tất cả 7 PT
```

#### Test Filter

```
1. Click chip "Active"
2. Verify: 6 PT hiển thị
3. Click chip "On Leave"
4. Verify: 1 PT (Võ Thị Mai)
5. Click chip "All"
6. Verify: 7 PT hiển thị
```

#### Test Stats Cards

```
1. Verify "Tổng số PT": 7
2. Verify "PT đang hoạt động": 6
3. Verify "Tổng buổi tập": Số > 0
```

#### Test Trainer Card

```
1. Click vào card "Nguyễn Văn Mạnh"
2. Verify: Navigate to detail view
3. Back về list
4. Click "Edit" button
5. Verify: Navigate to form view
```

#### Test FAB

```
1. Click FAB (+)
2. Verify: Form mở với empty fields
3. Back
```

### 2. **Tab 2: Assignment Management**

#### Test Stats

```
1. Vào tab "Phân Công PT"
2. Verify "Đang thực hiện": 1
3. Verify "Đã hoàn thành": 1
4. Verify "Tổng buổi tập": 38
```

#### Test Assignment Card

```
1. Verify assignment card hiển thị:
   - Trainer name → User name
   - Progress bar: 8/20 buổi (40%)
   - Status badge "Đang thực hiện" (xanh)
   - Start date
   - Price per session
2. Verify completed assignment:
   - Progress 100%
   - Status "Đã hoàn thành" (xanh dương)
```

#### Test Update Sessions

```
1. Click "Cập nhật buổi" trên active assignment
2. Enter số buổi mới (vd: 10)
3. Click "Cập nhật"
4. Verify: Progress bar cập nhật
5. Verify: Toast message success
```

#### Test Complete Assignment

```
1. Click "Hoàn thành" trên active assignment
2. Confirm dialog
3. Verify: Status chuyển thành "Đã hoàn thành"
4. Verify: Progress bar = 100%
```

#### Test Add Assignment

```
1. Click FAB (+)
2. Fill form:
   - Trainer ID: (copy từ Firestore)
   - User ID: user999
   - User Name: Test User
   - Sessions: 15
   - Price: 280000
3. Click "Phân công"
4. Verify: New assignment xuất hiện
5. Verify: Stats cards cập nhật
```

### 3. **Tab 3: Statistics**

#### Test Overview Stats

```
1. Vào tab "Thống kê & Lịch"
2. Verify "Tổng số PT": 7
3. Verify "PT đang hoạt động": 6
4. Verify "Tổng buổi tập": Số > 0
5. Verify "Doanh thu": > 0đ
```

#### Test Top Performers

```
1. Scroll to "Top PT Xuất Sắc"
2. Verify: Có ít nhất 2 PT
3. Verify: Sorted by rating (highest first)
4. Verify: Top 1 có badge màu vàng (#FFD700)
5. Verify: Top 2 có badge màu bạc (#C0C0C0)
```

#### Test Revenue Chart

```
1. Scroll to "Doanh Thu PT"
2. Verify: Bar chart hiển thị
3. Verify: Có ít nhất 1 bar màu cam
4. Verify: X-axis có tên PT (họ)
5. Verify: Y-axis có số tiền format (K/M)
```

#### Test Distribution

```
1. Scroll to "Phân Bố PT"
2. Verify: Progress bar "Đang làm việc": 6 PT (86%)
3. Verify: Progress bar "Nghỉ phép": 1 PT (14%)
4. Verify: Colors match status (green, blue, etc.)
```

### 4. **Trainer Detail View**

#### Test Header

```
1. Vào detail view của "Nguyễn Văn Mạnh"
2. Verify: Orange gradient background
3. Verify: Avatar (hoặc fallback icon)
4. Verify: Name "Nguyễn Văn Mạnh"
5. Verify: Rating 4.8 sao (45 đánh giá)
6. Verify: Status badge "Đang làm việc" (xanh)
```

#### Test Stats Cards

```
1. Verify "Học viên": 1
2. Verify "Buổi tập": 8
3. Verify "Đánh giá": 2
```

#### Test Info Section

```
1. Scroll to "Thông tin cơ bản"
2. Verify: Phone 0901234567
3. Verify: Email manh.pt@gympro.vn
4. Verify: Age (calculated from namSinh)
5. Verify: Address
6. Verify: Lương 15,000,000đ/tháng
7. Verify: Hoa hồng 15%
```

#### Test Skills Section

```
1. Scroll to "Chuyên môn & Chứng chỉ"
2. Verify: Specialties chips (Tăng cơ, Boxing, HIIT)
3. Verify: Degrees list (Cử nhân TDTT, ISSA Certified)
4. Verify: Certifications (ISSA-CPT-2019, CrossFit-Level1-2020)
```

#### Test Assignments Section

```
1. Scroll to "Học viên được phân công"
2. Verify: 1 active assignment
3. Verify: Progress bar
4. Verify: Date + Price chips
```

#### Test Reviews Section

```
1. Scroll to "Đánh giá từ học viên"
2. Verify: 2 reviews
3. Verify: Stars displayed correctly
4. Verify: Comments
5. Verify: Tags (Nhiệt tình, Chuyên nghiệp, etc.)
```

### 5. **Trainer Form**

#### Test Add Trainer

```
1. Navigate to form (FAB from list)
2. Fill required fields:
   - Họ tên: "Test Trainer"
   - Điện thoại: "0909999999"
3. Leave optional fields empty
4. Don't select specialty
5. Click "Thêm PT"
6. Verify: Error "Vui lòng chọn ít nhất 1 chuyên môn"
7. Select "Yoga"
8. Click "Thêm PT"
9. Verify: Success message
10. Verify: New trainer in list
```

#### Test Edit Trainer

```
1. Click Edit on "Nguyễn Văn Mạnh"
2. Verify: All fields populated
3. Verify: Specialties selected
4. Change name to "Nguyễn Văn Mạnh (Updated)"
5. Add specialty "Cardio"
6. Click "Cập nhật"
7. Verify: Success message
8. Verify: Name updated in list
```

#### Test Form Validation

```
1. Clear name field
2. Click submit
3. Verify: "Vui lòng nhập họ tên"

4. Enter invalid email "test@"
5. Click submit
6. Verify: "Email không hợp lệ"

7. Enter commission 150
8. Click submit
9. Verify: "0-100"
```

#### Test Multi-Select

```
1. Click on specialty chips
2. Verify: Selected chips orange
3. Unclick chip
4. Verify: Chip back to normal
5. Select 5 specialties
6. Verify: All 5 selected
```

#### Test Add Degree/Cert

```
1. Click + button in "Bằng cấp"
2. Dialog opens
3. Enter "Test Degree"
4. Click "Thêm"
5. Verify: Appears in list
6. Click delete button
7. Verify: Removed from list
```

#### Test Date Picker

```
1. Click "Ngày sinh" field
2. Verify: DatePicker opens with orange theme
3. Select date
4. Verify: Date displayed in format dd/MM/yyyy
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "No trainers found"

**Solution**: Run `addSampleTrainers()` script

### Issue 2: Stats showing 0

**Solution**:

1. Check Firestore console
2. Verify collections exist: trainers, trainer_assignments
3. Run script again

### Issue 3: Charts not displaying

**Solution**:

1. Check if assignments have `mucGia` field
2. Verify trainer ratings > 0
3. Check console for errors

### Issue 4: Form validation not working

**Solution**:

1. Check validator functions in form_view.dart
2. Verify all required fields have validators

### Issue 5: Images not loading

**Solution**:

1. Sample data has `anhDaiDien: null`
2. Fallback icons should display
3. Update Firestore with real image URLs

---

## 📊 Expected Results

### After Adding Sample Data

- **Trainers**: 7 total (6 active, 1 on_leave)
- **Assignments**: 2 total (1 active, 1 completed)
- **Reviews**: 2 total
- **Stats**: All calculated correctly

### Performance

- Loading time < 2 seconds
- Smooth scrolling
- Responsive UI
- No lag when filtering

### Data Integrity

- All relationships correct (trainerId → userId)
- Progress percentages accurate
- Revenue calculations correct
- Rating averages correct

---

## ✅ Final Checklist

- [ ] All 7 trainers visible
- [ ] Search works
- [ ] All filters work
- [ ] Stats accurate
- [ ] Charts display
- [ ] Detail view complete
- [ ] Form validation works
- [ ] CRUD operations work
- [ ] No console errors
- [ ] UI responsive

---

## 🎉 Success Criteria

✅ **System is ready** when:

1. All test cases pass
2. No compilation errors
3. No runtime errors
4. All features functional
5. UI looks polished
6. Data accurate

---

**Happy Testing!** 🚀

Nếu gặp vấn đề, check:

1. Firestore Console
2. Flutter Console (errors)
3. Network tab (API calls)
4. PT_MANAGEMENT_SUMMARY.md (documentation)
