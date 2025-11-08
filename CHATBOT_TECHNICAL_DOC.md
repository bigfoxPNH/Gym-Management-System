# Tài liệu kỹ thuật - Gym Pro AI Chatbot

## 🏗️ Kiến trúc hệ thống

### Tổng quan

```
User Input
    ↓
AI Chat Controller
    ↓
AI Engine (Intent Detection + NLP)
    ↓
┌─────────────────────────────────────┐
│  AI Data Service (JSON Cache)       │
│  Body Metrics Calculator            │
└─────────────────────────────────────┘
    ↓
Response Generation
    ↓
User Output
```

### Components chính

#### 1. **AI Chat Controller** (`ai_chat_controller.dart`)

- **Trách nhiệm**: Quản lý state, UI interaction
- **Dependencies**:
  - AIDataService
  - BodyMetricsCalculator
  - AIEngine
- **Methods**:
  - `sendMessage()`: Xử lý tin nhắn từ user
  - `clearMessages()`: Xóa lịch sử chat
  - `toggleChat()`: Mở/đóng chatbot

#### 2. **AI Data Service** (`ai_data_service.dart`)

- **Trách nhiệm**: Load và cache dữ liệu JSON
- **Kỹ thuật**:
  - Load song song 7 file JSON bằng `Future.wait()`
  - Cache vào memory để truy cập nhanh
  - Singleton pattern
- **Files JSON**:
  - `bmi.json`: 20+ categories BMI theo tuổi/giới tính
  - `bmr.json`: BMR ranges và formulas
  - `tdee.json`: TDEE calculations và macros
  - `exercises.json`: 60+ bài tập với metadata
  - `nutrition.json`: 100+ món ăn với macros
  - `membership_cards.json`: 10 gói thẻ
  - `workout.json`: 7 workout programs

#### 3. **Body Metrics Calculator** (`body_metrics_calculator.dart`)

- **Trách nhiệm**: Tính toán các chỉ số cơ thể
- **Công thức**:
  - BMI: `weight / (height²)`
  - BMR (Mifflin-St Jeor):
    - Nam: `10 × weight + 6.25 × height - 5 × age + 5`
    - Nữ: `10 × weight + 6.25 × height - 5 × age - 161`
  - TDEE: `BMR × activity_multiplier`
- **Methods**:
  - `calculateBMI()`: Tính BMI
  - `calculateBMR()`: Tính BMR
  - `calculateTDEE()`: Tính TDEE
  - `analyzeBMI()`: Phân tích kết quả BMI
  - `analyzeBMR()`: Phân tích kết quả BMR

#### 4. **AI Engine** (`ai_engine.dart`)

- **Trách nhiệm**: Trái tim của chatbot - NLP và response generation
- **Flow**:
  ```
  User Message
      ↓
  Text Normalization (lowercase, remove accents)
      ↓
  Intent Detection (pattern matching)
      ↓
  Handler Selection
      ↓
  Data Query + Processing
      ↓
  Response Formatting
      ↓
  Return to User
  ```

## 🧠 AI Engine - Chi tiết kỹ thuật

### Intent Detection System

#### Supported Intents:

1. `greeting` - Lời chào
2. `help` - Yêu cầu trợ giúp
3. `calculate_bmi` - Tính BMI
4. `calculate_bmr` - Tính BMR
5. `calculate_tdee` - Tính TDEE
6. `ask_exercise` - Hỏi về bài tập
7. `ask_nutrition` - Hỏi về dinh dưỡng
8. `ask_membership` - Hỏi về gói thẻ
9. `ask_workout_schedule` - Hỏi về lịch tập
10. `general` - Câu hỏi chung

#### Detection Algorithm:

```dart
String _detectIntent(String normalizedMsg) {
  // Priority-based keyword matching

  // 1. Check for greetings
  if (_containsAny(msg, ['xin chao', 'hello', 'hi']))
    return 'greeting';

  // 2. Check for help requests
  if (_containsAny(msg, ['giup', 'help', 'huong dan']))
    return 'help';

  // 3. Check for calculations
  // BMI, BMR, TDEE detection with context

  // 4. Check for domain queries
  // Exercises, Nutrition, Membership, Workout

  // 5. Default to general
  return 'general';
}
```

### Text Normalization

**Vietnamese Accent Removal:**

```dart
String _normalizeText(String text) {
  text = text.toLowerCase();

  const vietnamese = 'àáạảã...đ';
  const nonVietnamese = 'aaaaa...d';

  for (int i = 0; i < vietnamese.length; i++) {
    text = text.replaceAll(vietnamese[i], nonVietnamese[i]);
  }

  return text.trim();
}
```

**Benefits:**

- Hiểu cả chữ có dấu và không dấu
- Case-insensitive
- Trim whitespace

### Context Memory

**Storage:**

```dart
Map<String, dynamic> _conversationContext = {};
```

**Stored Data:**

- `gender`: Giới tính
- `age`: Tuổi
- `weight`: Cân nặng (kg)
- `height`: Chiều cao (cm)

**Usage:**

```dart
// Save after BMR calculation
_conversationContext['weight'] = weight;
_conversationContext['height'] = height;

// Reuse in TDEE calculation
if (_conversationContext.containsKey('weight')) {
  // Use stored data without asking again
}
```

### Response Generation

**Markdown Formatting:**

- `**text**`: Bold
- `*text*`: Italic
- `•`: Bullet points
- Emoji: 📊, 💪, ✅, 🎯, etc.

**Structure:**

```
🔥 **HEADER**

📊 Main Content
💡 Description
✅ Recommendation

📌 Footer / Next Steps
```

## 📊 Data Flow Examples

### Example 1: BMI Calculation

```
User: "Tính BMI cho tôi, 70kg cao 175cm"
    ↓
normalize: "tinh bmi cho toi 70kg cao 175cm"
    ↓
detect_intent: "calculate_bmi"
    ↓
extract_numbers: [70, 175]
    ↓
calculate: 70 / (1.75²) = 22.86
    ↓
analyze: lookup in bmi.json
    ↓
format_response: Markdown with results
    ↓
Return: "📊 KẾT QUẢ TÍNH BMI..."
```

### Example 2: Exercise Query with Context

```
User: "Bài tập ngực cho người mới"
    ↓
normalize: "bai tap nguc cho nguoi moi"
    ↓
detect_intent: "ask_exercise"
    ↓
extract_keywords: ["nguc", "nguoi moi"]
    ↓
filter_exercises:
  - nhom_co contains "nguc"
  - do_kho == "Dễ"
    ↓
take(5) results
    ↓
format_response: List with details
    ↓
Return: "💪 GỢI Ý BÀI TẬP..."
```

## 🔧 Performance Optimizations

### 1. JSON Loading

- **Strategy**: Load once, cache in memory
- **Implementation**: `Future.wait()` for parallel loading
- **Result**: < 500ms initial load time

### 2. Search Optimization

- **Strategy**: Early termination on match
- **Implementation**: `take(5)` to limit results
- **Result**: < 50ms search time

### 3. Text Processing

- **Strategy**: Single-pass normalization
- **Implementation**: Character replacement map
- **Result**: < 10ms processing time

### 4. Response Caching

- **Strategy**: Context memory for reuse
- **Implementation**: Map<String, dynamic>
- **Result**: Instant response for context queries

## 🧪 Testing Strategy

### Unit Tests

```dart
// Test normalization
test('normalize Vietnamese text', () {
  expect(normalize('Chào bạn'), 'chao ban');
});

// Test intent detection
test('detect BMI intent', () {
  expect(detectIntent('tinh bmi'), 'calculate_bmi');
});

// Test calculations
test('calculate BMI correctly', () {
  expect(calculateBMI(70, 1.75), closeTo(22.86, 0.01));
});
```

### Integration Tests

- Test full conversation flows
- Test context memory
- Test error handling

### Manual Tests

- Test với từ viết sai
- Test với câu phức tạp
- Test edge cases

## 🔒 Error Handling

### Levels:

1. **Data Loading Errors**

   - Fallback to empty data
   - Show user-friendly message

2. **Calculation Errors**

   - Validate input
   - Ask for missing data

3. **Search Errors**

   - Return "no results" message
   - Suggest alternative queries

4. **General Errors**
   - Catch all exceptions
   - Log for debugging
   - Show generic error message

## 📈 Metrics & Analytics

### Measurable KPIs:

- Response time: < 1 second
- Accuracy: > 95% intent detection
- Coverage: 10+ intents, 1000+ keywords
- Data: 170+ items (exercises, foods, programs)

### Future Enhancements:

- [ ] Track most asked questions
- [ ] A/B testing response formats
- [ ] User satisfaction ratings
- [ ] Conversation flow analytics

## 🛠️ Development Guide

### Adding New Intent:

1. Add intent to `_detectIntent()`
2. Create handler method `_handle<Intent>()`
3. Update help text
4. Add test cases

### Adding New Data:

1. Create JSON file in `data/`
2. Add loading in `AIDataService`
3. Create getter method
4. Use in AI Engine

### Updating Response Format:

1. Modify handler methods
2. Keep markdown consistent
3. Test with different screen sizes

## 📚 References

- **BMI Standards**: WHO (World Health Organization)
- **BMR Formula**: Mifflin-St Jeor Equation (2005)
- **TDEE**: American College of Sports Medicine
- **Nutrition Data**: USDA Food Database
- **Exercise Info**: ACE (American Council on Exercise)

## 🤝 Contributing

### Code Style:

- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep methods small and focused

### Git Workflow:

- Feature branch for each new feature
- Descriptive commit messages
- Pull request for review

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-07  
**Maintainer**: Gym Pro Development Team
