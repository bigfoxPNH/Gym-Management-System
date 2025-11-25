# Hướng Dẫn Quản Lý Sản Phẩm với Base64

## Thay Đổi Chính

### ✅ Đã Sửa

1. **Lưu ảnh dưới dạng Base64** thay vì Firebase Storage

   - Tương thích với Firebase Free Plan
   - Không cần Firebase Storage và Cloud Functions
   - Lưu trực tiếp vào Firestore

2. **Giới hạn kích thước ảnh**

   - Mỗi ảnh tối đa 500KB
   - Cảnh báo nếu ảnh quá lớn
   - Tối ưu cho Firestore document size limit (1MB)

3. **Tự động khởi tạo collection**
   - Tạo collection `products` nếu chưa tồn tại
   - Không cần setup thủ công

## Cách Sử Dụng

### Thêm Sản Phẩm Mới

1. Vào "Quản Lý Sản Phẩm" từ trang admin
2. Nhấn nút "Thêm sản phẩm" (màu tím)
3. Điền thông tin:

   - **Tên sản phẩm**: Ví dụ "Optimum Nutrition Gold Standard Whey"
   - **Nhóm sản phẩm**: Chọn từ dropdown (11 loại)
   - **Hãng sản xuất**: Ví dụ "Optimum Nutrition"
   - **Giá gốc**: Giá niêm yết
   - **Giá bán**: Giá sau giảm (phải <= giá gốc)
   - **Số lượng tồn kho**: Số nguyên dương
   - **Trạng thái**: Còn hàng / Sắp hết / Hết hàng
   - **Mô tả**: Chi tiết về sản phẩm
   - **Ảnh**: Chọn nhiều ảnh (mỗi ảnh < 500KB)

4. Nhấn "Thêm sản phẩm"

### Lưu Ý Quan Trọng

⚠️ **Kích thước ảnh**:

- Mỗi ảnh phải < 500KB
- Khuyến nghị: Resize ảnh trước khi upload
- Dùng công cụ online: TinyPNG, Squoosh, etc.

⚠️ **Số lượng ảnh**:

- Có thể thêm nhiều ảnh cho 1 sản phẩm
- Tổng dung lượng document nên < 800KB
- Khuyến nghị: 2-3 ảnh mỗi sản phẩm

## Cấu Trúc Dữ Liệu

### Firestore Collection: `products`

```json
{
  "id": "auto-generated",
  "name": "Optimum Nutrition Gold Standard Whey",
  "category": "Whey Protein",
  "manufacturer": "Optimum Nutrition",
  "originalPrice": 2200000,
  "sellingPrice": 1900000,
  "stockQuantity": 50,
  "description": "Whey protein tinh khiết...",
  "images": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  ],
  "status": "inStock",
  "createdAt": "2025-11-25T10:00:00.000Z",
  "updatedAt": "2025-11-25T10:00:00.000Z"
}
```

## Các Nhóm Sản Phẩm

1. **Whey Protein** - Protein nhanh
2. **Mass Gainer** - Tăng cân nhanh
3. **Casein** - Protein chậm
4. **EAAs** - Amino acid thiết yếu
5. **BCAAs** - Amino acid chuỗi nhánh
6. **Creatine** - Tăng sức mạnh
7. **Pre-workout** - Trước tập
8. **Vitamin & Khoáng chất**
9. **Đồ ăn liền** - Protein bars, snacks
10. **Dụng cụ tập** - Equipment
11. **Khác** - Sản phẩm khác

## Tính Năng

### ✅ Hoàn Thành

- [x] CRUD đầy đủ (Thêm, Sửa, Xóa, Xem)
- [x] Tìm kiếm sản phẩm
- [x] Lọc theo nhóm
- [x] Thống kê (Tổng SP, Sắp hết, Hết hàng)
- [x] Upload nhiều ảnh (base64)
- [x] Hiển thị giảm giá (%)
- [x] Cảnh báo tồn kho thấp
- [x] Validation đầy đủ
- [x] Loading states
- [x] Error handling

### 🔄 Có Thể Cải Tiến

- [ ] Image compression tự động
- [ ] Crop ảnh trước khi save
- [ ] Export danh sách ra Excel
- [ ] Import sản phẩm từ CSV
- [ ] Quản lý variants (size, color)
- [ ] Batch operations (xóa nhiều)

## Troubleshooting

### Lỗi: "Ảnh quá lớn"

**Giải pháp**:

1. Dùng TinyPNG để nén ảnh: https://tinypng.com/
2. Hoặc resize ảnh về 800x800px
3. Giảm quality xuống 70-80%

### Lỗi: "Không thể lưu sản phẩm"

**Kiểm tra**:

1. Đã đăng nhập với tài khoản admin?
2. Firestore rules đã deploy?
3. Tất cả trường required đã điền?
4. Giá bán <= Giá gốc?

### Lỗi: "Products collection not found"

**Giải pháp**: App tự động tạo collection khi lần đầu thêm sản phẩm.

## Files Đã Thay Đổi

1. **lib/views/admin/product_detail_view.dart**

   - Xóa Firebase Storage
   - Thêm base64 encoding
   - Thêm file size validation
   - Thêm auto-initialize collection

2. **lib/views/admin/product_management_view.dart**

   - Thêm base64 image rendering
   - Import dart:convert

3. **lib/utils/initialize_products_collection.dart** (MỚI)
   - Helper tự động tạo collection

## Code Changes Summary

### Before (Firebase Storage)

```dart
// Upload to Storage
final ref = FirebaseStorage.instance.ref().child(fileName);
await ref.putData(bytes);
final url = await ref.getDownloadURL();
```

### After (Base64 in Firestore)

```dart
// Convert to base64
final base64String = base64Encode(bytes);
final base64Image = 'data:image/jpeg;base64,$base64String';
```

## Lưu Ý Firestore Free Plan

✅ **Cho phép**:

- 1GB storage (đủ cho ~2000-3000 ảnh 500KB)
- 50K reads/day
- 20K writes/day
- 20K deletes/day

⚠️ **Hạn chế**:

- Document size: Max 1MB
- Collection size: Unlimited
- No automatic backups

💡 **Best Practices**:

- Nén ảnh trước khi upload
- Giới hạn 2-3 ảnh/sản phẩm
- Monitor Firestore usage
- Backup định kỳ

---

**Cập nhật**: 25/11/2025
**Version**: 2.0 (Base64 Storage)
