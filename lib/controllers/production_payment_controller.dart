import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/production_momo_service.dart';

class ProductionPaymentController extends GetxController {
  final ProductionMoMoService _momoService = ProductionMoMoService();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxString currentOrderId = ''.obs;
  final RxString paymentStatus =
      'idle'.obs; // idle, creating, pending, success, failed, expired
  final RxString statusMessage = ''.obs;
  final Rx<PaymentResponse?> currentPaymentResponse = Rx<PaymentResponse?>(
    null,
  );
  final Rx<PaymentStatus?> currentPaymentStatus = Rx<PaymentStatus?>(null);

  StreamSubscription<PaymentStatus>? _statusSubscription;

  @override
  void onClose() {
    _statusSubscription?.cancel();
    _momoService.dispose();
    super.onClose();
  }

  /// Create a new MoMo payment
  Future<bool> createPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
  }) async {
    try {
      isLoading.value = true;
      paymentStatus.value = 'creating';
      statusMessage.value = 'Đang tạo mã thanh toán...';
      currentOrderId.value = orderId;

      print('🔄 Creating payment: $orderId, amount: $amount');

      final response = await _momoService.createPayment(
        orderId: orderId,
        amount: amount,
        orderInfo: orderInfo,
      );

      currentPaymentResponse.value = response;

      if (response.success) {
        paymentStatus.value = 'pending';
        statusMessage.value = 'Vui lòng quét mã QR để thanh toán';

        // Start monitoring payment status
        _startStatusMonitoring(orderId);

        print('✅ Payment created successfully');
        return true;
      } else {
        paymentStatus.value = 'failed';
        statusMessage.value = response.error ?? 'Không thể tạo thanh toán';

        _showErrorSnackbar(
          'Lỗi tạo thanh toán',
          response.error ?? 'Unknown error',
        );
        print('❌ Payment creation failed: ${response.error}');
        return false;
      }
    } catch (e) {
      paymentStatus.value = 'failed';
      statusMessage.value = 'Lỗi hệ thống: $e';

      _showErrorSnackbar('Lỗi hệ thống', e.toString());
      print('❌ Exception creating payment: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start monitoring payment status via polling
  void _startStatusMonitoring(String orderId) {
    _statusSubscription?.cancel();

    _statusSubscription = _momoService
        .pollPaymentStatus(orderId)
        .listen(
          (status) {
            currentPaymentStatus.value = status;
            statusMessage.value = status.message;

            if (status.isSuccess) {
              paymentStatus.value = 'success';
              _handlePaymentSuccess(status);
            } else if (status.isFailed) {
              paymentStatus.value = 'failed';
              _handlePaymentFailure(status);
            } else if (status.isExpired) {
              paymentStatus.value = 'expired';
              _handlePaymentExpired(status);
            } else if (status.isPending) {
              paymentStatus.value = 'pending';
            }
          },
          onError: (error) {
            print('❌ Status monitoring error: $error');
            statusMessage.value = 'Lỗi theo dõi trạng thái thanh toán';
          },
        );
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentStatus status) {
    print('🎉 Payment successful: ${status.orderId}');

    Get.snackbar(
      '✅ Thanh toán thành công',
      'Giao dịch ${status.orderId} đã được xử lý thành công',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );

    // Stop monitoring
    _statusSubscription?.cancel();
  }

  /// Handle failed payment
  void _handlePaymentFailure(PaymentStatus status) {
    print('❌ Payment failed: ${status.orderId}');

    Get.snackbar(
      '❌ Thanh toán thất bại',
      status.message.isNotEmpty ? status.message : 'Giao dịch không thành công',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.error, color: Colors.red),
    );

    // Stop monitoring
    _statusSubscription?.cancel();
  }

  /// Handle expired payment
  void _handlePaymentExpired(PaymentStatus status) {
    print('⏰ Payment expired: ${status.orderId}');

    Get.snackbar(
      '⏰ Thanh toán hết hạn',
      'Giao dịch đã quá thời gian cho phép',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.access_time, color: Colors.orange),
    );

    // Stop monitoring
    _statusSubscription?.cancel();
  }

  /// Manual status check
  Future<void> checkPaymentStatus(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      orderId = currentOrderId.value;
    }

    if (orderId.isEmpty) {
      print('❌ No order ID to check');
      return;
    }

    try {
      final status = await _momoService.getPaymentStatus(orderId);
      currentPaymentStatus.value = status;
      statusMessage.value = status.message;

      print('🔍 Manual status check: ${status.status}');
    } catch (e) {
      print('❌ Error checking status: $e');
      statusMessage.value = 'Lỗi kiểm tra trạng thái';
    }
  }

  /// Reset payment state
  void resetPayment() {
    _statusSubscription?.cancel();

    isLoading.value = false;
    currentOrderId.value = '';
    paymentStatus.value = 'idle';
    statusMessage.value = '';
    currentPaymentResponse.value = null;
    currentPaymentStatus.value = null;

    print('🔄 Payment state reset');
  }

  /// Show payment dialog
  void showPaymentDialog({
    required String orderId,
    required int amount,
    required String orderInfo,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFB0006D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Thanh toán MoMo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        resetPayment();
                        Get.back();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  if (paymentStatus.value == 'idle') {
                    return _buildStartPaymentContent(
                      orderId,
                      amount,
                      orderInfo,
                    );
                  } else {
                    return _buildPaymentProgressContent(onSuccess, onFailure);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildStartPaymentContent(
    String orderId,
    int amount,
    String orderInfo,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code, size: 64, color: Color(0xFFB0006D)),
        const SizedBox(height: 16),
        const Text(
          'Thanh toán bằng mã QR MoMo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Số tiền: ${_formatCurrency(amount)}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading.value
                ? null
                : () {
                    createPayment(
                      orderId: orderId,
                      amount: amount,
                      orderInfo: orderInfo,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB0006D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Tạo mã QR thanh toán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProgressContent(
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        Obx(() {
          Color statusColor;
          IconData statusIcon;

          switch (paymentStatus.value) {
            case 'creating':
              statusColor = Colors.blue;
              statusIcon = Icons.sync;
              break;
            case 'pending':
              statusColor = Colors.orange;
              statusIcon = Icons.qr_code;
              break;
            case 'success':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case 'failed':
            case 'expired':
              statusColor = Colors.red;
              statusIcon = Icons.error;
              break;
            default:
              statusColor = Colors.grey;
              statusIcon = Icons.help;
          }

          return Column(
            children: [
              Icon(statusIcon, size: 64, color: statusColor),
              const SizedBox(height: 16),
              Text(
                statusMessage.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),

        const SizedBox(height: 20),

        // QR Code (only show when pending)
        Obx(() {
          if (paymentStatus.value == 'pending' &&
              currentPaymentResponse.value?.qrCodeUrl != null) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Image.network(
                    currentPaymentResponse.value!.qrCodeUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: Text('QR Code Error')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '📱 Quét mã QR bằng ứng dụng MoMo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        // Action buttons
        Obx(() {
          if (paymentStatus.value == 'success') {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onSuccess?.call();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hoàn tất'),
              ),
            );
          } else if (paymentStatus.value == 'failed' ||
              paymentStatus.value == 'expired') {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      resetPayment();
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final orderId = currentOrderId.value;
                      final response = currentPaymentResponse.value;
                      if (orderId.isNotEmpty && response != null) {
                        createPayment(
                          orderId: orderId,
                          amount: response.amount,
                          orderInfo: response.orderInfo,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB0006D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ),
              ],
            );
          } else if (paymentStatus.value == 'pending') {
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  checkPaymentStatus(null);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB0006D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Kiểm tra trạng thái'),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.error, color: Colors.red),
    );
  }
}
