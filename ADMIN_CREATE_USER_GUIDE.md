# 🚀 QUICK START: Tạo User Mới Khi Admin Đã Đăng Nhập

## 📖 Tổng quan

Khi Admin tạo user mới, hệ thống sẽ yêu cầu xác thực mật khẩu Admin để đảm bảo:

- ✅ Admin không bị logout
- ✅ Không tự động đăng nhập bằng tài khoản user mới
- ✅ Bảo mật cao hơn

---

## 🎯 Hướng dẫn sử dụng

### Bước 1: Vào màn Quản lý thành viên

```
Home → Menu → Quản Lý Thành Viên
```

### Bước 2: Nhấn nút thêm thành viên

```
Tap icon "+" ở góc trên bên phải
```

### Bước 3: Điền thông tin user mới

```
┌─────────────────────────────────┐
│ Thêm Thành Viên                 │
├─────────────────────────────────┤
│ Họ và tên: [____________]       │
│ Email: [_______________]        │
│ Mật khẩu: [____________]        │
│ Số điện thoại: [_______]        │
│ Ngày sinh: [___________]        │
│ Địa chỉ: [_____________]        │
│ Quyền: [▼ Hội viên ▼]          │
│                                 │
│  [Hủy]         [Tạo mới]       │
└─────────────────────────────────┘
```

### Bước 4: Xác thực mật khẩu Admin

```
Sau khi nhấn "Tạo mới", dialog xuất hiện:

┌─────────────────────────────────┐
│ 🔒 Xác thực Admin               │
├─────────────────────────────────┤
│ Để tạo thành viên mới, vui lòng │
│ xác nhận mật khẩu Admin của bạn:│
│                                 │
│ Mật khẩu Admin:                 │
│ [●●●●●●●●]                      │
│                                 │
│ ℹ️ Mật khẩu sẽ được dùng để     │
│   khôi phục phiên đăng nhập     │
│                                 │
│  [Hủy]      [Xác nhận]         │
└─────────────────────────────────┘
```

**Nhập mật khẩu Admin** → Nhấn "Xác nhận" hoặc Enter

### Bước 5: Hoàn tất ✅

```
✅ Thành công
   Đã tạo thành viên mới: [Tên user]
```

---

## ❓ FAQ - Câu hỏi thường gặp

### Q1: Tại sao phải nhập mật khẩu Admin?

**A:** Do hạn chế của Firebase Authentication (không có backend), khi tạo user mới, Firebase tự động đăng nhập vào tài khoản đó. Để giữ Admin không bị logout, chúng ta cần:

1. Tạo user mới
2. Đăng xuất user mới
3. Đăng nhập lại Admin (cần mật khẩu)

### Q2: Mật khẩu Admin có được lưu lại không?

**A:** **KHÔNG**. Mật khẩu chỉ tồn tại trong bộ nhớ tạm và bị xóa ngay sau khi sử dụng xong.

### Q3: Nếu nhập sai mật khẩu Admin thì sao?

**A:** Hệ thống sẽ:

- Hiển thị lỗi: "Mật khẩu không đúng"
- User mới KHÔNG được tạo
- Admin có thể bị logout (cần đăng nhập lại)

### Q4: Có thể hủy ở bước xác thực không?

**A:** **CÓ**. Nhấn "Hủy" → User mới không được tạo → Quay về màn quản lý.

### Q5: Tôi quên mật khẩu Admin thì làm sao?

**A:**

- Nhấn "Hủy" để thoát
- Đăng xuất → Chọn "Quên mật khẩu" → Reset qua email
- Hoặc liên hệ Super Admin

### Q6: Có cách nào tạo user mà không cần nhập password không?

**A:** Hiện tại không có. Trong tương lai, có thể sử dụng:

- Firebase Cloud Functions với Admin SDK
- Backend API riêng

### Q7: Password dialog có thể tự động điền không?

**A:** Không được khuyến khích vì lý do bảo mật. Tuy nhiên, bạn có thể:

- Sử dụng password manager (LastPass, 1Password, Bitwarden)
- Autofill từ trình duyệt (nếu chạy trên web)

---

## 🛡️ Bảo mật

### Điều cần biết:

✅ **Mật khẩu không được lưu trữ** đâu cả  
✅ **Chỉ sử dụng trong session hiện tại** để re-authenticate  
✅ **Biến bị xóa** ngay sau khi hoàn tất  
✅ **TextField dạng `obscureText`** (ẩn ký tự khi nhập)

### Rủi ro:

⚠️ Nếu có người nhìn qua vai khi bạn nhập password  
⚠️ Nếu device bị malware keylogger (hiếm)

### Khuyến nghị:

- Đảm bảo nhập password trong môi trường an toàn
- Không chia sẻ password Admin
- Đổi password định kỳ

---

## 🔧 Troubleshooting

### Vấn đề 1: Dialog không hiển thị

**Nguyên nhân:** Loading đang chạy  
**Giải pháp:** Đợi 1-2 giây, reload app

### Vấn đề 2: Nhập password xong không có gì xảy ra

**Nguyên nhân:** Mất kết nối internet  
**Giải pháp:**

- Kiểm tra kết nối
- Nhấn "Xác nhận" lại

### Vấn đề 3: Snackbar không hiển thị

**Nguyên nhân:** Bị che bởi dialog khác  
**Giải pháp:** Đợi vài giây, thông báo sẽ xuất hiện

### Vấn đề 4: Admin bị logout sau khi tạo user

**Nguyên nhân:** Lỗi trong quá trình re-authenticate  
**Giải pháp:**

- Đăng nhập lại Admin
- Kiểm tra console log để debug
- Báo cáo lỗi cho dev team

---

## 📞 Liên hệ hỗ trợ

Nếu gặp vấn đề không giải quyết được, vui lòng liên hệ:

- **Email:** support@gympro.com
- **Phone:** 1900-xxxx
- **GitHub Issues:** [Link to repo]

---

## 🎓 Video hướng dẫn

[Sẽ cập nhật link video demo sau]

---

**Phiên bản:** 1.0  
**Cập nhật:** 31/10/2025  
**Tác giả:** Gym Pro Dev Team
