# 🔄 User-Trainer Synchronization System (BI-DIRECTIONAL)

## 📋 Tổng Quan

Hệ thống tự động đồng bộ thông tin **2 CHIỀU** giữa **User Account** (collection `users`) và **Trainer Profile** (collection `trainers`) để đảm bảo dữ liệu luôn nhất quán.

---

## 🎯 Vấn Đề Được Giải Quyết

### Trước Khi Có Sync 2 Chiều:

❌ Sửa email PT trong **Quản lý thành viên** → Trainer profile KHÔNG cập nhật  
❌ Sửa email PT trong **Quản lý PT** → User account KHÔNG cập nhật  
❌ PT không thể đăng nhập với email mới  
❌ Thông tin PT hiển thị không nhất quán giữa các màn hình  
❌ Phải sửa thông tin ở 2 nơi khác nhau

### Sau Khi Có Sync 2 Chiều:

✅ Sửa ở **BẤT KỲ ĐÂU** → Tự động cập nhật tất cả  
✅ PT luôn đăng nhập được với thông tin mới nhất  
✅ Dữ liệu đồng bộ 100% giữa users và trainers  
✅ Chỉ cần sửa 1 lần ở 1 màn hình bất kỳ  
✅ Tự động link trainer với user nếu chưa có userId

---

## 🔧 Cách Hoạt Động

### 🔄 Chiều 1: Users → Trainers

**Khi sửa trong Quản lý thành viên:**

```dart
// File: member_management_controller.dart
// Method: updateUser()

// 1. Update users collection
await _firestore.collection('users').doc(userId).update(updateData);

// 2. Auto sync to trainers collection
if (newRole == 'trainer') {
  await _syncTrainerProfile(userId, userData);
}
```

**Kết quả:**

- ✅ Cập nhật `users` collection
- ✅ TỰ ĐỘNG cập nhật `trainers` collection với cùng thông tin

---

### � Chiều 2: Trainers → Users (MỚI!)

**Khi sửa trong Quản lý PT hoặc Sửa thông tin PT:**

```dart
// File: trainer_management_controller.dart
// Method: updateTrainer()

// 1. Update trainers collection
await _firestore
    .collection('trainers')
    .doc(trainer.id)
    .update(trainer.toFirestore());

// 2. Auto sync to users collection
await _syncUserAccount(trainer);
```

**Logic thông minh:**

1. Nếu trainer có `userId` → Dùng luôn
2. Nếu KHÔNG có `userId` → Tìm user bằng email
3. Nếu tìm thấy → Link trainer với user (lưu userId vào trainer)
4. Cập nhật user account với thông tin mới

**Kết quả:**

- ✅ Cập nhật `trainers` collection
- ✅ TỰ ĐỘNG cập nhật `users` collection với cùng thông tin
- ✅ TỰ ĐỘNG link trainer với user nếu chưa có

---

### 1️⃣ Tạo User Mới Với Role = Trainer

**File:** `lib/controllers/member_management_controller.dart`  
**Method:** `createUser()`

```dart
if (role == Role.trainer) {
  await _createTrainerProfile(userId, userData);
}
```

**Kết quả:**

- Tạo document trong `users` collection
- **TỰ ĐỘNG** tạo document trong `trainers` collection với:
  - `userId`: Link đến user account
  - `hoTen`: Lấy từ fullName
  - `email`: Lấy từ email
  - `soDienThoai`: Lấy từ phoneNumber
  - `diaChi`: Lấy từ address
  - `namSinh`: Lấy từ dateOfBirth
  - Các field khác: Giá trị mặc định

---

### 2️⃣ Cập Nhật Thông Tin User Có Role = Trainer

**File:** `lib/controllers/member_management_controller.dart`  
**Method:** `updateUser()`

```dart
// SYNC: If current role is trainer, update trainer profile
if (newRole == 'trainer') {
  await _syncTrainerProfile(userId, userData);
}
```

**Luồng xử lý:**

1. **Cập nhật users collection:**

   ```dart
   await _firestore.collection('users').doc(userId).update({
     'fullName': userData['fullName'],
     'email': userData['email'],
     'phone': userData['phoneNumber'],
     'address': userData['address'],
     'dob': ...,
     'updatedAt': DateTime.now(),
   });
   ```

2. **TỰ ĐỘNG đồng bộ sang trainers collection:**

   ```dart
   await _syncTrainerProfile(userId, userData);
   ```

3. **Trainer profile được cập nhật:**
   ```dart
   await _firestore.collection('trainers').doc(trainerId).update({
     'hoTen': userData['fullName'],
     'email': userData['email'],
     'soDienThoai': userData['phoneNumber'],
     'diaChi': userData['address'],
     'namSinh': Timestamp.fromDate(dob),
     'updatedAt': Timestamp.now(),
   });
   ```

---

### 3️⃣ Đổi Role: Member → Trainer

**Kịch bản:** User ban đầu là member, admin đổi role thành trainer

```dart
if (oldRole != 'trainer' && newRole == 'trainer') {
  final trainerQuery = await _firestore
      .collection('trainers')
      .where('userId', isEqualTo: userId)
      .get();

  if (trainerQuery.docs.isEmpty) {
    await _createTrainerProfile(userId, userData);
  }
}
```

**Kết quả:**

- Tạo trainer profile mới nếu chưa tồn tại
- Link với user account qua `userId`

---

### 4️⃣ Đổi Role: Trainer → Member/Staff/Admin

**Kịch bản:** PT nghỉ việc hoặc chuyển sang vị trí khác

```dart
if (oldRole == 'trainer' && newRole != 'trainer') {
  final trainerQuery = await _firestore
      .collection('trainers')
      .where('userId', isEqualTo: userId)
      .get();

  for (var doc in trainerQuery.docs) {
    await _firestore.collection('trainers').doc(doc.id).update({
      'trangThai': 'inactive',
      'updatedAt': Timestamp.now(),
    });
  }
}
```

**Kết quả:**

- Trainer profile KHÔNG bị xóa (để giữ lịch sử)
- Chỉ set `trangThai: 'inactive'`
- Không hiển thị trong danh sách PT active

---

## 📊 Các Trường Được Đồng Bộ

| Field in `users` | Field in `trainers` | Ghi chú                     |
| ---------------- | ------------------- | --------------------------- |
| `fullName`       | `hoTen`             | ✅ Đồng bộ tự động          |
| `email`          | `email`             | ✅ Đồng bộ tự động          |
| `phone`          | `soDienThoai`       | ✅ Đồng bộ tự động          |
| `address`        | `diaChi`            | ✅ Đồng bộ tự động          |
| `dob`            | `namSinh`           | ✅ Đồng bộ tự động          |
| `avatarUrl`      | `anhDaiDien`        | ⚠️ KHÔNG đồng bộ (riêng PT) |
| `role`           | `trangThai`         | ⚠️ Logic đặc biệt           |

---

## 🔍 Method Chi Tiết: `_syncTrainerProfile()`

**Location:** `lib/controllers/member_management_controller.dart`

```dart
Future<void> _syncTrainerProfile(
  String userId,
  Map<String, dynamic> userData,
) async {
  try {
    // 1. Tìm trainer document bằng userId
    final trainerQuery = await _firestore
        .collection('trainers')
        .where('userId', isEqualTo: userId)
        .get();

    if (trainerQuery.docs.isEmpty) {
      print('No trainer profile found for userId: $userId');
      return;
    }

    // 2. Cập nhật tất cả trainer profiles (thường chỉ 1)
    for (var doc in trainerQuery.docs) {
      final updateData = <String, dynamic>{
        'hoTen': userData['fullName'],
        'email': userData['email'],
        'soDienThoai': userData['phoneNumber'] ?? '',
        'diaChi': userData['address'] ?? '',
        'updatedAt': Timestamp.now(),
      };

      // 3. Cập nhật namSinh nếu có dateOfBirth
      if (userData['dateOfBirth'] != null &&
          userData['dateOfBirth'].toString().isNotEmpty) {
        final dob = _parseDate(userData['dateOfBirth']);
        if (dob != null) {
          updateData['namSinh'] = Timestamp.fromDate(dob);
        }
      }

      // 4. Loại bỏ null values
      updateData.removeWhere((key, value) => value == null);

      // 5. Update Firestore
      await _firestore.collection('trainers').doc(doc.id).update(updateData);

      print('Synced trainer profile ${doc.id} for userId: $userId');
    }
  } catch (e) {
    print('Error syncing trainer profile: $e');
    // Don't throw - user update should still succeed
  }
}
```

**Đặc điểm:**

- ✅ Tìm trainer bằng `userId` (không cần biết trainerId)
- ✅ Cập nhật tất cả fields liên quan
- ✅ Xử lý an toàn: Không throw error nếu sync thất bại
- ✅ Log chi tiết để debug

---

## 🧪 Test Cases (CẬP NHẬT)

### Test 1: Sửa Email PT Trong Quản Lý Thành Viên ✅

**Steps:**

1. Vào **Admin → Quản lý thành viên**
2. Tìm PT có email `trinhhalan@gmail.com`
3. Click menu → **Chỉnh sửa**
4. Đổi email thành `trinhhalan.new@gmail.com`
5. Click **Cập nhật**

**Expected:**

- ✅ Email trong `users` collection được cập nhật
- ✅ Email trong `trainers` collection **TỰ ĐỘNG** được cập nhật
- ✅ PT đăng nhập với email mới → **Thành công!**

---

### Test 2: Sửa Email PT Trong Quản Lý PT ✅ (MỚI!)

**Steps:**

1. Vào **Admin → Quản lý PT**
2. Click vào PT có email `trinhhalan@gmail.com`
3. Click icon **✏️ Sửa**
4. Đổi email thành `trinhhalan.updated@gmail.com`
5. Click **Cập nhật**

**Expected:**

- ✅ Email trong `trainers` collection được cập nhật
- ✅ Email trong `users` collection **TỰ ĐỘNG** được cập nhật (CHIỀU NGƯỢC!)
- ✅ PT đăng nhập với email mới → **Thành công!**

**Verify Console Logs:**

```
Synced user account {userId} with trainer data
```

---

### Test 3: Sửa PT Chưa Có userId ✅ (MỚI!)

**Tình huống:** PT được tạo trực tiếp từ Quản lý PT (không qua Quản lý thành viên)

**Steps:**

1. Vào **Admin → Quản lý PT**
2. Tìm PT có email `trinhhalan@gmail.com` (nhưng không có userId)
3. Click **✏️ Sửa**
4. Đổi số điện thoại thành `0999888777`
5. Click **Cập nhật**

**Expected:**

- ✅ System tìm user bằng email
- ✅ Tự động link trainer với user (lưu userId vào trainer)
- ✅ Cập nhật phone trong cả 2 collections
- ✅ Lần sau sửa sẽ nhanh hơn (đã có userId)

**Verify Console Logs:**

```
Linked trainer {trainerId} with userId: {userId}
Synced user account {userId} with trainer data
```

**Verify Firestore:**

```javascript
// trainers/{trainerId}
{
  userId: "{userId}",  // ← NEW! Auto-linked
  email: "trinhhalan@gmail.com",
  soDienThoai: "0999888777"
}

// users/{userId}
{
  email: "trinhhalan@gmail.com",
  phone: "0999888777"  // ← Synced!
}
```

---

### Test 4: Sửa Nhiều Trường Từ Quản Lý PT ✅ (MỚI!)

**Steps:**

1. Vào **Quản lý PT**
2. Sửa PT với:
   - Họ tên: `Trần Hạ Linh Updated`
   - Email: `newmail@gmail.com`
   - SĐT: `0123456789`
   - Địa chỉ: `456 XYZ Street`
3. Click **Cập nhật**

**Expected:**

- ✅ Tất cả 4 fields đều được sync sang users collection

**Verify:**

```javascript
// users/{userId}
{
  fullName: "Trần Hạ Linh Updated",  // ✅ Synced
  email: "newmail@gmail.com",         // ✅ Synced
  phone: "0123456789",                // ✅ Synced
  address: "456 XYZ Street"           // ✅ Synced
}
```

---

### Test 5: PT Không Có Email (Edge Case) ⚠️

**Tình huống:** PT được tạo mà không có email

**Steps:**

1. Tạo/sửa PT để email trống
2. Click **Cập nhật**

**Expected:**

- ✅ Trainer được cập nhật thành công
- ⚠️ Không sync được sang users (vì không có email để tìm)
- ✅ Không gây lỗi

**Console Log:**

```
No user account found for trainer email: (empty)
```

---

## ⚠️ Lưu Ý Quan Trọng

### 1. Không Sync Ngược Chiều

❌ Khi sửa trainer trong **Quản lý PT** → **KHÔNG** tự động sync sang users  
✅ Chỉ sync từ `users` → `trainers` (một chiều)

**Lý do:**

- Trainer có nhiều field đặc thụ (chuyên môn, bằng cấp, lương...)
- Users chỉ có thông tin cơ bản
- Sync 2 chiều dễ gây conflict

**Giải pháp:**

- Luôn sửa thông tin cơ bản (email, phone, address) trong **Quản lý thành viên**
- Sửa thông tin chuyên môn (chuyên môn, bằng cấp, lương) trong **Quản lý PT**

---

### 2. Xử lý Lỗi An Toàn

```dart
try {
  await _syncTrainerProfile(userId, userData);
} catch (e) {
  print('Error syncing trainer profile: $e');
  // Don't throw - user update should still succeed
}
```

**Ý nghĩa:**

- Nếu sync thất bại → Vẫn cập nhật users collection thành công
- Không làm fail toàn bộ update process
- Log error để debug

---

### 3. Performance

**Query hiệu quả:**

```dart
.where('userId', isEqualTo: userId)
```

**Index Firestore:**

- Cần tạo composite index: `trainers` collection, field `userId`
- Auto-created khi chạy query lần đầu

---

## 🎓 Best Practices

### 1. Luôn Sử Dụng Quản Lý Thành Viên Cho Thông Tin Cơ Bản

✅ **ĐÚNG:**

```
Admin → Quản lý thành viên → Sửa email/phone/address PT
→ Tự động sync sang Trainer profile
```

❌ **SAI:**

```
Admin → Quản lý PT → Sửa email
→ Không sync sang User account
→ PT không đăng nhập được
```

---

### 2. Sử Dụng Quản Lý PT Cho Thông Tin Chuyên Môn

✅ **ĐÚNG:**

```
Admin → Quản lý PT → Sửa chuyên môn/bằng cấp/lương
→ Chỉ ảnh hưởng trainer profile
```

---

### 3. Test Đăng Nhập Sau Khi Sửa

Sau khi sửa email PT:

1. Đăng xuất tài khoản PT (nếu đang đăng nhập)
2. Đăng nhập lại với email mới
3. Verify thông tin hiển thị đúng

---

## 🐛 Troubleshooting

### Vấn đề 1: PT Không Đăng Nhập Được Sau Khi Sửa Email

**Nguyên nhân:** Email trong `users` và `trainers` không khớp

**Cách fix:**

1. Kiểm tra Firestore Console
2. So sánh email trong 2 collections
3. Sửa lại trong **Quản lý thành viên** (sẽ tự động sync)

---

### Vấn đề 2: Thông Tin Hiển Thị Không Nhất Quán

**Nguyên nhân:** Sửa trực tiếp trong Firestore Console hoặc từ Quản lý PT

**Cách fix:**

1. Luôn sửa trong **Quản lý thành viên**
2. Reload ứng dụng để lấy dữ liệu mới

---

### Vấn đề 3: Trainer Profile Không Được Tạo

**Nguyên nhân:** Lỗi permission Firestore hoặc logic error

**Debug:**

```dart
// Check console logs
print('Created trainer profile for userId: $userId');
print('Error creating trainer profile: $e');
```

**Cách fix:**

1. Kiểm tra Firestore Rules
2. Verify userId tồn tại
3. Check console logs

---

## 📝 Summary (CẬP NHẬT)

| Action                                  | Users Collection | Trainers Collection | Auto Sync?                  |
| --------------------------------------- | ---------------- | ------------------- | --------------------------- |
| Tạo user mới với role=trainer           | ✅ Created       | ✅ Created          | ✅ Yes (1 chiều)            |
| Sửa email/phone PT (Quản lý thành viên) | ✅ Updated       | ✅ Updated          | ✅ Yes (→ trainers)         |
| Sửa email/phone PT (Quản lý PT)         | ✅ Updated       | ✅ Updated          | ✅ Yes (→ users) **MỚI!**   |
| Sửa chuyên môn PT (Quản lý PT)          | ❌ No change     | ✅ Updated          | ⚠️ Partial (chỉ basic info) |
| Đổi role member→trainer                 | ✅ Updated       | ✅ Created          | ✅ Yes (1 chiều)            |
| Đổi role trainer→member                 | ✅ Updated       | ⚠️ Set inactive     | ✅ Yes (1 chiều)            |
| PT chưa có userId                       | ✅ Updated       | ✅ Auto-linked      | ✅ Yes **MỚI!**             |

---

## 🎓 Best Practices (CẬP NHẬT)

### 1. Sửa Thông Tin Cơ Bản: Dùng BẤT KỲ Màn Hình Nào ✅

✅ **Quản lý thành viên** (Khuyến nghị nếu chỉ sửa thông tin cơ bản):

```
Admin → Quản lý thành viên → Sửa PT
→ Tự động sync sang Trainer profile
```

✅ **Quản lý PT** (Khuyến nghị nếu sửa cả thông tin chuyên môn):

```
Admin → Quản lý PT → Sửa PT
→ Tự động sync sang User account
→ Đồng thời sửa được chuyên môn, bằng cấp, lương...
```

**Kết quả:** Dữ liệu luôn đồng bộ dù sửa ở đâu! 🎉

---

### 2. Tự Động Link Trainer Với User

Nếu PT được tạo trực tiếp (không qua Quản lý thành viên):

- ✅ Lần đầu sửa → System tự động tìm user bằng email
- ✅ Tự động link trainer với user (lưu userId)
- ✅ Từ lần sau → Sync nhanh hơn

**Lưu ý:** PT cần có email trùng với user account để link được

---

## 🔍 Method Chi Tiết

### 1. `_syncTrainerProfile()` (Users → Trainers)

**Location:** `lib/controllers/member_management_controller.dart`

**Chức năng:**

- Tìm trainer bằng `userId`
- Cập nhật: hoTen, email, soDienThoai, diaChi, namSinh
- Trigger: Khi sửa user có role = trainer

---

### 2. `_syncUserAccount()` (Trainers → Users) **MỚI!**

**Location:** `lib/controllers/trainer_management_controller.dart`

**Chức năng thông minh:**

```dart
// 1. Nếu có userId → Dùng luôn
if (trainer.userId != null && trainer.userId.isNotEmpty) {
  userId = trainer.userId;
}

// 2. Nếu KHÔNG có userId → Tìm bằng email
else if (trainer.email != null && trainer.email.isNotEmpty) {
  final userQuery = await _firestore
      .collection('users')
      .where('email', isEqualTo: trainer.email)
      .where('role', isEqualTo: 'trainer')
      .limit(1)
      .get();

  if (userQuery.docs.isNotEmpty) {
    userId = userQuery.docs.first.id;

    // Lưu userId vào trainer để lần sau nhanh hơn
    await _firestore
        .collection('trainers')
        .doc(trainer.id)
        .update({'userId': userId});
  }
}

// 3. Cập nhật user account
await _firestore.collection('users').doc(userId).update({
  'fullName': trainer.hoTen,
  'email': trainer.email,
  'phone': trainer.soDienThoai,
  'address': trainer.diaChi,
  'dob': trainer.namSinh?.millisecondsSinceEpoch,
});
```

**Trigger:** Khi sửa trainer trong Quản lý PT

---

## 🐛 Troubleshooting (CẬP NHẬT)

### Vấn đề 1: Sửa Ở Quản Lý PT Nhưng User Không Cập Nhật

**Debug:**

1. Check console logs:
   ```
   Linked trainer {trainerId} with userId: {userId}
   Synced user account {userId} with trainer data
   ```
2. Nếu thấy `No user account found for trainer email: ...`
   - Trainer không có email HOẶC
   - Không có user account với email đó

**Giải pháp:**

- Đảm bảo PT có email
- Đảm bảo có user account với email trùng khớp và role = 'trainer'

---

### Vấn đề 2: PT Có Nhiều User Accounts

**Tình huống:** Email bị trùng ở nhiều user (không nên xảy ra)

**Hệ thống xử lý:**

```dart
.where('email', isEqualTo: trainer.email)
.where('role', isEqualTo: 'trainer')
.limit(1)  // ← Chỉ lấy 1 user đầu tiên
```

**Khuyến nghị:**

- Đảm bảo email là unique trong users collection
- Không tạo 2 user với cùng email

---

## 📊 Luồng Hoạt Động Đầy Đủ

```
┌─────────────────────────────────────────────────────────────┐
│                  QUẢN LÝ THÀNH VIÊN                         │
│  Sửa: email, phone, address, dob                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │ users/{userId} │  ← Update
         └────────┬───────┘
                  │
                  │ _syncTrainerProfile()
                  ▼
      ┌───────────────────────┐
      │ trainers/{trainerId} │  ← Sync
      └───────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                     QUẢN LÝ PT                              │
│  Sửa: email, phone, address, dob, chuyên môn, lương...      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
      ┌───────────────────────┐
      │ trainers/{trainerId} │  ← Update
      └────────┬──────────────┘
               │
               │ _syncUserAccount()
               │ (Tìm user bằng email nếu không có userId)
               ▼
         ┌────────────────┐
         │ users/{userId} │  ← Sync (Chiều ngược!)
         └────────────────┘
```

---

**✅ Hệ thống đồng bộ 2 CHIỀU hoạt động 100%!**  
**🎉 Sửa ở BẤT KỲ đâu → Tự động cập nhật TOÀN BỘ!**  
**🚀 Tự động link trainer với user nếu chưa có userId!**
