import 'package:get/get.dart';

import '../models/membership_card.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../models/user_account.dart';
import '../services/auth_service.dart';

class CheckoutController extends GetxController {
  // Observable state
  final isLoading = false.obs;
  final selectedPaymentMethod = Rxn<PaymentMethod>();
  final currentTransaction = Rxn<PaymentTransaction>();
  final availablePaymentMethods = <PaymentMethod>[].obs;
  final isProcessingPayment = false.obs;

  // Data
  MembershipCard? membershipCard;
  UserAccount? currentUser;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    // Get current user from Firebase Auth (static)
    final firebaseUser = AuthService.currentUser;
    if (firebaseUser != null) {
      currentUser = UserAccount(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        fullName: firebaseUser.displayName ?? '',
        phone: firebaseUser.phoneNumber,
        avatarUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Set default payment method to Banking
    selectedPaymentMethod.value = PaymentMethod(
      id: 'banking',
      name: 'banking',
      displayName: 'Chuyển khoản ngân hàng',
      type: PaymentMethodType.banking,
      iconUrl: 'assets/images/banking_icon.png',
      isEnabled: true,
      description: 'Thanh toán qua chuyển khoản ngân hàng',
    );
  }

  // Set membership card for checkout
  void setMembershipCard(MembershipCard card) {
    membershipCard = card;
    update();
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  // Create payment - simplified version
  Future<void> createPayment() async {
    if (membershipCard == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn thẻ tập');
      return;
    }

    if (selectedPaymentMethod.value == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn phương thức thanh toán');
      return;
    }

    isLoading.value = true;

    try {
      // Create transaction
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final purchaseId = DateTime.now().microsecondsSinceEpoch.toString();

      final transaction = PaymentTransaction(
        id: transactionId,
        userId: currentUser?.id ?? '',
        membershipCardId: membershipCard!.id,
        membershipPurchaseId: purchaseId,
        paymentType: PaymentType.membership,
        paymentMethod: selectedPaymentMethod.value!.type,
        amount: membershipCard!.price,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        description: 'Mua ${membershipCard!.cardName}',
      );

      currentTransaction.value = transaction;

      // Navigate to Banking payment page
      if (selectedPaymentMethod.value!.type == PaymentMethodType.banking) {
        print('🚀 Navigating to Banking payment with:');
        print('  - MembershipCard: ${membershipCard?.cardName}');
        print('  - Transaction: ${transaction.id}');

        Get.toNamed(
          '/banking-payment',
          arguments: {
            'membershipCard': membershipCard,
            'transaction': transaction,
          },
        );
      } else {
        Get.snackbar('Thông báo', 'Phương thức thanh toán chưa được hỗ trợ');
      }
    } catch (e) {
      print('❌ Error creating payment: $e');
      Get.snackbar('Lỗi', 'Không thể tạo thanh toán: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Retry payment
  Future<void> retryPayment() async {
    currentTransaction.value = null;
    await createPayment();
  }

  // Get formatted payment method name
  String getPaymentMethodName() {
    return selectedPaymentMethod.value?.displayName ?? '';
  }

  // Get formatted amount
  String getFormattedAmount() {
    if (membershipCard == null) return '';
    return '${membershipCard!.price.toStringAsFixed(0)} VNĐ';
  }

  // Get total amount (no transaction fee)
  double getTotalAmount() {
    return membershipCard?.price ?? 0;
  }

  // Get formatted total amount
  String getFormattedTotalAmount() {
    if (membershipCard == null) return '0 VNĐ';
    return '${getTotalAmount().toStringAsFixed(0)} VNĐ';
  }
}
