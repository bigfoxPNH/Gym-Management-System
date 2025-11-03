# AI Chat Feature

## Cấu trúc thư mục

```
lib/features/ai_chat/
├── controllers/          # Logic xử lý chat
│   └── ai_chat_controller.dart
├── models/              # Data models
│   └── chat_message.dart
├── views/               # UI screens
│   └── ai_chat_view.dart
├── widgets/             # UI components
│   └── draggable_ai_chat_button.dart
└── data/                # JSON data files
    └── intents.json     # Training data cho AI
```

## Tính năng hiện tại

- ✅ Icon chatbot có thể di chuyển (draggable)
- ✅ Giới hạn di chuyển trong vùng màn hình (padding 10px từ mép)
- ✅ Giao diện chat với AI
- ✅ Hiển thị tin nhắn user và AI
- ✅ Typing indicator khi AI đang trả lời
- ✅ Cấu trúc dữ liệu JSON cho training

## Tính năng cần phát triển

### Phase 1: Basic AI

- [ ] Tích hợp model AI (sử dụng intents.json)
- [ ] Pattern matching cho câu hỏi thường gặp
- [ ] Response templates

### Phase 2: Advanced Features

- [ ] Lưu lịch sử chat vào Firestore
- [ ] Context awareness (nhớ ngữ cảnh chat)
- [ ] Multi-turn conversations
- [ ] Quick reply buttons

### Phase 3: Integration

- [ ] Kết nối với dữ liệu Gym Pro (gói tập, PT, lịch tập)
- [ ] Đề xuất gói tập dựa trên nhu cầu user
- [ ] Đặt lịch tập qua chat
- [ ] Thống kê và báo cáo từ chat

### Phase 4: Advanced AI

- [ ] Tích hợp API AI (OpenAI, Gemini, etc.)
- [ ] Natural Language Understanding
- [ ] Sentiment analysis
- [ ] Voice input/output

## Cách sử dụng

### Controller Setup

```dart
final controller = Get.put(AIChatController());
```

### Gửi tin nhắn

```dart
controller.sendMessage("Xin chào");
```

### Mở/đóng chat

```dart
controller.openChat();
controller.closeChat();
```

## Dữ liệu Training (intents.json)

File `data/intents.json` chứa các patterns và responses cho chatbot:

```json
{
  "intents": [
    {
      "tag": "greeting",
      "patterns": ["Xin chào", "Hello"],
      "responses": ["Xin chào! Tôi có thể giúp gì?"]
    }
  ]
}
```

Có thể mở rộng thêm các intent mới cho các tính năng khác.

## TODO

1. Implement pattern matching từ intents.json
2. Thêm context management
3. Tích hợp Firestore để lưu chat history
4. Thêm quick actions (đặt lịch, xem gói tập, etc.)
5. Implement AI API integration (optional)
