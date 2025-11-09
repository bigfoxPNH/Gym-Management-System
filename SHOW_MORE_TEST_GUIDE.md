# Hướng Dẫn Test Chức Năng "Hiện Thêm"

## 📋 Tổng Quan

Chức năng "hiện thêm" cho phép người dùng xem thêm kết quả tìm kiếm khi có nhiều kết quả phù hợp.

## 🔧 Cách Hoạt Động

### 1. **Lưu Trạng Thái Tìm Kiếm**

- Mỗi khi tìm kiếm bài tập hoặc món ăn, hệ thống lưu:
  - `_lastSearchResults`: Danh sách tất cả kết quả
  - `_lastSearchType`: Loại tìm kiếm ('exercise' hoặc 'nutrition')
  - `_lastDisplayCount`: Số lượng đã hiển thị

### 2. **Phát Hiện Intent "Show More"**

Bot phát hiện các từ khóa:

- "hiện thêm", "hien them"
- "xem thêm", "xem them"
- "show more", "more"
- "tiếp", "tiep"
- "nữa", "nua"
- "còn nữa", "con nua"

### 3. **Hiển Thị Thêm Kết Quả**

- Mỗi lần hiển thị thêm 5 kết quả
- Cập nhật `_lastDisplayCount` để tracking
- Thông báo còn bao nhiêu kết quả

---

## 🧪 Test Cases

### Test 1: Hiện Thêm Bài Tập

```
Bước 1: "các bài tập chân"
→ Bot hiện 5 bài tập đầu
→ Bot nói: "Còn X bài tập khác phù hợp. Nói 'hiện thêm' để xem tiếp!"

Bước 2: "hiện thêm"
→ Bot hiện 5 bài tiếp theo (6-10)
→ Cập nhật: "Còn Y bài tập khác..."

Bước 3: "hiện thêm" (tiếp)
→ Bot hiện 5 bài tiếp (11-15)
```

**Expected Result:**

- ✅ Hiển thị đúng 5 bài mỗi lần
- ✅ Số thứ tự liên tục (1,2,3... → 6,7,8... → 11,12,13...)
- ✅ Thông báo còn bao nhiêu bài chính xác
- ✅ Khi hết: "Đã hiển thị hết X kết quả phù hợp!"

---

### Test 2: Hiện Thêm Món Ăn

```
Bước 1: "món ăn giảm cân"
→ Bot hiện 5 món đầu
→ Bot nói: "Còn X món khác..."

Bước 2: "xem thêm"
→ Bot hiện 5 món tiếp theo
→ Hiển thị giá, calories, protein, etc.

Bước 3: "tiếp"
→ Bot hiện 5 món tiếp
```

**Expected Result:**

- ✅ Format hiển thị đúng: tên, giá, calories, protein, carb, fat
- ✅ Số thứ tự liên tục
- ✅ Tracking chính xác số món đã hiển thị

---

### Test 3: Hiện Thêm Món Ăn Với Filter Phức Tạp

```
Bước 1: "món ăn rẻ mà nhiều protein"
→ Bot hiện 5 món phù hợp
→ Tất cả món đều giá rẻ + nhiều protein

Bước 2: "hiện thêm"
→ Bot hiện 5 món tiếp theo
→ Vẫn giữ filter: rẻ + nhiều protein
```

**Expected Result:**

- ✅ Tất cả món trong lần 2 vẫn thỏa điều kiện ban đầu
- ✅ Không bị mất filter

---

### Test 4: Hiện Thêm Khi Không Có Tìm Kiếm Trước Đó

```
Bước 1: Mở chat bot mới (không có history)

Bước 2: "hiện thêm"
→ Bot: "❌ CHƯA CÓ KẾT QUẢ TÌM KIẾM"
→ Gợi ý tìm kiếm trước
```

**Expected Result:**

- ✅ Không crash
- ✅ Thông báo rõ ràng cần tìm kiếm trước

---

### Test 5: Hiện Thêm Khi Đã Hết Kết Quả

```
Bước 1: "gợi ý bài tập"
→ Bot hiện 5 bài
→ Giả sử chỉ có đúng 5 bài

Bước 2: "hiện thêm"
→ Bot: "✅ ĐÃ HIỂN THỊ HẾT"
→ Bot: "Bạn đã xem hết tất cả 5 kết quả..."
```

**Expected Result:**

- ✅ Không hiện kết quả trống
- ✅ Thông báo rõ đã hết

---

### Test 6: Chuyển Đổi Giữa Bài Tập và Món Ăn

```
Bước 1: "các bài tập chân"
→ Bot hiện bài tập

Bước 2: "hiện thêm"
→ Bot hiện thêm bài tập

Bước 3: "món ăn giảm cân"
→ Bot hiện món ăn (reset trạng thái)

Bước 4: "hiện thêm"
→ Bot hiện thêm món ăn (KHÔNG phải bài tập)
```

**Expected Result:**

- ✅ Mỗi lần tìm kiếm mới reset trạng thái
- ✅ "Hiện thêm" luôn hiện đúng loại vừa tìm

---

### Test 7: Số Lượng Yêu Cầu Cụ Thể

```
Bước 1: "1 bài tập chân"
→ Bot hiện 1 bài (displayCount = 1)

Bước 2: "hiện thêm"
→ Bot hiện 5 bài tiếp theo (2-6)
→ Không bị limit 1 nữa
```

**Expected Result:**

- ✅ "Hiện thêm" luôn hiện 5 item, không theo số yêu cầu ban đầu

---

### Test 8: Các Cách Nói Khác Nhau

```
Test tất cả các cách nói:
- "hiện thêm" ✅
- "hien them" ✅
- "xem thêm" ✅
- "show more" ✅
- "more" ✅
- "tiếp" ✅
- "nữa" ✅
- "còn nữa" ✅
```

**Expected Result:**

- ✅ Tất cả đều work, không phân biệt có dấu hay không

---

## 🎯 Checklist Tổng Quan

### Functionality

- [ ] Bot nhận dạng đúng "hiện thêm" intent
- [ ] Lưu đúng search results từ exercise query
- [ ] Lưu đúng search results từ nutrition query
- [ ] Hiển thị đúng 5 items mỗi lần
- [ ] Tracking đúng số lượng đã hiển thị
- [ ] Format hiển thị đúng cho exercise
- [ ] Format hiển thị đúng cho nutrition

### Edge Cases

- [ ] Xử lý đúng khi chưa có tìm kiếm
- [ ] Xử lý đúng khi đã hết kết quả
- [ ] Reset đúng khi tìm kiếm mới
- [ ] Chuyển đổi đúng giữa exercise và nutrition

### UX

- [ ] Thông báo rõ ràng còn bao nhiêu kết quả
- [ ] Số thứ tự liên tục (không reset về 1)
- [ ] Emoji phù hợp cho từng loại
- [ ] Gợi ý "hiện thêm" ở exercise query
- [ ] Gợi ý "hiện thêm" ở nutrition query

---

## 🐛 Debug Tips

### Nếu "Hiện Thêm" Không Hoạt Động:

1. **Check intent detection:**

   ```dart
   print('Intent detected: $intent');
   ```

2. **Check saved state:**

   ```dart
   print('Last results count: ${_lastSearchResults.length}');
   print('Last display count: $_lastDisplayCount');
   print('Last search type: $_lastSearchType');
   ```

3. **Check remaining items:**
   ```dart
   final remaining = _lastSearchResults.skip(_lastDisplayCount).toList();
   print('Remaining items: ${remaining.length}');
   ```

---

## 📊 Expected Behavior Summary

| Trường Hợp                 | Hành Động   | Kết Quả                                   |
| -------------------------- | ----------- | ----------------------------------------- |
| Chưa tìm kiếm              | "hiện thêm" | Thông báo cần tìm kiếm trước              |
| Có 10 kết quả, hiện 5      | "hiện thêm" | Hiện 5 kết quả tiếp (6-10)                |
| Có 12 kết quả, đã hiện 10  | "hiện thêm" | Hiện 2 kết quả còn lại (11-12)            |
| Đã hiện hết                | "hiện thêm" | Thông báo đã xem hết                      |
| Tìm exercise rồi nutrition | "hiện thêm" | Hiện thêm nutrition (không phải exercise) |

---

## ✅ Success Criteria

- ✅ Người dùng có thể xem hết tất cả kết quả bằng "hiện thêm"
- ✅ Không bị giới hạn bởi displayCount ban đầu
- ✅ Thông báo rõ ràng, không confusing
- ✅ Performance tốt (không load lại từ đầu)
- ✅ State management chính xác
