import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat_message.dart';
import '../services/ai_data_service.dart';
import '../services/body_metrics_calculator.dart';
import '../services/ai_engine.dart';

/// Controller cho AI Chat với AI Engine thông minh
class AIChatController extends GetxController {
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatOpen = false.obs;
  final Rx<Offset> _iconPosition = Offset.zero.obs;

  // AI Services
  late final AIDataService _dataService;
  late final BodyMetricsCalculator _calculator;
  late final AIEngine _aiEngine;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping.value;
  bool get isChatOpen => _isChatOpen.value;
  Offset get iconPosition => _iconPosition.value;

  void updateIconPosition(Offset position) {
    _iconPosition.value = position;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAI();
  }

  /// Khởi tạo AI Engine
  Future<void> _initializeAI() async {
    try {
      _dataService = AIDataService();
      await _dataService.initialize();

      _calculator = BodyMetricsCalculator(_dataService);
      _aiEngine = AIEngine(_dataService, _calculator);

      _addWelcomeMessage();
      print('✅ AI Chat Controller initialized successfully');
    } catch (e) {
      print('❌ Error initializing AI: $e');
      _addErrorMessage();
    }
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '''
 Xin chào! Tôi là Gym Pro AI - trợ lý thông minh của bạn!

 Tôi có thể giúp bạn:
• Tính BMI, BMR, TDEE
• Tư vấn bài tập
• Gợi ý dinh dưỡng
• Lịch tập chi tiết
• Thông tin gói thẻ

Bạn cần giúp gì? 
''',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _addErrorMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Xin lỗi, đã có lỗi khi khởi tạo AI. Vui lòng thử lại sau! 😔',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void toggleChat() {
    _isChatOpen.value = !_isChatOpen.value;
  }

  void openChat() {
    _isChatOpen.value = true;
  }

  void closeChat() {
    _isChatOpen.value = false;
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Thêm tin nhắn của user
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    // Hiển thị typing indicator
    _isTyping.value = true;

    try {
      // Xử lý tin nhắn qua AI Engine
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate thinking
      final response = await _aiEngine.processMessage(content);

      _isTyping.value = false;

      // Thêm tin nhắn phản hồi của AI
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
    } catch (e) {
      _isTyping.value = false;

      // Thêm tin nhắn lỗi
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Xin lỗi, có lỗi xảy ra khi xử lý tin nhắn của bạn. 😔\n\n$e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }
  }

  void clearMessages() {
    _messages.clear();
    _aiEngine.clearContext();
    _addWelcomeMessage();
  }
}
