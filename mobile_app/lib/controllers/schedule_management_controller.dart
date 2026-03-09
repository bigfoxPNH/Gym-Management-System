import 'package:get/get.dart';
import 'package:gympro/models/workout_schedule.dart';
import '../services/workout_schedule_service.dart';
import 'package:gympro/models/exercise.dart';
import 'package:gympro/services/exercise_service.dart';

class ScheduleManagementController extends GetxController {
  final WorkoutScheduleService _scheduleService = WorkoutScheduleService();
  final ExerciseService _exerciseService = ExerciseService();

  // Observable variables
  var schedules = <WorkoutSchedule>[].obs;
  var exercises = <Exercise>[].obs;
  var isLoading = false.obs;
  var selectedCategory = Rx<ScheduleCategory?>(null);
  var selectedDifficulty = Rx<DifficultyLevel?>(null);

  // Form variables
  var titleController = ''.obs;
  var descriptionController = ''.obs;
  var selectedType = ScheduleType.preset.obs;
  var selectedCategoryForm = ScheduleCategory.general.obs;
  var selectedDifficultyForm = DifficultyLevel.beginner.obs;
  var selectedExerciseIds = <String>[].obs;
  var durationWeeks = 4.obs;
  var sessionsPerWeek = 3.obs;
  var tags = <String>[].obs;
  var imageUrl = ''.obs;

  // Statistics
  var totalSchedules = 0.obs;
  var activeSchedules = 0.obs;
  var categoryStats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([loadSchedules(), loadExercises(), loadStatistics()]);
  }

  Future<void> loadSchedules() async {
    try {
      isLoading.value = true;
      final result = await _scheduleService.getAllSchedules();
      schedules.value = result;
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

  Future<void> loadStatistics() async {
    try {
      final total = await _scheduleService.getTotalSchedulesCount();
      final active = await _scheduleService.getActiveUserSchedulesCount();
      final stats = await _scheduleService.getScheduleStatsByCategory();

      totalSchedules.value = total;
      activeSchedules.value = active;
      categoryStats.value = stats;
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải thống kê: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> createSchedule() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final schedule = WorkoutSchedule(
        id: '',
        title: titleController.value,
        description: descriptionController.value,
        type: selectedType.value,
        difficulty: selectedDifficultyForm.value,
        category: selectedCategoryForm.value,
        exerciseIds: selectedExerciseIds.toList(),
        durationWeeks: durationWeeks.value,
        sessionsPerWeek: sessionsPerWeek.value,
        createdBy: 'admin', // TODO: Get from actual auth service
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        imageUrl: imageUrl.value.isEmpty ? null : imageUrl.value,
        tags: tags.toList(),
      );

      await _scheduleService.createSchedule(schedule);

      Get.snackbar(
        'Thành công',
        'Tạo lịch trình thành công!',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
      await loadSchedules();
      await loadStatistics();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSchedule(WorkoutSchedule schedule) async {
    try {
      isLoading.value = true;

      final updatedSchedule = schedule.copyWith(updatedAt: DateTime.now());

      await _scheduleService.updateSchedule(updatedSchedule);

      Get.snackbar(
        'Thành công',
        'Cập nhật lịch trình thành công!',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadSchedules();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      isLoading.value = true;
      await _scheduleService.deleteSchedule(id);

      Get.snackbar(
        'Thành công',
        'Xóa lịch trình thành công!',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadSchedules();
      await loadStatistics();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa lịch trình: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleScheduleStatus(String id, bool isActive) async {
    try {
      await _scheduleService.toggleScheduleStatus(id, isActive);

      Get.snackbar(
        'Thành công',
        isActive
            ? 'Kích hoạt lịch trình thành công!'
            : 'Tạm dừng lịch trình thành công!',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadSchedules();
      await loadStatistics();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thay đổi trạng thái lịch trình: $e',
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

  void _applyFilters() async {
    try {
      isLoading.value = true;

      List<WorkoutSchedule> result;

      if (selectedCategory.value != null && selectedDifficulty.value != null) {
        // Nếu có cả hai filter, cần load tất cả rồi filter local
        result = await _scheduleService.getAllSchedules();
        result = result
            .where(
              (schedule) =>
                  schedule.category == selectedCategory.value &&
                  schedule.difficulty == selectedDifficulty.value,
            )
            .toList();
      } else if (selectedCategory.value != null) {
        result = await _scheduleService.getSchedulesByCategory(
          selectedCategory.value!,
        );
      } else if (selectedDifficulty.value != null) {
        result = await _scheduleService.getSchedulesByDifficulty(
          selectedDifficulty.value!,
        );
      } else {
        result = await _scheduleService.getAllSchedules();
      }

      schedules.value = result;
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
    loadSchedules();
  }

  // Form methods
  void toggleExerciseSelection(String exerciseId) {
    if (selectedExerciseIds.contains(exerciseId)) {
      selectedExerciseIds.remove(exerciseId);
    } else {
      selectedExerciseIds.add(exerciseId);
    }
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  void clearForm() {
    titleController.value = '';
    descriptionController.value = '';
    selectedType.value = ScheduleType.preset;
    selectedCategoryForm.value = ScheduleCategory.general;
    selectedDifficultyForm.value = DifficultyLevel.beginner;
    selectedExerciseIds.clear();
    durationWeeks.value = 4;
    sessionsPerWeek.value = 3;
    tags.clear();
    imageUrl.value = '';
  }

  void loadScheduleForEdit(WorkoutSchedule schedule) {
    titleController.value = schedule.title;
    descriptionController.value = schedule.description;
    selectedType.value = schedule.type;
    selectedCategoryForm.value = schedule.category;
    selectedDifficultyForm.value = schedule.difficulty;
    selectedExerciseIds.value = schedule.exerciseIds;
    durationWeeks.value = schedule.durationWeeks;
    sessionsPerWeek.value = schedule.sessionsPerWeek;
    tags.value = schedule.tags;
    imageUrl.value = schedule.imageUrl ?? '';
  }

  bool _validateForm() {
    if (titleController.value.trim().isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập tiêu đề lịch trình',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (descriptionController.value.trim().isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập mô tả lịch trình',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (selectedExerciseIds.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn ít nhất một bài tập',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (durationWeeks.value < 1 || durationWeeks.value > 52) {
      Get.snackbar(
        'Lỗi',
        'Thời gian lịch trình phải từ 1-52 tuần',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (sessionsPerWeek.value < 1 || sessionsPerWeek.value > 7) {
      Get.snackbar(
        'Lỗi',
        'Số buổi tập mỗi tuần phải từ 1-7',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Getters
  List<WorkoutSchedule> get filteredSchedules {
    return schedules.where((schedule) => schedule.isActive).toList();
  }

  List<Exercise> get availableExercises {
    return exercises
        .toList(); // TODO: Filter by isActive when Exercise model is updated
  }

  bool isExerciseSelected(String exerciseId) {
    return selectedExerciseIds.contains(exerciseId);
  }

  String get selectedExercisesText {
    if (selectedExerciseIds.isEmpty) return 'Chưa chọn bài tập nào';
    return '${selectedExerciseIds.length} bài tập đã chọn';
  }
}
