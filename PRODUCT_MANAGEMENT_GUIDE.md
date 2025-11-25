# Hệ Thống Quản Lý Sản Phẩm Gym

## Tổng quan

Hệ thống quản lý sản phẩm bổ sung (supplements) và phụ kiện gym cho admin.

## Cấu trúc

### 1. Model: Product (`lib/models/product.dart`)

**Thuộc tính:**

- `id`: ID sản phẩm
- `name`: Tên sản phẩm
- `category`: Nhóm sản phẩm (Whey Protein, Mass, Creatine, etc.)
- `manufacturer`: Hãng sản xuất
- `originalPrice`: Giá gốc
- `sellingPrice`: Giá bán
- `stockQuantity`: Số lượng tồn kho
- `description`: Mô tả sản phẩm
- `images`: Danh sách ảnh sản phẩm
- `status`: Trạng thái (Còn hàng, Hết hàng, Sắp hết)
- `createdAt`, `updatedAt`: Thời gian tạo/cập nhật

**Nhóm sản phẩm được hỗ trợ:**

- Whey Protein
- Mass
- Casein
- EAAs
- BCAAs
- Creatine
- Pre-workout
- Vitamin - Khoáng chất
- Đồ ăn liền
- Dụng cụ tập
- Khác

### 2. Controller: ProductManagementController

**Chức năng:**

- `loadProducts()`: Tải danh sách sản phẩm
- `addProduct(Product)`: Thêm sản phẩm mới
- `updateProduct(Product)`: Cập nhật sản phẩm
- `deleteProduct(String)`: Xóa sản phẩm
- `updateProductStatus(String, ProductStatus)`: Cập nhật trạng thái
- `filterProducts()`: Lọc sản phẩm theo danh mục và từ khóa

**Thống kê:**

- `getTotalStockValue()`: Tổng giá trị tồn kho
- `getLowStockCount()`: Số sản phẩm sắp hết
- `getOutOfStockCount()`: Số sản phẩm hết hàng

### 3. Views

#### ProductManagementView (`lib/views/admin/product_management_view.dart`)

**Tính năng:**

- Hiển thị danh sách sản phẩm với thông tin đầy đủ
- Cards thống kê: Tổng SP, Sắp hết, Hết hàng
- Thanh tìm kiếm theo tên, hãng, nhóm
- Filter chips theo nhóm sản phẩm
- Hiển thị ảnh, giá, % giảm giá, số lượng, trạng thái
- Actions: Edit, Delete
- FAB button để thêm sản phẩm mới

#### ProductDetailView (`lib/views/admin/product_detail_view.dart`)

**Tính năng:**

- Form nhập liệu đầy đủ với validation
- Upload nhiều ảnh từ thiết bị (Firebase Storage)
- Preview và xóa ảnh
- Dropdown chọn nhóm sản phẩm và trạng thái
- Tự động upload ảnh lên Firebase Storage
- Hiển thị progress khi đang lưu

## Cách sử dụng

### Thêm sản phẩm mới

1. Truy cập trang chủ admin
2. Click vào icon "Sản Phẩm"
3. Click nút FAB "Thêm sản phẩm"
4. Điền thông tin:
   - Thêm ảnh (click "Thêm ảnh")
   - Nhập tên sản phẩm
   - Chọn nhóm sản phẩm
   - Nhập hãng sản xuất
   - Nhập giá gốc và giá bán
   - Nhập số lượng tồn kho
   - Chọn trạng thái
   - Nhập mô tả
5. Click "Thêm sản phẩm"

### Chỉnh sửa sản phẩm

1. Click vào card sản phẩm hoặc menu "..." > "Chỉnh sửa"
2. Cập nhật thông tin cần thiết
3. Click "Cập nhật sản phẩm"

### Xóa sản phẩm

1. Click menu "..." trên card sản phẩm
2. Chọn "Xóa"
3. Xác nhận xóa

### Tìm kiếm và lọc

- **Tìm kiếm:** Gõ từ khóa vào thanh tìm kiếm (tìm theo tên, hãng, nhóm)
- **Lọc theo nhóm:** Click vào filter chip nhóm sản phẩm

## Firestore Structure

```
products/
  {productId}/
    - id: string
    - name: string
    - category: string
    - manufacturer: string
    - originalPrice: number
    - sellingPrice: number
    - stockQuantity: number
    - description: string
    - images: array<string>
    - status: string (in_stock | out_of_stock | low_stock)
    - createdAt: timestamp
    - updatedAt: timestamp
```

## Security Rules

- **Read**: Public (tất cả users)
- **Create/Update/Delete**: Chỉ admin

## Routes

- `/admin/product-management`: Danh sách sản phẩm
- `/admin/product-detail`: Chi tiết/Thêm/Sửa sản phẩm

## Dependencies cần thiết

```yaml
dependencies:
  cloud_firestore: latest
  firebase_storage: latest
  image_picker: latest
  get: latest
  intl: latest
```

## UI/UX Features

- Material Design với màu deepPurple theme
- Statistics cards với icons và màu sắc phân biệt
- Search bar với real-time filtering
- Filter chips cho nhóm sản phẩm
- Product cards với:
  - Ảnh sản phẩm (fallback icon nếu không có)
  - Tên, hãng, nhóm
  - Giá và % giảm giá (nếu có)
  - Số lượng tồn kho với màu cảnh báo
  - Status badge với màu tương ứng
  - Menu actions
- Image gallery với khả năng thêm/xóa nhiều ảnh
- Form validation đầy đủ
- Loading states và error handling

## Best Practices

1. **Validation**: Tất cả fields bắt buộc đều có validation
2. **Image Upload**: Upload song song nhiều ảnh, hiển thị progress
3. **Error Handling**: Snackbar thông báo lỗi rõ ràng
4. **Auto-calculation**: Tự động tính % giảm giá và cảnh báo low stock
5. **Responsive**: Sử dụng Grid/List view phù hợp với màn hình
6. **Performance**: Lazy loading images, efficient filtering

## Mở rộng trong tương lai

- [ ] Quản lý đơn hàng sản phẩm
- [ ] Thống kê doanh thu theo sản phẩm
- [ ] Barcode scanning
- [ ] Import/Export CSV
- [ ] Notifications khi sản phẩm sắp hết
- [ ] Lịch sử thay đổi giá
- [ ] Reviews và ratings từ khách hàng
