import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_account.dart';
import '../models/membership_card.dart';
import 'trainer_management_controller.dart';

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

  int get trainerCount {
    try {
      return users.where((u) => u.role == Role.trainer).length;
    } catch (e) {
      print('Error calculating trainerCount: $e');
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

      final userId = credential.user!.uid;
      final role = _parseRole(userData['role']);

      // Create user document in Firestore
      final userAccount = UserAccount(
        id: userId,
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
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(userAccount.toMap());

      // If role is trainer, create trainer profile
      if (role == Role.trainer) {
        await _createTrainerProfile(userId, userData);
      }

      // Reload users list
      await loadAllUsers();

      // Set isLoading false
      isLoading.value = false;

      // Close the dialog
      Get.back();

      // Small delay before showing snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Thành công',
        'Đã tạo thành viên mới: ${userData['fullName']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      print('Error creating user: $e');
      isLoading.value = false;

      // Close dialog on error too
      Get.back();

      // Small delay before showing error snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Lỗi',
        'Không thể tạo thành viên mới: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  // Helper method to create trainer profile
  Future<void> _createTrainerProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // VALIDATE: userId must not be null or empty
      if (userId.isEmpty) {
        print('❌ Cannot create trainer profile: userId is empty');
        return;
      }

      // Check if trainer profile already exists
      final existingQuery = await _firestore
          .collection('trainers')
          .where('userId', isEqualTo: userId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        print('⚠️ Trainer profile already exists for userId: $userId');
        return;
      }

      final trainerData = {
        'userId': userId, // CRITICAL: Always set userId
        'hoTen': userData['fullName'],
        'email': userData['email'],
        'soDienThoai': userData['phoneNumber'] ?? '',
        'gioiTinh': 'male', // Default, can be changed later
        'namSinh':
            userData['dateOfBirth'] != null &&
                userData['dateOfBirth'].isNotEmpty
            ? Timestamp.fromDate(_parseDate(userData['dateOfBirth'])!)
            : null,
        'anhDaiDien': null,
        'diaChi': userData['address'] ?? '',
        'bangCap': [],
        'chuyenMon': [],
        'moTa': 'Huấn luyện viên mới',
        'chungChi': [],
        'trangThai': 'active',
        'mucLuongCoBan': 0.0,
        'hoaHongPhanTram': 0.0,
        'ngayVaoLam': Timestamp.now(),
        'danhGiaTrungBinh': 0.0,
        'soLuotDanhGia': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdBy': 'admin',
      };

      await _firestore.collection('trainers').add(trainerData);

      print('✅ Created trainer profile for userId: $userId');
    } catch (e) {
      print('❌ Error creating trainer profile: $e');
      // Don't throw - user is already created, just log the error
    }
  }

  // Helper method to sync trainer profile with user data
  Future<void> _syncTrainerProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      print('🔄 [SYNC] Starting sync trainer profile for userId: $userId');

      // Find trainer document by userId
      final trainerQuery = await _firestore
          .collection('trainers')
          .where('userId', isEqualTo: userId)
          .get();

      if (trainerQuery.docs.isEmpty) {
        print('⚠️ [SYNC] No trainer profile found for userId: $userId');
        return;
      }

      print('✅ [SYNC] Found ${trainerQuery.docs.length} trainer profile(s)');

      // Update all trainer profiles with this userId (should be only 1)
      for (var doc in trainerQuery.docs) {
        final updateData = <String, dynamic>{
          'userId': userId, // CRITICAL: Always preserve userId
          'hoTen': userData['fullName'],
          'email': userData['email'],
          'soDienThoai': userData['phoneNumber'] ?? '',
          'diaChi': userData['address'] ?? '',
          'updatedAt': Timestamp.now(),
        };

        // Only update namSinh if dateOfBirth is provided
        if (userData['dateOfBirth'] != null &&
            userData['dateOfBirth'].toString().isNotEmpty) {
          final dob = _parseDate(userData['dateOfBirth']);
          if (dob != null) {
            updateData['namSinh'] = Timestamp.fromDate(dob);
          }
        }

        // Remove null values
        updateData.removeWhere((key, value) => value == null);

        await _firestore.collection('trainers').doc(doc.id).update(updateData);

        print('✅ [SYNC] Synced trainer profile ${doc.id} for userId: $userId');
        print('📝 [SYNC] Updated data: $updateData');
      }
    } catch (e) {
      print('❌ [SYNC] Error syncing trainer profile: $e');
      // Don't throw - user update should still succeed
    }
  }

  // Update existing user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;

      // Get old user data to check role change
      final oldUserDoc = await _firestore.collection('users').doc(userId).get();
      final oldRole = oldUserDoc.data()?['role'] ?? 'member';
      final newRole = userData['role'];

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
        'role': newRole,
        'updatedAt': DateTime.now()
            .millisecondsSinceEpoch, // Fix: Use DateTime instead of Timestamp
      };

      // Remove null values to avoid Firestore issues
      updateData.removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(userId).update(updateData);

      // Handle role change to trainer
      if (oldRole != 'trainer' && newRole == 'trainer') {
        // Check if trainer profile exists
        final trainerQuery = await _firestore
            .collection('trainers')
            .where('userId', isEqualTo: userId)
            .get();

        if (trainerQuery.docs.isEmpty) {
          // Create trainer profile if not exists
          await _createTrainerProfile(userId, userData);
        }
      }

      // Handle role change from trainer to other role
      if (oldRole == 'trainer' && newRole != 'trainer') {
        // Optional: You might want to deactivate or delete trainer profile
        // For now, we'll just set status to inactive
        final trainerQuery = await _firestore
            .collection('trainers')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in trainerQuery.docs) {
          await _firestore.collection('trainers').doc(doc.id).update({
            'trangThai': 'inactive',
            'updatedAt': Timestamp.now(),
          });
        }
      }

      // SYNC: If current role is trainer, update trainer profile
      if (newRole == 'trainer') {
        await _syncTrainerProfile(userId, userData);
      }

      // Reload users list
      await loadAllUsers();

      // IMPORTANT: Also reload TrainerManagementController if exists
      print(
        '🔄 [MemberMgmt] Attempting to find TrainerManagementController...',
      );
      try {
        final trainerController = Get.find<TrainerManagementController>();
        print('✅ [MemberMgmt] Found TrainerManagementController! Reloading...');
        await trainerController.loadTrainers();
        print(
          '✅ [MemberMgmt] TrainerManagementController reloaded successfully!',
        );
      } catch (e) {
        print('⚠️ [MemberMgmt] Could not find TrainerManagementController');
        print('   Error: ${e.toString().split('\n').first}');
        print(
          '   This is normal if Trainer Management page hasn\'t been opened yet.',
        );
      }

      // Set isLoading false
      isLoading.value = false;

      // Close the dialog
      Get.back();

      // Small delay before showing snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Thành công',
        'Đã cập nhật thông tin thành viên',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      print('Error updating user: $e');
      isLoading.value = false;

      // Close dialog on error
      Get.back();

      // Small delay before showing error snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật thông tin thành viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      isLoading.value = true;
      print('🔄 [MemberMgmt.delete] Starting delete for userId: $userId');

      // Get user data to check role
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userRole = userData?['role'] ?? 'member';
      final userName = userData?['fullName'] ?? 'Unknown';

      print('   User role: $userRole, name: $userName');

      // If user is trainer, also delete/deactivate trainer profile
      if (userRole == 'trainer') {
        print(
          '🔄 [MemberMgmt.delete] User is trainer, looking for trainer profile...',
        );
        print('   Query: trainers where userId == $userId');

        final trainerQuery = await _firestore
            .collection('trainers')
            .where('userId', isEqualTo: userId)
            .get();

        print('   Found ${trainerQuery.docs.length} trainer profile(s)');

        for (var doc in trainerQuery.docs) {
          final trainerData = doc.data();
          print('   Trainer doc ID: ${doc.id}');
          print(
            '   Trainer data: hoTen=${trainerData['hoTen']}, userId=${trainerData['userId']}',
          );

          // DELETE the trainer document
          print('   🗑️ Deleting trainer document: ${doc.id}');
          await _firestore.collection('trainers').doc(doc.id).delete();
          print('   ✅ Deleted trainer document: ${doc.id}');

          // Verify deletion
          final verifyDoc = await _firestore
              .collection('trainers')
              .doc(doc.id)
              .get();
          if (verifyDoc.exists) {
            print(
              '   ❌ WARNING: Trainer document ${doc.id} still exists after delete!',
            );
          } else {
            print(
              '   ✅ Verified: Trainer document ${doc.id} successfully deleted',
            );
          }
        }

        print(
          '✅ [MemberMgmt.delete] Deleted ${trainerQuery.docs.length} trainer profile(s) for userId: $userId',
        );
      }

      // Delete user document from Firestore
      print('🔄 [MemberMgmt.delete] Deleting user document...');
      await _firestore.collection('users').doc(userId).delete();
      print('✅ [MemberMgmt.delete] User document deleted');

      // Note: We can't delete the user from Firebase Auth here
      // because we don't have admin privileges to do so
      // This would require Firebase Admin SDK

      // Reload users list from Firestore to ensure sync
      print('🔄 [MemberMgmt.delete] Reloading users list...');
      await loadAllUsers();
      print('✅ [MemberMgmt.delete] Users list reloaded');

      // IMPORTANT: Also reload TrainerManagementController if exists
      print(
        '🔄 [MemberMgmt.delete] Attempting to find TrainerManagementController...',
      );
      try {
        final trainerController = Get.find<TrainerManagementController>();
        print(
          '✅ [MemberMgmt.delete] Found TrainerManagementController! Reloading...',
        );

        // Check current trainer count BEFORE reload
        print(
          '   Current trainers count BEFORE reload: ${trainerController.trainers.length}',
        );

        await trainerController.loadTrainers();

        // Check trainer count AFTER reload
        print(
          '   Current trainers count AFTER reload: ${trainerController.trainers.length}',
        );
        print(
          '   Filtered trainers count: ${trainerController.filteredTrainers.length}',
        );

        print(
          '✅ [MemberMgmt.delete] TrainerManagementController reloaded successfully!',
        );
      } catch (e) {
        print(
          '⚠️ [MemberMgmt.delete] Could not find TrainerManagementController',
        );
        print('   Error: ${e.toString().split('\n').first}');
        print(
          '   This is normal if Trainer Management page hasn\'t been opened yet.',
        );
      }

      // Set isLoading false
      isLoading.value = false;

      // Close the delete confirmation dialog
      Get.back();

      // Small delay before showing snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Thành công',
        'Đã xóa thành viên khỏi hệ thống',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      print('Error deleting user: $e');
      isLoading.value = false;

      // Close dialog on error
      Get.back();

      // Small delay before showing error snackbar
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Lỗi',
        'Không thể xóa thành viên: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
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
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload data to ensure consistency
      await loadAllUserMemberships();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái thẻ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating membership status: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> setMembershipExpired(String membershipId) async {
    try {
      await _firestore.collection('user_memberships').doc(membershipId).update({
        'status': 'expired',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload data to ensure consistency
      await loadAllUserMemberships();

      Get.snackbar(
        'Thành công',
        'Đã đặt thẻ sang trạng thái hết hạn',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error setting membership expired: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái hết hạn',
        snackPosition: SnackPosition.BOTTOM,
      );
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

      // Reload data to ensure consistency
      await loadAllUserMemberships();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái thanh toán',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating payment status: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái thanh toán',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    final status = membership['status'] ?? '';

    // Check explicit status first (for manually set expired status)
    if (status == 'expired') {
      return 'Đã hết hạn';
    }

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
    final status = membership['status'] ?? ''; // Add explicit status field

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

    // Check explicit status first (for manually set expired status)
    if (status == 'expired') {
      primaryStatus = 'Đã hết hạn';
      return {'primary': primaryStatus, 'secondary': secondaryStatus};
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
