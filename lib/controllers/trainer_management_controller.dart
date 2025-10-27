import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trainer.dart';
import '../models/trainer_assignment.dart';
import '../models/trainer_review.dart';
import '../models/trainer_schedule.dart';
import 'member_management_controller.dart';

class TrainerManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable lists
  var trainers = <Trainer>[].obs;
  var filteredTrainers = <Trainer>[].obs;
  var assignments = <TrainerAssignment>[].obs;
  var reviews = <TrainerReview>[].obs;
  var schedules = <TrainerSchedule>[].obs;

  // Loading states
  var isLoading = false.obs;
  var isLoadingAssignments = false.obs;
  var isLoadingReviews = false.obs;
  var isLoadingSchedules = false.obs;

  // Filters
  var searchQuery = ''.obs;
  var selectedStatus = 'all'.obs; // 'all', 'active', 'inactive', ...
  var selectedSpecialty = 'all'.obs;

  // Statistics
  var totalTrainers = 0.obs;
  var activeTrainers = 0.obs;
  var totalSessions = 0.obs;
  var totalRevenue = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadTrainers();
    loadStatistics();
  }

  // ============ LOAD DATA ============

  Future<void> loadTrainers() async {
    try {
      isLoading.value = true;
      print('🔄 [TrainerMgmt] Loading trainers from Firestore...');

      final snapshot = await _firestore
          .collection('trainers')
          .orderBy('createdAt', descending: true)
          .get();

      print(
        '✅ [TrainerMgmt] Firestore returned ${snapshot.docs.length} documents',
      );

      final loadedTrainers = <Trainer>[];
      for (var doc in snapshot.docs) {
        final trainer = Trainer.fromFirestore(doc);
        loadedTrainers.add(trainer);
        print(
          '   - Trainer: ${trainer.hoTen} (docId: ${doc.id}, userId: ${trainer.userId})',
        );
      }

      print(
        '✅ [TrainerMgmt] Loaded ${loadedTrainers.length} trainers from Firestore',
      );

      trainers.value = loadedTrainers;
      applyFilters();

      print(
        '✅ [TrainerMgmt] Applied filters, filteredTrainers: ${filteredTrainers.length}',
      );
    } catch (e) {
      print('❌ [TrainerMgmt] Error loading trainers: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách PT: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAssignments([String? trainerId]) async {
    try {
      isLoadingAssignments.value = true;
      Query<Map<String, dynamic>> query = _firestore.collection(
        'trainer_assignments',
      );

      if (trainerId != null) {
        query = query.where('trainerId', isEqualTo: trainerId);
      }

      final snapshot = await query.get();
      final list = snapshot.docs
          .map((doc) => TrainerAssignment.fromFirestore(doc))
          .toList();

      // Sort ở client-side để tránh cần composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      assignments.value = list;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách phân công: $e');
    } finally {
      isLoadingAssignments.value = false;
    }
  }

  Future<void> loadReviews([String? trainerId]) async {
    try {
      isLoadingReviews.value = true;
      Query<Map<String, dynamic>> query = _firestore.collection(
        'trainer_reviews',
      );

      if (trainerId != null) {
        query = query.where('trainerId', isEqualTo: trainerId);
      }

      final snapshot = await query.get();
      final list = snapshot.docs
          .map((doc) => TrainerReview.fromFirestore(doc))
          .toList();

      // Sort ở client-side để tránh cần composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      reviews.value = list;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải đánh giá: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  Future<void> loadSchedules([String? trainerId, DateTime? date]) async {
    try {
      isLoadingSchedules.value = true;
      Query<Map<String, dynamic>> query = _firestore.collection(
        'trainer_schedules',
      );

      if (trainerId != null) {
        query = query.where('trainerId', isEqualTo: trainerId);
      }

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        query = query
            .where(
              'ngay',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('ngay', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      final snapshot = await query.get();
      final list = snapshot.docs
          .map((doc) => TrainerSchedule.fromFirestore(doc))
          .toList();

      // Sort ở client-side để tránh cần composite index
      list.sort((a, b) => a.ngay.compareTo(b.ngay));
      schedules.value = list;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải lịch làm việc: $e');
    } finally {
      isLoadingSchedules.value = false;
    }
  }

  Future<void> loadStatistics() async {
    try {
      // Count trainers by status
      final trainersSnapshot = await _firestore.collection('trainers').get();
      totalTrainers.value = trainersSnapshot.docs.length;
      activeTrainers.value = trainersSnapshot.docs
          .where((doc) => (doc.data())['trangThai'] == 'active')
          .length;

      // Count total sessions
      final assignmentsSnapshot = await _firestore
          .collection('trainer_assignments')
          .where('trangThai', isEqualTo: 'active')
          .get();

      totalSessions.value = assignmentsSnapshot.docs.fold(
        0,
        (sum, doc) => sum + ((doc.data())['soBuoiHoanThanh'] as int? ?? 0),
      );

      // Calculate total revenue (example calculation)
      totalRevenue.value = assignmentsSnapshot.docs.fold(0, (sum, doc) {
        final sessions = (doc.data())['soBuoiHoanThanh'] as int? ?? 0;
        final price = (doc.data())['mucGia'] as num? ?? 0;
        return sum + (sessions * price.toInt());
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  // ============ CRUD OPERATIONS ============

  // Cleanup invalid trainers (those with null userId)
  Future<void> cleanupInvalidTrainers() async {
    try {
      print('🔄 [TrainerMgmt.cleanup] Starting cleanup of invalid trainers...');

      final snapshot = await _firestore.collection('trainers').get();
      int deletedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'];

        // STRICT CHECK: Only delete if userId is ACTUALLY null or empty string
        final isInvalid =
            userId == null || (userId is String && userId.trim().isEmpty);

        if (isInvalid) {
          print(
            '   🗑️ Deleting trainer with null/empty userId: ${doc.id} (${data['hoTen']})',
          );
          print('      userId value: $userId (type: ${userId.runtimeType})');
          await doc.reference.delete();
          deletedCount++;
        } else {
          print(
            '   ✅ Keeping trainer with valid userId: ${doc.id} (${data['hoTen']}) - userId: $userId',
          );
        }
      }

      print(
        '✅ [TrainerMgmt.cleanup] Cleanup completed. Deleted $deletedCount invalid trainer(s)',
      );

      if (deletedCount > 0) {
        Get.snackbar(
          'Thành công',
          'Đã xóa $deletedCount PT không hợp lệ',
          duration: const Duration(seconds: 3),
        );
        await loadTrainers();
      } else {
        Get.snackbar(
          'Thông báo',
          'Không tìm thấy PT không hợp lệ. Tất cả PT đều có userId.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ [TrainerMgmt.cleanup] Error: $e');
      Get.snackbar('Lỗi', 'Không thể xóa PT không hợp lệ: $e');
    }
  }

  Future<void> addTrainer(Trainer trainer) async {
    try {
      isLoading.value = true;

      // VALIDATE: Trainer must have userId
      if (trainer.userId == null || trainer.userId!.isEmpty) {
        Get.snackbar(
          'Lỗi',
          'PT phải có tài khoản người dùng. Vui lòng tạo tài khoản từ Quản Lý Thành Viên trước.',
          backgroundColor: Colors.red[100],
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check if trainer with this userId already exists
      final existingQuery = await _firestore
          .collection('trainers')
          .where('userId', isEqualTo: trainer.userId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        Get.snackbar(
          'Lỗi',
          'Tài khoản này đã có hồ sơ PT. Vui lòng sửa hồ sơ hiện tại thay vì tạo mới.',
          backgroundColor: Colors.red[100],
          duration: const Duration(seconds: 4),
        );
        return;
      }

      await _firestore.collection('trainers').add(trainer.toFirestore());
      Get.back();
      Get.snackbar('Thành công', 'Đã thêm PT mới');
      await loadTrainers();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm PT: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTrainer(Trainer trainer) async {
    try {
      isLoading.value = true;

      print('🔄 [TrainerMgmt.update] Updating trainer: ${trainer.hoTen}');
      print('   Trainer ID: ${trainer.id}');
      print('   Trainer userId: ${trainer.userId}');

      // CRITICAL VALIDATION: Ensure userId is not null when updating
      if (trainer.userId == null || trainer.userId!.trim().isEmpty) {
        print(
          '❌ [TrainerMgmt.update] ERROR: Attempting to update with null/empty userId!',
        );
        print(
          '   This would break sync. Fetching current userId from Firestore...',
        );

        // Fetch current trainer data to preserve userId
        final currentDoc = await _firestore
            .collection('trainers')
            .doc(trainer.id)
            .get();

        if (currentDoc.exists) {
          final currentUserId = currentDoc.data()?['userId'];
          if (currentUserId != null &&
              currentUserId.toString().trim().isNotEmpty) {
            print(
              '✅ [TrainerMgmt.update] Preserved userId from Firestore: $currentUserId',
            );

            // Create new trainer object with preserved userId
            final trainerWithUserId = Trainer(
              id: trainer.id,
              userId: currentUserId,
              hoTen: trainer.hoTen,
              email: trainer.email,
              soDienThoai: trainer.soDienThoai,
              gioiTinh: trainer.gioiTinh,
              namSinh: trainer.namSinh,
              anhDaiDien: trainer.anhDaiDien,
              diaChi: trainer.diaChi,
              bangCap: trainer.bangCap,
              chuyenMon: trainer.chuyenMon,
              moTa: trainer.moTa,
              chungChi: trainer.chungChi,
              namKinhNghiem: trainer.namKinhNghiem,
              trinhDoPT: trainer.trinhDoPT,
              trangThai: trainer.trangThai,
              mucLuongCoBan: trainer.mucLuongCoBan,
              hoaHongPhanTram: trainer.hoaHongPhanTram,
              ngayVaoLam: trainer.ngayVaoLam,
              ngayNghiViec: trainer.ngayNghiViec,
              danhGiaTrungBinh: trainer.danhGiaTrungBinh,
              soLuotDanhGia: trainer.soLuotDanhGia,
              facebookUrl: trainer.facebookUrl,
              instagramUrl: trainer.instagramUrl,
              ghiChu: trainer.ghiChu,
              createdAt: trainer.createdAt,
              updatedAt: trainer.updatedAt,
              createdBy: trainer.createdBy,
            );

            // Update with preserved userId
            await _firestore
                .collection('trainers')
                .doc(trainer.id)
                .update(trainerWithUserId.toFirestore());

            // SYNC with preserved userId
            await _syncUserAccount(trainerWithUserId);
          } else {
            print(
              '⚠️ [TrainerMgmt.update] WARNING: Current document also has no userId!',
            );
            print('   Proceeding with update but sync will fail.');
            await _firestore
                .collection('trainers')
                .doc(trainer.id)
                .update(trainer.toFirestore());
          }
        }
      } else {
        // Normal update with valid userId
        print(
          '✅ [TrainerMgmt.update] Trainer has valid userId, proceeding with update',
        );
        await _firestore
            .collection('trainers')
            .doc(trainer.id)
            .update(trainer.toFirestore());

        // SYNC: Always try to sync user account (method will handle finding user)
        await _syncUserAccount(trainer);
      }

      Get.back();
      Get.snackbar('Thành công', 'Đã cập nhật thông tin PT');

      // Reload trainers list
      await loadTrainers();

      // IMPORTANT: Also reload MemberManagementController if exists
      print(
        '🔄 [TrainerMgmt] Attempting to find MemberManagementController...',
      );
      try {
        final memberController = Get.find<MemberManagementController>();
        print('✅ [TrainerMgmt] Found MemberManagementController! Reloading...');
        await memberController.loadAllUsers();
        print(
          '✅ [TrainerMgmt] MemberManagementController reloaded successfully!',
        );
      } catch (e) {
        print('⚠️ [TrainerMgmt] Could not find MemberManagementController');
        print('   Error: ${e.toString().split('\n').first}');
        print(
          '   This is normal if Member Management page hasn\'t been opened yet.',
        );
      }
    } catch (e) {
      print('❌ [TrainerMgmt.update] Error: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to sync trainer data back to user account
  Future<void> _syncUserAccount(Trainer trainer) async {
    try {
      print(
        '🔄 [SYNC] Starting sync user account for trainer: ${trainer.hoTen}',
      );

      String? userId = trainer.userId;

      // CRITICAL: Validate userId before proceeding
      if (userId == null || userId.trim().isEmpty) {
        print('❌ [SYNC] Trainer has no userId, cannot sync to user account');
        print('   Trainer ID: ${trainer.id}');
        print('   Trainer name: ${trainer.hoTen}');
        return;
      }

      print('✅ [SYNC] Trainer has userId: $userId');

      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ [SYNC] User document not found for userId: $userId');
        return;
      }

      print('✅ [SYNC] Found user document for userId: $userId');

      // Update user document with trainer data
      final updateData = <String, dynamic>{
        'fullName': trainer.hoTen,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Only update email if it's not empty
      if (trainer.email != null && trainer.email!.isNotEmpty) {
        updateData['email'] = trainer.email;
      }

      // Only update phone if it's not empty
      if (trainer.soDienThoai != null && trainer.soDienThoai!.isNotEmpty) {
        updateData['phone'] = trainer.soDienThoai;
      }

      // Only update address if it's not empty
      if (trainer.diaChi != null && trainer.diaChi!.isNotEmpty) {
        updateData['address'] = trainer.diaChi;
      }

      // Only update dob if it exists
      if (trainer.namSinh != null) {
        updateData['dob'] = trainer.namSinh!.millisecondsSinceEpoch;
      }

      // Remove null values
      updateData.removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(userId).update(updateData);

      print('✅ [SYNC] Synced user account $userId with trainer data');
      print('📝 [SYNC] Updated data: $updateData');
    } catch (e) {
      print('❌ [SYNC] Error syncing user account: $e');
      // Don't throw - trainer update should still succeed
    }
  }

  Future<void> deleteTrainer(String trainerId) async {
    try {
      isLoading.value = true;

      // Check if trainer has active assignments
      final assignmentsSnapshot = await _firestore
          .collection('trainer_assignments')
          .where('trainerId', isEqualTo: trainerId)
          .where('trangThai', isEqualTo: 'active')
          .get();

      if (assignmentsSnapshot.docs.isNotEmpty) {
        Get.snackbar(
          'Không thể xóa',
          'PT này đang có học viên đang tập. Vui lòng hoàn thành hoặc hủy các phân công trước.',
          duration: const Duration(seconds: 4),
        );
        return;
      }

      await _firestore.collection('trainers').doc(trainerId).delete();
      Get.back();
      Get.snackbar('Thành công', 'Đã xóa PT');
      await loadTrainers();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> assignTrainerToUser({
    required String trainerId,
    required String userId,
    required String trainerName,
    required String userName,
    required int soBuoi,
    required double mucGia,
  }) async {
    try {
      isLoadingAssignments.value = true;

      final assignment = TrainerAssignment(
        id: '',
        trainerId: trainerId,
        userId: userId,
        trainerName: trainerName,
        userName: userName,
        ngayBatDau: DateTime.now(),
        soBuoiDangKy: soBuoi,
        mucGia: mucGia,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin',
      );

      await _firestore
          .collection('trainer_assignments')
          .add(assignment.toFirestore());

      Get.back();
      Get.snackbar('Thành công', 'Đã phân công PT cho học viên');
      await loadAssignments();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể phân công: $e');
    } finally {
      isLoadingAssignments.value = false;
    }
  }

  // ============ FILTERS ============

  void applyFilters() {
    print(
      '🔄 [TrainerMgmt.applyFilters] Starting filter with ${trainers.length} trainers',
    );
    print(
      '   Search: "${searchQuery.value}", Status: ${selectedStatus.value}, Specialty: ${selectedSpecialty.value}',
    );

    var filtered = trainers.toList();

    // Search by name
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((trainer) {
        return trainer.hoTen.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }).toList();
    }

    // Filter by status
    if (selectedStatus.value != 'all') {
      filtered = filtered
          .where((trainer) => trainer.trangThai == selectedStatus.value)
          .toList();
    }

    // Filter by specialty
    if (selectedSpecialty.value != 'all') {
      filtered = filtered.where((trainer) {
        return trainer.chuyenMon.contains(selectedSpecialty.value);
      }).toList();
    }

    print(
      '✅ [TrainerMgmt.applyFilters] Filtered to ${filtered.length} trainers',
    );
    filteredTrainers.value = filtered;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    applyFilters();
  }

  void updateSpecialtyFilter(String specialty) {
    selectedSpecialty.value = specialty;
    applyFilters();
  }

  // ============ HELPERS ============

  List<TrainerAssignment> getAssignmentsForTrainer(String trainerId) {
    return assignments.where((a) => a.trainerId == trainerId).toList();
  }

  List<TrainerReview> getReviewsForTrainer(String trainerId) {
    return reviews.where((r) => r.trainerId == trainerId).toList();
  }

  double getAverageRating(String trainerId) {
    final trainerReviews = getReviewsForTrainer(trainerId);
    if (trainerReviews.isEmpty) return 0;

    final sum = trainerReviews.fold(0.0, (sum, review) => sum + review.rating);
    return sum / trainerReviews.length;
  }

  int getTotalSessionsForTrainer(String trainerId) {
    final trainerAssignments = getAssignmentsForTrainer(trainerId);
    return trainerAssignments.fold(
      0,
      (sum, assignment) => sum + assignment.soBuoiHoanThanh,
    );
  }
}
