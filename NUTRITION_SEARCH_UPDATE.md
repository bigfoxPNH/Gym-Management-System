# 🥗 CẬP NHẬT - TÌM KIẾM MÓN ĂN THEO GIÁ

## 📅 Ngày cập nhật: 9 tháng 11, 2025

---

## 🚀 Tính Năng Mới

Chatbot AI giờ đây có thể tìm kiếm món ăn theo **mức giá**, giúp người dùng dễ dàng lựa chọn món ăn phù hợp với ngân sách!

---

## ✨ Các Mức Giá Hỗ Trợ

### 1. **💰 Rẻ**

- Món ăn tiết kiệm, giá dưới 20,000đ/phần
- Ví dụ: Cơm trắng, Rau muống, Khoai lang, Cơm gạo lứt

### 2. **💵 Bình Dân**

- Món ăn giá phải chăng, 20,000đ - 50,000đ/phần
- Ví dụ: Ức gà, Thịt heo, Trứng gà, Đậu phụ

### 3. **💴 Trung Bình**

- Món ăn giá vừa phải, 50,000đ - 100,000đ/phần
- Ví dụ: Chuối, Cam, Táo, Thịt bò kho

### 4. **💎 Tương Đối Đắt**

- Món ăn cao cấp, trên 100,000đ/phần
- Ví dụ: Cá hồi, Thịt bò xào, Bún riêu cua

---

## 🎯 Cách Tìm Kiếm

### Tìm Theo Giá Đơn Thuần:

```
✅ "món ăn giá rẻ"
✅ "món ăn bình dân"
✅ "món ăn trung bình"
✅ "món ăn đắt"
✅ "món ăn cao cấp"
✅ "món ăn tiết kiệm"
```

### Tìm Kết Hợp Giá + Mục Tiêu:

```
✅ "món ăn giá rẻ giảm cân"
✅ "món ăn bình dân tăng cơ"
✅ "món ăn tiết kiệm giàu protein"
✅ "món ăn rẻ ít calo"
```

### Tìm Kết Hợp Giá + Loại:

```
✅ "trái cây giá rẻ"
✅ "rau củ bình dân"
✅ "thịt giá trung bình"
✅ "hải sản cao cấp"
```

### Tìm Kết Hợp Giá + Dinh Dưỡng:

```
✅ "món ăn giá rẻ giàu protein"
✅ "món ăn bình dân nhiều carb"
✅ "món ăn tiết kiệm ít calo"
```

---

## 📊 Dữ Liệu Hiện Có

### Phân Bố Theo Giá:

- **Rẻ:** ~15 món (Cơm, Rau, Khoai, Đậu...)
- **Bình Dân:** ~20 món (Thịt heo, Ức gà, Trứng, Tôm...)
- **Trung Bình:** ~15 món (Trái cây, Thịt bò, Cá...)
- **Tương Đối Đắt:** ~5 món (Cá hồi, Bún riêu...)

**Tổng cộng:** 50+ món ăn

---

## 🧪 Test Cases

### Test 1: Tìm Món Rẻ

```
User: "món ăn giá rẻ"
Bot: → Hiện Cơm trắng, Rau muống, Khoai lang, Rau cải...
```

### Test 2: Tìm Món Bình Dân Tăng Cơ

```
User: "món ăn bình dân tăng cơ"
Bot: → Hiện Ức gà, Trứng gà, Thịt heo...
```

### Test 3: Tìm Món Rẻ Giảm Cân

```
User: "món ăn giá rẻ giảm cân"
Bot: → Hiện Rau muống, Rau cải, Canh rau...
```

### Test 4: Tìm Trái Cây Giá Rẻ

```
User: "trái cây giá rẻ"
Bot: → Hiện Chuối, Cam, Táo... (nếu có trong dữ liệu)
```

### Test 5: Tìm Món Cao Cấp

```
User: "món ăn đắt giá trị dinh dưỡng cao"
Bot: → Hiện Cá hồi, Thịt bò xào...
```

---

## 📋 Kết Quả Hiển Thị

### Format Mới:

```
🥗 GỢI Ý DINH DƯỠNG

💰 Lọc theo giá: rẻ

1. **Cơm trắng**
   💰 Giá: rẻ
   📊 Năng lượng: 130 kcal/100g
   💪 Protein: 2.7g
   🍚 Carb: 28.2g
   🥑 Béo: 0.3g
   🌾 Chất xơ: 0.4g
   ✅ Lợi ích: Cung cấp năng lượng nhanh cho cơ thể...

2. **Rau muống xào tỏi**
   💰 Giá: rẻ
   📊 Năng lượng: 90 kcal/100g
   💪 Protein: 3.5g
   🍚 Carb: 6g
   🥑 Béo: 5g
   🌾 Chất xơ: 2.5g
   ✅ Lợi ích: Giàu vitamin A, C, chất xơ...
```

---

## 🔧 Cải Tiến Kỹ Thuật

### 1. Scoring System

Mỗi món ăn được chấm điểm dựa trên:

```
+ Khớp tên món: +5 điểm
+ Khớp giá: +3 điểm
+ Khớp loại (thực vật/động vật/trái cây): +2 điểm
+ Khớp dinh dưỡng (protein/carb/calo): +2 điểm
+ Khớp mục đích (giảm cân/tăng cơ): +2 điểm

→ Sắp xếp theo điểm giảm dần
```

### 2. Filter Logic

```dart
// Tìm theo giá
if (_containsAny(msg, ['re', 'gia re', 'tiet kiem'])) {
  priceFilter = 'rẻ';
} else if (_containsAny(msg, ['binh dan', 'vua tui'])) {
  priceFilter = 'bình dân';
} else if (_containsAny(msg, ['trung binh'])) {
  priceFilter = 'trung bình';
} else if (_containsAny(msg, ['dat', 'cao cap'])) {
  priceFilter = 'tương đối đắt';
}

// So khớp với dữ liệu
if (priceFilter != null) {
  final foodPrice = _normalizeText(food['gia'] ?? '');
  if (foodPrice == _normalizeText(priceFilter)) {
    matches = true;
    matchScore += 3;
  }
}
```

### 3. Intent Detection

Mở rộng từ khóa nhận diện:

```dart
// Nutrition queries - Thêm từ khóa giá
if (_containsAny(normalizedMsg, [
  'thuc don',
  'mon an',
  'gia re',      // MỚI
  'binh dan',    // MỚI
  'tiet kiem',   // MỚI
  'dat',         // MỚI
  'cao cap',     // MỚI
  ...
])) {
  return 'ask_nutrition';
}
```

---

## 📝 Ví Dụ Câu Hỏi Chi Tiết

### 🟢 Câu Hỏi Đơn Giản:

```
"món ăn rẻ"
"món ăn giá rẻ"
"món ăn tiết kiệm"
"món ăn bình dân"
"món ăn vừa túi tiền"
"món ăn cao cấp"
"món ăn đắt"
```

### 🟡 Câu Hỏi Trung Bình:

```
"món ăn giá rẻ cho người giảm cân"
"món ăn bình dân giàu protein"
"trái cây giá rẻ"
"rau củ tiết kiệm"
"món ăn rẻ nhưng bổ dưỡng"
```

### 🔴 Câu Hỏi Phức Tạp:

```
"món ăn giá rẻ ít calo giàu chất xơ"
"món ăn bình dân tăng cơ nhiều protein"
"thực đơn tiết kiệm cho người tập gym"
"món ăn đắt tiền giá trị dinh dưỡng cao"
```

---

## ✅ Checklist Test

- [ ] Tìm món theo giá rẻ
- [ ] Tìm món theo giá bình dân
- [ ] Tìm món theo giá trung bình
- [ ] Tìm món theo giá đắt
- [ ] Kết hợp giá + mục tiêu (giảm cân, tăng cơ)
- [ ] Kết hợp giá + loại món (trái cây, rau củ, thịt)
- [ ] Kết hợp giá + dinh dưỡng (protein, carb, calo)
- [ ] Hiển thị thông tin giá trong kết quả
- [ ] Sorting theo điểm phù hợp
- [ ] Thông báo lọc theo giá

---

## 🎓 Lợi Ích Cho Người Dùng

### ✨ Trước:

- ❌ Không tìm được món theo ngân sách
- ❌ Phải tự lọc và chọn món
- ❌ Không biết món nào phù hợp túi tiền

### ✅ Sau:

- ✅ Tìm nhanh món ăn theo giá
- ✅ Kết hợp nhiều filter (giá + mục tiêu + dinh dưỡng)
- ✅ Gợi ý thông minh dựa trên ngân sách
- ✅ Tiết kiệm thời gian lựa chọn
- ✅ Tối ưu chi phí mà vẫn đảm bảo dinh dưỡng

---

## 💡 Use Cases Thực Tế

### Sinh viên với ngân sách hạn chế:

```
"món ăn giá rẻ giàu protein tăng cơ"
→ Trứng gà, Đậu phụ, Thịt heo luộc...
```

### Người tập gym muốn tiết kiệm:

```
"món ăn bình dân giảm mỡ nhiều protein"
→ Ức gà, Cá rô phi, Tôm hấp...
```

### Người cần giảm cân tiết kiệm:

```
"món ăn rẻ ít calo giảm cân"
→ Rau muống, Canh rau, Rau cải...
```

### Người muốn đầu tư dinh dưỡng cao:

```
"món ăn đắt giá trị dinh dưỡng cao tăng cơ"
→ Cá hồi, Thịt bò, Bún riêu cua...
```

---

## 🚀 Kế Hoạch Phát Triển Tiếp

### Phase 2:

- [ ] Thêm giá cụ thể (VNĐ) cho từng món
- [ ] Tính tổng chi phí cho thực đơn
- [ ] Gợi ý combo món ăn theo ngân sách
- [ ] So sánh giá giữa các món tương tự

### Phase 3:

- [ ] Filter theo khoảng giá (< 30k, 30-50k, > 50k)
- [ ] Gợi ý thay thế món đắt bằng món rẻ
- [ ] Tối ưu dinh dưỡng theo ngân sách
- [ ] Thống kê chi phí ăn uống theo tuần/tháng

---

## 📞 Test Ngay

```bash
flutter run
```

Thử các câu hỏi:

1. "món ăn giá rẻ"
2. "món ăn bình dân tăng cơ"
3. "món ăn tiết kiệm giảm cân"
4. "trái cây giá rẻ"
5. "món ăn rẻ giàu protein"

---

**Chúc bạn tìm được món ăn phù hợp với ngân sách! 💰🥗😊**
