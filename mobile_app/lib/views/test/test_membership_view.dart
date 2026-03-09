import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/auth_service.dart';

class TestMembershipController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTestMembership() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập');
      return;
    }

    try {
      final membershipId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final testMembershipData = {
        'id': membershipId,
        'userId': currentUser.uid,
        'membershipCardId': 'test_card_123',
        'membershipCardName': 'Thẻ Test - 1 Tháng',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'price': 500000.0,
        'paymentMethod': 'direct',
        'paymentStatus': 'completed',
        'transactionId':
            'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('user_memberships')
          .doc(membershipId)
          .set(testMembershipData);

      Get.snackbar(
        'Thành công',
        'Đã tạo thẻ test thành công!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error creating test membership: $e');
      Get.snackbar('Lỗi', 'Không thể tạo thẻ test: $e');
    }
  }
}

class TestMembershipView extends StatelessWidget {
  const TestMembershipView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TestMembershipController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Membership'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, size: 80, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Tạo thẻ test để kiểm tra',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.createTestMembership,
              icon: const Icon(Icons.add),
              label: const Text('Tạo thẻ test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/my-membership-cards'),
              icon: const Icon(Icons.card_membership),
              label: const Text('Xem thẻ tập của tôi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
