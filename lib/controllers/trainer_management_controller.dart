import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trainer.dart';
import '../models/trainer_assignment.dart';
import '../models/trainer_review.dart';
import '../models/trainer_schedule.dart';

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
      final snapshot = await _firestore
          .collection('trainers')
          .orderBy('createdAt', descending: true)
          .get();

      trainers.value = snapshot.docs
          .map((doc) => Trainer.fromFirestore(doc))
          .toList();

      applyFilters();
    } catch (e) {
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

  Future<void> addTrainer(Trainer trainer) async {
    try {
      isLoading.value = true;
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
      await _firestore
          .collection('trainers')
          .doc(trainer.id)
          .update(trainer.toFirestore());
      Get.back();
      Get.snackbar('Thành công', 'Đã cập nhật thông tin PT');
      await loadTrainers();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật: $e');
    } finally {
      isLoading.value = false;
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
