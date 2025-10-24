import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/schedule_management_controller.dart';
import 'package:gympro/models/workout_schedule.dart';
import 'package:gympro/views/admin/create_schedule_view.dart';
import 'package:gympro/views/admin/edit_schedule_view.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class ScheduleManagementView extends StatelessWidget {
  const ScheduleManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleManagementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch trình'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInitialData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatistics(controller),
          _buildFilters(controller),
          Expanded(child: _buildSchedulesList(controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CreateScheduleView()),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatistics(ScheduleManagementController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng lịch trình',
                controller.totalSchedules.value.toString(),
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Đang sử dụng',
                controller.activeSchedules.value.toString(),
                Icons.play_arrow,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFilters(ScheduleManagementController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<ScheduleCategory>(
                value: controller.selectedCategory.value,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
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
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => DropdownButtonFormField<DifficultyLevel>(
                value: controller.selectedDifficulty.value,
                decoration: const InputDecoration(
                  labelText: 'Độ khó',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
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
                onChanged: (value) => controller.filterByDifficulty(value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => controller.clearFilters(),
            tooltip: 'Xóa bộ lọc',
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList(ScheduleManagementController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.schedules.isEmpty) {
        return const CenterLoading(message: 'Đang tải danh sách lịch trình...');
      }

      if (controller.schedules.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch trình nào',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo lịch trình đầu tiên để bắt đầu',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.schedules.length,
        itemBuilder: (context, index) {
          final schedule = controller.schedules[index];
          return _buildScheduleCard(schedule, controller);
        },
      );
    });
  }

  Widget _buildScheduleCard(
    WorkoutSchedule schedule,
    ScheduleManagementController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isActive,
                  onChanged: (value) =>
                      controller.toggleScheduleStatus(schedule.id, value),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(_getCategoryText(schedule.category), Colors.blue),
                _buildChip(
                  _getDifficultyText(schedule.difficulty),
                  _getDifficultyColor(schedule.difficulty),
                ),
                _buildChip('${schedule.durationWeeks} tuần', Colors.orange),
                _buildChip('${schedule.sessionsPerWeek}x/tuần', Colors.purple),
                _buildChip(
                  '${schedule.exerciseIds.length} bài tập',
                  Colors.teal,
                ),
              ],
            ),
            if (schedule.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: schedule.tags
                    .map((tag) => _buildChip(tag, Colors.grey, size: 'small'))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạo: ${_formatDate(schedule.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          Get.to(() => EditScheduleView(schedule: schedule)),
                      tooltip: 'Chỉnh sửa',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _showDeleteDialog(schedule, controller),
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, {String size = 'normal'}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size == 'small' ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: size == 'small' ? 4 : 8,
        vertical: size == 'small' ? 0 : 2,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showDeleteDialog(
    WorkoutSchedule schedule,
    ScheduleManagementController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa lịch trình "${schedule.title}"?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: 'Xóa',
              isLoading: controller.isLoading.value,
              backgroundColor: Colors.red,
              height: 42,
              onPressed: () async {
                await controller.deleteSchedule(schedule.id);
                if (!controller.isLoading.value) {
                  Get.back();
                }
              },
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
