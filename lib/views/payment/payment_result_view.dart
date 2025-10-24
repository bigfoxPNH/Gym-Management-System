import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/payment_callback_controller.dart';
import '../../services/payment_service.dart';
import '../../models/payment_transaction.dart';
import '../../widgets/loading_overlay.dart';

class PaymentResultView extends StatefulWidget {
  const PaymentResultView({super.key});

  @override
  State<PaymentResultView> createState() => _PaymentResultViewState();
}

class _PaymentResultViewState extends State<PaymentResultView> {
  bool _isProcessing = true;
  Map<String, String> _paymentResult = {};

  @override
  void initState() {
    super.initState();
    _processPaymentResult();
  }

  Future<void> _processPaymentResult() async {
    try {
      // Lấy parameters từ URL
      final uri = Uri.parse(Get.currentRoute);
      final queryParams = uri.queryParameters;

      // Log tất cả parameters từ MoMo
      print('Payment Result Parameters:');
      queryParams.forEach((key, value) {
        print('$key: $value');
      });

      _paymentResult = Map<String, String>.from(queryParams);

      // Kiểm tra kết quả thanh toán
      final resultCode = queryParams['resultCode'];
      final orderId = queryParams['orderId'];

      if (resultCode == '0' && orderId != null && orderId.isNotEmpty) {
        // Payment thành công - cập nhật trạng thái trong hệ thống
        await _updatePaymentStatus(orderId, queryParams);
      }
    } catch (e) {
      print('Error processing payment result: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });

      // Hiển thị kết quả sau khi xử lý xong
      Future.delayed(const Duration(seconds: 1), () {
        _showResult();
      });
    }
  }

  Future<void> _updatePaymentStatus(
    String orderId,
    Map<String, String> params,
  ) async {
    try {
      print('Updating payment status for orderId: $orderId');

      // 1. Cập nhật thông qua PaymentCallbackController
      try {
        final paymentCallbackController = Get.find<PaymentCallbackController>();
        await paymentCallbackController.processReturnUrl(
          provider: 'momo',
          returnData: params,
        );
        print('PaymentCallbackController updated successfully');
      } catch (e) {
        print('PaymentCallbackController not available or error: $e');
      }

      // 2. Cập nhật trực tiếp trong database thông qua PaymentService
      final paymentService = PaymentService();
      await paymentService.updatePaymentStatus(
        orderId,
        PaymentStatus.completed,
      );
      print('Payment status updated directly in database');
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  void _showResult() {
    final resultCode = _paymentResult['resultCode'];
    final orderId = _paymentResult['orderId'];
    final transId = _paymentResult['transId'];
    final amount = _paymentResult['amount'];
    final message = _paymentResult['message'];

    final bool isSuccess = resultCode == '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isSuccess ? 'Thành công' : 'Thất bại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSuccess)
              const Text(
                'Thanh toán đã được xử lý thành công!\nThông tin thành viên của bạn đã được cập nhật.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            if (orderId != null) Text('Mã đơn hàng: $orderId'),
            if (transId != null) Text('Mã giao dịch: $transId'),
            if (amount != null) Text('Số tiền: ${amount} VND'),
            if (message != null) Text('Thông báo: $message'),
          ],
        ),
        actions: [
          if (isSuccess) ...[
            TextButton(
              onPressed: () {
                Get.back(); // Đóng dialog
                Get.offAllNamed(
                  '/my-membership-cards',
                ); // Về trang thẻ tập của tôi
              },
              child: const Text('Xem thẻ tập'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Đóng dialog
                Get.offAllNamed(AppRoutes.home); // Về trang chủ
              },
              child: const Text('Về trang chủ'),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Get.back(); // Đóng dialog
                Get.offAllNamed(AppRoutes.home); // Về trang chủ
              },
              child: const Text('Về trang chủ'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Đóng dialog
                Get.offAllNamed('/checkout'); // Thử lại thanh toán
              },
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        centerTitle: true,
      ),
      body: const CenterLoading(message: 'Đang xử lý kết quả thanh toán...'),
    );
  }
}
