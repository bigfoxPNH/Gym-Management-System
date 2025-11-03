import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_chat_controller.dart';

/// Widget icon chatbot có thể di chuyển
class DraggableAIChatButton extends StatefulWidget {
  const DraggableAIChatButton({super.key});

  @override
  State<DraggableAIChatButton> createState() => _DraggableAIChatButtonState();
}

class _DraggableAIChatButtonState extends State<DraggableAIChatButton>
    with TickerProviderStateMixin {
  final controller = Get.put(AIChatController());
  Offset? _position; // Sẽ tính toán sau khi có context
  final double _iconSize = 60;
  final double _maxEdgeDistance = 38; // ~1cm từ mép (38 pixels)
  bool _isInitialized = false;

  late AnimationController _snapAnimationController;
  late AnimationController _fadeAnimationController;
  Animation<Offset>? _snapAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller cho snap to edge
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _snapAnimationController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _position = _snapAnimation!.value;
        });
      }
    });

    // Animation controller cho fade in/out
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    // Start with icon visible
    _fadeAnimationController.reverse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Khởi tạo vị trí mặc định ở góc phải 2/3 màn hình
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      final safeAreaTop = MediaQuery.of(context).padding.top;

      setState(() {
        _position = Offset(
          screenSize.width - _iconSize - _maxEdgeDistance,
          safeAreaTop +
              (screenSize.height - safeAreaTop) * 0.66 -
              _iconSize / 2,
        );
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _snapAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _snapToEdge() {
    if (_position == null) return;

    final screenSize = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Tính vị trí hiện tại
    double x = _position!.dx;
    double y = _position!.dy;

    // Snap to edge (left or right) như Messenger
    // Nếu gần bên trái hơn thì snap sang trái, ngược lại snap sang phải
    final double centerX = screenSize.width / 2;
    double targetX;

    if (x + _iconSize / 2 < centerX) {
      // Snap to left edge (trong phạm vi 1cm)
      targetX = _maxEdgeDistance;
    } else {
      // Snap to right edge (trong phạm vi 1cm)
      targetX = screenSize.width - _iconSize - _maxEdgeDistance;
    }

    // Giới hạn y trong phạm vi cho phép
    final double minY = safeAreaTop + _maxEdgeDistance;
    final double maxY =
        screenSize.height - _iconSize - safeAreaBottom - _maxEdgeDistance;
    final double targetY = y.clamp(minY, maxY);

    final targetPosition = Offset(targetX, targetY);

    // Animate mượt mà đến vị trí mới
    _snapAnimation = Tween<Offset>(begin: _position, end: targetPosition)
        .animate(
          CurvedAnimation(
            parent: _snapAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _snapAnimationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _position = targetPosition;
        });
      }
    });
  }

  Offset _constrainPosition(Offset position) {
    final screenSize = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Giới hạn vị trí trong màn hình
    double x = position.dx.clamp(0.0, screenSize.width - _iconSize);

    double y = position.dy.clamp(
      safeAreaTop + 16,
      screenSize.height - _iconSize - safeAreaBottom - 16,
    );

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    // Chờ khởi tạo xong
    if (_position == null) {
      return const SizedBox.shrink();
    }

    // Cập nhật vị trí icon cho controller (để chat view biết vị trí mở)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _position != null) {
        // Tính vị trí tâm của icon (cho animation)
        final iconCenter = Offset(
          _position!.dx + _iconSize / 2,
          _position!.dy + _iconSize / 2,
        );
        controller.updateIconPosition(iconCenter);
      }
    });

    return Obx(() {
      // Animate fade out khi chat mở, fade in khi chat đóng
      if (controller.isChatOpen) {
        _fadeAnimationController.forward();
      } else {
        _fadeAnimationController.reverse();
      }

      // Ẩn hoàn toàn khi chat đang mở và animation hoàn tất
      if (controller.isChatOpen && !_fadeAnimationController.isAnimating) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: _position!.dx,
        top: _position!.dy,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.8).animate(
              CurvedAnimation(
                parent: _fadeAnimationController,
                curve: Curves.easeOut,
              ),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                // Dừng animation nếu đang chạy
                if (_snapAnimationController.isAnimating) {
                  _snapAnimationController.stop();
                }

                // Cập nhật vị trí trực tiếp khi kéo (không animate)
                setState(() {
                  final newPosition = Offset(
                    _position!.dx + details.delta.dx,
                    _position!.dy + details.delta.dy,
                  );
                  _position = _constrainPosition(newPosition);
                });
              },
              onPanEnd: (details) {
                // Snap to edge mượt mà khi thả tay
                _snapToEdge();
              },
              child: _buildChatButton(),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildChatButton() {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: const CircleBorder(),
      child: Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.openChat(),
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom robot head icon
                _buildRobotIcon(),
                // Badge cho số tin nhắn mới (có thể thêm sau)
                Obx(() {
                  if (controller.messages.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRobotIcon() {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _RobotHeadPainter()),
    );
  }
}

/// Custom painter để vẽ đầu robot AI
class _RobotHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Vẽ râu ăng ten trên đầu
    final antennaPath = Path();
    antennaPath.moveTo(size.width * 0.5, size.height * 0.1);
    antennaPath.lineTo(size.width * 0.5, size.height * 0.25);
    canvas.drawPath(antennaPath, strokePaint);

    // Vẽ bulb ăng ten
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.08), 2.5, paint);

    // Vẽ đầu robot (hình chữ nhật bo góc)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.55,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(headRect, paint);

    // Vẽ 2 mắt (hình chữ nhật)
    final leftEyePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    final rightEyePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    // Mắt trái
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.4,
          size.width * 0.15,
          size.height * 0.12,
        ),
        const Radius.circular(2),
      ),
      leftEyePaint,
    );

    // Mắt phải
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.6,
          size.height * 0.4,
          size.width * 0.15,
          size.height * 0.12,
        ),
        const Radius.circular(2),
      ),
      rightEyePaint,
    );

    // Vẽ miệng (đường thẳng ngang)
    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.3, size.height * 0.65);
    mouthPath.lineTo(size.width * 0.7, size.height * 0.65);
    canvas.drawPath(mouthPath, strokePaint);

    // Vẽ tai robot (2 nửa hình tròn nhỏ 2 bên)
    // Tai trái
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.5), 4, paint);

    // Tai phải
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.5), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
