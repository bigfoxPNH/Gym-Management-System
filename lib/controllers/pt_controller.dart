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
  final RxBool _isLoading = false.obs;

  // Getters
  Trainer? get trainerProfile => _trainerProfile.value;
  List<TrainerAssignment> get myAssignments => _myAssignments;
  List<TrainerReview> get myReviews => _myReviews;
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

      // Load assignments and reviews
      await _loadMyAssignments();
      await _loadMyReviews();
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
}
