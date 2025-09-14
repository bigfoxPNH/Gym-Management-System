import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_account.dart';
import '../models/membership_card.dart';

class MemberManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<UserAccount> users = <UserAccount>[].obs;
  final RxList<UserAccount> filteredUsers = <UserAccount>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<Role?> selectedRole = Rx<Role?>(null);
  final RxList<MembershipCard> membershipCards = <MembershipCard>[].obs;
  final RxList<Map<String, dynamic>> userMemberships =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredUserMemberships =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllUsers();
    loadAllMembershipCards();
    loadAllUserMemberships();

    // Listen to search query changes
    searchQuery.listen((_) => _applyFilters());
    selectedRole.listen((_) => _applyFilters());
  }

  // Statistics getters with error handling
  int get adminCount {
    try {
      return users.where((u) => u.role == Role.admin).length;
    } catch (e) {
      print('Error calculating adminCount: $e');
      return 0;
    }
  }

  int get managerCount {
    try {
      return users.where((u) => u.role == Role.manager).length;
    } catch (e) {
      print('Error calculating managerCount: $e');
      return 0;
    }
  }

  int get staffCount {
    try {
      return users.where((u) => u.role == Role.staff).length;
    } catch (e) {
      print('Error calculating staffCount: $e');
      return 0;
    }
  }

  int get memberCount {
    try {
      return users.where((u) => u.role == Role.member).length;
    } catch (e) {
      print('Error calculating memberCount: $e');
      return 0;
    }
  }

  int get membershipCardCount {
    try {
      return userMemberships.length;
    } catch (e) {
      return 0;
    }
  }

  // Load all users from Firestore
  Future<void> loadAllUsers() async {
    try {
      isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('fullName')
          .get();

      users.clear();
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Processing user ${doc.id}');
          print('Raw data: $data');

          // Validate data before parsing
          if (data.isEmpty) {
            print('Empty data for user ${doc.id}');
            continue;
          }

          // Clean problematic fields
          if (data['avatarUrl'] != null) {
            final avatarUrl = data['avatarUrl'].toString();
            if (avatarUrl.contains('data:image/') || avatarUrl.length > 1000) {
              print('Removing problematic avatarUrl for user ${doc.id}');
              data['avatarUrl'] = null;
            }
          }

          // Validate timestamp fields
          final fieldsToCheck = ['dob', 'createdAt', 'updatedAt'];
          for (final field in fieldsToCheck) {
            if (data[field] != null) {
              print(
                '$field value: ${data[field]} (type: ${data[field].runtimeType})',
              );
              // Convert invalid timestamps
              if (data[field] is String) {
                final parsed = int.tryParse(data[field]);
                if (parsed != null && parsed > 0) {
                  data[field] = parsed;
                } else {
                  print('Removing invalid $field for user ${doc.id}');
                  data[field] = null;
                }
              }
            }
          }

          final user = UserAccount.fromMap({...data, 'id': doc.id});
          users.add(user);
          print('Successfully parsed user ${doc.id}: ${user.fullName}');
        } catch (e, stackTrace) {
          print('Error parsing user ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          print('User data: ${doc.data()}');
          // Skip this user and continue with others
          continue;
        }
      }

      _applyFilters(); // Apply current filters after loading
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách thành viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load all membership cards from Firestore
  Future<void> loadAllMembershipCards() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore.collection('membershipCards').get();
      membershipCards.value = snapshot.docs
          .map((doc) => MembershipCard.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading membership cards: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load all user memberships from Firestore
  Future<void> loadAllUserMemberships() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore.collection('user_memberships').get();

      List<Map<String, dynamic>> memberships = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> membership = {'id': doc.id, ...doc.data()};

        // Get user info
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(membership['userId'])
              .get();
          if (userDoc.exists) {
            membership['userName'] =
                userDoc.data()?['fullName'] ?? 'Unknown User';
            membership['userEmail'] = userDoc.data()?['email'] ?? '';
          }
        } catch (e) {
          membership['userName'] = 'Unknown User';
          membership['userEmail'] = '';
        }

        // Get membership card info for membershipType
        try {
          final cardDoc = await _firestore
              .collection('membership_cards')
              .doc(membership['membershipCardId'])
              .get();
          if (cardDoc.exists) {
            membership['membershipType'] =
                cardDoc.data()?['cardName'] ??
                membership['membershipCardName'] ??
                'Không xác định';
          } else {
            membership['membershipType'] =
                membership['membershipCardName'] ?? 'Không xác định';
          }
        } catch (e) {
          membership['membershipType'] =
              membership['membershipCardName'] ?? 'Không xác định';
        }

        memberships.add(membership);
      }

      userMemberships.value = memberships;
      filteredUserMemberships.value = memberships;
    } catch (e) {
      print('Error loading user memberships: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create new user
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;

      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );

      if (credential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Create user document in Firestore
      final userAccount = UserAccount(
        id: credential.user!.uid,
        email: userData['email'],
        fullName: userData['fullName'],
        phone: userData['phoneNumber'] ?? '',
        address: userData['address'] ?? '',
        dob:
            userData['dateOfBirth'] != null &&
                userData['dateOfBirth'].isNotEmpty
            ? _parseDate(userData['dateOfBirth'])
            : null,
        avatarUrl: '',
        role: _parseRole(userData['role']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userAccount.toMap());

      // Reload users list
      await loadAllUsers();

      Get.snackbar(
        'Thành công',
        'Đã tạo thành viên mới: ${userData['fullName']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      print('Error creating user: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tạo thành viên mới: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;

      // Update user document in Firestore
      final updateData = {
        'fullName': userData['fullName'],
        'email': userData['email'], // Add email update
        'phone': userData['phoneNumber'] ?? '',
        'address': userData['address'] ?? '',
        'dob':
            userData['dateOfBirth'] != null &&
                userData['dateOfBirth'].isNotEmpty
            ? _parseDate(userData['dateOfBirth'])?.millisecondsSinceEpoch
            : null,
        'role': userData['role'],
        'updatedAt': DateTime.now()
            .millisecondsSinceEpoch, // Fix: Use DateTime instead of Timestamp
      };

      // Remove null values to avoid Firestore issues
      updateData.removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(userId).update(updateData);

      // Reload users list
      await loadAllUsers();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật thông tin thành viên',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      print('Error updating user: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật thông tin thành viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      isLoading.value = true;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: We can't delete the user from Firebase Auth here
      // because we don't have admin privileges to do so
      // This would require Firebase Admin SDK

      // Remove from local list
      users.removeWhere((user) => user.id == userId);

      Get.snackbar(
        'Thành công',
        'Đã xóa thành viên khỏi hệ thống',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      print('Error deleting user: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa thành viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add new membership card
  Future<void> addMembershipCard(MembershipCard card) async {
    try {
      await _firestore.collection('membershipCards').doc(card.id).set({
        'cardName': card.cardName,
        'description': card.description,
        'cardType': card.cardType.label,
        'durationType': card.durationType.label,
        'duration': card.duration,
        'customEndDate': card.customEndDate?.toIso8601String(),
        'price': card.price,
        'createdAt': card.createdAt.toIso8601String(),
        'updatedAt': card.updatedAt.toIso8601String(),
        'createdBy': card.createdBy,
        'isActive': card.isActive,
      });
      membershipCards.add(card);
    } catch (e) {
      print('Error adding membership card: $e');
    }
  }

  // Update membership card
  Future<void> updateMembershipCard(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore
          .collection('membershipCards')
          .doc(id)
          .update(updatedData);
      final index = membershipCards.indexWhere((card) => card.id == id);
      if (index != -1) {
        membershipCards[index] = membershipCards[index].copyWith(
          cardName: updatedData['cardName'] ?? membershipCards[index].cardName,
          description:
              updatedData['description'] ?? membershipCards[index].description,
          price: updatedData['price'] ?? membershipCards[index].price,
          isActive: updatedData['isActive'] ?? membershipCards[index].isActive,
        );
      }
    } catch (e) {
      print('Error updating membership card: $e');
    }
  }

  // Delete membership card
  Future<void> deleteMembershipCard(String id) async {
    try {
      await _firestore.collection('membershipCards').doc(id).delete();
      membershipCards.removeWhere((card) => card.id == id);
    } catch (e) {
      print('Error deleting membership card: $e');
    }
  }

  // Helper method to parse role string to Role enum
  Role _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'staff':
        return Role.staff;
      case 'member':
      default:
        return Role.member;
    }
  }

  // Search users by name or email
  List<UserAccount> searchUsers(String query) {
    if (query.isEmpty) return users;

    return users
        .where(
          (user) =>
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Filter users by role
  List<UserAccount> filterUsersByRole(Role role) {
    return users.where((user) => user.role == role).toList();
  }

  // Apply search and role filters
  void _applyFilters() {
    try {
      List<UserAccount> filtered = users.toList();

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        filtered = filtered.where((user) {
          try {
            return user.fullName.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                user.email.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                (user.phone?.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ??
                    false);
          } catch (e) {
            print('Error filtering user ${user.id}: $e');
            return false;
          }
        }).toList();
      }

      // Apply role filter
      if (selectedRole.value != null) {
        filtered = filtered
            .where((user) => user.role == selectedRole.value)
            .toList();
      }

      filteredUsers.value = filtered;
    } catch (e) {
      print('Error applying filters: $e');
      filteredUsers.value = users.toList();
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Update role filter
  void updateRoleFilter(Role? role) {
    selectedRole.value = role;

    // If membershipCard is selected, load user memberships
    if (role == Role.membershipCard) {
      loadAllUserMemberships();
    }
  }

  // Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedRole.value = null;
  }

  // Helper method to parse date from string (dd/mm/yyyy)
  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      final parts = dateString.trim().split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0].trim());
      final month = int.tryParse(parts[1].trim());
      final year = int.tryParse(parts[2].trim());

      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900)
        return null;

      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date from string: $dateString - $e');
      return null;
    }
  }

  // User Membership Management Methods
  Future<void> updateUserMembershipStatus(
    String membershipId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('user_memberships').doc(membershipId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final index = userMemberships.indexWhere((m) => m['id'] == membershipId);
      if (index != -1) {
        userMemberships[index]['isActive'] = isActive;
        userMemberships.refresh();
      }

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái thẻ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating membership status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái');
    }
  }

  Future<void> updateUserMembershipPaymentStatus(
    String membershipId,
    String paymentStatus,
  ) async {
    try {
      await _firestore.collection('user_memberships').doc(membershipId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final index = userMemberships.indexWhere((m) => m['id'] == membershipId);
      if (index != -1) {
        userMemberships[index]['paymentStatus'] = paymentStatus;
        userMemberships.refresh();
      }

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái thanh toán',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating payment status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái thanh toán');
    }
  }

  Future<void> deleteUserMembership(String membershipId) async {
    try {
      await _firestore
          .collection('user_memberships')
          .doc(membershipId)
          .delete();

      // Remove from local data
      userMemberships.removeWhere((m) => m['id'] == membershipId);
      filteredUserMemberships.removeWhere((m) => m['id'] == membershipId);

      Get.snackbar(
        'Thành công',
        'Đã xóa thẻ thành công',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting membership: $e');
      Get.snackbar('Lỗi', 'Không thể xóa thẻ');
    }
  }

  Future<void> extendMembership(String membershipId, int additionalDays) async {
    try {
      final membershipDoc = await _firestore
          .collection('user_memberships')
          .doc(membershipId)
          .get();
      if (!membershipDoc.exists) return;

      final data = membershipDoc.data()!;
      final currentEndDate = (data['endDate'] as Timestamp).toDate();
      final newEndDate = currentEndDate.add(Duration(days: additionalDays));

      await _firestore.collection('user_memberships').doc(membershipId).update({
        'endDate': Timestamp.fromDate(newEndDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final index = userMemberships.indexWhere((m) => m['id'] == membershipId);
      if (index != -1) {
        userMemberships[index]['endDate'] = Timestamp.fromDate(newEndDate);
        userMemberships.refresh();
      }

      Get.snackbar(
        'Thành công',
        'Đã gia hạn thẻ $additionalDays ngày',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error extending membership: $e');
      Get.snackbar('Lỗi', 'Không thể gia hạn thẻ');
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

  String getMembershipStatus(Map<String, dynamic> membership) {
    final isActive = membership['isActive'] ?? false;
    final paymentStatus = membership['paymentStatus'] ?? '';
    final endDate = membership['endDate'];

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

  // New method to get detailed membership status
  Map<String, String> getMembershipDetailedStatus(
    Map<String, dynamic> membership,
  ) {
    final isActive = membership['isActive'] ?? false;
    final paymentStatus = membership['paymentStatus'] ?? '';
    final endDate = membership['endDate'];

    String primaryStatus = '';
    String secondaryStatus = '';

    // Determine payment status
    if (paymentStatus == 'completed') {
      secondaryStatus = 'Đã thanh toán';
    } else if (paymentStatus == 'pending') {
      secondaryStatus = 'Chờ thanh toán';
    } else if (paymentStatus == 'failed') {
      secondaryStatus = 'Thanh toán thất bại';
    } else {
      secondaryStatus = 'Chưa thanh toán';
    }

    // Determine activation status
    if (!isActive) {
      primaryStatus = 'Chưa kích hoạt';
    } else {
      if (endDate != null) {
        DateTime endDateTime;
        if (endDate is Timestamp) {
          endDateTime = endDate.toDate();
        } else if (endDate is DateTime) {
          endDateTime = endDate;
        } else {
          primaryStatus = 'Đang hoạt động';
          return {'primary': primaryStatus, 'secondary': secondaryStatus};
        }

        if (endDateTime.isBefore(DateTime.now())) {
          primaryStatus = 'Đã hết hạn';
        } else {
          primaryStatus = 'Đang hoạt động';
        }
      } else {
        primaryStatus = 'Đang hoạt động';
      }
    }

    return {'primary': primaryStatus, 'secondary': secondaryStatus};
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

  String formatPaymentMethod(String? paymentMethod) {
    if (paymentMethod == null) return 'Không xác định';

    switch (paymentMethod.toLowerCase()) {
      case 'direct':
        return 'Thanh toán trực tiếp';
      case 'momo':
        return 'Ví MoMo';
      case 'bank':
        return 'Chuyển khoản ngân hàng';
      case 'cash':
        return 'Tiền mặt';
      default:
        return paymentMethod;
    }
  }

  String formatPaymentStatus(String? paymentStatus) {
    if (paymentStatus == null) return 'Không xác định';

    switch (paymentStatus.toLowerCase()) {
      case 'completed':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'failed':
        return 'Thanh toán thất bại';
      case 'cancelled':
        return 'Đã hủy';
      case 'processing':
        return 'Đang xử lý';
      default:
        return paymentStatus;
    }
  }

  String formatAmount(dynamic amount) {
    if (amount == null) return '0';

    double amountValue;
    if (amount is String) {
      amountValue = double.tryParse(amount) ?? 0;
    } else if (amount is num) {
      amountValue = amount.toDouble();
    } else {
      return '0';
    }

    // Format with thousands separator
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amountValue);
  }
}
