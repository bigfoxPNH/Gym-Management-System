# 🚀 Quick Start: PT Role & Dashboard System

## ⚡ Tạo Tài Khoản PT Nhanh

### Bước 1: Tạo User Account

Trong Firestore Console, thêm document vào collection `users`:

```json
{
  "id": "pt001",
  "fullName": "Nguyễn Văn Mạnh",
  "email": "manh.pt@gympro.vn",
  "role": "trainer",
  "phone": "0901234567",
  "avatarUrl": null,
  "address": "123 Nguyễn Văn Cừ, Q5, TP.HCM",
  "gender": "male",
  "dob": 725846400000,
  "createdAt": 1729900800000,
  "updatedAt": 1729900800000
}
```

### Bước 2: Tạo Trainer Profile

Thêm document vào collection `trainers`:

```json
{
  "userId": "pt001",
  "hoTen": "Nguyễn Văn Mạnh",
  "email": "manh.pt@gympro.vn",
  "soDienThoai": "0901234567",
  "gioiTinh": "male",
  "namSinh": 725846400000,
  "anhDaiDien": null,
  "diaChi": "123 Nguyễn Văn Cừ, Q5, TP.HCM",
  "bangCap": [
    "Cử nhân TDTT Đại học TDTT TP.HCM",
    "ISSA Certified Personal Trainer"
  ],
  "chuyenMon": ["Tăng cơ", "Boxing", "HIIT", "Dinh dưỡng"],
  "moTa": "10 năm kinh nghiệm huấn luyện thể hình và boxing. Chuyên về tăng cơ giảm mỡ hiệu quả.",
  "chungChi": ["ISSA-CPT-2019", "CrossFit-Level1-2020"],
  "trangThai": "active",
  "mucLuongCoBan": 15000000,
  "hoaHongPhanTram": 15,
  "ngayVaoLam": 1577836800000,
  "danhGiaTrungBinh": 4.8,
  "soLuotDanhGia": 45,
  "facebookUrl": "https://facebook.com/manhpt",
  "instagramUrl": "https://instagram.com/manhpt",
  "createdAt": 1729900800000,
  "updatedAt": 1729900800000,
  "createdBy": "admin"
}
```

### Bước 3: Tạo Firebase Auth

1. Vào Firebase Console → Authentication
2. Click "Add User"
3. Email: `manh.pt@gympro.vn`
4. Password: `Test@123` (hoặc password của bạn)
5. User UID: `pt001` (QUAN TRỌNG: phải trùng với user document ID)

### Bước 4: Login & Test

1. Chạy app: `flutter run`
2. Login với email: `manh.pt@gympro.vn`
3. Verify: Auto-redirect to PT Dashboard
4. Check stats, assignments, reviews

---

## 🧪 Test Checklist

- [ ] Login successful
- [ ] Auto-redirect to `/pt/dashboard`
- [ ] Welcome card shows name & rating
- [ ] Stats cards display (clients, reviews, sessions, revenue)
- [ ] Quick action buttons work
- [ ] Assignments section shows (even if empty)
- [ ] Reviews section shows (even if empty)
- [ ] Pull-to-refresh works
- [ ] Update session dialog opens
- [ ] Complete assignment dialog opens

---

## 📊 Add Sample Assignments (Optional)

Thêm vào collection `trainer_assignments`:

```json
{
  "trainerId": "trainer_id_from_trainers_collection",
  "userId": "user123",
  "trainerName": "Nguyễn Văn Mạnh",
  "userName": "Trần Văn Nam",
  "soBuoiDangKy": 20,
  "soBuoiHoanThanh": 8,
  "mucGia": 300000,
  "trangThai": "active",
  "ngayBatDau": 1729900800000,
  "ghiChuTienDo": "Đang tập tốt, cần tăng cường cardio",
  "createdAt": 1729900800000,
  "updatedAt": 1729900800000,
  "createdBy": "admin"
}
```

## 📝 Add Sample Reviews (Optional)

Thêm vào collection `trainer_reviews`:

```json
{
  "trainerId": "trainer_id_from_trainers_collection",
  "userId": "user123",
  "userName": "Trần Văn Nam",
  "rating": 5,
  "comment": "PT Mạnh rất nhiệt tình và chuyên nghiệp. Tôi đã giảm được 10kg trong 3 tháng!",
  "tags": ["Nhiệt tình", "Chuyên nghiệp", "Hiệu quả"],
  "createdAt": 1729900800000,
  "updatedAt": 1729900800000
}
```

---

## 🎯 Expected Results

### Stats Should Show:

- **Tổng học viên**: Number of unique clients from assignments
- **Đánh giá**: Total review count
- **Tổng buổi tập**: Sum of all registered sessions
- **Doanh thu**: Sum of (price × completed sessions)

### Welcome Card:

- Avatar or fallback icon
- Trainer name
- Average rating with stars
- Quick stats (clients, sessions, completion %)

### Assignments:

- Progress bars with percentages
- Update & Complete buttons
- Client names & dates
- Price per session

### Reviews:

- Star ratings (1-5)
- Comments
- Tags as colored chips
- Dates

---

## 🔥 Pro Tips

1. **Link trainerId correctly**: Make sure `trainerId` in assignments/reviews matches the document ID in `trainers` collection

2. **Match userId**: `userId` field in `trainers` document MUST match `id` field in `users` document AND Firebase Auth UID

3. **Use timestamps**: All dates should be in milliseconds since epoch (use `Timestamp.now()` or timestamp converter)

4. **Test empty states**: Login with new PT (no data) to see empty state messages

5. **Pull to refresh**: Test data updates by pulling down from top

---

## 🐛 Troubleshooting

### "Không tìm thấy hồ sơ PT"

- Check: `userId` in trainer document matches Firebase Auth UID
- Check: trainer document exists in Firestore
- Try: Click "Thử lại" button

### Stats showing 0

- Add sample assignments to `trainer_assignments` collection
- Make sure `trainerId` matches trainer document ID
- Refresh dashboard

### Auto-redirect not working

- Check: user role is exactly `'trainer'` (lowercase)
- Check: `isTrainer` getter in UserAccount model
- Clear app data and login again

---

## 📞 Support

If you encounter issues:

1. Check Firebase Console for data
2. Check Flutter Console for errors
3. Read [PT_ROLE_SYSTEM_GUIDE.md](PT_ROLE_SYSTEM_GUIDE.md) for details

---

**Happy Testing!** 🎉
