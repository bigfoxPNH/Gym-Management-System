import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class MyMembershipCardsController extends GetxController {
  final isLoading = false.obs;
  final membershipCards = <Map<String, dynamic>>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    loadMyMembershipCards();
  }

  Future<void> loadMyMembershipCards() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập');
      return;
    }

    isLoading.value = true;
    try {
      // Simple query without orderBy to avoid index requirement
      final snapshot = await _firestore
          .collection('user_memberships')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> cards = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort locally by createdAt
      cards.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        DateTime aDate, bDate;
        if (aTime is Timestamp) {
          aDate = aTime.toDate();
        } else if (aTime is DateTime) {
          aDate = aTime;
        } else {
          return 1;
        }

        if (bTime is Timestamp) {
          bDate = bTime.toDate();
        } else if (bTime is DateTime) {
          bDate = bTime;
        } else {
          return -1;
        }

        return bDate.compareTo(aDate); // Descending order (newest first)
      });

      membershipCards.value = cards;
    } catch (e) {
      print('Error loading membership cards: $e');
      Get.snackbar('Lỗi', 'Không thể tải thẻ tập');
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return 'Không xác định';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Không xác định';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String getCardStatus(Map<String, dynamic> card) {
    final isActive = card['isActive'] ?? false;
    final paymentStatus = card['paymentStatus'] ?? '';
    final endDate = card['endDate'];

    if (paymentStatus == 'pending') {
      return 'Chờ thanh toán';
    }

    if (!isActive) {
      return 'Chưa kích hoạt';
    }

    if (endDate != null) {
      DateTime endDateTime;
      if (endDate is Timestamp) {
        endDateTime = endDate.toDate();
      } else if (endDate is DateTime) {
        endDateTime = endDate;
      } else {
        return 'Đang hoạt động';
      }

      if (endDateTime.isBefore(DateTime.now())) {
        return 'Đã hết hạn';
      }
    }

    return 'Đang hoạt động';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đang hoạt động':
        return Colors.green;
      case 'Chờ thanh toán':
        return Colors.orange;
      case 'Chưa kích hoạt':
        return Colors.blue;
      case 'Đã hết hạn':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int getDaysRemaining(Map<String, dynamic> card) {
    final endDate = card['endDate'];
    if (endDate == null) return 0;

    DateTime endDateTime;
    if (endDate is Timestamp) {
      endDateTime = endDate.toDate();
    } else if (endDate is DateTime) {
      endDateTime = endDate;
    } else {
      return 0;
    }

    final now = DateTime.now();
    final difference = endDateTime.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }
}
