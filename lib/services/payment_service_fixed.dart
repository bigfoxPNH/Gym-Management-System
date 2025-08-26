import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/payment_transaction.dart';
import '../models/payment_method.dart';
import '../models/membership_card.dart';
import 'momo_service_v3.dart';
import 'vietqr_service.dart';

class PaymentService {
  final CollectionReference _paymentsCollection;
  final MoMoServiceV3 _momoService = MoMoServiceV3();
  final VietQRService _vietqrService = VietQRService();

  PaymentService() : _paymentsCollection = FirebaseFirestore.instance.collection('payment_transactions');

  // Tạo transaction thanh toán
  Future<PaymentTransaction> createPaymentTransaction({
    required String userId,
    required String membershipCardId,
    required String membershipPurchaseId,
    required PaymentMethodType paymentMethod,
    required double amount,
    String? description,
  }) async {
    final transactionId = _generateTransactionId();
    final now = DateTime.now();

    PaymentTransaction transaction = PaymentTransaction(
      id: transactionId,
      userId: userId,
      membershipCardId: membershipCardId,
      membershipPurchaseId: membershipPurchaseId,
      paymentType: PaymentType.membership,
      paymentMethod: paymentMethod,
      amount: amount,
      status: PaymentStatus.pending,
      description: description,
      createdAt: now,
      expiredAt: now.add(const Duration(minutes: 30)), // Hết hạn sau 30 phút
    );

    // Save to Firestore
    await _paymentsCollection.doc(transactionId).set(transaction.toMap());

    // Enrich with payment gateway data
    PaymentTransaction enrichedTransaction;
    
    switch (paymentMethod) {
      case PaymentMethodType.momo:
        enrichedTransaction = await _createMomoPayment(transaction);
        break;
      case PaymentMethodType.banking:
        enrichedTransaction = await _createBankingPayment(transaction);
        break;
      case PaymentMethodType.cash:
        enrichedTransaction = transaction;
        break;
    }
    
    // Update in Firestore
    await _paymentsCollection.doc(transactionId).update(enrichedTransaction.toMap());
    
    return enrichedTransaction;
  }

  // Tạo thanh toán MoMo (thực tế)
  Future<PaymentTransaction> _createMomoPayment(PaymentTransaction transaction) async {
    try {
      print('Creating real MoMo payment for transaction: ${transaction.id}');
      
      // Call MoMo API
      final momoResponse = await _momoService.createPayment(
        orderId: transaction.id,
        amount: transaction.amount.toInt(),
        orderInfo: transaction.description ?? 'Thanh toán thẻ tập gym',
      );

      if (momoResponse.isSuccess) {
        return transaction.copyWith(
          qrCodeUrl: momoResponse.qrCodeUrl,
          transactionId: momoResponse.requestId,
          metadata: {
            'partnerCode': momoResponse.partnerCode,
            'requestId': momoResponse.requestId,
            'orderId': momoResponse.orderId,
            'payUrl': momoResponse.payUrl,
            'deeplink': momoResponse.deeplink,
            'message': momoResponse.message,
          },
        );
      } else {
        print('MoMo API failed, falling back to demo');
        return _createMomoPaymentDemo(transaction);
      }
    } catch (e) {
      print('Error creating MoMo payment: $e, falling back to demo');
      return _createMomoPaymentDemo(transaction);
    }
  }

  // MoMo demo fallback
  Future<PaymentTransaction> _createMomoPaymentDemo(PaymentTransaction transaction) async {
    final qrData = _generateMomoQR(transaction);
    
    return transaction.copyWith(
      qrCodeUrl: qrData['qrUrl'],
      bankInfo: qrData['info'],
    );
  }

  // Tạo thanh toán Banking (thực tế)
  Future<PaymentTransaction> _createBankingPayment(PaymentTransaction transaction) async {
    try {
      print('Creating real Banking payment for transaction: ${transaction.id}');
      
      // Generate transfer content
      final transferContent = 'GYMPRO ${transaction.id}';
      
      // Call VietQR API
      final qrUrl = await _vietqrService.generateQRUrl(
        amount: transaction.amount,
        transferContent: transferContent,
      );
      
      if (qrUrl.isNotEmpty) {
        final bankInfo = await _vietqrService.getBankTransferInfo(
          amount: transaction.amount,
          transferContent: transferContent,
        );
        
        return transaction.copyWith(
          qrCodeUrl: qrUrl,
          bankInfo: bankInfo,
          metadata: {
            'transferContent': transferContent,
            'bankAccount': '1234567890',
            'bankName': 'Vietcombank',
            'accountHolder': 'GYM PRO VIETNAM',
          },
        );
      } else {
        print('VietQR API failed, falling back to demo');
        return _createBankingPaymentDemo(transaction);
      }
    } catch (e) {
      print('Error creating Banking payment: $e, falling back to demo');
      return _createBankingPaymentDemo(transaction);
    }
  }

  // Banking demo fallback
  Future<PaymentTransaction> _createBankingPaymentDemo(PaymentTransaction transaction) async {
    final bankInfo = _generateBankingInfo(transaction);
    
    return transaction.copyWith(
      qrCodeUrl: bankInfo['qrUrl'],
      bankInfo: bankInfo['info'],
    );
  }

  // Generate demo MoMo QR
  Map<String, String> _generateMomoQR(PaymentTransaction transaction) {
    final requestId = _generateRequestId();
    
    return {
      'qrUrl': 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=momo://app?amount=${transaction.amount.toInt()}&description=${Uri.encodeComponent(transaction.description ?? "Thanh toán")}&requestId=$requestId',
      'info': 'Demo MoMo QR - Amount: ${NumberFormat('#,###', 'vi_VN').format(transaction.amount)} VNĐ',
    };
  }

  // Generate demo Banking info
  Map<String, String> _generateBankingInfo(PaymentTransaction transaction) {
    final transferContent = 'GYMPRO ${transaction.id}';
    
    return {
      'qrUrl': 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=banking://transfer?amount=${transaction.amount.toInt()}&content=${Uri.encodeComponent(transferContent)}',
      'info': '''Ngân hàng: VIETCOMBANK
Số tài khoản: 1234567890
Chủ tài khoản: GYM PRO VIETNAM
Số tiền: ${NumberFormat('#,###', 'vi_VN').format(transaction.amount)} VNĐ
Nội dung: $transferContent''',
    };
  }

  // Get available payment methods
  List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod(
        id: 'momo',
        type: PaymentMethodType.momo,
        displayName: 'Ví MoMo',
        description: 'Thanh toán qua ví điện tử MoMo',
        isEnabled: true,
        fee: 0,
        iconUrl: 'assets/icons/momo.png',
      ),
      PaymentMethod(
        id: 'banking',
        type: PaymentMethodType.banking,
        displayName: 'Chuyển khoản ngân hàng',
        description: 'Chuyển khoản qua QR Banking',
        isEnabled: true,
        fee: 0,
        iconUrl: 'assets/icons/banking.png',
      ),
      PaymentMethod(
        id: 'cash',
        type: PaymentMethodType.cash,
        displayName: 'Thanh toán tại quầy',
        description: 'Thanh toán trực tiếp tại gym',
        isEnabled: true,
        fee: 0,
        iconUrl: 'assets/icons/cash.png',
      ),
    ];
  }

  // Get payment transaction by ID
  Future<PaymentTransaction?> getPaymentTransaction(String transactionId) async {
    try {
      final doc = await _paymentsCollection.doc(transactionId).get();
      if (doc.exists) {
        return PaymentTransaction.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting payment transaction: $e');
      return null;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String transactionId, PaymentStatus status) async {
    try {
      await _paymentsCollection.doc(transactionId).update({
        'status': status.toString(),
        'completedAt': status == PaymentStatus.completed ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  // Handle MoMo callback
  Future<bool> handleMoMoCallback(Map<String, dynamic> callbackData) async {
    try {
      // Verify callback and parse data
      final isValid = _momoService.verifyCallback(callbackData);
      final callbackDataObj = _momoService.handleCallback(callbackData);
      final success = isValid && callbackDataObj != null && callbackDataObj.isSuccess;
      
      if (success) {
        print('MoMo callback processed successfully');
      } else {
        print('MoMo callback processing failed');
      }
      
      return success;
    } catch (e) {
      print('Error handling MoMo callback: $e');
      return false;
    }
  }

  // Simulate payment completion (for demo)
  Future<void> simulatePaymentCompletion(String transactionId) async {
    await Future.delayed(const Duration(seconds: 2));
    await updatePaymentStatus(transactionId, PaymentStatus.completed);
  }

  // Generate transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'PAY_${timestamp.toString().substring(8)}$random';
  }

  // Generate request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'REQ_$timestamp$random';
  }
}
