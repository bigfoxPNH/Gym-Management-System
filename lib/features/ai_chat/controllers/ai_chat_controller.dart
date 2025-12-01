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

  // ScrollController để tự động scroll đến tin nhắn mới
  final ScrollController scrollController = ScrollController();

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

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Scroll xuống tin nhắn mới nhất
  void scrollToBottom() {
    // Đợi cho đến khi ScrollController có clients và đã render xong
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (scrollController.hasClients) {
        // Delay nhỏ để đảm bảo UI đã render xong
        await Future.delayed(const Duration(milliseconds: 100));

        if (scrollController.hasClients) {
          final position = scrollController.position;
          // Scroll hoàn toàn xuống cuối để tin nhắn mới hiển thị
          scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
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
 Xin chào! Tôi là Gym Pro AI trợ lý thông minh của bạn!

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
    // Không auto scroll khi hiện welcome message
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
    // Không auto scroll khi mở chat
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

    // Scroll đến tin nhắn user vừa gửi
    scrollToBottom();

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

      // KHÔNG scroll khi AI trả lời - để user đọc ở vị trí hiện tại
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

      // KHÔNG scroll khi có lỗi - để user đọc ở vị trí hiện tại
    }
  }

  void clearMessages() {
    _messages.clear();
    _aiEngine.clearContext();
    _addWelcomeMessage();
  }
}
