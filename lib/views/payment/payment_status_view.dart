import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_callback_controller.dart';
import '../../controllers/payment_api_controller.dart';
import '../../models/payment_transaction.dart';

class PaymentStatusView extends StatelessWidget {
  final String orderId;

  const PaymentStatusView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentCallbackController());
    final apiController = Get.put(PaymentApiController());

    // Check initial status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkPaymentStatus(orderId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái thanh toán'),
        centerTitle: true,
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin đơn hàng',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã đơn hàng:'),
                          Text(
                            orderId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trạng thái:'),
                          _buildStatusChip(controller.paymentStatus.value),
                        ],
                      ),
                      if (controller.statusMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thông báo:'),
                            Expanded(
                              child: Text(
                                controller.statusMessage.value,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Animation
              _buildStatusAnimation(controller.paymentStatus.value),

              const SizedBox(height: 24),

              // Processing Indicator
              if (controller.isProcessingCallback.value)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Đang xử lý callback...'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Test Buttons (for demonstration)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Test Webhook (Demo)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _simulateSuccessCallback(apiController),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Mô phỏng thành công'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _simulateFailureCallback(apiController),
                              icon: const Icon(Icons.error),
                              label: const Text('Mô phỏng thất bại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              if (controller.paymentStatus.value ==
                  PaymentStatus.completed) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    // Navigate back to main screen or membership view
                    Get.offAllNamed('/home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Về trang chính'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else if (controller.paymentStatus.value.isFailed) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    // TODO: Navigate back to checkout to retry
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại thanh toán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Back Button
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.access_time;
        break;
      case PaymentStatus.processing:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.sync;
        break;
      case PaymentStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.expired:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(status.getStatusText()),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusAnimation(PaymentStatus status) {
    Widget child;

    switch (status) {
      case PaymentStatus.pending:
        child = const CircularProgressIndicator();
        break;
      case PaymentStatus.processing:
        child = const CircularProgressIndicator();
        break;
      case PaymentStatus.completed:
        child = Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green.shade600,
        );
        break;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.expired:
        child = Icon(Icons.error, size: 80, color: Colors.red.shade600);
        break;
    }

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          key: ValueKey(status),
          width: 120,
          height: 120,
          child: Center(child: child),
        ),
      ),
    );
  }

  void _simulateSuccessCallback(PaymentApiController apiController) {
    MockPaymentServer.simulateMoMoWebhook(
      orderId: orderId,
      paymentSuccess: true,
    );

    Get.snackbar(
      'Mô phỏng thành công',
      'Đã gửi callback thành công cho đơn hàng $orderId',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _simulateFailureCallback(PaymentApiController apiController) {
    MockPaymentServer.simulateMoMoWebhook(
      orderId: orderId,
      paymentSuccess: false,
      errorMessage: 'Tài khoản không đủ số dư',
    );

    Get.snackbar(
      'Mô phỏng thất bại',
      'Đã gửi callback thất bại cho đơn hàng $orderId',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

extension on PaymentStatus {
  String getStatusText() {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ thanh toán';
      case PaymentStatus.processing:
        return 'Đang xử lý';
      case PaymentStatus.completed:
        return 'Thành công';
      case PaymentStatus.failed:
        return 'Thất bại';
      case PaymentStatus.cancelled:
        return 'Đã hủy';
      case PaymentStatus.expired:
        return 'Hết hạn';
    }
  }

  bool get isFailed => [
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
  ].contains(this);
}
