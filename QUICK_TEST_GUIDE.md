# Hướng Dẫn Test Nhanh Chức Năng Tìm Kiếm

## Test Vietnamese Foods

1. Gõ **"pho"** - nên tìm thấy "Phở bò"
2. Gõ **"banh"** - nên tìm thấy "Bánh mì thịt nướng"
3. Gõ **"bun"** - nên tìm thấy "Bún chả", "Bún bò Huế"
4. Gõ **"com"** - nên tìm thấy "Cơm tấm"

## Test USDA API

1. Gõ **"rice"** - nên tìm thấy các loại gạo từ USDA
2. Gõ **"chicken"** - nên tìm thấy thịt gà
3. Gõ **"apple"** - nên tìm thấy táo

## Logs cần chú ý

- **Vietnamese foods**: "All Vietnamese foods: 8" và "Filtered Vietnamese foods: X"
- **USDA API**: "Found X foods in response" và "First food structure: ..."
- **Kết quả cuối**: "Total results: X" và "Final search results: X"

## Nếu vẫn không hoạt động

- Kiểm tra console browser (F12) xem có lỗi JavaScript không
- Kiểm tra network tab xem API calls có thành công không
- Kiểm tra terminal logs để xem debug info

