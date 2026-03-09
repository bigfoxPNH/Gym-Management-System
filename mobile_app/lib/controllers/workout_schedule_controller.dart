import 'package:get/get.dart';
import 'package:gympro/models/workout_schedule.dart';
import 'package:gympro/models/user_schedule.dart';
import '../services/workout_schedule_service.dart';
import 'package:gympro/models/exercise.dart';
import 'package:gympro/services/exercise_service.dart';

class WorkoutScheduleController extends GetxController {
  final WorkoutScheduleService _scheduleService = WorkoutScheduleService();
  final ExerciseService _exerciseService = ExerciseService();

  // Observable variables
  var availableSchedules = <WorkoutSchedule>[].obs;
  var userSchedules = <UserSchedule>[].obs;
  var exercises = <Exercise>[].obs;
  var isLoading = false.obs;

  // Current active schedule
  var currentSchedule = Rx<UserSchedule?>(null);
  var currentWorkoutSchedule = Rx<WorkoutSchedule?>(null);

  // Filters
  var selectedCategory = Rx<ScheduleCategory?>(null);
  var selectedDifficulty = Rx<DifficultyLevel?>(null);
  var searchQuery = ''.obs;
  var showActiveOnly = false.obs;

  // User ID - TODO: Get from auth service
  var userId = 'current_user_id'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadAvailableSchedules(),
      loadUserSchedules(),
      loadExercises(),
    ]);
    _updateCurrentSchedule();
  }

  Future<void> loadAvailableSchedules() async {
    try {
      isLoading.value = true;
      final result = await _scheduleService.getPresetSchedules();
      availableSchedules.value = result;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserSchedules() async {
    try {
      final result = await _scheduleService.getUserSchedules(userId.value);
      userSchedules.value = result;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải lịch trình của bạn: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loadExercises() async {
    try {
      final result = await _exerciseService.getAllExercises();
      exercises.value = result;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách bài tập: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _updateCurrentSchedule() {
    final activeSchedules = userSchedules
        .where((schedule) => schedule.status == UserScheduleStatus.active)
        .toList();

    if (activeSchedules.isNotEmpty) {
      currentSchedule.value = activeSchedules.first;
      _loadCurrentWorkoutSchedule();
    } else {
      currentSchedule.value = null;
      currentWorkoutSchedule.value = null;
    }
  }

  Future<void> _loadCurrentWorkoutSchedule() async {
    if (currentSchedule.value == null) return;

    try {
      final workoutSchedule = await _scheduleService.getScheduleById(
        currentSchedule.value!.scheduleId,
      );
      currentWorkoutSchedule.value = workoutSchedule;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải chi tiết lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> selectSchedule(String scheduleId) async {
    try {
      isLoading.value = true;

      // Kiểm tra xem user đã có lịch trình active nào chưa
      final activeSchedules = await _scheduleService.getActiveUserSchedules(
        userId.value,
      );

      if (activeSchedules.isNotEmpty) {
        Get.snackbar(
          'Thông báo',
          'Bạn đã có lịch trình đang thực hiện. Vui lòng hoàn thành hoặc tạm dừng lịch trình hiện tại trước khi chọn lịch trình mới.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 4),
        );
        return;
      }

      await _scheduleService.assignScheduleToUser(userId.value, scheduleId);

      Get.snackbar(
        'Thành công',
        'Đã chọn lịch trình thành công! Hãy bắt đầu tập luyện.',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chọn lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pauseCurrentSchedule() async {
    if (currentSchedule.value == null) return;

    try {
      await _scheduleService.changeUserScheduleStatus(
        currentSchedule.value!.id,
        UserScheduleStatus.paused,
      );

      Get.snackbar(
        'Thành công',
        'Đã tạm dừng lịch trình',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạm dừng lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> resumeSchedule(String userScheduleId) async {
    try {
      await _scheduleService.changeUserScheduleStatus(
        userScheduleId,
        UserScheduleStatus.active,
      );

      Get.snackbar(
        'Thành công',
        'Đã tiếp tục lịch trình',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tiếp tục lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> completeCurrentSchedule() async {
    if (currentSchedule.value == null) return;

    try {
      await _scheduleService.changeUserScheduleStatus(
        currentSchedule.value!.id,
        UserScheduleStatus.completed,
      );

      Get.snackbar(
        'Chúc mừng!',
        'Bạn đã hoàn thành lịch trình tập luyện!',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể hoàn thành lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> cancelSchedule(String userScheduleId) async {
    try {
      await _scheduleService.changeUserScheduleStatus(
        userScheduleId,
        UserScheduleStatus.cancelled,
      );

      Get.snackbar(
        'Thành công',
        'Đã hủy lịch trình',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể hủy lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper method for history view
  Future<void> changeUserScheduleStatus(
    String userScheduleId,
    UserScheduleStatus status,
  ) async {
    try {
      await _scheduleService.changeUserScheduleStatus(userScheduleId, status);

      String message;
      switch (status) {
        case UserScheduleStatus.paused:
          message = 'Đã tạm dừng lịch trình';
          break;
        case UserScheduleStatus.completed:
          message = 'Đã hoàn thành lịch trình';
          break;
        case UserScheduleStatus.cancelled:
          message = 'Đã hủy lịch trình';
          break;
        case UserScheduleStatus.active:
          message = 'Đã tiếp tục lịch trình';
          break;
      }

      Get.snackbar('Thành công', message, snackPosition: SnackPosition.BOTTOM);

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thay đổi trạng thái lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateProgress({
    required int currentWeek,
    required int currentSession,
    required List<String> completedExerciseIds,
    Map<String, dynamic>? progress,
  }) async {
    if (currentSchedule.value == null) return;

    try {
      await _scheduleService.updateUserScheduleProgress(
        currentSchedule.value!.id,
        currentWeek,
        currentSession,
        completedExerciseIds,
      );

      Get.snackbar(
        'Thành công',
        'Đã cập nhật tiến độ',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadUserSchedules();
      _updateCurrentSchedule();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật tiến độ: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void filterByCategory(ScheduleCategory? category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void filterByDifficulty(DifficultyLevel? difficulty) {
    selectedDifficulty.value = difficulty;
    _applyFilters();
  }

  void searchByName(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByActiveStatus(bool showActiveOnly) {
    this.showActiveOnly.value = showActiveOnly;
    _applyFilters();
  }

  void _applyFilters() async {
    try {
      isLoading.value = true;

      List<WorkoutSchedule> result = await _scheduleService
          .getPresetSchedules();

      // Apply category filter
      if (selectedCategory.value != null) {
        result = result
            .where((schedule) => schedule.category == selectedCategory.value)
            .toList();
      }

      // Apply difficulty filter
      if (selectedDifficulty.value != null) {
        result = result
            .where(
              (schedule) => schedule.difficulty == selectedDifficulty.value,
            )
            .toList();
      }

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        result = result
            .where(
              (schedule) => schedule.title.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            )
            .toList();
      }

      // Apply active status filter
      if (showActiveOnly.value) {
        result = result
            .where((schedule) => isScheduleActive(schedule.id))
            .toList();
      }

      availableSchedules.value = result;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể lọc dữ liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    selectedCategory.value = null;
    selectedDifficulty.value = null;
    searchQuery.value = '';
    showActiveOnly.value = false;
    loadAvailableSchedules();
  }

  // Getters
  bool get hasActiveSchedule => currentSchedule.value != null;

  String get currentScheduleTitle {
    return currentWorkoutSchedule.value?.title ?? 'Không có lịch trình';
  }

  String get currentScheduleDescription {
    return currentWorkoutSchedule.value?.description ?? '';
  }

  int get totalWeeks {
    return currentWorkoutSchedule.value?.durationWeeks ?? 0;
  }

  int get sessionsPerWeek {
    return currentWorkoutSchedule.value?.sessionsPerWeek ?? 0;
  }

  int get currentWeek {
    return currentSchedule.value?.currentWeek ?? 1;
  }

  int get currentSession {
    return currentSchedule.value?.currentSession ?? 1;
  }

  double get progressPercentage {
    return currentSchedule.value?.progressPercentage ?? 0.0;
  }

  List<String> get currentExerciseIds {
    return currentWorkoutSchedule.value?.exerciseIds ?? [];
  }

  List<Exercise> get currentExercises {
    if (currentExerciseIds.isEmpty) return [];

    return exercises
        .where((exercise) => currentExerciseIds.contains(exercise.id))
        .toList();
  }

  List<UserSchedule> get activeSchedules {
    return userSchedules
        .where((schedule) => schedule.status == UserScheduleStatus.active)
        .toList();
  }

  List<UserSchedule> get pausedSchedules {
    return userSchedules
        .where((schedule) => schedule.status == UserScheduleStatus.paused)
        .toList();
  }

  // Check if a schedule is currently active
  bool isScheduleActive(String scheduleId) {
    return currentSchedule.value?.scheduleId == scheduleId;
  }

  List<UserSchedule> get completedSchedules {
    return userSchedules
        .where((schedule) => schedule.status == UserScheduleStatus.completed)
        .toList();
  }

  // Helper methods
  Exercise? getExerciseById(String exerciseId) {
    try {
      return exercises.firstWhere((exercise) => exercise.id == exerciseId);
    } catch (e) {
      return null;
    }
  }

  bool isExerciseCompleted(String exerciseId) {
    return currentSchedule.value?.completedExerciseIds.contains(exerciseId) ??
        false;
  }

  String getScheduleStatusText(UserScheduleStatus status) {
    switch (status) {
      case UserScheduleStatus.active:
        return 'Đang thực hiện';
      case UserScheduleStatus.paused:
        return 'Tạm dừng';
      case UserScheduleStatus.completed:
        return 'Hoàn thành';
      case UserScheduleStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
