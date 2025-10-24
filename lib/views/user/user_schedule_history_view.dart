import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/workout_schedule_controller.dart';
import 'package:gympro/models/user_schedule.dart';
import 'package:gympro/models/workout_schedule.dart';
import '../../services/workout_schedule_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class UserScheduleHistoryView extends StatelessWidget {
  const UserScheduleHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkoutScheduleController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử lịch trình'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadUserSchedules(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const CenterLoading(message: 'Đang tải lịch sử lịch trình...');
        }

        if (controller.userSchedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử lịch trình',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Các lịch trình bạn đã thực hiện sẽ hiển thị ở đây',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Material(
                color: Colors.purple[50],
                child: TabBar(
                  labelColor: Colors.purple[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.purple[700],
                  tabs: const [
                    Tab(text: 'Đang thực hiện', icon: Icon(Icons.play_arrow)),
                    Tab(text: 'Tạm dừng', icon: Icon(Icons.pause)),
                    Tab(text: 'Hoàn thành', icon: Icon(Icons.check_circle)),
                    Tab(text: 'Đã hủy', icon: Icon(Icons.cancel)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildScheduleList(controller.activeSchedules, controller),
                    _buildScheduleList(controller.pausedSchedules, controller),
                    _buildScheduleList(
                      controller.completedSchedules,
                      controller,
                    ),
                    _buildScheduleList(
                      controller.userSchedules
                          .where(
                            (s) => s.status == UserScheduleStatus.cancelled,
                          )
                          .toList(),
                      controller,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildScheduleList(
    List<UserSchedule> schedules,
    WorkoutScheduleController controller,
  ) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Không có lịch trình nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final userSchedule = schedules[index];
        return _buildScheduleCard(userSchedule, controller);
      },
    );
  }

  Widget _buildScheduleCard(
    UserSchedule userSchedule,
    WorkoutScheduleController controller,
  ) {
    final scheduleService = WorkoutScheduleService();

    return FutureBuilder<WorkoutSchedule?>(
      future: scheduleService.getScheduleById(userSchedule.scheduleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
              child: const CenterLoading(message: 'Đang tải...'),
            ),
          );
        }

        final schedule = snapshot.data!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(userSchedule.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Info
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tuần ${userSchedule.currentWeek}/${schedule.durationWeeks}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${userSchedule.completedExerciseIds.length}/${schedule.exerciseIds.length} bài tập',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                LinearProgressIndicator(
                  value: userSchedule.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(userSchedule.status),
                  ),
                ),
                const SizedBox(height: 8),

                // Dates and Actions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bắt đầu: ${_formatDate(userSchedule.startDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (userSchedule.completedDate != null)
                            Text(
                              'Hoàn thành: ${_formatDate(userSchedule.completedDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildActionButtons(userSchedule, controller),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(UserScheduleStatus status) {
    Color color = _getStatusColor(status);
    String text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    UserSchedule userSchedule,
    WorkoutScheduleController controller,
  ) {
    switch (userSchedule.status) {
      case UserScheduleStatus.active:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, size: 20),
              onPressed: () => _showPauseDialog(userSchedule, controller),
              tooltip: 'Tạm dừng',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, size: 20),
              onPressed: () => _showCompleteDialog(userSchedule, controller),
              tooltip: 'Hoàn thành',
            ),
          ],
        );
      case UserScheduleStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: () => controller.resumeSchedule(userSchedule.id),
              tooltip: 'Tiếp tục',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, size: 20),
              onPressed: () => _showCancelDialog(userSchedule, controller),
              tooltip: 'Hủy',
            ),
          ],
        );
      case UserScheduleStatus.completed:
      case UserScheduleStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(UserScheduleStatus status) {
    switch (status) {
      case UserScheduleStatus.active:
        return Colors.green;
      case UserScheduleStatus.paused:
        return Colors.orange;
      case UserScheduleStatus.completed:
        return Colors.blue;
      case UserScheduleStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(UserScheduleStatus status) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPauseDialog(
    UserSchedule userSchedule,
    WorkoutScheduleController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tạm dừng lịch trình'),
        content: const Text('Bạn có chắc chắn muốn tạm dừng lịch trình này?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingTextButton(
              text: 'Tạm dừng',
              textColor: Colors.orange,
              loadingColor: Colors.orange,
              isLoading: controller.isLoading.value,
              onPressed: () async {
                await controller.changeUserScheduleStatus(
                  userSchedule.id,
                  UserScheduleStatus.paused,
                );
                if (!controller.isLoading.value) Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
    UserSchedule userSchedule,
    WorkoutScheduleController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hoàn thành lịch trình'),
        content: const Text(
          'Chúc mừng! Bạn có muốn đánh dấu lịch trình này là đã hoàn thành?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingTextButton(
              text: 'Hoàn thành',
              textColor: Colors.green,
              loadingColor: Colors.green,
              isLoading: controller.isLoading.value,
              onPressed: () async {
                await controller.changeUserScheduleStatus(
                  userSchedule.id,
                  UserScheduleStatus.completed,
                );
                if (!controller.isLoading.value) Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    UserSchedule userSchedule,
    WorkoutScheduleController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hủy lịch trình'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch trình này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Không')),
          Obx(
            () => LoadingTextButton(
              text: 'Hủy lịch trình',
              textColor: Colors.red,
              loadingColor: Colors.red,
              isLoading: controller.isLoading.value,
              onPressed: () async {
                await controller.cancelSchedule(userSchedule.id);
                if (!controller.isLoading.value) Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}
