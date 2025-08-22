# Lưu Trữ Ảnh với Firestore (FREE)

## ✅ Giải Pháp MIỄN PHÍ
Thay vì sử dụng Firebase Storage (tính phí), ứng dụng này sử dụng **Firestore** để lưu ảnh dưới dạng Base64.

## 🚀 Ưu Điểm:
- **Hoàn toàn MIỄN PHÍ** trong giới hạn Firestore
- **Không cần Storage rules** 
- **Tích hợp sẵn** với user data
- **Không cần upgrade billing plan**

## 📊 Giới Hạn:
- **Kích thước ảnh**: Tối đa 500KB
- **Định dạng**: JPG, PNG 
- **Kích thước**: Tự động resize 512x512px
- **Chất lượng**: 70% để giảm dung lượng

## 🛠️ Cách Hoạt Động:
1. Người dùng chọn ảnh từ Gallery/Camera
2. Ảnh được resize và compress
3. Convert sang Base64 string
4. Lưu vào Firestore field `avatarUrl`
5. Hiển thị từ Base64 data

## 💾 Lưu Trữ:
```json
{
  "id": "user123",
  "avatarUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...",
  "fullName": "John Doe",
  // ... other fields
}
```

## 🎯 Không Cần Setup Gì Thêm!
Firestore đã sẵn sàng sử dụng với Firebase Auth.
