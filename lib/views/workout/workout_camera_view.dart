import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/workout_assistant_controller.dart';
import '../../models/exercise_model.dart';
import '../../widgets/realtime_feedback_widget.dart';

class WorkoutCameraView extends StatelessWidget {
  const WorkoutCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkoutAssistantController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Stack(
          children: [
            // Camera Preview với hỗ trợ đa platform
            Positioned.fill(
              child: kIsWeb
                  ? _buildWebCameraPreview(controller)
                  : _buildMobileCameraPreview(controller),
            ),

            // Exercise Animation Overlay
            if (controller.selectedExercise.value != null)
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildExerciseAnimation(
                      controller.selectedExercise.value!,
                    ),
                  ),
                ),
              ),

            // Real-time Feedback với hỗ trợ web và mobile
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Obx(() {
                final feedback = controller.currentFeedback.value;
                return feedback != null
                    ? PulsatingFeedbackWidget(feedback: feedback)
                    : const SizedBox.shrink();
              }),
            ),

            // Feedback History (chỉ hiển thị khi có lịch sử)
            Positioned(
              top: 120,
              right: 20,
              child: Obx(() {
                return controller.feedbackHistory.isNotEmpty
                    ? FeedbackHistoryWidget(
                        feedbackHistory: controller.feedbackHistory,
                        maxHistoryItems: 3,
                      )
                    : const SizedBox.shrink();
              }),
            ),

            // Workout Stats
            Positioned(
              bottom: 200,
              left: 20,
              right: 20,
              child: _buildWorkoutStats(controller),
            ),

            // Control Buttons
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: _buildControlButtons(controller),
            ),

            // Back Button
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWebCameraPreview(WorkoutAssistantController controller) {
    // Cho web, chúng ta sẽ sử dụng HTML video element hoặc WebRTC
    return Container(
      color: Colors.black,
      child: controller.cameraController != null
          ? CameraPreview(controller.cameraController!)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera không khả dụng trên web\nSử dụng chế độ thủ công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.switchToManualMode(),
                    child: const Text('Chế độ thủ công'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMobileCameraPreview(WorkoutAssistantController controller) {
    // Cho mobile sử dụng camera plugin
    return controller.cameraController != null
        ? CameraPreview(controller.cameraController!)
        : Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
  }

  Widget _buildExerciseAnimation(Exercise exercise) {
    // Since we don't have actual Lottie files, we'll show a placeholder with icon
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getExerciseIcon(exercise.id), size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    // TODO: Replace with actual Lottie animation when files are available
    // return Lottie.asset(
    //   exercise.animationPath,
    //   fit: BoxFit.cover,
    // );
  }

  IconData _getExerciseIcon(String exerciseId) {
    switch (exerciseId) {
      case 'squat':
        return Icons.accessibility_new;
      case 'pushup':
        return Icons.fitness_center;
      case 'plank':
        return Icons.timer;
      case 'lunge':
        return Icons.directions_walk;
      case 'burpee':
        return Icons.sports_gymnastics;
      case 'mountain_climbers':
        return Icons.terrain;
      case 'jumping_jacks':
        return Icons.sports;
      case 'situp':
        return Icons.self_improvement;
      case 'deadlift':
        return Icons.fitness_center;
      case 'shoulder_press':
        return Icons.sports_handball;
      default:
        return Icons.sports_gymnastics;
    }
  }

  Widget _buildWorkoutStats(WorkoutAssistantController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Thời gian',
              controller.getFormattedTimer(),
              Icons.timer,
            ),
            _buildStatItem(
              'Số lần',
              '${controller.repetitionCount.value}',
              Icons.repeat,
            ),
            _buildStatItem(
              'Độ chính xác',
              controller.getConfidencePercentage(),
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildControlButtons(WorkoutAssistantController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Start/Stop Button
          FloatingActionButton.extended(
            onPressed: () {
              if (controller.isWorkoutActive.value) {
                controller.stopWorkout();
              } else {
                controller.startWorkout();
              }
            },
            backgroundColor: controller.isWorkoutActive.value
                ? Colors.red
                : Colors.green,
            icon: Icon(
              controller.isWorkoutActive.value ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              controller.isWorkoutActive.value ? 'Dừng' : 'Bắt đầu',
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Reset Button
          FloatingActionButton(
            onPressed: () => controller.resetWorkout(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),

          // Exercise Info Button
          FloatingActionButton(
            onPressed: () => _showExerciseInfo(controller),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.info, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showExerciseInfo(WorkoutAssistantController controller) {
    final exercise = controller.selectedExercise.value;
    if (exercise == null) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getExerciseIcon(exercise.id),
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Hướng dẫn:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(exercise.instructions),
            const SizedBox(height: 16),
            Text(
              'Lỗi thường gặp:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            ...exercise.commonMistakes.map(
              (mistake) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mistake)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mẹo an toàn:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            ...exercise.safetyTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
