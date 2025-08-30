import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';

class MemberManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<UserAccount> users = <UserAccount>[].obs;
  final RxList<UserAccount> filteredUsers = <UserAccount>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<Role?> selectedRole = Rx<Role?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAllUsers();

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
      return users.where((u) => u.role == Role.membershipCard).length;
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

  // Delete membership card
  Future<void> deleteMembershipCard(String cardId) async {
    try {
      await _firestore.collection('membership_cards').doc(cardId).delete();
      Get.snackbar(
        'Thành công',
        'Đã xóa thẻ hội viên',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa thẻ hội viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
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
}
