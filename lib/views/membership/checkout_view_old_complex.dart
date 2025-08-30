import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/checkout_controller.dart';
import '../../models/membership_card.dart';
import '../../models/payment_method.dart';
import '../../models/payment_transaction.dart';
import '../../widgets/app_button.dart';

class CheckoutView extends StatelessWidget {
  CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.put(CheckoutController());
    // Get arguments from route
    final arguments = Get.arguments as Map<String, dynamic>?;
    final MembershipCard? membershipCard = arguments?['membershipCard'];
    final String? purchaseId = arguments?['purchaseId'];

    if (membershipCard == null || purchaseId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const Center(child: Text('Thông tin không hợp lệ')),
      );
    }

    // Initialize checkout
    controller.setMembershipCard(membershipCard);
    // Nếu cần truyền purchaseId, có thể lưu vào controller hoặc truyền qua hàm khác

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Obx(() {
        if (controller.currentTransaction.value != null) {
          return _buildPaymentProcessing(controller);
        }
        return _buildCheckoutForm(membershipCard, controller);
      }),
    );
  }

  Widget _buildCheckoutForm(
    MembershipCard membershipCard,
    CheckoutController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(membershipCard),
          const SizedBox(height: 20),

          // Payment Method Selection
          _buildPaymentMethodSection(controller),
          const SizedBox(height: 20),

          // Order Total
          _buildOrderTotalCard(controller),
          const SizedBox(height: 30),

          // Confirm Payment Button
          _buildConfirmButton(controller),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(MembershipCard membershipCard) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getCardTypeColor(membershipCard.cardType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membershipCard.cardName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCardTypeText(membershipCard.cardType),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDurationText(membershipCard),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat('#,###', 'vi_VN').format(membershipCard.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(' VNĐ', style: TextStyle(color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(CheckoutController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: controller.availablePaymentMethods.map((method) {
                  final isSelected =
                      controller.selectedPaymentMethod.value?.id == method.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: method.isEnabled
                          ? () => controller.selectPaymentMethod(method)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Get.theme.primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: method.isEnabled
                              ? (isSelected
                                    ? Get.theme.primaryColor.withOpacity(0.1)
                                    : Colors.white)
                              : Colors.grey[100],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getPaymentMethodColor(method.type),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getPaymentMethodIcon(method.type),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: method.isEnabled
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    method.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Get.theme.primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotalCard(CheckoutController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giá thẻ:', style: TextStyle(fontSize: 16)),
                Text(
                  controller.getFormattedAmount(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => Text(
                    controller.getFormattedTotalAmount(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(CheckoutController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: AppButton(
          text: 'Xác nhận thanh toán',
          onPressed: controller.selectedPaymentMethod.value != null
              ? controller.createPayment
              : null,
          isLoading: controller.isProcessingPayment.value,
          height: 50,
        ),
      ),
    );
  }

  Widget _buildPaymentProcessing(CheckoutController controller) {
    return Obx(() {
      final transaction = controller.currentTransaction.value;
      if (transaction == null) return const SizedBox.shrink();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildPaymentStatusCard(transaction),
            const SizedBox(height: 20),
            if (transaction.paymentMethod == PaymentMethodType.momo) ...[
              _buildMomoPaymentInstructions(transaction),
            ] else if (transaction.paymentMethod ==
                PaymentMethodType.banking) ...[
              _buildBankingPaymentInstructions(transaction),
            ] else ...[
              _buildCashPaymentInstructions(transaction, controller),
            ],
            const SizedBox(height: 30),
            _buildPaymentActions(transaction, controller),
          ],
        ),
      );
    });
  }

  Widget _buildPaymentStatusCard(PaymentTransaction transaction) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(transaction.status),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              transaction.getStatusText(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã giao dịch: ${transaction.id}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomoPaymentInstructions(PaymentTransaction transaction) {
    final isDemo = transaction.metadata?['isDemo'] == true;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB0006D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thanh toán bằng MoMo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDemo)
                      const Text(
                        'Phiên bản Demo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // QR Code Section
            if (transaction.qrCodeUrl != null &&
                transaction.qrCodeUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Quét mã QR để thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          transaction.qrCodeUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('QR Code loading error: $error');
                            return const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                Text(
                                  'Không thể tải QR Code',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mã giao dịch:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Flexible(
                        child: Text(
                          transaction.id,
                          style: const TextStyle(fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số tiền:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Flexible(
                        child: Text(
                          '${NumberFormat('#,###', 'vi_VN').format(transaction.amount)} VNĐ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB0006D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFB0006D).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFFB0006D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hướng dẫn thanh toán:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB0006D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Mở ứng dụng MoMo trên điện thoại'),
                  const Text('2. Chọn "Quét mã QR"'),
                  const Text('3. Quét mã QR phía trên'),
                  const Text('4. Xác nhận thanh toán trong ứng dụng'),
                  if (isDemo) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Lưu ý: Đây là phiên bản demo, vui lòng sử dụng nút mô phỏng bên dưới.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Demo button (only show for demo)
            if (isDemo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Giả lập thanh toán thành công (Demo)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingPaymentInstructions(PaymentTransaction transaction) {
    final isDemo = transaction.metadata?['isDemo'] == true;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chuyển khoản ngân hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDemo)
                      const Text(
                        'Phiên bản Demo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // VietQR Code Section
            if (transaction.qrCodeUrl != null &&
                transaction.qrCodeUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Quét mã QR bằng app ngân hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          transaction.qrCodeUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('VietQR loading error: $error');
                            return const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                Text(
                                  'Không thể tải QR Code',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bank Transfer Info
            if (transaction.bankInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Thông tin chuyển khoản:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        transaction.bankInfo!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hướng dẫn thanh toán:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Mở ứng dụng ngân hàng trên điện thoại'),
                  const Text('2. Chọn "Quét mã QR" hoặc "Chuyển khoản"'),
                  const Text('3. Quét mã QR hoặc nhập thông tin chuyển khoản'),
                  const Text('4. Kiểm tra thông tin và xác nhận chuyển khoản'),
                  if (isDemo) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Lưu ý: Đây là phiên bản demo, vui lòng sử dụng nút mô phỏng bên dưới.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Demo button (only show for demo)
            if (isDemo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Giả lập thanh toán thành công (Demo)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPaymentInstructions(
    PaymentTransaction transaction,
    CheckoutController controller,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Thanh toán tại quầy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thanh toán tại quầy lễ tân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Vui lòng đến quầy lễ tân để thanh toán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mã giao dịch: ${transaction.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Số tiền: ${NumberFormat('#,###', 'vi_VN').format(transaction.amount)} VNĐ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Đây là phiên bản demo. Trong thực tế, nhân viên sẽ xác nhận thanh toán và kích hoạt thẻ cho bạn.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Demo button for simulation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle),
                label: const Text('Giả lập thanh toán thành công'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentActions(
    PaymentTransaction transaction,
    CheckoutController controller,
  ) {
    return Column(
      children: [
        // Payment Status Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.toNamed('/payment/status', arguments: transaction.id);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Xem trạng thái thanh toán'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (transaction.canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Hủy thanh toán'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (transaction.isFailed) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Thử lại',
              onPressed: controller.retryPayment,
            ),
          ),
        ],
      ],
    );
  }

  // Helper methods
  Color _getCardTypeColor(CardType cardType) {
    switch (cardType) {
      case CardType.member:
        return Colors.blue;
      case CardType.premium:
        return Colors.orange;
      case CardType.vip:
        return Colors.purple;
    }
  }

  String _getCardTypeText(CardType cardType) {
    switch (cardType) {
      case CardType.member:
        return 'Thành viên';
      case CardType.premium:
        return 'Cao cấp';
      case CardType.vip:
        return 'VIP';
    }
  }

  String _getDurationText(MembershipCard card) {
    switch (card.durationType) {
      case DurationType.days:
        return '${card.duration} ngày';
      case DurationType.months:
        return '${card.duration} tháng';
      case DurationType.years:
        return '${card.duration} năm';
      case DurationType.custom:
        return 'Tùy chỉnh';
    }
  }

  Color _getPaymentMethodColor(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.momo:
        return const Color(0xFFB0006D);
      case PaymentMethodType.banking:
        return Colors.blue;
      case PaymentMethodType.cash:
        return Colors.green;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.momo:
        return Icons.account_balance_wallet;
      case PaymentMethodType.banking:
        return Icons.account_balance;
      case PaymentMethodType.cash:
        return Icons.attach_money;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.expired:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.access_time;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.expired:
        return Icons.timer_off;
    }
  }
}
