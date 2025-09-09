import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/payment_transaction.dart';
import '../models/payment_method.dart';
import 'vietqr_service.dart';

class PaymentService {
  final CollectionReference _paymentsCollection;
  final VietQRService _vietqrService = VietQRService();

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

    switch (paymentMethod) {
      case PaymentMethodType.banking:
        enrichedTransaction = await _createBankingPayment(transaction);
        break;
      case PaymentMethodType.cash:
        enrichedTransaction = transaction;
        break;
    }

    // Update in Firestore
    await _paymentsCollection
        .doc(transactionId)
        .update(enrichedTransaction.toMap());

    return enrichedTransaction;
  }

  // Tạo thanh toán Banking (thực tế)
  Future<PaymentTransaction> _createBankingPayment(
    PaymentTransaction transaction,
  ) async {
    try {
      print('Creating real Banking payment for transaction: ${transaction.id}');

      // Generate transfer content
      final transferContent = 'GYMPRO ${transaction.id}';

      // Call VietQR API
      final qrUrl = _vietqrService.generateQRUrl(
        amount: transaction.amount,
        description: transferContent,
      );

      if (qrUrl.isNotEmpty) {
        final bankInfo = _vietqrService.getBankTransferInfo(
          amount: transaction.amount,
          description: transferContent,
          transferCode: transferContent,
        );

        return transaction.copyWith(
          qrCodeUrl: qrUrl,
          bankInfo: bankInfo.values.join('\n'),
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
  Future<PaymentTransaction> _createBankingPaymentDemo(
    PaymentTransaction transaction,
  ) async {
    final bankInfo = _generateBankingInfo(transaction);

    return transaction.copyWith(
      qrCodeUrl: bankInfo['qrUrl'],
      bankInfo: bankInfo['info'],
    );
  }

  // Generate demo Banking info
  Map<String, String> _generateBankingInfo(PaymentTransaction transaction) {
    final transferContent = 'GYMPRO ${transaction.id}';

    return {
      'qrUrl':
          'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=banking://transfer?amount=${transaction.amount.toInt()}&content=${Uri.encodeComponent(transferContent)}',
      'info':
          '''Ngân hàng: VIETCOMBANK
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
        id: 'banking',
        name: 'Banking',
        type: PaymentMethodType.banking,
        displayName: 'Chuyển khoản ngân hàng',
        description: 'Chuyển khoản qua VietQR',
        isEnabled: true,
        iconUrl: 'assets/icons/banking.png',
      ),
      PaymentMethod(
        id: 'cash',
        name: 'Cash',
        type: PaymentMethodType.cash,
        displayName: 'Thanh toán tại quầy',
        description: 'Thanh toán trực tiếp tại gym',
        isEnabled: true,
        iconUrl: 'assets/icons/cash.png',
      ),
    ];
  }

  // Get payment transaction by ID
  Future<PaymentTransaction?> getPaymentTransaction(
    String transactionId,
  ) async {
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
  Future<void> updatePaymentStatus(
    String transactionId,
    PaymentStatus status,
  ) async {
    try {
      await _paymentsCollection.doc(transactionId).update({
        'status': status.toString(),
        'completedAt': status == PaymentStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
      });
    } catch (e) {
      print('Error updating payment status: $e');
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
}
