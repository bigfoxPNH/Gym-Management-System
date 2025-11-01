# 🔒 FIX: Admin Bị Đăng Nhập Tự Động Khi Tạo User Mới

## ❌ VẤN ĐỀ

Khi **Admin** tạo thành viên mới trong `MemberManagementView`:

1. Admin nhấn "Tạo mới" → điền thông tin user mới
2. Hệ thống gọi `createUserWithEmailAndPassword()`
3. **Firebase Auth tự động đăng nhập** tài khoản user vừa tạo
4. `AuthController` nhận `authStateChanges` → cập nhật `currentUser`
5. Admin bị "đá ra" → App **tự động đăng nhập bằng tài khoản user mới** ❌

### Nguyên nhân

Firebase Authentication **không hỗ trợ tạo user mà không tự động đăng nhập** khi:

- Không sử dụng Firebase Admin SDK (cần backend)
- Sử dụng `createUserWithEmailAndPassword()` từ client

## ✅ GIẢI PHÁP

### Phương án đã triển khai: **Save & Restore Admin Session**

**Luồng hoạt động:**

```
1. Admin click "Tạo mới"
   ↓
2. Hiển thị dialog yêu cầu mật khẩu Admin (để restore session sau)
   ↓
3. Lưu email + password Admin
   ↓
4. Tạo user mới → Firebase tự động login user mới ❌
   ↓
5. Lưu dữ liệu user vào Firestore
   ↓
6. Nếu là Trainer → tạo trainer profile
   ↓
7. ✅ CRITICAL: Đăng xuất user mới ngay lập tức
   ↓
8. ✅ CRITICAL: Đăng nhập lại Admin với thông tin đã lưu
   ↓
9. Reload danh sách users
   ↓
10. Hiển thị thông báo thành công ✅
```

### Code Implementation

**File:** `lib/controllers/member_management_controller.dart`

```dart
Future<void> createUser(Map<String, dynamic> userData) async {
  // STEP 1: Yêu cầu mật khẩu Admin trước
  final adminPassword = await _requestAdminPassword();
  if (adminPassword == null) {
    return; // User hủy
  }

  try {
    isLoading.value = true;

    // STEP 2: Lưu email Admin hiện tại
    final adminEmail = _auth.currentUser?.email;
    if (adminEmail == null) {
      throw Exception('Admin must be logged in');
    }

    // STEP 3: Tạo user mới (Firebase tự động login user này)
    final credential = await _auth.createUserWithEmailAndPassword(
      email: userData['email'],
      password: userData['password'],
    );

    // STEP 4-5: Lưu dữ liệu user + trainer profile (nếu cần)
    await _firestore.collection('users').doc(userId).set(...);
    if (role == Role.trainer) {
      await _createTrainerProfile(userId, userData);
    }

    // STEP 6: ✅ Đăng xuất user mới
    await _auth.signOut();

    // STEP 7: ✅ Đăng nhập lại Admin
    await _auth.signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );

    // STEP 8-9: Reload data + thông báo
    await loadAllUsers();
    Get.back();
    Get.snackbar('Thành công', 'Đã tạo user mới');
  } catch (e) {
    // Handle error
  }
}
```

### Helper Method: Request Admin Password

```dart
Future<String?> _requestAdminPassword() async {
  String? password;
  final controller = TextEditingController();

  await Get.dialog(
    AlertDialog(
      title: Row([
        Icon(Icons.security),
        Text('Xác thực Admin'),
      ]),
      content: Column([
        Text('Để tạo thành viên mới, vui lòng xác nhận mật khẩu Admin:'),
        TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Mật khẩu Admin',
            helperText: 'Mật khẩu sẽ được dùng để khôi phục phiên đăng nhập',
          ),
        ),
      ]),
      actions: [
        TextButton('Hủy', onPressed: () {
          password = null;
          Get.back();
        }),
        ElevatedButton('Xác nhận', onPressed: () {
          password = controller.text;
          Get.back();
        }),
      ],
    ),
    barrierDismissible: false,
  );

  return password;
}
```

## 🎯 LỢI ÍCH

✅ **Bảo mật:** Admin phải xác nhận mật khẩu trước khi tạo user  
✅ **Không mất session:** Admin không bị đăng xuất  
✅ **Trải nghiệm tốt:** Chỉ nhập mật khẩu 1 lần, không bị gián đoạn  
✅ **Tương thích:** Hoạt động với Flutter + Firebase (không cần backend)

## 🔄 LUỒNG NGƯỜI DÙNG

### Trước khi fix:

```
Admin login → Tạo user mới → ❌ App tự động login user mới
→ Admin mất quyền truy cập → Phải login lại
```

### Sau khi fix:

```
Admin login → Nhập mật khẩu xác thực → Tạo user mới
→ ✅ Admin vẫn login → Tiếp tục quản lý bình thường
```

## 📝 LƯU Ý

### Bảo mật mật khẩu

- Mật khẩu Admin **chỉ lưu trong bộ nhớ tạm** (biến local)
- **Không** lưu vào SharedPreferences, Database hay file
- Biến bị xóa ngay sau khi re-authenticate xong

### Trường hợp lỗi

1. **Mật khẩu sai:** Hiển thị lỗi, yêu cầu nhập lại
2. **Mất kết nối:** Firebase retry tự động
3. **User hủy dialog:** Không tạo user, quay về màn hình quản lý

### Tương lai: Backend Solution (Optional)

Nếu muốn UX tốt hơn (không cần nhập password), có thể:

1. Tạo Firebase Cloud Function với Admin SDK
2. Client gọi function qua HTTP
3. Function tạo user **không** auto-login

```javascript
// functions/index.js
exports.createUser = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied");
  }

  // Create user without auto-login
  const user = await admin.auth().createUser({
    email: data.email,
    password: data.password,
    displayName: data.fullName,
  });

  return { uid: user.uid };
});
```

## 📚 THAM KHẢO

- [Firebase Auth - Admin SDK](https://firebase.google.com/docs/auth/admin)
- [GetX Dialog](https://pub.dev/packages/get#dialogs)
- [Firebase Auth State Changes](https://firebase.google.com/docs/auth/flutter/manage-users#get_the_currently_signed-in_user)

---

**Status:** ✅ Fixed  
**Date:** 2025-10-31  
**Modified Files:** `lib/controllers/member_management_controller.dart`
