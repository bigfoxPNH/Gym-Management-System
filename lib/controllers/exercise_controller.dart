import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

class ExerciseController extends GetxController {
  final ExerciseService _exerciseService = ExerciseService();

  // Observable variables
  final RxList<Exercise> exercises = <Exercise>[].obs;
  final RxList<Exercise> filteredExercises = <Exercise>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'Tất cả'.obs;
  final RxString selectedLevel = 'Tất cả'.obs;

  // Search controller
  final TextEditingController searchController = TextEditingController();

  // Categories for filter
  final List<String> categories = [
    'Tất cả',
    'Compound',
    'Isolation',
    'Đẩy',
    'Kéo',
    'Chân',
    'Cardio',
    'Linh hoạt',
    'Sức mạnh',
    'Sức bền',
    'Cân bằng',
    'Plyometric',
    'HIIT',
  ];

  final List<String> levels = ['Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'];

  @override
  void onInit() {
    super.onInit();
    loadAllExercises();

    // Listen to search changes
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterExercises();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load all exercises
  Future<void> loadAllExercises() async {
    try {
      isLoading.value = true;
      final exercisesList = await _exerciseService.getAllExercises();
      exercises.value = exercisesList;
      filterExercises();
    } catch (e) {
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

  // Filter exercises based on search and categories
  void filterExercises() {
    List<Exercise> filtered = exercises.toList();

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return exercise.tenBaiTap.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            exercise.moTa.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            exercise.cochinh.any(
              (muscle) => muscle.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            ) ||
            exercise.coPhu.any(
              (muscle) => muscle.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            ) ||
            exercise.dungCu.any(
              (equipment) => equipment.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            );
      }).toList();
    }

    // Filter by category
    if (selectedCategory.value != 'Tất cả') {
      filtered = filtered.where((exercise) {
        return exercise.loaiBaiTap.contains(selectedCategory.value);
      }).toList();
    }

    // Filter by level
    if (selectedLevel.value != 'Tất cả') {
      filtered = filtered.where((exercise) {
        return exercise.doKho.label == selectedLevel.value;
      }).toList();
    }

    filteredExercises.value = filtered;
  }

  // Update category filter
  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
    filterExercises();
  }

  // Update level filter
  void updateLevelFilter(String level) {
    selectedLevel.value = level;
    filterExercises();
  }

  // Clear all filters
  void clearFilters() {
    selectedCategory.value = 'Tất cả';
    selectedLevel.value = 'Tất cả';
    searchController.clear();
    searchQuery.value = '';
    filterExercises();
  }

  // Get exercise by ID
  Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }
}
