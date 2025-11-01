# 🧪 TEST CASE: Admin Create User Fix

## Mục đích

Kiểm tra xem Admin có bị tự động đăng nhập vào tài khoản user mới tạo hay không.

## Điều kiện tiên quyết

- ✅ Firebase Auth đã được cấu hình
- ✅ Có tài khoản Admin (role: admin)
- ✅ App đang chạy

## Test Case 1: Tạo user mới thành công

### Bước thực hiện:

1. **Đăng nhập Admin**

   - Email: `admin@gympro.com`
   - Password: `admin123`
   - Kỳ vọng: Đăng nhập thành công, hiển thị màn Home với badge "ADMIN"

2. **Vào Quản lý thành viên**

   - Tap vào menu → "Quản Lý Thành Viên"
   - Kỳ vọng: Hiển thị danh sách users hiện có

3. **Nhấn nút "Thêm thành viên"**

   - Tap icon "+" ở AppBar
   - Kỳ vọng: Hiển thị dialog "Thêm Thành Viên"

4. **Điền thông tin user mới**

   - Họ tên: `Nguyen Van A`
   - Email: `nguyenvana@test.com`
   - Mật khẩu: `test1234`
   - Số điện thoại: `0901234567`
   - Quyền: `Hội viên`
   - Tap "Tạo mới"

5. **Nhập mật khẩu Admin**

   - Kỳ vọng: Hiển thị dialog "Xác thực Admin"
   - Nhập password Admin: `admin123`
   - Tap "Xác nhận"

6. **Kiểm tra kết quả**
   - ✅ User mới được tạo thành công
   - ✅ Hiển thị Snackbar: "Đã tạo thành viên mới: Nguyen Van A"
   - ✅ Danh sách users được refresh, có user mới
   - ✅ **QUAN TRỌNG:** Admin vẫn đăng nhập, không bị logout
   - ✅ **QUAN TRỌNG:** AppBar vẫn hiển thị badge "ADMIN"
   - ✅ **QUAN TRỌNG:** Không bị chuyển về màn Login

### Kết quả mong đợi:

```
✅ PASS: Admin không bị logout sau khi tạo user mới
```

---

## Test Case 2: Hủy tạo user (Cancel password dialog)

### Bước thực hiện:

1. Đăng nhập Admin
2. Vào Quản lý thành viên → Tap "+"
3. Điền thông tin user mới
4. Tap "Tạo mới"
5. **Tap "Hủy"** ở dialog "Xác thực Admin"

### Kết quả mong đợi:

```
✅ Dialog đóng
✅ Không tạo user mới
✅ Quay về màn Quản lý thành viên
✅ Admin vẫn đăng nhập
```

---

## Test Case 3: Nhập sai mật khẩu Admin

### Bước thực hiện:

1. Đăng nhập Admin
2. Vào Quản lý thành viên → Tap "+"
3. Điền thông tin user mới
4. Tap "Tạo mới"
5. Nhập mật khẩu sai: `wrongpassword`
6. Tap "Xác nhận"

### Kết quả mong đợi:

```
❌ Hiển thị lỗi: "Mật khẩu không đúng. Vui lòng thử lại."
✅ Dialog đóng
✅ User mới KHÔNG được tạo
✅ Admin bị logout (do Firebase Auth lỗi khi re-authenticate)
```

**⚠️ LƯU Ý:** Test case này có thể fail admin logout do cơ chế Firebase Auth. Nếu gặp case này, cần xử lý thêm try-catch.

---

## Test Case 4: Tạo nhiều user liên tiếp

### Bước thực hiện:

1. Đăng nhập Admin
2. Tạo user 1: `user1@test.com`
3. Kiểm tra Admin vẫn login
4. Tạo user 2: `user2@test.com`
5. Kiểm tra Admin vẫn login
6. Tạo user 3: `user3@test.com`
7. Kiểm tra Admin vẫn login

### Kết quả mong đợi:

```
✅ 3 users được tạo thành công
✅ Admin KHÔNG bị logout sau mỗi lần tạo user
✅ Danh sách users hiển thị đầy đủ 3 users mới
```

---

## Test Case 5: Tạo Trainer (Role có logic đặc biệt)

### Bước thực hiện:

1. Đăng nhập Admin
2. Vào Quản lý thành viên → Tap "+"
3. Điền thông tin:
   - Họ tên: `PT John Doe`
   - Email: `pt.john@test.com`
   - Mật khẩu: `pt123456`
   - **Quyền: `Huấn luyện viên (PT)`**
4. Tap "Tạo mới" → Nhập password Admin
5. Tap "Xác nhận"

### Kết quả mong đợi:

```
✅ User Trainer được tạo
✅ Trainer profile được tạo trong collection 'trainers'
✅ Admin vẫn đăng nhập
✅ Không bị redirect đến PT Dashboard
```

---

## Regression Test: Chức năng khác

### Test các chức năng liên quan không bị ảnh hưởng:

- ✅ **Update User:** Admin có thể cập nhật thông tin user
- ✅ **Delete User:** Admin có thể xóa user
- ✅ **View User Details:** Admin có thể xem chi tiết user
- ✅ **Search Users:** Tìm kiếm user hoạt động bình thường
- ✅ **Filter by Role:** Lọc user theo role hoạt động

---

## Debug Checklist

Nếu test fail, kiểm tra:

### 1. Check AuthController state

```dart
print('Current User: ${_auth.currentUser?.email}');
print('User Role: ${authController.userAccount?.role}');
```

### 2. Check Firebase Auth Listeners

```dart
AuthService.authStateChanges.listen((user) {
  print('🔥 Auth State Changed: ${user?.email}');
});
```

### 3. Check dialog flow

```dart
// Trong _requestAdminPassword()
print('🔒 Password dialog opened');
print('🔒 Password entered: ${password != null}');
```

### 4. Check re-authenticate flow

```dart
// Trong createUser()
print('👤 Admin email before: $adminEmail');
print('👤 New user created: ${credential.user?.email}');
print('🔓 Signed out new user');
print('🔒 Re-authenticating admin: $adminEmail');
print('✅ Admin re-authenticated successfully');
```

---

## 📊 Test Results Template

| Test Case                | Status            | Notes |
| ------------------------ | ----------------- | ----- |
| TC1: Tạo user thành công | ⬜ PASS / ❌ FAIL |       |
| TC2: Hủy tạo user        | ⬜ PASS / ❌ FAIL |       |
| TC3: Sai password        | ⬜ PASS / ❌ FAIL |       |
| TC4: Tạo nhiều user      | ⬜ PASS / ❌ FAIL |       |
| TC5: Tạo Trainer         | ⬜ PASS / ❌ FAIL |       |
| Regression: Update user  | ⬜ PASS / ❌ FAIL |       |
| Regression: Delete user  | ⬜ PASS / ❌ FAIL |       |

---

## 🐛 Known Issues

### Issue 1: Password dialog không tự động focus

**Workaround:** Tap vào TextField để focus

### Issue 2: Loading overlay không hiển thị

**Expected:** Loading hiển thị trong lúc tạo user  
**Status:** Non-blocking, chức năng vẫn hoạt động

---

## 📝 Test Notes

- **Môi trường test:** Flutter Debug Mode
- **Platform:** Android / iOS / Web
- **Firebase Project:** [Tên project]
- **Tester:** [Tên người test]
- **Date:** [Ngày test]
