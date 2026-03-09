import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/loading_overlay.dart';

/// Utility class để quản lý loading state một cách dễ dàng
class LoadingUtils {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Hiển thị loading overlay toàn màn hình
  /// - [message]: Thông báo hiển thị (tùy chọn)
  /// - [dismissible]: Cho phép dismiss bằng tap bên ngoài (mặc định: false)
  static void show({String? message, bool dismissible = false}) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) =>
          LoadingOverlay(message: message, dismissible: dismissible),
    );

    Overlay.of(Get.overlayContext!).insert(_overlayEntry!);
  }

  /// Ẩn loading overlay
  static void hide() {
    if (!_isShowing) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  /// Hiển thị loading dialog (sử dụng Get.dialog)
  static void showDialog({String? message}) {
    Get.dialog(
      LoadingOverlay(message: message),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }

  /// Ẩn dialog
  static void hideDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Hiển thị loading snackbar
  static void showSnackbar(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00BCD4),
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  /// Thực thi async function với loading overlay
  /// - [future]: Future cần thực thi
  /// - [message]: Thông báo loading
  /// - [successMessage]: Thông báo thành công (tùy chọn)
  /// - [errorMessage]: Thông báo lỗi (tùy chọn)
  /// - [showSuccessSnackbar]: Hiển thị snackbar khi thành công
  static Future<T?> runWithLoading<T>({
    required Future<T> Function() future,
    String? message,
    String? successMessage,
    String? errorMessage,
    bool showSuccessSnackbar = false,
  }) async {
    try {
      show(message: message);
      final result = await future();
      hide();

      if (showSuccessSnackbar && successMessage != null) {
        Get.snackbar(
          'Thành công',
          successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }

      return result;
    } catch (e) {
      hide();

      Get.snackbar(
        'Lỗi',
        errorMessage ?? 'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white),
      );

      return null;
    }
  }

  /// Hiển thị loading khi chuyển trang
  static void showPageTransitionLoading() {
    show(message: 'Đang tải...');
    Future.delayed(const Duration(milliseconds: 300), () {
      hide();
    });
  }
}

/// Extension cho BuildContext để dễ dàng show/hide loading
extension LoadingExtension on BuildContext {
  void showLoading({String? message}) {
    LoadingOverlay.show(this, message: message);
  }

  void hideLoading() {
    LoadingOverlay.hide(this);
  }
}
