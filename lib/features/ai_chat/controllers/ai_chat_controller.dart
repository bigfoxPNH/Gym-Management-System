import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat_message.dart';

/// Controller cho AI Chat
class AIChatController extends GetxController {
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatOpen = false.obs;
  final Rx<Offset> _iconPosition = Offset.zero.obs;

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
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            'Xin chào! Tôi là trợ lý AI của Gym Pro. Tôi có thể giúp gì cho bạn?',
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

    // Simulate AI response (sẽ được thay thế bằng logic thực tế sau)
    await Future.delayed(const Duration(seconds: 1));

    _isTyping.value = false;

    // Thêm tin nhắn phản hồi của AI
    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _generateMockResponse(content),
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(aiMessage);
  }

  String _generateMockResponse(String userMessage) {
    // Mock response - sẽ được thay thế bằng AI thực tế
    return 'Cảm ơn bạn đã nhắn tin! Hiện tại tính năng AI đang được phát triển. Tin nhắn của bạn: "$userMessage"';
  }

  void clearMessages() {
    _messages.clear();
    _addWelcomeMessage();
  }
}
