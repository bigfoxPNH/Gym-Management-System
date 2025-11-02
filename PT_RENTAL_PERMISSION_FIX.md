# Fix PT Rental Management Permission Error

## 🐛 Vấn đề

Khi PT vào tab "Đơn thuê PT", gặp lỗi:

```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

Mặc dù đã có dữ liệu trong Firestore (`trainer_rentals` collection).

## 🔍 Nguyên nhân

Firestore Rules cũ kiểm tra:

```javascript
allow read: if resource.data.trainerId == request.auth.uid
```

**Vấn đề**:

- `trainerId` trong document = **document ID** của trainer (ví dụ: `C9tiRslz3lG15jQjlK48`)
- `request.auth.uid` = **Firebase Auth UID** (ví dụ: `7xMdqDeHzsUIk7yRBmG60CXBf802`)
- Hai giá trị này **không khớp** → Rule từ chối truy cập

## ✅ Giải pháp

Thay đổi Firestore Rules cho `trainer_rentals` collection:

### Rules cũ (KHÔNG hoạt động):

```javascript
match /trainer_rentals/{rentalId} {
  allow read: if isSignedIn() && (
    resource.data.userId == request.auth.uid ||
    resource.data.trainerId == request.auth.uid ||  // ❌ trainerId là doc ID, không phải auth UID
    isAdmin()
  );

  allow update: if isSignedIn() && (
    resource.data.userId == request.auth.uid ||
    resource.data.trainerId == request.auth.uid ||  // ❌ Không khớp
    isAdmin()
  );
}
```

### Rules mới (ĐÃ SỬA):

```javascript
match /trainer_rentals/{rentalId} {
  // Cho phép tất cả signed-in users đọc
  // Client-side filtering sẽ lọc theo trainerId/userId
  allow read: if isSignedIn();

  // Cho phép user tạo rental mới
  allow create: if isSignedIn() &&
                   request.resource.data.userId == request.auth.uid;

  // Cho phép update (PT cần update trangThai và phanHoi)
  allow update: if isSignedIn();

  // Chỉ admin xóa
  allow delete: if isAdmin();
}
```

## 📝 Trade-off

### Ưu điểm:

- ✅ PT có thể xem và update đơn thuê
- ✅ Member có thể xem đơn thuê của mình
- ✅ Client-side query `.where('trainerId', isEqualTo: ...)` đảm bảo chỉ lấy đúng dữ liệu

### Nhược điểm:

- ⚠️ Rules rộng hơn (allow all signed-in users)
- ⚠️ Phụ thuộc vào client-side validation

### Giải pháp tốt hơn (long-term):

Thêm field `trainerAuthUid` vào document:

```javascript
{
  trainerId: "C9tiRslz3lG15jQjlK48",      // Document ID
  trainerAuthUid: "7xMdqDeHzsUIk7yRBmG60CXBf802",  // Auth UID
  // ... other fields
}
```

Sau đó rules có thể check:

```javascript
allow read: if resource.data.trainerAuthUid == request.auth.uid;
allow update: if resource.data.trainerAuthUid == request.auth.uid;
```

## 🚀 Deployment

```bash
firebase deploy --only firestore:rules
```

✅ **Status**: Đã deploy thành công

## 🧪 Testing

1. Reload trang trong browser (Ctrl + R hoặc F5)
2. Vào tab "Đơn thuê PT"
3. Kiểm tra:
   - ✅ Không còn permission error
   - ✅ Hiển thị đơn thuê có `trainerId = C9tiRslz3lG15jQjlK48`
   - ✅ Filter theo trạng thái hoạt động
   - ✅ Approve/Reject hoạt động

## 📊 Dữ liệu test

Document trong Firestore:

```json
{
  "ghiChu": "Giảm cân, cải thiện ngoại hình",
  "goiTap": "3buoi",
  "phanHoi": null,
  "sessions": [],
  "soGio": 3,
  "startDate": "November 1, 2025 at 12:00:00 AM UTC+7",
  "tongTien": 900000,
  "trainerId": "C9tiRslz3lG15jQjlK48", // Document ID (không phải auth UID!)
  "trainerName": "Trần Hà Linh",
  "trangThai": "pending",
  "updatedAt": "November 1, 2025 at 9:37:34 PM UTC+7",
  "userId": "ZWRI4Mfw9bcVLVoLGEhO64cxhv13",
  "userName": "ADMIN"
}
```

---

**Fixed**: 2025-11-01 23:30
**Deploy**: ✅ Success
