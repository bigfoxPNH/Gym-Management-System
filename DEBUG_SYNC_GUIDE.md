# 🔍 DEBUG ĐỒNG BỘ - HƯỚNG DẪN KIỂM TRA

## 🎯 **Mục Đích**

Tìm ra nguyên nhân chính xác tại sao UI không đồng bộ sau khi sửa dữ liệu.

---

## 📋 **Test Case 1: Sửa Email Trong Quản Lý Thành Viên**

### Steps:

1. **Đăng nhập** vào hệ thống
2. Mở **Quản lý thành viên**
3. Tìm PT **Trần Hà Linh** (email: `trinhhalan@gmail.com`)
4. Click **Edit** (icon ✏️)
5. Sửa email: `trinhhalan@gmail.com` → `test123@gmail.com`
6. Click **Cập nhật**

### Expected Console Logs:

```
🔄 [SYNC] Starting sync trainer profile for userId: {userId}
✅ [SYNC] Found 1 trainer profile(s)
✅ [SYNC] Synced trainer profile {trainerId} for userId: {userId}
📝 [SYNC] Updated data: {email: test123@gmail.com, ...}

🔄 [MemberMgmt] Attempting to reload TrainerManagementController...
✅ [MemberMgmt] Found TrainerManagementController, reloading...
✅ [MemberMgmt] TrainerManagementController reloaded successfully!
```

### Kiểm Tra:

- [ ] Console có log "🔄 [SYNC] Starting sync..."?

  - ❌ Không → `_syncTrainerProfile()` không được gọi
  - ✅ Có → Tiếp tục kiểm tra

- [ ] Console có log "✅ [SYNC] Found 1 trainer profile(s)"?

  - ❌ Không → Trainer không có `userId` hoặc query sai
  - ✅ Có → Sync thành công

- [ ] Console có log "🔄 [MemberMgmt] Attempting to reload..."?

  - ❌ Không → Code reload không được chạy
  - ✅ Có → Tiếp tục kiểm tra

- [ ] Console có log "✅ [MemberMgmt] Found TrainerManagementController"?
  - ❌ Không → **VẤN ĐỀ: TrainerManagementController chưa được tạo**
  - ✅ Có → Controller reload thành công

### Kiểm Tra UI:

7. Mở tab mới → **Quản lý PT**
8. Tìm PT **Trần Hà Linh**

**Expected:**

- Email hiển thị: `test123@gmail.com` ✅

**Nếu vẫn hiển thị email cũ:**

- Vấn đề: **UI không reload** hoặc **Firestore chưa cập nhật**
- Debug: Check Firestore Console xem email đã update chưa

---

## 📋 **Test Case 2: Sửa SĐT Trong Quản Lý PT**

### Steps:

1. Mở **Quản lý PT**
2. Click **Edit** PT **Trần Hà Linh**
3. Sửa SĐT: `0325545876` → `0999888777`
4. Click **Cập nhật**

### Expected Console Logs:

```
Linked trainer {trainerId} with userId: {userId}
Synced user account {userId} with trainer data

🔄 [TrainerMgmt] Attempting to reload MemberManagementController...
✅ [TrainerMgmt] Found MemberManagementController, reloading...
✅ [TrainerMgmt] MemberManagementController reloaded successfully!
```

### Kiểm Tra:

- [ ] Console có log "Synced user account"?

  - ❌ Không → `_syncUserAccount()` không được gọi
  - ✅ Có → Sync thành công

- [ ] Console có log "🔄 [TrainerMgmt] Attempting to reload..."?

  - ❌ Không → Code reload không được chạy
  - ✅ Có → Tiếp tục kiểm tra

- [ ] Console có log "✅ [TrainerMgmt] Found MemberManagementController"?
  - ❌ Không → **VẤN ĐỀ: MemberManagementController chưa được tạo**
  - ✅ Có → Controller reload thành công

### Kiểm Tra UI:

5. Quay lại **Quản lý thành viên**
6. Tìm PT **Trần Hà Linh**

**Expected:**

- SĐT hiển thị: `0999888777` ✅

---

## 📋 **Test Case 3: Xóa PT**

### Steps:

1. Mở **Quản lý thành viên**
2. Click menu ⋮ của PT → **Xóa**
3. Xác nhận xóa

### Expected Console Logs:

```
Deleted trainer profile for userId: {userId}

🔄 [MemberMgmt.delete] Attempting to reload TrainerManagementController...
✅ [MemberMgmt.delete] Found TrainerManagementController, reloading...
✅ [MemberMgmt.delete] TrainerManagementController reloaded successfully!
```

### Kiểm Tra UI:

4. Vào **Quản lý PT**

**Expected:**

- PT đã bị xóa không còn hiển thị ✅

---

## 🔍 **Các Vấn Đề Có Thể Xảy Ra**

### ❌ **Vấn Đề 1: Controller Not Found**

**Console Log:**

```
⚠️ [MemberMgmt] TrainerManagementController not found: ...
```

**Nguyên Nhân:**

- Màn **Quản lý PT** chưa được mở → Controller chưa được tạo

**Giải Pháp:**

1. Mở **Quản lý PT** trước
2. Sau đó mới sửa trong **Quản lý thành viên**
3. Quay lại **Quản lý PT** → UI sẽ cập nhật

**Lưu ý:**

- Đây là **GIỚI HẠN** của lazy initialization
- Chỉ reload được controller **ĐÃ TỒN TẠI**
- Nếu chưa mở màn hình → Controller chưa tạo → Không reload được

---

### ❌ **Vấn Đề 2: Sync Không Được Gọi**

**Console Log:**

- KHÔNG CÓ log "🔄 [SYNC] Starting sync..."

**Nguyên Nhân:**

- `_syncTrainerProfile()` không được gọi trong `updateUser()`
- Role check sai

**Debug:**

- Check code trong `updateUser()`:
  ```dart
  if (newRole == 'trainer') {
    await _syncTrainerProfile(userId, userData);
  }
  ```

---

### ❌ **Vấn Đề 3: Trainer Không Có userId**

**Console Log:**

```
⚠️ [SYNC] No trainer profile found for userId: {userId}
```

**Nguyên Nhân:**

- Trainer document trong Firestore **KHÔNG CÓ** field `userId`

**Giải Pháp:**

1. Mở Firestore Console
2. Vào collection `trainers`
3. Tìm document của PT
4. Kiểm tra xem có field `userId` không
5. Nếu không có → Thêm manually hoặc sửa email trong Quản lý PT (sẽ auto-link)

---

### ❌ **Vấn Đề 4: UI Không Reload Dù Console Log OK**

**Console Log:**

```
✅ [MemberMgmt] TrainerManagementController reloaded successfully!
```

**Nhưng UI vẫn hiển thị dữ liệu cũ**

**Nguyên Nhân:**

- GetX observable không trigger rebuild
- `filteredTrainers.value` không được set

**Debug:**

1. Check `loadTrainers()`:

   ```dart
   trainers.value = snapshot.docs.map(...).toList();
   applyFilters(); // ← Phải có dòng này!
   ```

2. Check `applyFilters()`:
   ```dart
   filteredTrainers.value = filtered; // ← Phải set .value!
   ```

---

## 🎯 **Kịch Bản Test Hoàn Chỉnh**

### Scenario: 2 Tabs Cùng Lúc

**Setup:**

1. Mở **2 tab Chrome**
2. Tab 1: Đăng nhập → Mở **Quản lý thành viên**
3. Tab 2: Đăng nhập (cùng account) → Mở **Quản lý PT**

**Test:** 4. Trong **Tab 1**, sửa email PT 5. Nhìn sang **Tab 2** → Email có cập nhật không?

**Expected với Current Implementation:**

- ❌ **Tab 2 KHÔNG tự động cập nhật** (vì không có real-time listener)
- ✅ **Tab 2 cập nhật SAU KHI refresh** (F5 hoặc click reload)

**Lý Do:**

- Controllers chỉ reload **TRONG CÙNG 1 APP INSTANCE**
- Nhiều tabs = Nhiều app instances riêng biệt
- Cần dùng **StreamBuilder** hoặc **Firestore Snapshot Listener** để real-time sync giữa tabs

---

## 📝 **Checklist Debug**

Khi test, điền vào checklist này:

### Test 1: Sửa Email (Quản lý thành viên)

- [ ] Console có log sync start
- [ ] Console có log sync success
- [ ] Console có log reload TrainerMgmt start
- [ ] Console có log reload TrainerMgmt success
- [ ] Firestore `trainers` có email mới
- [ ] UI Quản lý PT hiển thị email mới (sau khi mở lại)

### Test 2: Sửa SĐT (Quản lý PT)

- [ ] Console có log sync user account
- [ ] Console có log reload MemberMgmt start
- [ ] Console có log reload MemberMgmt success
- [ ] Firestore `users` có SĐT mới
- [ ] UI Quản lý thành viên hiển thị SĐT mới

### Test 3: Xóa PT

- [ ] Console có log deleted trainer profile
- [ ] Console có log reload TrainerMgmt start
- [ ] Console có log reload TrainerMgmt success
- [ ] Firestore `trainers` không còn document
- [ ] Firestore `users` không còn document
- [ ] UI Quản lý PT không còn hiển thị PT

---

## 🚀 **Hướng Dẫn Thực Hiện**

1. **Mở DevTools Console** (F12 trong Chrome)
2. **Clear console** (để dễ theo dõi logs)
3. **Thực hiện Test Case 1**
4. **Copy toàn bộ console logs** và gửi lại
5. Báo cáo kết quả:
   - ✅ Logs nào có
   - ❌ Logs nào không có
   - UI có cập nhật không

→ Từ đó tôi sẽ xác định chính xác vấn đề nằm ở đâu!
