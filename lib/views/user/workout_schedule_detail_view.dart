import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/models/workout_schedule.dart';
import 'package:gympro/models/exercise.dart';
import 'package:gympro/controllers/workout_schedule_controller.dart';
import 'package:gympro/views/user/exercise_detail_view.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class WorkoutScheduleDetailView extends StatelessWidget {
  final WorkoutSchedule schedule;

  const WorkoutScheduleDetailView({Key? key, required this.schedule})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkoutScheduleController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Add to favorites
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _showShareDialog();
                  break;
                case 'report':
                  _showReportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chia sẻ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Báo cáo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScheduleHeader(),
            _buildScheduleStats(),
            _buildScheduleDescription(),
            _buildScheduleTags(),
            _buildExercisesList(controller),
            _buildActionButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (schedule.imageUrl != null && schedule.imageUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                schedule.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryText(schedule.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Thời lượng',
              '${schedule.durationWeeks} tuần',
              Icons.calendar_today,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Buổi/tuần',
              '${schedule.sessionsPerWeek}',
              Icons.repeat,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Bài tập',
              '${schedule.exerciseIds.length}',
              Icons.fitness_center,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            schedule.description.isNotEmpty
                ? schedule.description
                : 'Chưa có mô tả cho lịch trình này.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTags() {
    if (schedule.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: schedule.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(WorkoutScheduleController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách bài tập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${schedule.exerciseIds.length} bài tập',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value) {
              return const CenterLoading(message: 'Đang tải bài tập...');
            }

            final exercises = controller.exercises
                .where((exercise) => schedule.exerciseIds.contains(exercise.id))
                .toList();

            if (exercises.isEmpty) {
              return const Center(
                child: Text(
                  'Đang tải danh sách bài tập...',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _buildExerciseCard(exercise, index + 1);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Get.to(() => ExerciseDetailView(exercise: exercise));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise Number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Exercise Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: exercise.anhMinhHoa.isNotEmpty
                        ? Image.network(
                            exercise.anhMinhHoa.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.fitness_center,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(Icons.fitness_center, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),

                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.tenBaiTap,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (exercise.loaiBaiTap.isNotEmpty)
                        Text(
                          exercise.loaiBaiTap.take(2).join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(
                                exercise.doKho,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.doKho.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getDifficultyColor(exercise.doKho),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nhấp để xem chi tiết',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(WorkoutScheduleController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => _showSelectScheduleDialog(controller),
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            'Bắt đầu lịch trình này',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectScheduleDialog(WorkoutScheduleController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Bắt đầu lịch trình'),
        content: Text(
          'Bạn có muốn bắt đầu lịch trình "${schedule.title}" không?\n\nNếu bạn đang có lịch trình khác, nó sẽ được thay thế.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: 'Bắt đầu',
              isLoading: controller.isLoading.value,
              backgroundColor: const Color(0xFF00BCD4),
              height: 42,
              onPressed: () async {
                await controller.selectSchedule(schedule.id);
                if (!controller.isLoading.value) {
                  Get.back();
                  Get.back(); // Go back to schedule list
                  Get.snackbar(
                    'Thành công',
                    'Đã bắt đầu lịch trình "${schedule.title}"',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Chia sẻ lịch trình'),
        content: const Text(
          'Tính năng chia sẻ sẽ được phát triển trong tương lai.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _showReportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Báo cáo lịch trình'),
        content: const Text(
          'Tính năng báo cáo sẽ được phát triển trong tương lai.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _getDifficultyText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Dễ';
      case DifficultyLevel.intermediate:
        return 'Trung bình';
      case DifficultyLevel.advanced:
        return 'Khó';
    }
  }

  Color _getDifficultyColor(dynamic difficulty) {
    if (difficulty is DifficultyLevel) {
      switch (difficulty) {
        case DifficultyLevel.beginner:
          return Colors.green;
        case DifficultyLevel.intermediate:
          return Colors.orange;
        case DifficultyLevel.advanced:
          return Colors.red;
      }
    }
    return Colors.grey;
  }

  String _getCategoryText(ScheduleCategory category) {
    switch (category) {
      case ScheduleCategory.strength:
        return 'Tăng sức mạnh';
      case ScheduleCategory.cardio:
        return 'Tim mạch';
      case ScheduleCategory.flexibility:
        return 'Linh hoạt';
      case ScheduleCategory.weightLoss:
        return 'Giảm cân';
      case ScheduleCategory.muscleGain:
        return 'Tăng cơ';
      case ScheduleCategory.general:
        return 'Tổng hợp';
    }
  }
}
