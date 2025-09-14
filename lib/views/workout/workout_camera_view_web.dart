import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import '../../controllers/workout_assistant_controller.dart';
import '../../models/exercise_model.dart';
import '../../widgets/camera_alternative_dialog.dart';
import '../../widgets/camera_bypass_dialog.dart';

class WorkoutCameraViewWeb extends StatelessWidget {
  const WorkoutCameraViewWeb({super.key});

  // Setup image stream for real-time AI analysis
  void _setupImageStream(WorkoutAssistantController controller) {
    if (controller.cameraController != null &&
        controller.isWorkoutActive.value) {
      try {
        controller.cameraController!.startImageStream((CameraImage image) {
          // Call real-time AI analysis
          controller.performRealTimeAIAnalysis(image);
        });
      } catch (e) {
        debugPrint('❌ Failed to start image stream: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkoutAssistantController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: Obx(() {
              final controller = Get.find<WorkoutAssistantController>();

              if (controller.isCameraInitialized.value &&
                  controller.cameraController != null) {
                // Set up image stream for AI analysis
                _setupImageStream(controller);
                return CameraPreview(controller.cameraController!);
              }

              // Camera not initialized - show error with retry options
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? 'Lỗi Camera'
                            : 'Camera Chưa Sẵn Sàng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : 'Cần camera để phân tích tư thế tập luyện',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await controller.initializeCameraWithService();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử Lại Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CameraBypassDialog(),
                          );
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Bỏ Qua Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                const CameraAlternativeDialog(),
                          );
                        },
                        icon: const Icon(Icons.more_horiz),
                        label: const Text('Tùy Chọn Khác'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Exercise Animation Overlay
          Obx(() {
            final exercise = controller.selectedExercise.value;
            if (exercise != null) {
              return Positioned(
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
                    child: _buildExerciseAnimation(exercise),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Real-time Feedback
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildFeedbackOverlay(controller),
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

          // Camera Permission Button (when camera not available)
          Obx(() {
            final controller = Get.find<WorkoutAssistantController>();
            if (!controller.isCameraInitialized.value) {
              return Positioned(
                bottom: 150,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Auto-suggest demo mode after failed attempts
                    if (controller.cameraRetryCount >= 2) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.recommend, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Khuyến nghị: Sử dụng Chế độ Demo để bắt đầu tập ngay!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Primary: Demo mode button (after failed attempts)
                    if (controller.cameraRetryCount >= 2)
                      ElevatedButton.icon(
                        onPressed: () => _continueWithoutCamera(controller),
                        icon: const Icon(Icons.sports_gymnastics),
                        label: const Text('Tập Ngay (Chế độ Demo)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      // Primary: Try Camera Button (first attempts)
                      ElevatedButton.icon(
                        onPressed: () => _requestCameraPermission(controller),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Thử Bật Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Secondary button
                    if (controller.cameraRetryCount >= 2)
                      OutlinedButton.icon(
                        onPressed: () => _requestCameraPermission(controller),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Thử Camera Lần Nữa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _continueWithoutCamera(controller),
                        icon: const Icon(Icons.sports_gymnastics),
                        label: const Text('Tập Không Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

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
      ),
    );
  }

  Widget _buildExerciseAnimation(Exercise exercise) {
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

  Widget _buildFeedbackOverlay(WorkoutAssistantController controller) {
    return Obx(() {
      final feedback = controller.currentFeedback.value;
      if (feedback == null) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: controller.getFeedbackColor(feedback.type).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              controller.getFeedbackIcon(feedback.type),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feedback.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
            heroTag: "start_stop_button",
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
            heroTag: "reset_button",
            onPressed: () => controller.resetWorkout(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),

          // Exercise Info Button
          FloatingActionButton(
            heroTag: "info_button",
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

  void _requestCameraPermission(WorkoutAssistantController controller) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Đang khởi tạo camera...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Vui lòng đợi trong khi hệ thống kiểm tra camera...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Lỗi',
          'Không tìm thấy camera nào trên thiết bị',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Try multiple camera configurations
      final configs = [
        {'resolution': ResolutionPreset.low, 'name': 'độ phân giải thấp'},
        {
          'resolution': ResolutionPreset.medium,
          'name': 'độ phân giải trung bình',
        },
        {'resolution': ResolutionPreset.high, 'name': 'độ phân giải cao'},
      ];

      bool success = false;
      String lastError = '';

      for (final config in configs) {
        try {
          controller.cameraController?.dispose();
          controller.cameraController = CameraController(
            cameras.first,
            config['resolution'] as ResolutionPreset,
            enableAudio: false,
          );

          await controller.cameraController!.initialize();
          controller.isCameraInitialized.value = true;
          success = true;

          Get.back(); // Close loading dialog
          Get.snackbar(
            'Thành công',
            'Camera đã được kích hoạt với ${config['name']}',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;
        } catch (e) {
          lastError = e.toString();
          print('Failed with ${config['name']}: $e');
          continue;
        }
      }

      if (!success) {
        Get.back(); // Close loading dialog
        _showCameraErrorDialog(lastError);
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      _showCameraErrorDialog(e.toString());
    }
  }

  void _showCameraErrorDialog(String error) {
    final controller = Get.find<WorkoutAssistantController>();
    controller.cameraRetryCount++;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Lỗi Camera'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.cameraRetryCount >=
                WorkoutAssistantController.maxCameraRetries) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã thử ${WorkoutAssistantController.maxCameraRetries} lần. Khuyến nghị dùng Chế độ Demo.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Không thể truy cập camera. Có thể do:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• Camera đang được sử dụng bởi ứng dụng khác'),
            const Text('• Trình duyệt chưa được cấp quyền camera'),
            const Text('• Camera bị lỗi phần cứng'),
            const Text('• Thiết bị không có camera'),
            const SizedBox(height: 16),
            const Text(
              'Giải pháp:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Đóng các ứng dụng đang dùng camera'),
            const Text('2. Cấp quyền camera cho trình duyệt'),
            const Text('3. Thử refresh trang web'),
            const Text('4. Thử trình duyệt khác'),
            const Text('5. Hoặc sử dụng Chế độ Demo'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Chi tiết lỗi: $error',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
          if (controller.cameraRetryCount <
              WorkoutAssistantController.maxCameraRetries)
            ElevatedButton(
              onPressed: () {
                Get.back();
                _requestCameraPermission(
                  Get.find<WorkoutAssistantController>(),
                );
              },
              child: Text(
                'Thử lại (${controller.cameraRetryCount}/${WorkoutAssistantController.maxCameraRetries})',
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _continueWithoutCamera(controller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Chế độ Demo'),
          ),
        ],
      ),
    );
  }

  void _continueWithoutCamera(WorkoutAssistantController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Tập Luyện Không Camera'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, size: 50, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Bạn có thể tiếp tục tập luyện mà không cần camera. '
              'Hệ thống sẽ mô phỏng phản hồi AI dựa trên thời gian tập.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Bạn sẽ thấy:\n'
              '• Timer đếm thời gian\n'
              '• Phản hồi mô phỏng\n'
              '• Hướng dẫn bài tập\n'
              '• Thống kê cơ bản',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              print('🎯 Starting demo mode...');
              Get.back();
              controller.isCameraInitialized.value =
                  true; // Fake camera for demo
              controller.cameraController = null; // Ensure no real camera

              // Start workout automatically in demo mode
              if (controller.selectedExercise.value != null) {
                controller.startWorkout();
              }

              Get.snackbar(
                'Chế độ Demo',
                'Đang tập luyện với phản hồi mô phỏng',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
                icon: const Icon(Icons.sports_gymnastics, color: Colors.white),
              );
              print('✅ Demo mode activated successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Tiếp Tục'),
          ),
        ],
      ),
    );
  }
}
