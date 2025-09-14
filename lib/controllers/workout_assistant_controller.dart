import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/exercise_model.dart';
import '../services/realtime_pose_analysis_service.dart';
import '../services/camera_service.dart';
import '../views/workout/manual_workout_view.dart';

// Mock class for pose analysis results (temporarily replacing AI service)
class MockPoseAnalysisResult {
  final double confidence = 0.85;
  final double repCount = 1.0;
  final WorkoutFeedback feedback = WorkoutFeedback(
    message: "Good form! Keep it up!",
    type: FeedbackType.correct,
    timestamp: DateTime.now(),
  );
  final String message = "Exercise performed correctly";
}

class WorkoutAssistantController extends GetxController {
  // Camera related
  CameraController? cameraController;
  final RxBool isCameraInitialized = false.obs;
  final RxBool isCameraReady = false.obs;
  final RxBool isRecording = false.obs;
  List<CameraDescription> cameras = [];
  int cameraRetryCount = 0;
  static const int maxCameraRetries = 3;

  // Camera service for platform-specific handling
  late final CameraServiceInterface _cameraService;

  // Realtime Pose Analysis Service
  final RealtimePoseAnalysisService _poseAnalysisService =
      RealtimePoseAnalysisService();

  // Exercise related
  final Rx<Exercise?> selectedExercise = Rx<Exercise?>(null);
  final RxList<Exercise> exercises = <Exercise>[].obs;
  final RxString selectedExerciseId = ''.obs;

  // Workout session
  final RxBool isWorkoutActive = false.obs;
  final RxInt workoutTimer = 0.obs;
  Timer? _workoutTimer;

  // Real-time feedback
  final RxList<WorkoutFeedback> feedbackHistory = <WorkoutFeedback>[].obs;
  final Rx<WorkoutFeedback?> currentFeedback = Rx<WorkoutFeedback?>(null);
  Timer? _feedbackTimer;

  // AI Analysis
  final RxBool isAnalyzing = false.obs;
  final RxDouble confidenceScore = 0.0.obs;
  final RxInt repetitionCount = 0.obs;

  // Manual workout mode (when camera not available)
  final RxBool isManualMode = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadExercises();
    // Initialize camera service
    _cameraService = CameraServiceFactory.create();
    // Initialize pose analysis service
    _initializePoseAnalysisService();
    // Only initialize camera on mobile, not on web
    if (!kIsWeb) {
      initializeCameraWithService();
    }
  }

  @override
  void onClose() {
    _disposeCamera();
    _poseAnalysisService.dispose();
    _workoutTimer?.cancel();
    _feedbackTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializePoseAnalysisService() async {
    try {
      await _poseAnalysisService.initialize();
      // Lắng nghe kết quả phân tích realtime
      _poseAnalysisService.analysisStream.listen((result) {
        _handlePoseAnalysisResult(result);
      });
      debugPrint('✅ Realtime Pose Analysis Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize pose analysis service: $e');
    }
  }

  void _handlePoseAnalysisResult(PoseAnalysisResult result) {
    // Cập nhật feedback hiện tại
    currentFeedback.value = result.feedback;

    // Thêm vào lịch sử
    feedbackHistory.add(result.feedback);
    if (feedbackHistory.length > 20) {
      feedbackHistory.removeAt(0); // Giữ tối đa 20 feedback
    }

    // Cập nhật thống kê
    confidenceScore.value = result.overallConfidence;
    repetitionCount.value = result.repCount;

    // Auto-clear feedback sau 3 giây
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      currentFeedback.value = null;
    });
  }

  void _loadExercises() {
    exercises.value = ExerciseData.getAllExercises();
  }

  Future<void> initializeCameraWithService() async {
    debugPrint('🎥 Starting camera initialization with service...');
    errorMessage.value = ''; // Clear previous errors

    try {
      final success = await _cameraService.initializeCamera();

      if (success) {
        cameraController = _cameraService.controller;
        isCameraInitialized.value = true;
        isCameraReady.value = true;
        errorMessage.value = '';
        cameraRetryCount = 0; // Reset retry count on success
        debugPrint('✅ Camera service initialized successfully');
      } else {
        _handleCameraServiceError(_cameraService.errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Camera service failed: $e');
      _handleCameraServiceError('Lỗi camera service: ${e.toString()}');
    }
  }

  void _handleCameraServiceError(String message) {
    isCameraInitialized.value = false;
    isCameraReady.value = false;
    errorMessage.value = message;

    // Increment retry count for auto-fallback logic
    cameraRetryCount++;

    // Show error snackbar with retry option
    Get.snackbar(
      'Lỗi Camera',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          initializeCameraWithService(); // Retry with service
        },
        child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
      ),
    );

    // Auto-fallback to manual mode after max retries
    if (cameraRetryCount >= maxCameraRetries) {
      debugPrint('🔄 Max retries reached, offering manual mode');
      _offerManualMode();
    }
  }

  void _offerManualMode() {
    Get.snackbar(
      'Chế độ thủ công',
      'Camera không khả dụng. Bạn có muốn sử dụng chế độ thủ công?',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 10),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          switchToManualMode();
        },
        child: const Text(
          'Chế độ thủ công',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _disposeCamera() {
    try {
      cameraController?.dispose();
      cameraController = null;
      isCameraInitialized.value = false;
      isCameraReady.value = false;
      debugPrint('📷 Camera disposed');
    } catch (e) {
      debugPrint('❌ Error disposing camera: $e');
    }
  }

  // Exercise selection
  void selectExercise(String exerciseId) {
    selectedExerciseId.value = exerciseId;
    selectedExercise.value = exercises.firstWhere((ex) => ex.id == exerciseId);
    debugPrint('✅ Exercise selected: ${selectedExercise.value!.name}');

    if (isWorkoutActive.value) {
      stopWorkout();
    }
    resetWorkout();
  }

  void startWorkout() {
    if (selectedExercise.value == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn bài tập trước');
      return;
    }

    isWorkoutActive.value = true;
    workoutTimer.value = 0;
    repetitionCount.value = 0;
    feedbackHistory.clear();

    // Start workout timer
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      workoutTimer.value++;

      // Auto stop after exercise duration
      if (workoutTimer.value >= selectedExercise.value!.duration) {
        stopWorkout();
      }
    });

    // Bắt đầu phân tích pose realtime (nếu không phải chế độ thủ công)
    if (!isManualMode.value) {
      isAnalyzing.value = true;
      _poseAnalysisService.startAnalysis(selectedExercise.value!);
    } else {
      // Start AI feedback simulation for manual mode
      _startAIFeedback();
    }

    _addFeedback(
      'Bắt đầu tập luyện! Hãy làm theo hướng dẫn.',
      FeedbackType.correct,
    );

    debugPrint('🏃‍♂️ Workout started: ${selectedExercise.value!.name}');
  }

  void stopWorkout() {
    isWorkoutActive.value = false;
    isAnalyzing.value = false;
    _workoutTimer?.cancel();
    _feedbackTimer?.cancel();

    // Dừng phân tích pose
    if (!isManualMode.value) {
      _poseAnalysisService.stopAnalysis();
    }

    _addFeedback(
      'Kết thúc buổi tập! Bạn đã hoàn thành ${repetitionCount.value} lần lặp.',
      FeedbackType.correct,
    );

    debugPrint('⏹️ Workout stopped');
  }

  void resetWorkout() {
    stopWorkout();
    workoutTimer.value = 0;
    repetitionCount.value = 0;
    confidenceScore.value = 0.0;
    feedbackHistory.clear();
    currentFeedback.value = null;
    debugPrint('🔄 Workout reset');
  }

  void switchToManualMode() {
    isManualMode.value = true;
    Get.to(() => const ManualWorkoutView());
  }

  void _startAIFeedback() {
    _feedbackTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      timer,
    ) {
      if (!isWorkoutActive.value) {
        timer.cancel();
        return;
      }
      _simulateAIFeedbackForNow();
    });
  }

  void _simulateAIFeedbackForNow() {
    final random = Random();
    final scenarios = [
      // Correct form (60% chance)
      () {
        final correctMessages = [
          'Tuyệt vời! Form chuẩn!',
          'Đúng rồi, tiếp tục!',
          'Excellent! Giữ vững!',
          'Perfect form!',
          'Tốt lắm! Duy trì tư thế!',
        ];
        _addFeedback(
          correctMessages[random.nextInt(correctMessages.length)],
          FeedbackType.correct,
        );

        // Sometimes add rep count
        if (random.nextDouble() < 0.3) {
          repetitionCount.value++;
        }
      },

      // Warning/Guidance (25% chance)
      () {
        final guidanceMessages = [
          'Cảnh báo: Lưng hơi cong',
          'Điều chỉnh tư thế vai',
          'Giữ ngực thẳng',
          'Xuống sâu hơn một chút',
          'Siết chặt cơ bụng',
          'Đều đặn hơn',
        ];
        _addFeedback(
          guidanceMessages[random.nextInt(guidanceMessages.length)],
          random.nextBool() ? FeedbackType.warning : FeedbackType.guidance,
        );
      },

      // Danger/Incorrect (15% chance)
      () {
        final dangerMessages = [
          'Nguy hiểm: Góc cơ thể không an toàn',
          'Sai tư thế lưng',
          'Nguy hiểm: Tay quá sâu',
          'Sai tư thế: Cơ thể không thẳng',
          'Nguy hiểm: Áp lực lên khớp quá lớn',
        ];
        _addFeedback(
          dangerMessages[random.nextInt(dangerMessages.length)],
          random.nextBool() ? FeedbackType.danger : FeedbackType.incorrect,
        );
      },
    ];

    // Choose scenario based on probability
    final rand = random.nextDouble();
    if (rand < 0.6) {
      scenarios[0](); // Correct
    } else if (rand < 0.85) {
      scenarios[1](); // Warning/Guidance
    } else {
      scenarios[2](); // Danger/Incorrect
    }

    // Update confidence score
    confidenceScore.value = 0.7 + (random.nextDouble() * 0.3);
  }

  void _addFeedback(String message, FeedbackType type) {
    final feedback = WorkoutFeedback(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    currentFeedback.value = feedback;
    feedbackHistory.add(feedback);

    // Keep only last 20 feedback items
    if (feedbackHistory.length > 20) {
      feedbackHistory.removeAt(0);
    }

    // Clear current feedback after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (currentFeedback.value == feedback) {
        currentFeedback.value = null;
      }
    });
  }

  Color getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return const Color(0xFF4CAF50); // Xanh lá
      case FeedbackType.warning:
        return const Color(0xFFFF9800); // Vàng
      case FeedbackType.danger:
        return const Color(0xFFF44336); // Đỏ
      case FeedbackType.incorrect:
        return const Color(0xFFE91E63); // Hồng đỏ
      case FeedbackType.guidance:
        return const Color(0xFF2196F3); // Xanh dương
    }
  }

  IconData getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return Icons.check_circle;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.danger:
        return Icons.dangerous;
      case FeedbackType.incorrect:
        return Icons.cancel;
      case FeedbackType.guidance:
        return Icons.lightbulb;
    }
  }

  String getFormattedTimer() {
    final minutes = workoutTimer.value ~/ 60;
    final seconds = workoutTimer.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getConfidencePercentage() {
    return '${(confidenceScore.value * 100).toInt()}%';
  }

  // Exercise selection method (missing)
  void selectExerciseById(String exerciseId) {
    selectedExerciseId.value = exerciseId;
    selectedExercise.value = exercises.firstWhere((ex) => ex.id == exerciseId);
    debugPrint('✅ Exercise selected: ${selectedExercise.value!.name}');

    if (isWorkoutActive.value) {
      stopWorkout();
    }
    resetWorkout();
  }

  // Manual mode methods (missing)
  void enableManualMode() {
    isManualMode.value = true;
    debugPrint('🔧 Manual mode enabled');
  }

  void manualIncrementRep() {
    repetitionCount.value++;
    _addFeedback(
      'Rep ${repetitionCount.value} hoàn thành!',
      FeedbackType.correct,
    );
    debugPrint('➕ Manual rep increment: ${repetitionCount.value}');
  }

  void manualDecrementRep() {
    if (repetitionCount.value > 0) {
      repetitionCount.value--;
      _addFeedback(
        'Rep đã giảm xuống ${repetitionCount.value}',
        FeedbackType.warning,
      );
      debugPrint('➖ Manual rep decrement: ${repetitionCount.value}');
    }
  }

  // AI Analysis method for web camera (missing)
  Future<void> performRealTimeAIAnalysis(dynamic cameraImage) async {
    if (selectedExercise.value == null || !isWorkoutActive.value) return;

    try {
      isAnalyzing.value = true;

      // For web, we'll simulate analysis since we can't directly process camera frames
      if (kIsWeb) {
        await _simulateWebAIAnalysis();
      } else {
        // For mobile, use the real pose analysis service
        // This would typically process the actual camera frame
        _simulateAIFeedbackForNow();
      }
    } catch (e) {
      debugPrint('❌ AI Analysis error: $e');
      _addFeedback('Lỗi phân tích AI: ${e.toString()}', FeedbackType.warning);
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> _simulateWebAIAnalysis() async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Generate realistic feedback based on current exercise
    final random = Random();
    final exercise = selectedExercise.value!;

    // Simulate pose analysis with realistic results
    final confidence = 0.7 + (random.nextDouble() * 0.3);
    confidenceScore.value = confidence;

    // Occasionally increment rep count
    if (random.nextDouble() < 0.1) {
      // 10% chance per analysis
      repetitionCount.value++;
    }

    // Generate contextual feedback
    _generateContextualFeedback(exercise, confidence);
  }

  void _generateContextualFeedback(Exercise exercise, double confidence) {
    final random = Random();
    List<Map<String, dynamic>> messages = [];

    switch (exercise.id) {
      case 'squat':
        messages = [
          {'message': 'Tuyệt vời! Squat chuẩn!', 'type': FeedbackType.correct},
          {'message': 'Giữ lưng thẳng', 'type': FeedbackType.guidance},
          {
            'message': 'Cảnh báo: Đầu gối hơi vào trong',
            'type': FeedbackType.warning,
          },
          {
            'message': 'Nguy hiểm: Đầu gối vượt quá ngón chân',
            'type': FeedbackType.danger,
          },
        ];
        break;
      case 'pushup':
        messages = [
          {'message': 'Perfect push-up form!', 'type': FeedbackType.correct},
          {'message': 'Giữ cơ thể thẳng', 'type': FeedbackType.guidance},
          {'message': 'Cảnh báo: Hông hơi cao', 'type': FeedbackType.warning},
          {'message': 'Nguy hiểm: Tay quá rộng', 'type': FeedbackType.danger},
        ];
        break;
      case 'shoulder_press':
        messages = [
          {
            'message': 'Excellent shoulder press!',
            'type': FeedbackType.correct,
          },
          {'message': 'Đẩy thẳng lên trên', 'type': FeedbackType.guidance},
          {'message': 'Cảnh báo: Lưng hơi võng', 'type': FeedbackType.warning},
          {'message': 'Nguy hiểm: Tay quá sâu', 'type': FeedbackType.danger},
        ];
        break;
      default:
        messages = [
          {'message': 'Tốt lắm! Tiếp tục!', 'type': FeedbackType.correct},
          {'message': 'Điều chỉnh tư thế nhẹ', 'type': FeedbackType.guidance},
          {'message': 'Cần chú ý form', 'type': FeedbackType.warning},
        ];
    }

    // Choose message based on confidence, with some randomness
    Map<String, dynamic> selectedMessage;

    if (confidence > 0.85) {
      final correctMessages = messages
          .where((m) => m['type'] == FeedbackType.correct)
          .toList();
      selectedMessage = correctMessages.isNotEmpty
          ? correctMessages[random.nextInt(correctMessages.length)]
          : messages.first;
    } else if (confidence > 0.7) {
      final guidanceMessages = messages
          .where((m) => m['type'] == FeedbackType.guidance)
          .toList();
      selectedMessage = guidanceMessages.isNotEmpty
          ? guidanceMessages[random.nextInt(guidanceMessages.length)]
          : messages.first;
    } else if (confidence > 0.5) {
      final warningMessages = messages
          .where((m) => m['type'] == FeedbackType.warning)
          .toList();
      selectedMessage = warningMessages.isNotEmpty
          ? warningMessages[random.nextInt(warningMessages.length)]
          : messages.first;
    } else {
      final dangerMessages = messages
          .where((m) => m['type'] == FeedbackType.danger)
          .toList();
      selectedMessage = dangerMessages.isNotEmpty
          ? dangerMessages[random.nextInt(dangerMessages.length)]
          : messages.first;
    }

    _addFeedback(selectedMessage['message'], selectedMessage['type']);
  }
}
