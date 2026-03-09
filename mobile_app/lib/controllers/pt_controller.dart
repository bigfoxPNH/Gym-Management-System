import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trainer.dart';
import '../models/trainer_assignment.dart';
import '../models/trainer_review.dart';
import 'auth_controller.dart';

/// Controller cho Personal Trainer (PT) Dashboard
class PTController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authController = Get.find<AuthController>();

  // Observable data
  final Rx<Trainer?> _trainerProfile = Rx<Trainer?>(null);
  final RxList<TrainerAssignment> _myAssignments = <TrainerAssignment>[].obs;
  final RxList<TrainerReview> _myReviews = <TrainerReview>[].obs;
  final RxList<Map<String, dynamic>> _activeRentals =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  Trainer? get trainerProfile => _trainerProfile.value;
  List<TrainerAssignment> get myAssignments => _myAssignments;
  List<TrainerReview> get myReviews => _myReviews;
  List<Map<String, dynamic>> get activeRentals => _activeRentals;
  bool get isLoading => _isLoading.value;

  // Stats getters
  int get totalClients => _myAssignments
      .where((a) => a.trangThai == 'active' || a.trangThai == 'completed')
      .toSet()
      .length;

  int get activeClients =>
      _myAssignments.where((a) => a.trangThai == 'active').length;

  int get completedSessions => _myAssignments.fold<int>(
    0,
    (sum, assignment) => sum + assignment.soBuoiHoanThanh,
  );

  int get totalSessions => _myAssignments.fold<int>(
    0,
    (sum, assignment) => sum + assignment.soBuoiDangKy,
  );

  double get completionRate =>
      totalSessions > 0 ? (completedSessions / totalSessions * 100) : 0;

  double get averageRating => trainerProfile?.danhGiaTrungBinh ?? 0;

  int get totalReviews => trainerProfile?.soLuotDanhGia ?? 0;

  double get totalRevenue => _myAssignments.fold<double>(
    0,
    (sum, assignment) =>
        sum + ((assignment.mucGia ?? 0) * assignment.soBuoiHoanThanh),
  );

  @override
  void onInit() {
    super.onInit();
    _loadTrainerProfile();
  }

  /// Load trainer profile from userId
  Future<void> _loadTrainerProfile() async {
    try {
      _isLoading.value = true;
      final userId = _authController.user?.uid;

      if (userId == null) {
        print('No user logged in');
        return;
      }

      // Query trainer by userId
      final querySnapshot = await _firestore
          .collection('trainers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No trainer profile found for userId: $userId');
        Get.snackbar(
          'Thông báo',
          'Không tìm thấy hồ sơ PT. Vui lòng liên hệ quản trị viên.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final trainerDoc = querySnapshot.docs.first;
      _trainerProfile.value = Trainer.fromFirestore(trainerDoc);

      // Load assignments, reviews and rental statistics
      await _loadMyAssignments();
      await _loadMyReviews();
      await _loadActiveRentals();
      await loadRentalStatistics();
    } catch (e) {
      print('Error loading trainer profile: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải hồ sơ PT: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load assignments for this trainer
  Future<void> _loadMyAssignments() async {
    try {
      if (_trainerProfile.value == null) return;

      final querySnapshot = await _firestore
          .collection('trainer_assignments')
          .where('trainerId', isEqualTo: _trainerProfile.value!.id)
          .orderBy('ngayBatDau', descending: true)
          .get();

      _myAssignments.value = querySnapshot.docs
          .map((doc) => TrainerAssignment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  /// Load reviews for this trainer
  Future<void> _loadMyReviews() async {
    try {
      if (_trainerProfile.value == null) return;

      final querySnapshot = await _firestore
          .collection('trainer_reviews')
          .where('trainerId', isEqualTo: _trainerProfile.value!.id)
          .orderBy('createdAt', descending: true)
          .get();

      _myReviews.value = querySnapshot.docs
          .map((doc) => TrainerReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  /// Load active rentals (approved/completed) with user info
  Future<void> _loadActiveRentals() async {
    try {
      if (_trainerProfile.value == null) return;

      final querySnapshot = await _firestore
          .collection('trainer_rentals')
          .where('trainerId', isEqualTo: _trainerProfile.value!.id)
          .where('trangThai', whereIn: ['approved', 'completed'])
          .orderBy('createdAt', descending: true)
          .get();

      // Load user info for each rental
      final rentalsWithUserInfo = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;

        if (userId != null) {
          // Get user info
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            rentalsWithUserInfo.add({
              'rentalId': doc.id,
              'userId': userId,
              'userName': data['userName'] ?? 'N/A',
              'userAvatar': userData?['avatarUrl'],
              'trangThai': data['trangThai'],
              'startDate': (data['startDate'] as Timestamp?)?.toDate(),
              'endDate': (data['endDate'] as Timestamp?)?.toDate(),
            });
          }
        }
      }

      _activeRentals.value = rentalsWithUserInfo;
    } catch (e) {
      print('Error loading active rentals: $e');
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await _loadTrainerProfile();
  }

  /// Update session count for an assignment
  Future<void> updateSessionCount(String assignmentId, int newCount) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('trainer_assignments')
          .doc(assignmentId)
          .update({
            'soBuoiHoanThanh': newCount,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Refresh assignments
      await _loadMyAssignments();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật số buổi tập',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating session count: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Mark assignment as completed
  Future<void> completeAssignment(String assignmentId) async {
    try {
      _isLoading.value = true;

      final assignment = _myAssignments.firstWhere((a) => a.id == assignmentId);

      await _firestore
          .collection('trainer_assignments')
          .doc(assignmentId)
          .update({
            'trangThai': 'completed',
            'soBuoiHoanThanh': assignment.soBuoiDangKy, // Set to total sessions
            'ngayKetThuc': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Refresh assignments
      await _loadMyAssignments();

      Get.snackbar(
        'Thành công',
        'Đã hoàn thành phân công',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error completing assignment: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể hoàn thành: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Filter assignments by status
  List<TrainerAssignment> getAssignmentsByStatus(String status) {
    if (status == 'all') return _myAssignments;
    return _myAssignments.where((a) => a.trangThai == status).toList();
  }

  /// Get active assignments
  List<TrainerAssignment> get activeAssignments =>
      getAssignmentsByStatus('active');

  /// Get completed assignments
  List<TrainerAssignment> get completedAssignments =>
      getAssignmentsByStatus('completed');

  /// Get recent reviews (last 5)
  List<TrainerReview> get recentReviews => _myReviews.take(5).toList();

  // ========== THỐNG KÊ TỪ TRAINER_RENTALS ==========

  final RxInt _totalStudents = 0.obs;
  final RxInt _totalCompletedSessions = 0.obs;
  final RxInt _totalCompletedRentals = 0.obs;
  final RxInt _totalValidRentals = 0.obs; // Tổng đơn không tính cancelled

  int get totalStudents => _totalStudents.value;
  int get totalCompletedSessions => _totalCompletedSessions.value;
  double get rentalCompletionRate => _totalValidRentals.value > 0
      ? (_totalCompletedRentals.value / _totalValidRentals.value * 100)
      : 0;

  /// Load thống kê từ trainer_rentals
  Future<void> loadRentalStatistics() async {
    try {
      if (_trainerProfile.value == null) return;

      final trainerId = _trainerProfile.value!.id;

      // Lấy tất cả đơn thuê của PT này
      final rentalsSnapshot = await _firestore
          .collection('trainer_rentals')
          .where('trainerId', isEqualTo: trainerId)
          .get();

      // Tính số học viên unique (user đã hoàn thành ít nhất 1 đơn)
      final completedUserIds = <String>{};
      int completedSessions = 0;
      int completedRentals = 0;
      int validRentals = 0; // Đếm tổng đơn (không tính pending và cancelled)

      for (final doc in rentalsSnapshot.docs) {
        final data = doc.data();
        var trangThai = data['trangThai'] as String?;
        final userId = data['userId'] as String?;

        // Check và update expired status
        final endDate = (data['endDate'] as Timestamp?)?.toDate();
        if (endDate != null && DateTime.now().isAfter(endDate)) {
          if (trangThai == 'approved' || trangThai == 'active') {
            // Cập nhật thành expired
            await _firestore.collection('trainer_rentals').doc(doc.id).update({
              'trangThai': 'expired',
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
            trangThai = 'expired'; // Update local variable
          }
        }

        // Đếm tổng đơn hợp lệ (không tính pending và cancelled)
        // Chỉ tính: approved, active, completed, expired
        if (trangThai == 'approved' ||
            trangThai == 'active' ||
            trangThai == 'completed' ||
            trangThai == 'expired') {
          validRentals++;
        }

        // Đếm học viên và buổi tập từ đơn hoàn thành
        if (trangThai == 'completed') {
          if (userId != null) {
            completedUserIds.add(userId);
          }

          // Tính số buổi từ goiTap (ví dụ: "5buoi" -> 5)
          final goiTap = data['goiTap'] as String? ?? '';
          final match = RegExp(r'(\d+)').firstMatch(goiTap);
          if (match != null) {
            final soBuoi = int.tryParse(match.group(1) ?? '0') ?? 0;
            completedSessions += soBuoi;
          }

          completedRentals++;
        }
      }

      _totalStudents.value = completedUserIds.length;
      _totalCompletedSessions.value = completedSessions;
      _totalCompletedRentals.value = completedRentals;
      _totalValidRentals.value = validRentals;

      print(
        '✅ [PTController] Stats loaded: Students=$_totalStudents, Sessions=$completedSessions, Completed=$completedRentals',
      );
    } catch (e) {
      print('Error loading rental statistics: $e');
    }
  }
}
