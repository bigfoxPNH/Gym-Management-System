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

  // Statistics getters
  int get adminCount => users.where((u) => u.role == Role.admin).length;
  int get managerCount => users.where((u) => u.role == Role.manager).length;
  int get staffCount => users.where((u) => u.role == Role.staff).length;
  int get memberCount => users.where((u) => u.role == Role.member).length;

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
          final user = UserAccount.fromMap({...doc.data(), 'id': doc.id});
          users.add(user);
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }
      
      _applyFilters(); // Apply current filters after loading
      
      Get.snackbar(
        'Thành công',
        'Đã tải ${users.length} thành viên',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
      );
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
        dob: userData['dateOfBirth'] != null && userData['dateOfBirth'].isNotEmpty 
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
        'phone': userData['phoneNumber'] ?? '',
        'address': userData['address'] ?? '',
        'dob': userData['dateOfBirth'] != null && userData['dateOfBirth'].isNotEmpty 
            ? _parseDate(userData['dateOfBirth'])?.millisecondsSinceEpoch
            : null,
        'role': userData['role'],
        'updatedAt': Timestamp.now().millisecondsSinceEpoch,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);

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
      await _firestore
          .collection('users')
          .doc(userId)
          .delete();

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
    
    return users.where((user) =>
      user.fullName.toLowerCase().contains(query.toLowerCase()) ||
      user.email.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Filter users by role
  List<UserAccount> filterUsersByRole(Role role) {
    return users.where((user) => user.role == role).toList();
  }

  // Apply search and role filters
  void _applyFilters() {
    List<UserAccount> filtered = users.toList();
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((user) =>
        user.fullName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        user.email.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        (user.phone?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Apply role filter
    if (selectedRole.value != null) {
      filtered = filtered.where((user) => user.role == selectedRole.value).toList();
    }
    
    filteredUsers.value = filtered;
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
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}
