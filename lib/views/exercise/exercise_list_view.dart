import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/exercise_controller.dart';
import '../../models/exercise.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';
import 'simple_exercise_detail_view.dart';

class ExerciseListView extends StatefulWidget {
  const ExerciseListView({Key? key}) : super(key: key);

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView> {
  @override
  void initState() {
    super.initState();
    // Check if there's an exerciseId in arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args is Map && args['exerciseId'] != null) {
        final controller = Get.find<ExerciseController>();
        // Wait for exercises to load
        Future.delayed(const Duration(milliseconds: 500), () {
          final exercise = controller.exercises.firstWhereOrNull(
            (e) => e.id == args['exerciseId'],
          );
          if (exercise != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SimpleExerciseDetailView(exercise: exercise),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExerciseController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kho Bài Tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài tập...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.searchController.clear(),
                        )
                      : const SizedBox(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Filter Tags
          Container(
            height: 50,
            color: Colors.white,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    controller.selectedCategory.value,
                    controller.categories,
                    controller.updateCategoryFilter,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    controller.selectedLevel.value,
                    controller.levels,
                    controller.updateLevelFilter,
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  if (controller.selectedCategory.value != 'Tất cả' ||
                      controller.selectedLevel.value != 'Tất cả' ||
                      controller.searchQuery.isNotEmpty)
                    ActionChip(
                      label: const Text('Xóa bộ lọc'),
                      onPressed: controller.clearFilters,
                      backgroundColor: Colors.red[50],
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Exercise Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => Row(
                children: [
                  Text(
                    '${controller.filteredExercises.length} bài tập',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (controller.isLoading.value)
                    const InlineLoading(message: ''),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Exercise List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.exercises.isEmpty) {
                return const CenterLoading(
                  message: 'Đang tải danh sách bài tập...',
                );
              }

              if (controller.filteredExercises.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.loadAllExercises,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = controller.filteredExercises[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExerciseCard(
                        exercise: exercise,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SimpleExerciseDetailView(exercise: exercise),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String selectedValue,
    List<String> options,
    Function(String) onSelected,
    Color color,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      child: Chip(
        label: Text(selectedValue),
        backgroundColor: selectedValue == 'Tất cả'
            ? Colors.grey[200]
            : color.withOpacity(0.1),
        side: BorderSide(
          color: selectedValue == 'Tất cả' ? Colors.grey[400]! : color,
        ),
        avatar: Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: selectedValue == 'Tất cả' ? Colors.grey[600] : color,
        ),
      ),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy bài tập nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử thay đổi từ khóa tìm kiếm\nhoặc bộ lọc',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    ExerciseController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ Lọc',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    controller.clearFilters();
                    Get.back();
                  },
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Filter
            const Text(
              'Loại bài tập',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.categories.map((category) {
                  final isSelected =
                      controller.selectedCategory.value == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      controller.updateCategoryFilter(category);
                      Get.back();
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade600,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Level Filter
            const Text(
              'Mức độ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.levels.map((level) {
                  final isSelected = controller.selectedLevel.value == level;
                  return FilterChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (_) {
                      controller.updateLevelFilter(level);
                      Get.back();
                    },
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange.shade600,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPage(Exercise exercise) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.tenBaiTap),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main image
            if (exercise.anhMinhHoa != null && exercise.anhMinhHoa!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    exercise.anhMinhHoa.isNotEmpty
                        ? exercise.anhMinhHoa.first
                        : '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.fitness_center,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Title
            Text(
              exercise.tenBaiTap,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Description
            if (exercise.moTa.isNotEmpty) ...[
              const Text(
                'Mô tả:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.moTa,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
            ],

            // Exercise Types
            if (exercise.loaiBaiTap.isNotEmpty) ...[
              const Text(
                'Loại bài tập:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.loaiBaiTap
                    .map(
                      (type) => Chip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Video button
            if (exercise.videoMinhHoa != null &&
                exercise.videoMinhHoa!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Simple message for now
                    print('Video: ${exercise.videoMinhHoa}');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Xem video hướng dẫn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
