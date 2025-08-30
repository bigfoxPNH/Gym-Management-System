import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/payment_transaction.dart';
import '../models/payment_method.dart';
import '../models/membership_card.dart';
import 'momo_service_v3.dart';

class PaymentService {
  final CollectionReference _paymentsCollection;
  final MoMoServiceV3 _momoService = MoMoServiceV3();

  PaymentService()
    : _paymentsCollection = FirebaseFirestore.instance.collection(
        'payment_transactions',
      );

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

    if (paymentMethod == PaymentMethodType.momo) {
      enrichedTransaction = await _createMomoPayment(transaction);
    } else {
      enrichedTransaction = transaction;
    }

    // Update in Firestore
    await _paymentsCollection
        .doc(transactionId)
        .update(enrichedTransaction.toMap());

    return enrichedTransaction;
  }

  // Tạo thanh toán MoMo (thực tế)
  Future<PaymentTransaction> _createMomoPayment(
    PaymentTransaction transaction,
  ) async {
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
  Future<PaymentTransaction> _createMomoPaymentDemo(
    PaymentTransaction transaction,
  ) async {
    final qrData = _generateMomoQR(transaction);

    return transaction.copyWith(
      qrCodeUrl: qrData['qrUrl'],
      bankInfo: qrData['info'],
    );
  }

  // Generate demo MoMo QR
  Map<String, String> _generateMomoQR(PaymentTransaction transaction) {
    final requestId = _generateRequestId();

    return {
      'qrUrl':
          'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=momo://app?amount=${transaction.amount.toInt()}&description=${Uri.encodeComponent(transaction.description ?? "Thanh toán")}&requestId=$requestId',
      'info':
          'Demo MoMo QR - Amount: ${NumberFormat('#,###', 'vi_VN').format(transaction.amount)} VNĐ',
    };
  }

  // Get available payment methods
  List<PaymentMethod> getAvailablePaymentMethods() {
    return [
      PaymentMethod(
        id: 'momo',
        name: 'momo',
        displayName: 'Ví MoMo',
        type: PaymentMethodType.momo,
        iconUrl: 'assets/icons/momo.png',
        isEnabled: true,
        description: 'Thanh toán qua ví điện tử MoMo',
        fee: 0,
      ),
    ];
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
