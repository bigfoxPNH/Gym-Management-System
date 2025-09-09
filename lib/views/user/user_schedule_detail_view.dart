import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/workout_schedule_controller.dart';
import 'package:gympro/views/user/exercise_detail_view.dart';

class UserScheduleDetailView extends StatelessWidget {
  const UserScheduleDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkoutScheduleController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch trình của tôi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pause':
                  _showPauseDialog(controller);
                  break;
                case 'complete':
                  _showCompleteDialog(controller);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pause',
                child: Row(
                  children: [
                    Icon(Icons.pause, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Tạm dừng'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Hoàn thành'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.hasActiveSchedule) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Bạn chưa có lịch trình nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy chọn một lịch trình để bắt đầu',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Chọn lịch trình'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(controller),
              const SizedBox(height: 20),
              _buildScheduleInfo(controller),
              const SizedBox(height: 20),
              _buildCurrentExercises(controller),
              const SizedBox(height: 20),
              _buildActionButtons(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProgressCard(WorkoutScheduleController controller) {
    return Obx(
      () => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.currentScheduleTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${controller.progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.progressPercentage / 100,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Tuần hiện tại',
                      '${controller.currentWeek}/${controller.totalWeeks}',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Buổi hiện tại',
                      '${controller.currentSession}',
                      Icons.play_arrow,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Buổi/tuần',
                      '${controller.sessionsPerWeek}',
                      Icons.repeat,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(WorkoutScheduleController controller) {
    return Obx(
      () => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Thông tin lịch trình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                controller.currentScheduleDescription,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (controller.currentWorkoutSchedule.value?.tags.isNotEmpty ==
                  true) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: controller.currentWorkoutSchedule.value!.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentExercises(WorkoutScheduleController controller) {
    return Obx(
      () => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.list, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Bài tập trong lịch trình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.currentExercises.length} bài tập',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (controller.currentExercises.isEmpty)
                const Center(
                  child: Text(
                    'Đang tải danh sách bài tập...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              else
                ...controller.currentExercises
                    .map((exercise) => _buildExerciseItem(exercise, controller))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(exercise, WorkoutScheduleController controller) {
    final isCompleted = controller.isExerciseCompleted(exercise.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Get.to(() => ExerciseDetailView(exercise: exercise));
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? Colors.green[300]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                // Exercise Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 50,
                    height: 50,
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
                const SizedBox(width: 12),

                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.tenBaiTap,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green[700]
                              : Colors.black87,
                        ),
                      ),
                      if (exercise.loaiBaiTap.isNotEmpty)
                        Text(
                          exercise.loaiBaiTap.take(2).join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        'Nhấp để xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Completion Status
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(WorkoutScheduleController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPauseDialog(controller),
            icon: const Icon(Icons.pause),
            label: const Text('Tạm dừng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteDialog(controller),
            icon: const Icon(Icons.check_circle),
            label: const Text('Hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showPauseDialog(WorkoutScheduleController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tạm dừng lịch trình'),
        content: const Text(
          'Bạn có chắc chắn muốn tạm dừng lịch trình hiện tại? Bạn có thể tiếp tục lại sau.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.pauseCurrentSchedule();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Tạm dừng'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(WorkoutScheduleController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hoàn thành lịch trình'),
        content: const Text(
          'Chúc mừng! Bạn có muốn đánh dấu lịch trình này là đã hoàn thành?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.completeCurrentSchedule();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }
}
