import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class QRCheckinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate QR data for user checkin/checkout
  static String generateUserQRData(String userId, String userEmail) {
    final qrData = {
      'type': 'gym_checkin',
      'userId': userId,
      'email': userEmail,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(qrData);
  }

  /// Validate QR data and check if user has active membership
  static Future<Map<String, dynamic>> validateQRForCheckin(
    String qrDataString,
  ) async {
    try {
      print('=== QR Validation Debug ===');
      print('QR Data String: $qrDataString');

      // Parse QR data
      final qrData = jsonDecode(qrDataString);
      print('Parsed QR Data: $qrData');

      // Validate QR format
      if (qrData['type'] != 'gym_checkin' || qrData['userId'] == null) {
        return {'isValid': false, 'message': 'QR code không hợp lệ'};
      }

      final userId = qrData['userId'];
      final userEmail = qrData['email'];
      print('User ID: $userId, Email: $userEmail');

      // Get user information
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User not found in users collection');
        return {'isValid': false, 'message': 'Người dùng không tồn tại'};
      }

      final userData = userDoc.data()!;
      final userName = userData['fullName'] ?? userEmail;
      print('User found: $userName');

      // Check if user has active membership
      final activeMembership = await _getActiveUserMembership(userId);
      print('Active Membership: $activeMembership');

      if (activeMembership == null) {
        return {
          'isValid': false,
          'message': 'Người dùng không có thẻ tập đang hoạt động',
          'userId': userId,
          'userName': userName,
        };
      }

      print('=== QR Validation Success ===');
      return {
        'isValid': true,
        'message': 'QR code hợp lệ',
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'membership': activeMembership,
      };
    } catch (e) {
      print('Error validating QR: $e');
      return {'isValid': false, 'message': 'Lỗi khi xử lý QR code: $e'};
    }
  }

  /// Get active membership for user
  static Future<Map<String, dynamic>?> _getActiveUserMembership(
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      print('=== Checking memberships for user: $userId ===');
      print('Current time: $now');

      // Check user_memberships collection (from your Firebase screenshot)
      final userMembershipsQuery = await _firestore
          .collection('user_memberships')
          .where('userId', isEqualTo: userId)
          .get();

      print(
        'user_memberships query returned ${userMembershipsQuery.docs.length} docs',
      );

      // Find valid membership (not expired and active)
      for (final doc in userMembershipsQuery.docs) {
        final data = doc.data();
        print('user_memberships doc: $data');

        final isActive = data['isActive'] ?? false;
        final paymentStatus = data['paymentStatus'] ?? '';
        final endDate = (data['endDate'] as Timestamp?)?.toDate();

        print(
          'isActive: $isActive, paymentStatus: $paymentStatus, endDate: $endDate',
        );

        if (endDate != null) {
          print('End date: $endDate, is after now: ${endDate.isAfter(now)}');

          // Check if membership is active and not expired
          if (isActive &&
              paymentStatus == 'completed' &&
              endDate.isAfter(now)) {
            final result = {
              'id': doc.id,
              'cardName':
                  data['membershipCardName'] ??
                  data['cardName'] ??
                  'Unknown Card',
              'endDate': endDate,
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? now,
              ...data,
            };
            print('Found valid membership in user_memberships: $result');
            return result;
          }
        }
      }

      // Fallback: check membership_purchases collection
      final purchasesQuery = await _firestore
          .collection('membership_purchases')
          .where('userId', isEqualTo: userId)
          .get();

      print(
        'membership_purchases query returned ${purchasesQuery.docs.length} docs',
      );

      // Find valid membership (not expired and completed payment)
      for (final doc in purchasesQuery.docs) {
        final data = doc.data();
        print('membership_purchases doc: $data');

        final paymentStatus = data['paymentStatus'] ?? '';
        final status = data['status'] ?? '';
        final endDate = (data['endDate'] as Timestamp?)?.toDate();

        print(
          'paymentStatus: $paymentStatus, status: $status, endDate: $endDate',
        );

        if (endDate != null) {
          print('End date: $endDate, is after now: ${endDate.isAfter(now)}');

          // Check if payment is completed and membership not expired
          if ((paymentStatus == 'completed' || status == 'active') &&
              endDate.isAfter(now)) {
            final result = {
              'id': doc.id,
              'cardName': data['cardName'] ?? 'Unknown Card',
              'endDate': endDate,
              'startDate': (data['startDate'] as Timestamp?)?.toDate() ?? now,
              ...data,
            };
            print('Found valid membership in membership_purchases: $result');
            return result;
          }
        }
      }

      print('No valid membership found for user: $userId');
      return null;
    } catch (e) {
      print('Error getting active membership: $e');
      return null;
    }
  }

  /// Record checkin/checkout activity
  static Future<bool> recordCheckinCheckout({
    required String userId,
    required String userName,
    required String type, // 'checkin' or 'checkout'
    required Map<String, dynamic> membership,
    String? notes,
  }) async {
    try {
      await _firestore.collection('check_ins').add({
        'userId': userId,
        'userName': userName,
        'userEmail': membership['userEmail'] ?? '',
        'type': type,
        'method': 'qr_scan',
        'membershipId': membership['id'],
        'membershipName': membership['cardName'],
        'membershipEndDate': membership['endDate'],
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'notes': notes ?? '',
      });

      return true;
    } catch (e) {
      print('Error recording checkin/checkout: $e');
      return false;
    }
  }

  /// Get user's checkin/checkout history
  static Future<List<Map<String, dynamic>>> getUserCheckinHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('check_ins')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting checkin history: $e');
      return [];
    }
  }

  /// Get today's checkin statistics
  static Future<Map<String, dynamic>> getTodayCheckinStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('check_ins')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int checkinCount = 0;
      int checkoutCount = 0;
      final uniqueUsers = <String>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final type = data['type'];
        final userId = data['userId'];

        if (type == 'checkin') {
          checkinCount++;
        } else if (type == 'checkout') {
          checkoutCount++;
        }

        if (userId != null) {
          uniqueUsers.add(userId);
        }
      }

      return {
        'totalCheckins': checkinCount,
        'totalCheckouts': checkoutCount,
        'uniqueVisitors': uniqueUsers.length,
        'totalRecords': querySnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting today stats: $e');
      return {
        'totalCheckins': 0,
        'totalCheckouts': 0,
        'uniqueVisitors': 0,
        'totalRecords': 0,
      };
    }
  }
}
