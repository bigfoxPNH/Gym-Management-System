import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_message.dart';

/// Màn hình chat với AI với animation
class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AIChatController>();
    final screenSize = MediaQuery.of(context).size;

    return Obx(() {
      if (controller.isChatOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }

      if (!controller.isChatOpen && !_animationController.isAnimating) {
        return const SizedBox.shrink();
      }

      // Vị trí cố định của chat (góc phải dưới)
      const chatWidth = 350.0;
      const chatHeight = 500.0;
      const chatRight = 20.0;
      const chatBottom = 20.0;

      // Tính toán alignment dựa vào vị trí icon
      final iconPos = controller.iconPosition;
      final chatLeft = screenSize.width - chatWidth - chatRight;
      final chatTop = screenSize.height - chatHeight - chatBottom;

      // Tính alignment để scale từ hướng icon
      // Nếu icon ở bên trái thì alignment sẽ lệch về trái, ngược lại
      final alignmentX = ((iconPos.dx - chatLeft) / chatWidth) * 2 - 1;
      final alignmentY = ((iconPos.dy - chatTop) / chatHeight) * 2 - 1;
      final scaleAlignment = Alignment(
        alignmentX.clamp(-1.0, 1.0),
        alignmentY.clamp(-1.0, 1.0),
      );

      return Positioned(
        right: chatRight,
        bottom: chatBottom,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: scaleAlignment,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: chatWidth,
                height: chatHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(controller),

                    // Messages
                    Expanded(child: _buildMessagesList(controller)),

                    // Typing indicator
                    Obx(() {
                      if (!controller.isTyping) return const SizedBox.shrink();
                      return _buildTypingIndicator();
                    }),

                    // Input
                    _buildInputField(controller, _textController),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(AIChatController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildRobotIcon(24)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gym Pro AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Trợ lý ảo',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: controller.closeChat,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AIChatController controller) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return const Center(
          child: Text('Chưa có tin nhắn', style: TextStyle(color: Colors.grey)),
        );
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          return _buildMessageBubble(message);
        },
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue.shade500 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0.0, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
    AIChatController controller,
    TextEditingController textController,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  controller.sendMessage(value);
                  textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final text = textController.text;
                if (text.trim().isNotEmpty) {
                  controller.sendMessage(text);
                  textController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotIcon(double size) {
    return CustomPaint(size: Size(size, size), painter: RobotIconPainter());
  }
}

/// Custom painter vẽ icon robot AI
class RobotIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;

    // Vẽ ăng-ten (antenna)
    final antennaPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..lineTo(size.width * 0.5, size.height * 0.25);
    canvas.drawPath(antennaPath, strokePaint);

    // Vẽ chấm tròn trên ăng-ten
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.05),
      size.width * 0.08,
      paint,
    );

    // Vẽ đầu robot (hình chữ nhật bo góc)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.6,
      ),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(headRect, paint);

    // Vẽ mắt trái
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.45),
      size.width * 0.08,
      Paint()..color = Colors.blue.shade700,
    );

    // Vẽ mắt phải
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.45),
      size.width * 0.08,
      Paint()..color = Colors.blue.shade700,
    );

    // Vẽ miệng (nụ cười)
    final mouthPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.75,
        size.width * 0.7,
        size.height * 0.65,
      );
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Vẽ tai trái
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.5),
      size.width * 0.08,
      paint,
    );

    // Vẽ tai phải
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.5),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
