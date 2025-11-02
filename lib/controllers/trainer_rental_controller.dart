import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/trainer.dart';
import '../models/trainer_rental.dart';

class TrainerRentalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable lists
  final RxList<Trainer> availableTrainers = <Trainer>[].obs;
  final RxList<TrainerRental> myRentals = <TrainerRental>[].obs;
  final RxList<TrainerRental> allRentals = <TrainerRental>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingTrainers = false.obs;
  final RxBool isSubmitting = false.obs;

  // Selected trainer
  final Rx<Trainer?> selectedTrainer = Rx<Trainer?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAvailableTrainers();
    loadMyRentals();
  }

  /// Load danh sách PT có thể thuê (active và available)
  Future<void> loadAvailableTrainers() async {
    try {
      isLoadingTrainers.value = true;

      final snapshot = await _firestore
          .collection('trainers')
          .where('trangThai', isEqualTo: 'active')
          .get();

      final list = snapshot.docs
          .map((doc) => Trainer.fromFirestore(doc))
          .toList();

      // Sort theo đánh giá trung bình
      list.sort((a, b) => b.danhGiaTrungBinh.compareTo(a.danhGiaTrungBinh));
      availableTrainers.value = list;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách PT: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingTrainers.value = false;
    }
  }

  /// Load lịch sử thuê PT của user hiện tại
  Future<void> loadMyRentals() async {
    try {
      isLoading.value = true;
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('trainer_rentals')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => TrainerRental.fromFirestore(doc))
          .toList();

      // Sort theo ngày tạo mới nhất
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      myRentals.value = list;

      // Tự động cập nhật trạng thái active cho các đơn đã duyệt trong thời gian thuê
      for (final rental in list) {
        if (rental.trangThai == 'approved') {
          await checkAndUpdateActiveStatus(rental.id);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải lịch sử thuê PT: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load tất cả rental (cho admin/PT)
  Future<void> loadAllRentals([String? trainerId]) async {
    try {
      isLoading.value = true;

      Query<Map<String, dynamic>> query = _firestore.collection(
        'trainer_rentals',
      );

      if (trainerId != null) {
        query = query.where('trainerId', isEqualTo: trainerId);
      }

      final snapshot = await query.get();
      final list = snapshot.docs
          .map((doc) => TrainerRental.fromFirestore(doc))
          .toList();

      // Sort theo ngày tạo
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allRentals.value = list;

      // Tự động cập nhật trạng thái active cho các đơn đã duyệt trong thời gian thuê
      for (final rental in list) {
        if (rental.trangThai == 'approved') {
          await checkAndUpdateActiveStatus(rental.id);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách thuê PT: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Tạo yêu cầu thuê PT mới
  Future<bool> createRental({
    required Trainer trainer,
    required DateTime startDate,
    required DateTime endDate,
    required int soGio,
    required String goiTap,
    String? ghiChu,
    List<TrainerSession>? sessions,
  }) async {
    try {
      isSubmitting.value = true;

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Lỗi', 'Bạn cần đăng nhập để thuê PT');
        return false;
      }

      // Lấy thông tin user
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['fullName'] ?? 'User';

      // Tính tiền dựa trên gói và số giờ
      double giaMoiGio = _getGiaMoiGio(goiTap, trainer);
      double tongTien = giaMoiGio * soGio;

      final rental = TrainerRental(
        id: '',
        userId: userId,
        userName: userName,
        trainerId: trainer.id,
        trainerName: trainer.hoTen,
        startDate: startDate,
        endDate: endDate,
        soGio: soGio,
        tongTien: tongTien,
        goiTap: goiTap,
        trangThai: 'pending',
        ghiChu: ghiChu,
        sessions: sessions ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('trainer_rentals').add(rental.toMap());

      Get.snackbar(
        'Thành công',
        'Yêu cầu thuê PT đã được gửi. PT sẽ phản hồi sớm nhất!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
      );

      await loadMyRentals();
      return true;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo yêu cầu thuê PT: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Cập nhật trạng thái rental
  Future<bool> updateRentalStatus(
    String rentalId,
    String newStatus, {
    String? phanHoi,
  }) async {
    try {
      isSubmitting.value = true;

      final updateData = {
        'trangThai': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (phanHoi != null) {
        updateData['phanHoi'] = phanHoi;
      }

      await _firestore
          .collection('trainer_rentals')
          .doc(rentalId)
          .update(updateData);

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );

      await loadMyRentals();
      await loadAllRentals();
      return true;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Hủy yêu cầu thuê PT
  Future<bool> cancelRental(String rentalId) async {
    return await updateRentalStatus(rentalId, 'cancelled');
  }

  /// Tính giá mỗi giờ dựa trên gói tập
  double _getGiaMoiGio(String goiTap, Trainer trainer) {
    switch (goiTap) {
      case 'personal':
        return 300000; // 300k/giờ cho cá nhân
      case 'group':
        return 150000; // 150k/giờ cho nhóm (chia cho nhiều người)
      case 'online':
        return 200000; // 200k/giờ cho online
      default:
        return 300000;
    }
  }

  /// Lấy rental theo ID
  Future<TrainerRental?> getRentalById(String rentalId) async {
    try {
      final doc = await _firestore
          .collection('trainer_rentals')
          .doc(rentalId)
          .get();
      if (doc.exists) {
        return TrainerRental.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải thông tin: $e');
      return null;
    }
  }

  /// Thêm session vào rental
  Future<bool> addSession(String rentalId, TrainerSession session) async {
    try {
      final rental = await getRentalById(rentalId);
      if (rental == null) return false;

      final sessions = [...rental.sessions, session];

      await _firestore.collection('trainer_rentals').doc(rentalId).update({
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await loadMyRentals();
      await loadAllRentals();
      return true;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm buổi tập: $e');
      return false;
    }
  }

  /// Thống kê
  int get totalRentals => myRentals.length;
  int get activeRentals =>
      myRentals.where((r) => r.trangThai == 'active').length;
  int get completedRentals =>
      myRentals.where((r) => r.trangThai == 'completed').length;
  int get pendingRentals =>
      myRentals.where((r) => r.trangThai == 'pending').length;

  /// Kiểm tra và cập nhật trạng thái rental thành "active" nếu đang trong thời gian thuê
  Future<void> checkAndUpdateActiveStatus(String rentalId) async {
    try {
      final rental = await getRentalById(rentalId);
      if (rental == null) return;

      final now = DateTime.now();

      // Nếu đơn đã được duyệt và đang trong khoảng thời gian thuê
      if (rental.trangThai == 'approved' &&
          now.isAfter(rental.startDate) &&
          now.isBefore(rental.endDate)) {
        await _firestore.collection('trainer_rentals').doc(rentalId).update({
          'trangThai': 'active',
          'updatedAt': Timestamp.fromDate(now),
        });

        await loadMyRentals();
        await loadAllRentals();
      }
    } catch (e) {
      print('Error checking active status: $e');
    }
  }

  /// Kiểm tra xem rental có đang active không
  bool isRentalActive(TrainerRental rental) {
    final now = DateTime.now();
    return (rental.trangThai == 'approved' || rental.trangThai == 'active') &&
        now.isAfter(rental.startDate) &&
        now.isBefore(rental.endDate);
  }

  /// Hoàn thành đơn thuê PT (chuyển từ active sang completed)
  Future<bool> completeRental(String rentalId) async {
    try {
      isSubmitting.value = true;

      await _firestore.collection('trainer_rentals').doc(rentalId).update({
        'trangThai': 'completed',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Get.snackbar(
        'Thành công',
        'Đã hoàn thành đơn thuê PT',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );

      await loadMyRentals();
      await loadAllRentals();
      return true;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể hoàn thành đơn: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Kiểm tra user có thể đánh giá PT này không
  Future<bool> canReviewTrainer(String trainerId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // 1. Kiểm tra có đơn thuê completed với PT này không
      final completedRentals = myRentals.where(
        (r) => r.trainerId == trainerId && r.trangThai == 'completed',
      );

      if (completedRentals.isEmpty) return false;

      // 2. Kiểm tra đã đánh giá PT này chưa
      final reviewSnapshot = await _firestore
          .collection('trainer_reviews')
          .where('userId', isEqualTo: userId)
          .where('trainerId', isEqualTo: trainerId)
          .limit(1)
          .get();

      if (reviewSnapshot.docs.isNotEmpty) return false;

      // 3. Kiểm tra thời hạn (30 ngày sau completed)
      final latestRental = completedRentals.reduce(
        (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
      );
      final daysSinceCompleted = DateTime.now()
          .difference(latestRental.updatedAt)
          .inDays;

      if (daysSinceCompleted > 30) return false;

      return true;
    } catch (e) {
      print('Error checking canReviewTrainer: $e');
      return false;
    }
  }

  /// Kiểm tra đã đánh giá PT này chưa
  Future<bool> hasReviewedTrainer(String trainerId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final reviewSnapshot = await _firestore
          .collection('trainer_reviews')
          .where('userId', isEqualTo: userId)
          .where('trainerId', isEqualTo: trainerId)
          .limit(1)
          .get();

      return reviewSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking hasReviewedTrainer: $e');
      return false;
    }
  }

  /// Submit đánh giá PT
  Future<bool> submitReview({
    required String trainerId,
    required String trainerName,
    required double rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    try {
      isSubmitting.value = true;

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Get.snackbar('Lỗi', 'Bạn cần đăng nhập');
        return false;
      }

      // Lấy thông tin user
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName = userData?['fullName'] ?? 'User';
      final userAvatar = userData?['avatarUrl'];

      // Kiểm tra có thể đánh giá không
      final canReview = await canReviewTrainer(trainerId);
      if (!canReview) {
        Get.snackbar(
          'Không thể đánh giá',
          'Bạn chỉ có thể đánh giá PT sau khi hoàn thành thuê và trong vòng 30 ngày',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Tạo review mới
      final reviewData = {
        'trainerId': trainerId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'tags': tags,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('trainer_reviews').add(reviewData);

      // Cập nhật rating trung bình của trainer
      await _updateTrainerRating(trainerId);

      return true;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể gửi đánh giá: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Cập nhật rating trung bình của trainer
  Future<void> _updateTrainerRating(String trainerId) async {
    try {
      // Lấy tất cả reviews của trainer
      final reviewsSnapshot = await _firestore
          .collection('trainer_reviews')
          .where('trainerId', isEqualTo: trainerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      // Tính rating trung bình
      final totalRating = reviewsSnapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + ((doc.data()['rating'] ?? 0) as num).toDouble(),
      );
      final avgRating = totalRating / reviewsSnapshot.docs.length;

      // Cập nhật trainer
      await _firestore.collection('trainers').doc(trainerId).update({
        'danhGiaTrungBinh': avgRating,
        'soLuotDanhGia': reviewsSnapshot.docs.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Reload trainers nếu cần
      await loadAvailableTrainers();
    } catch (e) {
      print('Error updating trainer rating: $e');
    }
  }
}
