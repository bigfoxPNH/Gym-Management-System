# Hệ Thống AI Chatbot Thông Minh - Hướng Dẫn

## 🎯 Tổng Quan

Hệ thống AI Chatbot đã được nâng cấp với khả năng **tự động phát hiện thiếu thông tin** và **hỏi lại người dùng một cách thân thiện** thay vì trả lỗi ngay lập tức.

## ✨ Tính Năng Mới

### 1. **Phát Hiện Thiếu Thông Tin Thông Minh**

AI có thể phát hiện khi người dùng:

- Nhập thiếu dữ liệu (ví dụ: chỉ có cân nặng mà không có chiều cao)
- Nhập sai định dạng
- Không rõ mục đích (muốn tính chỉ số nào)

### 2. **Hỏi Lại Thân Thiện**

Thay vì báo lỗi, AI sẽ:

- Hỏi thông tin còn thiếu một cách tự nhiên
- Gợi ý các chỉ số có thể tính
- Lưu thông tin đã nhập để không cần hỏi lại

### 3. **Gợi Ý Chỉ Số Phù Hợp**

Khi người dùng chưa rõ muốn tính gì, AI sẽ:

- Giải thích ý nghĩa từng chỉ số (BMI, BMR, TDEE)
- Gợi ý chỉ số phù hợp với mục tiêu
- Cho phép tính cả 3 chỉ số cùng lúc

### 4. **Context Memory Nâng Cao**

AI nhớ:

- Cân nặng, chiều cao đã nhập
- Tuổi, giới tính
- Mức độ vận động
- Chỉ số đang muốn tính

## 📝 Ví Dụ Sử Dụng

### Ví Dụ 1: Thiếu Thông Tin

```
👤 User: "Tính tdee nam 21 tuổi 160cm ít vận động"
🤖 AI: "Ok, bạn có thể cho mình biết cân nặng của bạn để mình tính chính xác TDEE nhé? 😊"

👤 User: "60kg"
🤖 AI: [Trả về kết quả TDEE đầy đủ với 60kg, 160cm, 21 tuổi, nam, ít vận động]
```

### Ví Dụ 2: Chỉ Có Cân Nặng

```
👤 User: "Tính bmi 65kg"
🤖 AI: "📐 Bạn cao bao nhiêu cm? 😊"

👤 User: "170"
🤖 AI: [Trả về kết quả BMI với 65kg, 170cm]
```

### Ví Dụ 3: Không Rõ Mục Đích

```
👤 User: "Tính giúp tôi xem cơ thể ổn không, tôi 60kg 170cm"
🤖 AI: "👋 Để tôi giúp bạn kiểm tra sức khỏe nhé!

📊 Với thông tin cân nặng và chiều cao, tôi có thể tính cho bạn:

🔹 **BMI** - Chỉ số khối cơ thể (đánh giá gầy/chuẩn/thừa cân)
🔹 **BMR** - Lượng calo cơ bản cơ thể cần khi nghỉ ngơi
🔹 **TDEE** - Tổng lượng calo hàng ngày dựa trên hoạt động

💡 Bạn muốn tôi tính chỉ số nào? Hoặc nếu muốn tôi tính cả 3 thì hãy nói **'tính cả 3'** nhé! 😊"

👤 User: "tính cả 3"
🤖 AI: [Trả về kết quả BMI, BMR, TDEE đầy đủ]
```

### Ví Dụ 4: Từng Bước Thu Thập Thông Tin

```
👤 User: "Tính BMR"
🤖 AI: "📏 Bạn nặng bao nhiêu kg vậy? 😊"

👤 User: "70kg"
🤖 AI: "📐 Bạn cao bao nhiêu cm? 😊"

👤 User: "175cm"
🤖 AI: "🎂 Bạn có thể cho tôi biết tuổi của bạn không? 😊"

👤 User: "25"
🤖 AI: "👤 Bạn là nam hay nữ để tôi tính chính xác hơn? 😊"

👤 User: "nam"
🤖 AI: [Trả về kết quả BMR đầy đủ]
```

### Ví Dụ 5: TDEE Với Mức Vận Động

```
👤 User: "Tính tdee"
🤖 AI: "📏 Bạn nặng bao nhiêu kg vậy? 😊"

👤 User: "70"
🤖 AI: "📐 Bạn cao bao nhiêu cm? 😊"

👤 User: "175"
🤖 AI: "🎂 Bạn có thể cho tôi biết tuổi của bạn không? 😊"

👤 User: "25"
🤖 AI: "👤 Bạn là nam hay nữ để tôi tính chính xác hơn? 😊"

👤 User: "nam"
🤖 AI: "🏃 Bạn có thường xuyên vận động không?

Chọn một trong các mức sau:
• **Ít vận động** - ngồi văn phòng, ít vận động
• **Nhẹ** - tập 1-3 buổi/tuần
• **Trung bình** - tập 3-5 buổi/tuần
• **Nhiều** - tập 6-7 buổi/tuần
• **Rất nhiều** - vận động viên chuyên nghiệp

Hãy cho tôi biết mức độ của bạn nhé! 😊"

👤 User: "tập vừa"
🤖 AI: [Trả về kết quả TDEE đầy đủ]
```

## 🧠 Logic Hoạt Động

### State Management

AI sử dụng 2 biến state chính:

1. **`_waitingFor`**: Đang chờ thông tin gì

   - `'weight'`: Chờ cân nặng
   - `'height'`: Chờ chiều cao
   - `'age'`: Chờ tuổi
   - `'gender'`: Chờ giới tính
   - `'activity'`: Chờ mức độ vận động
   - `'metric_type'`: Chờ chọn chỉ số muốn tính

2. **`_pendingCalculation`**: Đang chuẩn bị tính chỉ số nào
   - `'bmi'`: Chuẩn bị tính BMI
   - `'bmr'`: Chuẩn bị tính BMR
   - `'tdee'`: Chuẩn bị tính TDEE

### Flow Xử Lý

```
1. User gửi tin nhắn
   ↓
2. AI parse thông tin (cân nặng, chiều cao, tuổi, giới tính, mức vận động)
   ↓
3. AI lưu thông tin vào context
   ↓
4. AI kiểm tra đủ thông tin chưa?
   ├─ Đủ → Tính toán và trả kết quả
   └─ Thiếu → Set _waitingFor và hỏi lại
   ↓
5. Khi user trả lời:
   ├─ Parse thông tin từ câu trả lời
   ├─ Lưu vào context
   ├─ Clear _waitingFor
   └─ Quay lại bước 4
```

## 📊 Yêu Cầu Thông Tin Cho Mỗi Chỉ Số

### BMI

- ✅ Cân nặng (kg)
- ✅ Chiều cao (cm)
- ⚪ Tuổi (optional - dùng để phân loại chính xác hơn)
- ⚪ Giới tính (optional - dùng để phân loại chính xác hơn)

### BMR

- ✅ Cân nặng (kg)
- ✅ Chiều cao (cm)
- ✅ Tuổi
- ✅ Giới tính

### TDEE

- ✅ Cân nặng (kg)
- ✅ Chiều cao (cm)
- ✅ Tuổi
- ✅ Giới tính
- ✅ Mức độ vận động

## 🎨 Phong Cách Giao Tiếp

### Nguyên Tắc

1. **Thân thiện**: Luôn dùng emoji 😊
2. **Rõ ràng**: Hỏi từng thông tin một
3. **Hướng dẫn**: Đưa ra ví dụ cụ thể
4. **Linh hoạt**: Hiểu nhiều cách nói khác nhau

### Từ Khóa AI Hiểu

#### Cân Nặng

- "nặng", "cân", "weight"
- "60kg", "60 kg", "60 ký"

#### Chiều Cao

- "cao", "chiều cao", "height"
- "170cm", "170 cm", "1m70", "1.7m"

#### Tuổi

- "tuổi", "tuoi", "age"
- "25 tuổi", "25t", "25 years old"

#### Giới Tính

- Nam: "nam", "male", "man", "anh"
- Nữ: "nữ", "nu", "female", "woman", "chị", "cô"

#### Mức Độ Vận Động

- Ít: "ít vận động", "không tập", "ngồi nhiều"
- Nhẹ: "tập nhẹ", "1-3 buổi"
- Vừa: "tập vừa", "trung bình", "3-5 buổi"
- Nhiều: "tập nặng", "nhiều", "6-7 buổi"
- Rất nhiều: "rất nặng", "vdv", "vận động viên"

## 🔧 Cải Tiến Kỹ Thuật

### 1. Intent Detection Nâng Cao

```dart
// Thêm intent mới: general_health
if (_containsAny(normalizedMsg, [
  'chi so co the', 'suc khoe', 'co the', 'on khong', 'xem giup', 'kiem tra',
]) && (_containsAny(normalizedMsg, ['kg', 'cm']) ||
      _containsAny(normalizedMsg, ['nang', 'cao', 'can']))) {
  return 'general_health';
}
```

### 2. Pending Information Handler

```dart
String _handlePendingInformationResponse(String originalMsg, String normalizedMsg) {
  // Parse response
  // Update context
  // Clear _waitingFor if got info
  // Try calculate if complete
  // Or continue asking
}
```

### 3. Smart Context Management

```dart
// Auto-save khi parse được thông tin
if (weightHeight['weight'] != null) {
  _conversationContext['weight'] = weightHeight['weight'];
}

// Auto-detect gender
if (_containsAny(normalizedMsg, ['nu', 'chi', 'co'])) {
  _conversationContext['gender'] = 'nữ';
}
```

### 4. Graceful Fallback

```dart
// Nếu thiếu info → Hỏi lại
if (!_conversationContext.containsKey('weight')) {
  _waitingFor = 'weight';
  _pendingCalculation = 'bmi';
  return '📏 Bạn nặng bao nhiêu kg vậy? 😊';
}
```

## 🎯 Lợi Ích

### Cho Người Dùng

1. **Trải nghiệm tự nhiên**: Chat như với người thật
2. **Không bị mắc kẹt**: Luôn được hướng dẫn
3. **Tiết kiệm thời gian**: Không cần nhập lại thông tin
4. **Linh hoạt**: Nhiều cách hỏi đều được

### Cho Hệ Thống

1. **Giảm lỗi**: Ít trả lỗi hơn
2. **Tăng engagement**: User chat lâu hơn
3. **Dễ mở rộng**: Thêm chỉ số mới dễ dàng
4. **Maintainable**: Code rõ ràng, dễ debug

## 🚀 Hướng Dẫn Phát Triển Thêm

### Thêm Chỉ Số Mới

1. Thêm intent mới trong `_detectIntent()`
2. Thêm case trong `switch` của `processMessage()`
3. Tạo hàm `_handle{NewMetric}Calculation()`
4. Tạo hàm `_calculate{NewMetric}WithContext()`
5. Update `_askForMissingInformation()` với requirements mới

### Thêm Loại Thông Tin Mới

1. Thêm vào enum `_waitingFor`
2. Thêm logic parse trong `_handlePendingInformationResponse()`
3. Thêm câu hỏi trong `_askForMissingInformation()`
4. Update context saving

## 📚 Tài Liệu Liên Quan

- [CHATBOT_USER_GUIDE.md](./CHATBOT_USER_GUIDE.md) - Hướng dẫn người dùng
- [CHATBOT_TECHNICAL_DOC.md](./CHATBOT_TECHNICAL_DOC.md) - Tài liệu kỹ thuật
- [README.md](./lib/features/ai_chat/README.md) - Tổng quan tính năng

## 🐛 Debug & Testing

### Enable Debug Logging

Debug logs đã được bật mặc định:

```
🤖 AI Engine Debug:
   User msg: tính bmi
   Waiting for: null
   Pending calc: null
   Intent: calculate_bmi
   Context: {}
```

### Test Cases

1. ✅ Nhập đủ thông tin 1 lần
2. ✅ Nhập từng thông tin theo yêu cầu
3. ✅ Nhập sai thứ tự thông tin
4. ✅ Nhập thiếu thông tin
5. ✅ Hỏi chung chung về sức khỏe
6. ✅ Chat liên tục nhiều chỉ số

## 💡 Tips & Tricks

### Cho Developer

- Luôn parse thông tin trước khi check context
- Clear state sau khi hoàn thành tính toán
- Log đầy đủ để dễ debug
- Handle edge cases (giá trị bất thường)

### Cho User

- Có thể nói ngắn gọn: "60kg 170cm"
- Có thể tách ra: "60" rồi "170"
- Có thể dùng tiếng Việt hoặc tiếng Anh
- Có thể có hoặc không có dấu

## 🎉 Kết Luận

Hệ thống AI Chatbot hiện đã **thông minh hơn rất nhiều**, có khả năng:

- ✅ Tự động phát hiện thiếu thông tin
- ✅ Hỏi lại thân thiện
- ✅ Gợi ý chỉ số phù hợp
- ✅ Nhớ ngữ cảnh cuộc hội thoại
- ✅ Xử lý nhiều trường hợp khác nhau

**Trải nghiệm người dùng được nâng cao đáng kể!** 🚀
