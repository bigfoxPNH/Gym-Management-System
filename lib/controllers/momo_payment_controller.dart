import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/membership_card.dart';
import '../models/payment_transaction.dart';
import '../models/payment_method.dart';
import '../models/membership_purchase.dart';
import '../controllers/auth_controller.dart';
import '../services/membership_purchase_service.dart';
import '../services/purchase_history_service.dart';
import '../services/payment_monitor_service.dart';
import '../services/production_momo_service.dart';
import '../config/momo_config.dart';

class MoMoPaymentController extends GetxController {
  final ProductionMoMoService _momoService = ProductionMoMoService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool paymentSuccess = false.obs;
  final RxString qrCodeUrl = ''.obs;
  final RxString deepLink = ''.obs;
  final RxString statusMessage = 'Vui lòng quét mã QR để thanh toán'.obs;
  final RxInt timeRemaining = 0.obs;
  final RxBool isExpired = false.obs;

  // Data
  MembershipCard? membershipCard;
  String? purchaseId;
  PaymentTransaction? currentTransaction;
  Timer? _checkTimer;
  Timer? _countdownTimer;
  StreamSubscription? _paymentMonitorSubscription;
  bool _paymentStarted = false;

  // Constants - use config for backend URL
  String get backendUrl => MoMoConfig.backendUrl;

  @override
  void onClose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    _paymentMonitorSubscription?.cancel();
    super.onClose();
  }

  // Initialize payment - create payment via backend and show QR
  void initializePayment(MembershipCard card, String id) {
    if (_paymentStarted) return; // Avoid duplicate init on rebuild
    _paymentStarted = true;

    membershipCard = card;
    purchaseId = id;
    _createPaymentAndDisplayQr();
  }

  // Create payment via backend and update UI state
  Future<void> _createPaymentAndDisplayQr() async {
    if (membershipCard == null || purchaseId == null) return;

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Create transaction ID
      final transactionId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';

      // Create transaction object for tracking
      currentTransaction = PaymentTransaction(
        id: transactionId,
        userId: _authController.userAccount?.id ?? '',
        membershipCardId: membershipCard!.id,
        membershipPurchaseId: purchaseId!,
        paymentType: PaymentType.membership,
        paymentMethod: PaymentMethodType.momo,
        amount: membershipCard!.price,
        status: PaymentStatus.pending,
        description: 'Mua thẻ tập ${membershipCard!.cardName}',
        createdAt: DateTime.now(),
      );

      // Call backend to create MoMo payment
      final result = await PaymentMonitorService.createPayment(
        orderId: transactionId,
        amount: membershipCard!.price.toInt(),
        orderInfo: 'Mua ${membershipCard!.cardName}',
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final String? qrDataUrl = data['qrCodeUrl'];
        final String? payUrl = data['payUrl'];

        if (qrDataUrl != null && qrDataUrl.isNotEmpty) {
          qrCodeUrl.value = qrDataUrl;
        } else if (payUrl != null && payUrl.isNotEmpty) {
          // Fallback: open MoMo payUrl externally
          if (await canLaunchUrlString(payUrl)) {
            await launchUrlString(payUrl, mode: LaunchMode.externalApplication);
          }
        }

        // Start monitoring payment status using stream
        _startPaymentMonitoringWithStream(transactionId);

        statusMessage.value = 'Vui lòng quét mã QR bằng MoMo để thanh toán';
      } else {
        throw Exception(result['error'] ?? 'Không thể tạo giao dịch MoMo');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Start monitoring payment status from web page using stream
  void _startPaymentMonitoringWithStream(String transactionId) {
    statusMessage.value = 'Đang chờ thanh toán...';

    _paymentMonitorSubscription =
        PaymentMonitorService.monitorPaymentStatus(transactionId).listen(
          (statusData) {
            print(
              '📊 Payment status update: ${statusData['status']} (check ${statusData['checkCount']})',
            );

            final status = statusData['status'];

            if (status == 'success') {
              _handlePaymentSuccess();
            } else if (status == 'expired') {
              _handlePaymentExpired();
            } else if (status == 'failed') {
              _handlePaymentFailed();
            } else if (status == 'error') {
              print('❌ Payment monitoring error: ${statusData['error']}');
            } else {
              // Update status message for pending
              if (statusData['timeRemaining'] != null) {
                final timeLeft = statusData['timeRemaining'] as int;
                final minutes = (timeLeft / 60000).floor();
                final seconds = ((timeLeft % 60000) / 1000).floor();
                statusMessage.value =
                    'Còn lại: ${minutes}:${seconds.toString().padLeft(2, '0')}';
              } else {
                statusMessage.value = 'Đang chờ quét mã QR...';
              }
            }
          },
          onError: (error) {
            print('❌ Payment monitoring stream error: $error');
            errorMessage.value = 'Lỗi theo dõi thanh toán: $error';
            hasError.value = true;
          },
        );
  }

  // Handle payment failed
  void _handlePaymentFailed() {
    _paymentMonitorSubscription?.cancel();

    hasError.value = true;
    errorMessage.value = 'Thanh toán thất bại';
    statusMessage.value = 'Thanh toán không thành công';

    Get.snackbar(
      'Thất bại',
      'Thanh toán không thành công. Vui lòng thử lại.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Handle payment expired
  void _handlePaymentExpired() {
    _paymentMonitorSubscription?.cancel();

    isExpired.value = true;
    statusMessage.value = 'Mã QR đã hết hạn';

    Get.snackbar(
      'Hết hạn',
      'Mã QR thanh toán đã hết hạn. Vui lòng tạo lại giao dịch.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Handle payment success
  void _handlePaymentSuccess() async {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    _paymentMonitorSubscription?.cancel();

    paymentSuccess.value = true;
    statusMessage.value = 'Thanh toán thành công!';

    // Update purchase status
    try {
      // Update membership purchase status
      await MembershipPurchaseService.updatePurchaseStatus(
        purchaseId!,
        PurchaseStatus.active,
      );

      // Get updated purchase info
      final purchase = await MembershipPurchaseService.getPurchaseById(
        purchaseId!,
      );

      // Save transaction to history
      currentTransaction = currentTransaction!.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
      );

      // Save to purchase history
      if (purchase != null) {
        await PurchaseHistoryService.savePurchaseHistory(
          purchase: purchase,
          transaction: currentTransaction!,
        );
      }

      // Show success message
      Get.snackbar(
        'Thành công',
        'Thanh toán thành công! Thẻ tập đã được kích hoạt và lưu vào lịch sử.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 5),
      );

      // Navigate back to home after delay
      await Future.delayed(const Duration(seconds: 3));
      Get.offAllNamed('/home');
    } catch (e) {
      print('❌ Error updating purchase: $e');

      // Still show success for payment, but warn about history
      Get.snackbar(
        'Thanh toán thành công',
        'Thanh toán đã hoàn tất nhưng có lỗi khi lưu lịch sử. Vui lòng liên hệ hỗ trợ.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Retry payment - recreate payment
  void retryPayment() {
    if (membershipCard != null && purchaseId != null) {
      _paymentStarted = false; // allow re-init
      _createPaymentAndDisplayQr();
    }
  }

  // Simulate payment success for demo
  Future<void> simulatePaymentSuccess() async {
    if (currentTransaction == null) return;

    try {
      print(
        '🧪 Demo: Simulating payment success for ${currentTransaction!.id}',
      );

      final response = await _dio.post(
        '$backendUrl/api/momo/manual-success/${currentTransaction!.id}',
      );

      if (response.statusCode == 200) {
        print('✅ Demo payment success triggered');
        Get.snackbar(
          'Demo',
          'Đã simulate thanh toán thành công!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error simulating payment: $e');
      Get.snackbar(
        'Lỗi Demo',
        'Không thể simulate thanh toán: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Try opening deep link (useful for mobile web)
  Future<void> openDeepLink() async {
    final link = deepLink.value;
    if (link.isEmpty) return;
    try {
      // Attempt to open via url_launcher which works on mobile and web
      print('🔗 Open deep link: $link');
      await launchUrlString(link);
    } catch (e) {
      print('Error opening deep link: $e');
    }
  }
}
