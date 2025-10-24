import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/workout_schedule_controller.dart';
import 'package:gympro/models/workout_schedule.dart';
import 'package:gympro/views/user/user_schedule_detail_view.dart';
import 'package:gympro/views/user/workout_schedule_detail_view.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class UserScheduleSelectionView extends StatelessWidget {
  const UserScheduleSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkoutScheduleController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn lịch trình tập'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInitialData(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (controller.hasActiveSchedule)
              _buildCurrentScheduleBanner(controller),
            _buildFilters(controller),
            Expanded(child: _buildSchedulesList(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScheduleBanner(WorkoutScheduleController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch trình hiện tại',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.currentScheduleTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tuần',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${controller.currentWeek}/${controller.totalWeeks}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Buổi',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${controller.currentSession}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Get.to(() => const UserScheduleDetailView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Chi tiết',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(WorkoutScheduleController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm theo tên lịch trình',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => controller.searchByName(value),
            ),
          ),
          const SizedBox(height: 12),
          // Row 1: Category and Difficulty filters
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<ScheduleCategory>(
                      value: controller.selectedCategory.value,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<ScheduleCategory>(
                          value: null,
                          child: Text('Tất cả danh mục'),
                        ),
                        ...ScheduleCategory.values.map(
                          (category) => DropdownMenuItem<ScheduleCategory>(
                            value: category,
                            child: Text(_getCategoryText(category)),
                          ),
                        ),
                      ],
                      onChanged: (value) => controller.filterByCategory(value),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<DifficultyLevel>(
                      value: controller.selectedDifficulty.value,
                      decoration: const InputDecoration(
                        labelText: 'Độ khó',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<DifficultyLevel>(
                          value: null,
                          child: Text('Tất cả độ khó'),
                        ),
                        ...DifficultyLevel.values.map(
                          (difficulty) => DropdownMenuItem<DifficultyLevel>(
                            value: difficulty,
                            child: Text(_getDifficultyText(difficulty)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          controller.filterByDifficulty(value),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Active status filter
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<bool?>(
                      value: controller.showActiveOnly.value ? true : null,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('Tất cả lịch trình'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Đang tập'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        controller.filterByActiveStatus(value ?? false);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Clear filters button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.clearFilters(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa bộ lọc'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList(WorkoutScheduleController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const CenterLoading(message: 'Đang tải danh sách lịch trình...');
      }

      if (controller.availableSchedules.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy lịch trình phù hợp',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Thử thay đổi bộ lọc để xem thêm lịch trình',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.availableSchedules.length,
        itemBuilder: (context, index) {
          final schedule = controller.availableSchedules[index];
          return _buildScheduleCard(schedule, controller);
        },
      );
    });
  }

  Widget _buildScheduleCard(
    WorkoutSchedule schedule,
    WorkoutScheduleController controller,
  ) {
    return Obx(() {
      final isActive = controller.isScheduleActive(schedule.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: isActive ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isActive
                ? const BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                Get.to(() => WorkoutScheduleDetailView(schedule: schedule)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image với overlay gradient
                Stack(
                  children: [
                    if (schedule.imageUrl != null)
                      Image.network(
                        schedule.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultImage(),
                      )
                    else
                      _buildDefaultImage(),

                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Active schedule indicator (top left)
                    Obx(() {
                      if (controller.isScheduleActive(schedule.id)) {
                        return Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đang tập',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),

                    // Difficulty badge (top right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(schedule.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getDifficultyText(schedule.difficulty),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        schedule.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        schedule.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // Stats trong container đẹp hơn
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.schedule,
                              '${schedule.durationWeeks}',
                              'Tuần',
                              Colors.blue,
                            ),
                            _buildStatItem(
                              Icons.repeat,
                              '${schedule.sessionsPerWeek}x',
                              'Tuần',
                              Colors.green,
                            ),
                            _buildStatItem(
                              Icons.fitness_center,
                              '${schedule.exerciseIds.length}',
                              'Bài tập',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCategoryText(schedule.category),
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Tags
                      if (schedule.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: schedule.tags
                              .take(3)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center, size: 60, color: Colors.white),
      ),
    );
  }

  String _getCategoryText(ScheduleCategory category) {
    switch (category) {
      case ScheduleCategory.weightLoss:
        return 'Giảm cân';
      case ScheduleCategory.muscleGain:
        return 'Tăng cơ';
      case ScheduleCategory.strength:
        return 'Sức mạnh';
      case ScheduleCategory.cardio:
        return 'Tim mạch';
      case ScheduleCategory.flexibility:
        return 'Linh hoạt';
      case ScheduleCategory.general:
        return 'Tổng hợp';
    }
  }

  String _getDifficultyText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Cơ bản';
      case DifficultyLevel.intermediate:
        return 'Trung bình';
      case DifficultyLevel.advanced:
        return 'Nâng cao';
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }
}
