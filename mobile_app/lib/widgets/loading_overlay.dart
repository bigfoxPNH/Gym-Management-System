import 'package:flutter/material.dart';

/// Widget hiển thị loading overlay toàn màn hình
/// - Màn hình tối nhẹ với overlay màu đen opacity 0.3
/// - CircularProgressIndicator màu cyan
/// - Text thông báo tùy chỉnh
/// - Có thể dismiss bằng cách tap ra ngoài (tùy chọn)
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool dismissible;

  const LoadingOverlay({super.key, this.message, this.dismissible = false});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => dismissible,
      child: Material(
        color: Colors.black.withOpacity(0.3), // Màu tối nhẹ
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator màu cyan
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00BCD4), // Cyan color
                    ),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hiển thị loading overlay
  static void show(
    BuildContext context, {
    String? message,
    bool dismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) =>
          LoadingOverlay(message: message, dismissible: dismissible),
    );
  }

  /// Ẩn loading overlay
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Widget loading nhỏ gọn cho inline display
class InlineLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const InlineLoading({super.key, this.size = 24, this.color, this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? const Color(0xFF00BCD4),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: color ?? const Color(0xFF00BCD4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget loading cho center screen
class CenterLoading extends StatelessWidget {
  final String? message;
  final double size;

  const CenterLoading({super.key, this.message, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF00BCD4), // Cyan color
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
