import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../controllers/auth_controller.dart';

class ExerciseManagementController extends GetxController {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable variables
  final RxList<Exercise> exercises = <Exercise>[].obs;
  final RxList<Exercise> filteredExercises = <Exercise>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxMap<String, int> statistics = <String, int>{}.obs;

  // Form controllers
  final TextEditingController tenBaiTapController = TextEditingController();
  final TextEditingController moTaController = TextEditingController();
  final TextEditingController anhMinhHoaController = TextEditingController();
  final TextEditingController videoMinhHoaController = TextEditingController();
  
  // Form state
  final RxList<String> selectedCochinh = <String>[].obs;
  final RxList<String> selectedCoPhu = <String>[].obs;
  final RxList<String> selectedDungCu = <String>[].obs;
  final RxList<ExerciseGoal> selectedMucTieu = <ExerciseGoal>[].obs;
  // Selected values for multi-select
  final RxList<String> selectedLoaiBaiTap = <String>[].obs;
  final RxList<String> selectedTuThe = <String>[].obs;
  final Rx<ExerciseLevel> selectedDoKho = ExerciseLevel.beginner.obs;

  // Predefined options
  final List<String> muscleGroups = [
    'Ngực', 'Vai', 'Lưng', 'Bụng', 'Tay trước', 'Tay sau', 
    'Chân trước', 'Chân sau', 'Mông', 'Bắp chân', 'Cổ', 'Cẳng tay'
  ];

  final List<String> equipmentOptions = [
    'Bodyweight', 'Tạ đơn', 'Tạ đòn', 'Máy tập', 'Dây kháng lực',
    'Kettlebell', 'TRX', 'Bóng tập', 'Thảm tập', 'Xà đơn', 'Xà kép'
  ];

  @override
  void onInit() {
    super.onInit();
    loadAllExercises();
    loadStatistics();
    
    // Listen to search query changes
    searchQuery.listen((_) => filterExercises());
    selectedFilter.listen((_) => filterExercises());
  }

  @override
  void onClose() {
    tenBaiTapController.dispose();
    moTaController.dispose();
    anhMinhHoaController.dispose();
    videoMinhHoaController.dispose();
    super.onClose();
  }

  // Load all exercises
  Future<void> loadAllExercises() async {
    try {
      isLoading.value = true;
      final exerciseList = await _exerciseService.getAllExercises();
      exercises.value = exerciseList;
      filterExercises();
    } catch (e) {
      print('Error loading exercises: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách bài tập: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final stats = await _exerciseService.getExerciseStats();
      statistics.value = stats;
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  // Filter exercises based on search and filter criteria
  void filterExercises() {
    List<Exercise> filtered = List.from(exercises);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((exercise) =>
          exercise.tenBaiTap.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          exercise.moTa.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          exercise.cochinh.any((muscle) => 
              muscle.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
          exercise.dungCu.any((equipment) => 
              equipment.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
          exercise.loaiBaiTap.any((type) => 
              type.toLowerCase().contains(searchQuery.value.toLowerCase())) ||
          exercise.tuThe.any((position) => 
              position.toLowerCase().contains(searchQuery.value.toLowerCase()))
      ).toList();
    }

    // Apply category filter
    switch (selectedFilter.value) {
      case 'beginner':
        filtered = filtered.where((e) => e.doKho == ExerciseLevel.beginner).toList();
        break;
      case 'intermediate':
        filtered = filtered.where((e) => e.doKho == ExerciseLevel.intermediate).toList();
        break;
      case 'advanced':
        filtered = filtered.where((e) => e.doKho == ExerciseLevel.advanced).toList();
        break;
      case 'push':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Đẩy')).toList();
        break;
      case 'pull':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Kéo')).toList();
        break;
      case 'compound':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Compound')).toList();
        break;
      case 'isolation':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Isolation')).toList();
        break;
      case 'cardio':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Cardio')).toList();
        break;
      case 'strength':
        filtered = filtered.where((e) => e.loaiBaiTap.contains('Sức mạnh')).toList();
        break;
    }

    filteredExercises.value = filtered;
  }

  // Create new exercise
  Future<void> createExercise() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final exercise = Exercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tenBaiTap: tenBaiTapController.text.trim(),
        cochinh: selectedCochinh.toList(),
        coPhu: selectedCoPhu.toList(),
        loaiBaiTap: selectedLoaiBaiTap.toList(), // Now List<String>
        dungCu: selectedDungCu.toList(),
        tuThe: selectedTuThe.toList(), // Now List<String>
        doKho: selectedDoKho.value,
        mucTieu: selectedMucTieu.toList(),
        moTa: moTaController.text.trim(),
        anhMinhHoa: anhMinhHoaController.text.trim().isEmpty 
            ? null : anhMinhHoaController.text.trim(),
        videoMinhHoa: videoMinhHoaController.text.trim().isEmpty 
            ? null : videoMinhHoaController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: _authController.userAccount?.id ?? '',
      );

      await _exerciseService.createExercise(exercise);
      await loadAllExercises();
      await loadStatistics();
      clearForm();

      Get.back(); // Close dialog
      Get.snackbar(
        'Thành công',
        'Đã tạo bài tập: ${exercise.tenBaiTap}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error creating exercise: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tạo bài tập: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing exercise
  Future<void> updateExercise(String exerciseId) async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final originalExercise = exercises.firstWhere((e) => e.id == exerciseId);
      final updatedExercise = Exercise(
        id: exerciseId,
        tenBaiTap: tenBaiTapController.text.trim(),
        cochinh: selectedCochinh.toList(),
        coPhu: selectedCoPhu.toList(),
        loaiBaiTap: selectedLoaiBaiTap.toList(), // Changed from .value
        dungCu: selectedDungCu.toList(),
        tuThe: selectedTuThe.toList(), // Changed from .value
        doKho: selectedDoKho.value,
        mucTieu: selectedMucTieu.toList(),
        moTa: moTaController.text.trim(),
        anhMinhHoa: anhMinhHoaController.text.trim().isEmpty 
            ? null : anhMinhHoaController.text.trim(),
        videoMinhHoa: videoMinhHoaController.text.trim().isEmpty 
            ? null : videoMinhHoaController.text.trim(),
        createdAt: originalExercise.createdAt,
        updatedAt: DateTime.now(),
        createdBy: originalExercise.createdBy,
      );

      await _exerciseService.updateExercise(exerciseId, updatedExercise);
      await loadAllExercises();
      await loadStatistics();
      clearForm();

      Get.back(); // Close dialog
      Get.snackbar(
        'Thành công',
        'Đã cập nhật bài tập: ${updatedExercise.tenBaiTap}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating exercise: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật bài tập: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      isLoading.value = true;

      await _exerciseService.deleteExercise(exerciseId);
      await loadAllExercises();
      await loadStatistics();

      Get.snackbar(
        'Thành công',
        'Đã xóa bài tập',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting exercise: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa bài tập: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load exercise data into form for editing
  void loadExerciseForEdit(Exercise exercise) {
    tenBaiTapController.text = exercise.tenBaiTap;
    moTaController.text = exercise.moTa;
    anhMinhHoaController.text = exercise.anhMinhHoa ?? '';
    videoMinhHoaController.text = exercise.videoMinhHoa ?? '';
    
    selectedCochinh.value = List.from(exercise.cochinh);
    selectedCoPhu.value = List.from(exercise.coPhu);
    selectedDungCu.value = List.from(exercise.dungCu);
    selectedMucTieu.value = List.from(exercise.mucTieu);
    selectedLoaiBaiTap.value = List.from(exercise.loaiBaiTap); // Updated for List<String>
    selectedTuThe.value = List.from(exercise.tuThe); // Updated for List<String>
    selectedDoKho.value = exercise.doKho;
  }

  // Clear form data
  void clearForm() {
    tenBaiTapController.clear();
    moTaController.clear();
    anhMinhHoaController.clear();
    videoMinhHoaController.clear();
    
    selectedCochinh.clear();
    selectedCoPhu.clear();
    selectedDungCu.clear();
    selectedMucTieu.clear();
    selectedLoaiBaiTap.clear(); // Now List<String>
    selectedTuThe.clear(); // Now List<String>
    selectedDoKho.value = ExerciseLevel.beginner;
  }

  // Validate form data
  bool _validateForm() {
    if (tenBaiTapController.text.trim().isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập tên bài tập',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedCochinh.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn ít nhất một nhóm cơ chính',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedDungCu.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn ít nhất một dụng cụ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedMucTieu.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn ít nhất một mục tiêu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (moTaController.text.trim().isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập mô tả bài tập',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate video URL if provided
    if (videoMinhHoaController.text.trim().isNotEmpty &&
        !_exerciseService.isValidVideoUrl(videoMinhHoaController.text.trim())) {
      Get.snackbar(
        'Lỗi',
        'URL video không hợp lệ. Vui lòng sử dụng link YouTube hoặc Vimeo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Get statistics for display
  int get totalExercises => statistics['total'] ?? 0;
  int get beginnerCount => statistics['beginner'] ?? 0;
  int get intermediateCount => statistics['intermediate'] ?? 0;
  int get advancedCount => statistics['advanced'] ?? 0;
}
