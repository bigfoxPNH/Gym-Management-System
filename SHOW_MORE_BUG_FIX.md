# Bug Fix: "Hiện Thêm" Không Hoạt Động & Giá Trị Null

## 🐛 Các Lỗi Được Phát Hiện

### 1. **"Hiện Thêm" Không Hoạt Động**

**Vấn đề:**

- Người dùng gõ "hiện thêm" (có dấu) → Bot không nhận dạng được
- Chỉ hoạt động khi gõ "hien them" (không dấu)

**Nguyên nhân:**

- Intent detection chỉ check `normalizedMsg` (đã remove dấu)
- Không check message gốc có dấu

### 2. **Giá Trị Null Khi "Tiếp" Với Món Ăn**

**Vấn đề:**

- Người dùng nói "tiếp" sau khi tìm món ăn → Hiển thị giá trị null
- VD: `Protein: nullg`, `Calories: null kcal`

**Nguyên nhân:**

- Code `_handleShowMore()` sử dụng field names sai
- Nutrition data dùng: `ten_mon`, `gia`, `nang_luong_kcal`, `dam_g`, `carb_g`, `beo_g`
- Code cũ dùng: `ten`, `price`, `calories`, `protein`, `carb`, `fat`

---

## ✅ Các Sửa Chữa

### Fix 1: Update Intent Detection

**Before:**

```dart
String _detectIntent(String normalizedMsg) {
  if (_containsAny(normalizedMsg, [
    'hien them',
    'xem them',
    'show more',
    'more',
    'tiep',
    'nua',
    'con nua',
  ])) {
    return 'show_more';
  }
}
```

**After:**

```dart
String _detectIntent(String originalMsg, String normalizedMsg) {
  final lowerMsg = originalMsg.toLowerCase();
  if (_containsAny(normalizedMsg, [
    'hien them',
    'xem them',
    'show more',
    'more',
    'tiep',
    'nua',
    'con nua',
  ]) || lowerMsg.contains('hiện thêm') || lowerMsg.contains('xem thêm') || lowerMsg.contains('tiếp')) {
    return 'show_more';
  }
}
```

**Changes:**

- ✅ Function nhận thêm parameter `originalMsg` (message gốc có dấu)
- ✅ Check cả message có dấu: `'hiện thêm'`, `'xem thêm'`, `'tiếp'`
- ✅ Update caller: `_detectIntent(userMessage, normalizedMsg)`

---

### Fix 2: Correct Field Names for Nutrition

**Before:**

```dart
else if (_lastSearchType == 'nutrition') {
  response = '🍽️ **THÊM MÓN ĂN PHÙ HỢP**\n\n';

  for (var i = 0; i < nextBatch.length; i++) {
    final item = nextBatch[i]['food'] as Map<String, dynamic>;
    response += '''
${_lastDisplayCount + i + 1}. **${item['ten']}**            ❌ WRONG
   💰 Giá: ${item['price'] ?? 'Không rõ'}                    ❌ WRONG
   🔥 Calories: ${item['calories']} kcal                     ❌ WRONG
   💪 Protein: ${item['protein']}g | Carb: ${item['carb']}g ❌ WRONG
   ...
''';
  }
}
```

**After:**

```dart
else if (_lastSearchType == 'nutrition') {
  response = '🍽️ **THÊM MÓN ĂN PHÙ HỢP**\n\n';

  for (var i = 0; i < nextBatch.length; i++) {
    final food = nextBatch[i]['food'] as Map<String, dynamic>;
    final score = nextBatch[i]['score'] as int;

    response += '''
${_lastDisplayCount + i + 1}. **${food['ten_mon']}** ${score >= 10 ? '⭐' : score >= 7 ? '✨' : ''}
   💰 Giá: **${food['gia'] ?? 'N/A'}**
   📊 Năng lượng: ${food['nang_luong_kcal']} kcal/100g
   💪 Protein: ${food['dam_g']}g | 🍚 Carb: ${food['carb_g']}g | 🥑 Béo: ${food['beo_g']}g
   🌾 Chất xơ: ${food['chat_xo_g'] ?? 0}g
   ${food['phu_hop_voi'] != null ? '🎯 Phù hợp: ${food['phu_hop_voi']}\n   ' : ''}✅ ${food['loi_ich']}

''';
  }
}
```

**Field Name Mapping:**
| Old (Wrong) | New (Correct) |
|-------------|---------------|
| `ten` | `ten_mon` |
| `price` | `gia` |
| `calories` | `nang_luong_kcal` |
| `protein` | `dam_g` |
| `carb` | `carb_g` |
| `fat` | `beo_g` |
| `fiber` | `chat_xo_g` |
| `suitable_for` | `phu_hop_voi` |
| `benefits` | `loi_ich` |

**Additional Improvements:**

- ✅ Thêm score display: ⭐ (score ≥ 10), ✨ (score ≥ 7)
- ✅ Format giống như nutrition query gốc
- ✅ Hiển thị đầy đủ thông tin: Giá, Năng lượng, Protein, Carb, Béo, Chất xơ, Phù hợp, Lợi ích

---

## 🧪 Testing

### Test Case 1: "Hiện Thêm" Với Dấu

```
User: "món ăn giảm cân"
Bot: [Hiện 5 món]

User: "hiện thêm"  ← Có dấu
Bot: ✅ [Hiện thêm 5 món tiếp theo] (BEFORE: ❌ Không nhận dạng)
```

### Test Case 2: "Xem Thêm" Với Dấu

```
User: "các bài tập chân"
Bot: [Hiện 5 bài]

User: "xem thêm"  ← Có dấu
Bot: ✅ [Hiện thêm 5 bài tiếp theo] (BEFORE: ❌ Không nhận dạng)
```

### Test Case 3: "Tiếp" Với Món Ăn

```
User: "món ăn giảm cân"
Bot: [Hiện 5 món]

User: "tiếp"
Bot: ✅ [Hiện thêm 5 món với giá trị đúng]
     (BEFORE: ❌ Giá trị null)

Expected:
1. **Cơm gạo lứt** ⭐
   💰 Giá: **rẻ**
   📊 Năng lượng: 123 kcal/100g
   💪 Protein: 2.5g | 🍚 Carb: 26g | 🥑 Béo: 1g
   ...
```

### Test Case 4: Không Dấu (Vẫn Hoạt Động)

```
User: "mon an giam can"
Bot: [Hiện 5 món]

User: "hien them"  ← Không dấu
Bot: ✅ [Hiện thêm 5 món] (Vẫn work như trước)
```

---

## 📊 Impact Analysis

### What's Fixed?

- ✅ **Intent Detection**: Nhận dạng cả có dấu và không dấu
- ✅ **Field Names**: Sử dụng đúng field names từ JSON
- ✅ **Display Format**: Format đẹp và đầy đủ thông tin
- ✅ **Score Display**: Thêm emoji ⭐/✨ cho món ăn có score cao

### What's Improved?

- ✅ **User Experience**: Người dùng có thể gõ tự nhiên (có dấu)
- ✅ **Consistency**: Format giống nutrition query gốc
- ✅ **Robustness**: Handle cả 2 trường hợp có/không dấu

### Backward Compatibility?

- ✅ **100% Compatible**: Không làm break code cũ
- ✅ Vẫn support "hien them" (không dấu)
- ✅ Thêm support "hiện thêm" (có dấu)

---

## 🎯 Summary

**Files Modified:** 1

- `lib/features/ai_chat/services/ai_engine.dart`

**Functions Updated:** 2

- `_detectIntent()`: Added originalMsg parameter, check có dấu
- `_handleShowMore()`: Fixed field names for nutrition

**Lines Changed:** ~30 lines

**Testing Status:** ✅ Ready to test

- No compile errors
- No lint warnings
- Backward compatible

---

## 🚀 Next Steps

1. **Test "hiện thêm"** với món ăn (có dấu)
2. **Test "xem thêm"** với bài tập (có dấu)
3. **Test "tiếp"** với món ăn (có dấu)
4. **Verify** không có giá trị null
5. **Verify** format đúng và đẹp

---

## ✅ Checklist

- [x] Fix intent detection cho có dấu
- [x] Fix field names cho nutrition
- [x] Add score display
- [x] No compile errors
- [x] Backward compatible
- [ ] User testing completed

---

**Status:** 🟢 READY FOR TESTING
