import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership_card.dart';
import '../models/payment_transaction.dart';
import '../services/auth_service.dart';

class DirectPaymentController extends GetxController {
  final isLoading = false.obs;

  MembershipCard? membershipCard;
  PaymentTransaction? transaction;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setPaymentData(MembershipCard card, PaymentTransaction trans) {
    membershipCard = card;
    transaction = trans;
  }

  Future<void> confirmDirectPayment() async {
    if (membershipCard == null || transaction == null) {
      Get.snackbar('Lỗi', 'Thiếu thông tin thanh toán');
      return;
    }

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập');
      return;
    }

    isLoading.value = true;

    try {
      // Create user membership record data
      final membershipId = DateTime.now().millisecondsSinceEpoch.toString();
      final userMembershipData = {
        'id': membershipId,
        'userId': currentUser.uid,
        'membershipCardId': membershipCard!.id,
        'membershipCardName': membershipCard!.cardName,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: membershipCard!.duration)),
        ),
        'price': membershipCard!.price,
        'paymentMethod': 'direct',
        'paymentStatus': 'pending',
        'transactionId': transaction!.id,
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('user_memberships')
          .doc(membershipId)
          .set(userMembershipData);

      // Also save transaction record
      await _firestore
          .collection('payment_transactions')
          .doc(transaction!.id)
          .set({
            ...transaction!.toMap(),
            'paymentMethod': 'direct',
            'status': 'pending',
            'note': 'Thanh toán trực tiếp - Chờ xác nhận từ nhân viên',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Show success dialog
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Thành công'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đơn hàng đã được tạo thành công!'),
              SizedBox(height: 8),
              Text(
                'Vui lòng đến quầy lễ tân để hoàn tất thanh toán.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.offAllNamed('/home'); // Go back to home page
              },
              child: const Text('Về trang chủ'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.offAllNamed(
                  '/my-membership-cards',
                ); // Go to my membership cards
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Xem thẻ tập',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print('❌ Error confirming direct payment: $e');
      Get.snackbar('Lỗi', 'Không thể xác nhận thanh toán: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
