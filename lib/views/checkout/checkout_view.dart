import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/checkout_controller.dart';
import '../../models/membership_card.dart';

class CheckoutView extends StatelessWidget {
  final CheckoutController controller = Get.put(CheckoutController());

  CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get membership card from arguments - handle both MembershipCard object and Map
    MembershipCard? membershipCard;

    try {
      final args = Get.arguments;
      print('=== CheckoutView Debug ===');
      print('Arguments type: ${args.runtimeType}');
      print('Arguments value: $args');

      if (args is MembershipCard) {
        membershipCard = args;
        print('Direct MembershipCard object received');
      } else if (args is Map<String, dynamic>) {
        print('Map received, checking for membershipCard key');
        if (args.containsKey('membershipCard')) {
          final cardData = args['membershipCard'];
          if (cardData is MembershipCard) {
            membershipCard = cardData;
            print('MembershipCard found in map');
          } else if (cardData is Map<String, dynamic>) {
            membershipCard = MembershipCard.fromMap(
              cardData,
              cardData['id'] ?? 'unknown-id',
            );
            print('Converting map data to MembershipCard');
          }
        } else {
          // Try to convert entire map to MembershipCard
          membershipCard = MembershipCard.fromMap(
            args,
            args['id'] ?? 'unknown-id',
          );
          print('Converting entire map to MembershipCard');
        }
      } else {
        print('Unknown argument type: ${args.runtimeType}');
      }
    } catch (e) {
      print('Error parsing arguments: $e');
      membershipCard = null;
    }

    if (membershipCard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Không tìm thấy thông tin thẻ tập'),
              SizedBox(height: 16),
              Text('Vui lòng thử lại từ trang chủ'),
            ],
          ),
        ),
      );
    }

    // Set membership card in controller
    controller.membershipCard = membershipCard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Membership Card Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membershipCard.cardName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(membershipCard.description),
                    const SizedBox(height: 8),
                    Text(
                      'Giá: ${membershipCard.price.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method
            const Text(
              'Phương thức thanh toán:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Obx(
              () => Card(
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Color(0xFFB0006D)),
                  title: Text(
                    controller.selectedPaymentMethod.value?.displayName ??
                        'MoMo',
                  ),
                  subtitle: const Text('Ví điện tử MoMo'),
                  trailing: const Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFFB0006D),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Payment Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.createPayment();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0006D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
