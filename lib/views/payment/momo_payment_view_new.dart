import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/membership_card.dart';
import '../../models/payment_transaction.dart';
import '../../models/payment_method.dart';
import '../../controllers/momo_payment_controller.dart';

class MoMoPaymentView extends StatelessWidget {
  const MoMoPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get controller and initialize
    final controller = Get.put(MoMoPaymentController());

    // Get arguments from navigation
    final arguments = Get.arguments as Map<String, dynamic>?;
    final membershipCard = arguments?['membershipCard'] as MembershipCard?;
    final transaction = arguments?['transaction'] as PaymentTransaction?;

    // Debug logging
    print('=== MoMoPaymentView Debug ===');
    print('Arguments: $arguments');
    print('MembershipCard: ${membershipCard?.id}');
    print('Transaction: ${transaction?.id}');

    // Use mock data if arguments are null (for testing)
    final displayCard =
        membershipCard ??
        MembershipCard(
          id: 'mock-card-id',
          cardName: 'Gói thành viên cơ bản',
          description: 'Mock membership card for testing',
          cardType: CardType.member,
          durationType: DurationType.days,
          duration: 30,
          price: 500000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
          isActive: true,
        );

    final displayTransaction =
        transaction ??
        PaymentTransaction(
          id: 'mock-transaction-id',
          userId: 'mock-user-id',
          membershipCardId: 'mock-card-id',
          membershipPurchaseId: 'mock-purchase-id',
          paymentType: PaymentType.membership,
          paymentMethod: PaymentMethodType.momo,
          amount: 500000,
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
        );

    // Initialize payment with the data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializePayment(displayCard, displayTransaction.id);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thanh toán MoMo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB0006D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildBody(displayCard, displayTransaction, controller),
    );
  }

  Widget _buildBody(
    MembershipCard card,
    PaymentTransaction transaction,
    MoMoPaymentController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderInfo(card, transaction),
          const SizedBox(height: 20),
          _buildRedirectInfo(controller),
          const SizedBox(height: 20),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(MembershipCard card, PaymentTransaction transaction) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Sản phẩm', card.cardName),
            _buildInfoRow(
              'Thời hạn',
              '${card.duration} ${card.durationType.label.toLowerCase()}',
            ),
            _buildInfoRow('Mã giao dịch', transaction.id),
            _buildInfoRow('Số tiền', formatter.format(transaction.amount)),
            _buildInfoRow('Phương thức', 'MoMo'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedirectInfo(MoMoPaymentController controller) {
    return Obx(() {
      if (controller.paymentSuccess.value) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Thanh toán thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Cảm ơn bạn đã sử dụng dịch vụ.\nĐang chuyển về trang chủ...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      if (controller.hasError.value) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${controller.errorMessage.value}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retryPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0006D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      }

      // Default: Show redirect info
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFB0006D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_browser,
                  color: Color(0xFFB0006D),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang mở trang thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB0006D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.statusMessage.value,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFFB0006D)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hướng dẫn thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1',
              'Trang thanh toán MoMo sẽ mở trong trình duyệt',
            ),
            _buildInstructionStep(
              '2',
              'Quét mã QR bằng ứng dụng MoMo trong vòng 2 phút',
            ),
            _buildInstructionStep(
              '3',
              'Xác nhận thanh toán trong ứng dụng MoMo',
            ),
            _buildInstructionStep(
              '4',
              'Hệ thống sẽ tự động xác nhận và kích hoạt thẻ',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(height: 4),
                  Text(
                    'Lưu ý',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mã QR có hiệu lực trong 2 phút. Sau thời gian này bạn sẽ cần tạo lại giao dịch.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFB0006D),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
