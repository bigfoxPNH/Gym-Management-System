import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/direct_payment_controller.dart';
import '../../models/membership_card.dart';
import '../../models/payment_transaction.dart';
import '../../widgets/loading_button.dart';

class DirectPaymentConfirmationView extends StatelessWidget {
  const DirectPaymentConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DirectPaymentController());

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>;
    final membershipCard = args['membershipCard'] as MembershipCard;
    final transaction = args['transaction'] as PaymentTransaction;

    controller.setPaymentData(membershipCard, transaction);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán trực tiếp'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment confirmation card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Thanh toán trực tiếp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Membership info
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thẻ tập: ${membershipCard.cardName}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thời hạn: ${membershipCard.duration} ngày',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Giá: ${membershipCard.price.toStringAsFixed(0)} VNĐ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instructions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hướng dẫn thanh toán',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          const _InstructionStep(
                            step: '1',
                            text: 'Đến quầy lễ tân của phòng tập',
                          ),
                          const _InstructionStep(
                            step: '2',
                            text: 'Xuất trình mã đơn hàng cho nhân viên',
                          ),
                          const _InstructionStep(
                            step: '3',
                            text: 'Thanh toán tiền mặt theo giá trị đơn hàng',
                          ),
                          const _InstructionStep(
                            step: '4',
                            text: 'Nhận xác nhận và kích hoạt thẻ tập',
                          ),

                          const SizedBox(height: 14),

                          // Order code
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Mã đơn hàng',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transaction.id,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed footer with action buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confirm button
                  Obx(
                    () => LoadingButton(
                      text: 'Xác nhận đã thanh toán',
                      isLoading: controller.isLoading.value,
                      backgroundColor: Colors.green,
                      height: 48,
                      onPressed: () => controller.confirmDirectPayment(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy bỏ',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String step;
  final String text;

  const _InstructionStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
