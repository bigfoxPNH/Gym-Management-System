import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/membership_card.dart';
import '../models/payment_models.dart';
import 'momo_service_v3.dart';
import 'vietqr_service.dart';

class PaymentServiceV2 extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MoMoServiceV3 _momoService = MoMoServiceV3();
  final VietQRService _vietqrService = VietQRService();

  // Observable states
  final RxBool isProcessing = false.obs;
  final RxString currentPaymentId = ''.obs;
  final RxString paymentStatus = 'pending'.obs;

  /// Tạo thanh toán cho membership card
  Future<Map<String, dynamic>> createPayment({
    required String userId,
    required MembershipCard membershipCard,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      isProcessing.value = true;

      final paymentId = _generatePaymentId();
      currentPaymentId.value = paymentId;
      paymentStatus.value = 'pending';

      // Tạo payment record trong Firestore
      final paymentData = {
        'id': paymentId,
        'userId': userId,
        'membershipCardId': membershipCard.id,
        'membershipCardName': membershipCard.cardName,
        'amount': membershipCard.price.toInt(),
        'method': method.name,
        'status': 'pending',
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('payments').doc(paymentId).set(paymentData);

      // Tạo QR/link thanh toán tùy theo method
      Map<String, dynamic> paymentResponse;

      switch (method) {
        case PaymentMethod.momo:
          paymentResponse = await _createMomoPayment(
            paymentId: paymentId,
            membershipCard: membershipCard,
            userId: userId,
          );
          break;

        case PaymentMethod.banking:
          paymentResponse = await _createBankingPayment(
            paymentId: paymentId,
            membershipCard: membershipCard,
            userId: userId,
          );
          break;

        case PaymentMethod.cash:
          paymentResponse = await _createCashPayment(
            paymentId: paymentId,
            membershipCard: membershipCard,
            userId: userId,
          );
          break;
      }

      // Cập nhật payment với thông tin QR/link
      await _firestore.collection('payments').doc(paymentId).update({
        'paymentData': paymentResponse,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'paymentId': paymentId,
        'method': method.name,
        'data': paymentResponse,
      };
    } catch (e) {
      print('❌ Error creating payment: $e');
      paymentStatus.value = 'failed';

      return {'success': false, 'error': e.toString()};
    } finally {
      isProcessing.value = false;
    }
  }

  /// Tạo thanh toán MoMo qua backend proxy
  Future<Map<String, dynamic>> _createMomoPayment({
    required String paymentId,
    required MembershipCard membershipCard,
    required String userId,
  }) async {
    try {
      print('🚀 Creating MoMo payment through backend proxy...');

      // Kiểm tra backend health trước
      final isBackendHealthy = await _momoService.checkBackendHealth();
      if (!isBackendHealthy) {
        print('⚠️ Backend not healthy, using fallback...');
        return await _createMomoFallback(paymentId, membershipCard);
      }

      final response = await _momoService.createPayment(
        orderId: paymentId,
        orderInfo: 'Thanh toán ${membershipCard.cardName}',
        amount: membershipCard.price.toInt(),
        extraData: jsonEncode({
          'userId': userId,
          'membershipCardId': membershipCard.id,
          'type': 'membership_purchase',
        }),
      );

      if (response.isSuccess) {
        print('✅ MoMo payment created successfully');

        return {
          'type': 'momo',
          'qrCodeUrl': response.qrCodeUrl,
          'payUrl': response.payUrl,
          'deeplink': response.deeplink,
          'applink': response.applink,
          'orderId': response.orderId,
          'transId': response.transId,
          'message':
              '✅ QR Code MoMo đã sẵn sàng!\n\n'
              '📱 Cách thức thanh toán:\n'
              '1. Mở ứng dụng MoMo\n'
              '2. Chọn "Quét mã QR"\n'
              '3. Quét mã QR bên dưới\n'
              '4. Xác nhận thanh toán\n\n'
              '💡 Mã QR này được tạo qua MoMo API thật!',
          'isReal': true,
        };
      } else {
        throw Exception('MoMo API Error: ${response.message}');
      }
    } catch (e) {
      print('💥 MoMo payment failed: $e');

      // Fallback to demo if backend issue
      if (e.toString().contains('Không thể kết nối tới server backend')) {
        print('🎭 Using MoMo fallback due to backend connection issue...');
        return await _createMomoFallback(paymentId, membershipCard);
      }

      throw Exception('Không thể tạo thanh toán MoMo: ${e.toString()}');
    }
  }

  /// Fallback MoMo payment (demo)
  Future<Map<String, dynamic>> _createMomoFallback(
    String paymentId,
    MembershipCard membershipCard,
  ) async {
    final demoResponse = _momoService.createDemoResponse(
      orderId: paymentId,
      orderInfo: 'Demo - ${membershipCard.cardName}',
      amount: membershipCard.price.toInt(),
    );

    return {
      'type': 'momo_demo',
      'qrCodeUrl': demoResponse.qrCodeUrl,
      'payUrl': demoResponse.payUrl,
      'deeplink': demoResponse.deeplink,
      'orderId': demoResponse.orderId,
      'transId': demoResponse.transId,
      'message':
          '🎭 QR Code Demo - Chỉ để test!\n\n'
          '⚠️ Đây là QR demo, không thể thanh toán thật\n\n'
          '🔧 Để sử dụng thanh toán thật:\n'
          '1. Chạy backend server: cd backend && npm start\n'
          '2. Cấu hình MoMo credentials thật\n'
          '3. Deploy lên production\n\n'
          '💡 Hiện tại chỉ có thể test UI và flow',
      'isReal': false,
    };
  }

  /// Tạo thanh toán Banking QR
  Future<Map<String, dynamic>> _createBankingPayment({
    required String paymentId,
    required MembershipCard membershipCard,
    required String userId,
  }) async {
    try {
      print('🏦 Creating Banking QR payment...');

      final qrUrl = _vietqrService.generateQRUrl(
        amount: membershipCard.price,
        description: 'Thanh toan ${membershipCard.cardName} - $paymentId',
        customBankCode: '970418', // BIDV
        customAccountNumber: '12345678901', // Có thể config
        customAccountName: 'GYMPRO SYSTEM',
      );

      // Verify QR URL is accessible
      final isAccessible = await _vietqrService.verifyQRUrl(qrUrl);

      if (isAccessible) {
        print('✅ Banking QR created successfully');

        return {
          'type': 'banking',
          'qrCodeUrl': qrUrl,
          'qrCode': qrUrl,
          'bankInfo': {
            'bankName': 'BIDV',
            'accountNumber': '12345678901',
            'accountName': 'GYMPRO SYSTEM',
            'amount': membershipCard.price,
            'content': 'Thanh toan ${membershipCard.cardName} - $paymentId',
          },
          'message':
              '🏦 QR Chuyển khoản ngân hàng\n\n'
              '📱 Cách thức thanh toán:\n'
              '1. Mở app ngân hàng\n'
              '2. Chọn "Chuyển khoản QR"\n'
              '3. Quét mã QR bên dưới\n'
              '4. Kiểm tra thông tin và xác nhận\n\n'
              '⚠️ Vui lòng chuyển đúng số tiền và nội dung',
          'isReal': true,
        };
      } else {
        throw Exception('QR URL not accessible');
      }
    } catch (e) {
      print('💥 Banking payment failed: $e');
      throw Exception('Không thể tạo QR chuyển khoản: ${e.toString()}');
    }
  }

  /// Tạo thanh toán tiền mặt
  Future<Map<String, dynamic>> _createCashPayment({
    required String paymentId,
    required MembershipCard membershipCard,
    required String userId,
  }) async {
    print('💰 Creating Cash payment...');

    return {
      'type': 'cash',
      'amount': membershipCard.price,
      'membershipCard': membershipCard.cardName,
      'paymentId': paymentId,
      'message':
          '💰 Thanh toán tiền mặt\n\n'
          '📍 Vui lòng đến quầy lễ tân để thanh toán\n'
          '💵 Số tiền: ${_formatCurrency(membershipCard.price)}\n'
          '📋 Mã đơn hàng: $paymentId\n\n'
          '⏰ Thời gian: Thứ 2 - Chủ nhật, 6:00 - 22:00\n'
          '📞 Hotline: 0123.456.789',
      'isReal': true,
    };
  }

  /// Xử lý callback từ MoMo
  Future<bool> handleMoMoCallback(Map<String, dynamic> callbackData) async {
    try {
      print('🔄 Handling MoMo callback: $callbackData');

      final orderId = callbackData['orderId']?.toString();
      if (orderId == null) {
        print('❌ No orderId in callback');
        return false;
      }

      // Verify callback
      final isValid = _momoService.verifyCallback(callbackData);
      if (!isValid) {
        print('❌ Invalid callback signature');
        return false;
      }

      // Parse callback data
      final callbackDataObj = _momoService.handleCallback(callbackData);
      if (callbackDataObj == null) {
        print('❌ Failed to parse callback data');
        return false;
      }

      // Update payment status
      await _updatePaymentStatus(
        paymentId: orderId,
        status: callbackDataObj.isSuccess ? 'success' : 'failed',
        transactionId: callbackDataObj.transId.toString(),
        callbackData: callbackData,
      );

      // If successful, create membership purchase
      if (callbackDataObj.isSuccess) {
        await _processMembershipPurchase(orderId);
      }

      return callbackDataObj.isSuccess;
    } catch (e) {
      print('💥 Error handling MoMo callback: $e');
      return false;
    }
  }

  /// Cập nhật trạng thái thanh toán
  Future<void> _updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    Map<String, dynamic>? callbackData,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (callbackData != null) {
        updateData['callbackData'] = callbackData;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);

      paymentStatus.value = status;
      print('✅ Payment status updated: $paymentId -> $status');
    } catch (e) {
      print('💥 Error updating payment status: $e');
    }
  }

  /// Xử lý mua membership sau khi thanh toán thành công
  Future<void> _processMembershipPurchase(String paymentId) async {
    try {
      // Get payment info
      final paymentDoc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();
      if (!paymentDoc.exists) {
        throw Exception('Payment not found: $paymentId');
      }

      final paymentData = paymentDoc.data()!;
      final userId = paymentData['userId'];
      final membershipCardId = paymentData['membershipCardId'];

      // Get membership card
      final cardDoc = await _firestore
          .collection('membership_cards')
          .doc(membershipCardId)
          .get();
      if (!cardDoc.exists) {
        throw Exception('Membership card not found: $membershipCardId');
      }

      final card = MembershipCard.fromFirestore(cardDoc);

      // Calculate dates
      final now = DateTime.now();
      final endDate = card.calculateEndDateFromPurchase(now);
      final durationDays = _calculateDurationDays(card);

      // Create membership purchase
      final purchaseId = _firestore.collection('membership_purchases').doc().id;
      final purchaseData = {
        'id': purchaseId,
        'userId': userId,
        'membershipCardId': card.id,
        'membershipCardName': card.cardName,
        'price': card.price,
        'durationDays': durationDays,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
        'paymentId': paymentId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('membership_purchases')
          .doc(purchaseId)
          .set(purchaseData);

      print('✅ Membership purchase created: $purchaseId');
    } catch (e) {
      print('💥 Error processing membership purchase: $e');
    }
  }

  /// Truy vấn trạng thái thanh toán
  Future<Map<String, dynamic>?> queryPaymentStatus(String paymentId) async {
    try {
      // Query from Firestore first
      final paymentDoc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();
      if (!paymentDoc.exists) {
        return null;
      }

      final paymentData = paymentDoc.data()!;
      final method = paymentData['method'];

      // For MoMo, also query from MoMo API
      if (method == 'momo' && paymentData['status'] == 'pending') {
        try {
          final momoResponse = await _momoService.queryPayment(
            orderId: paymentId,
          );

          // Update status if different
          if (momoResponse.isSuccess && paymentData['status'] != 'success') {
            await _updatePaymentStatus(
              paymentId: paymentId,
              status: 'success',
              transactionId: momoResponse.transId.toString(),
            );
            paymentData['status'] = 'success';
          } else if (momoResponse.isFailed &&
              paymentData['status'] != 'failed') {
            await _updatePaymentStatus(paymentId: paymentId, status: 'failed');
            paymentData['status'] = 'failed';
          }
        } catch (e) {
          print('⚠️ Failed to query MoMo status: $e');
          // Continue with Firestore data
        }
      }

      return paymentData;
    } catch (e) {
      print('💥 Error querying payment status: $e');
      return null;
    }
  }

  /// Generate unique payment ID
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'PAY_${timestamp}_${(timestamp % 10000)}';
  }

  /// Kiểm tra backend server có sẵn sàng không
  Future<bool> checkBackendHealth() async {
    return await _momoService.checkBackendHealth();
  }

  /// Tính số ngày từ MembershipCard duration
  int _calculateDurationDays(MembershipCard card) {
    final now = DateTime.now();
    final endDate = card.calculateEndDateFromPurchase(now);
    return endDate.difference(now).inDays;
  }

  /// Format currency
  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }
}
