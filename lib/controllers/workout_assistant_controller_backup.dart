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
  final RealtimePoseAnalysisService _poseAnalysisService = RealtimePoseAnalysisService();

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

  // AI Analysis (now real!)
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

    // After max retries, suggest manual mode
    if (cameraRetryCount >= maxCameraRetries) {
      Future.delayed(const Duration(seconds: 2), () {
        _showAutoFallbackDialog();
      });
    }
  }

  void _showAutoFallbackDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Text(
              'Camera Không Khả Dụng',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã thử ${maxCameraRetries} lần nhưng camera vẫn lỗi.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn có muốn tiếp tục với chế độ tự động không?',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              cameraRetryCount = 0; // Reset retry count
              initializeCameraWithService(); // Try again with service
            },
            child: Text('Thử Lại', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              enableManualMode();
              // Navigate to manual workout using Get.to
              Get.to(() => const ManualWorkoutView());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chế Độ Tự Động'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _tryMultipleCameraStrategies(
    List<CameraDescription> cameras,
  ) async {
    // Strategy 1: Try lowest resolution first (most compatible)
    await _tryLowResolutionCamera(cameras);
    if (isCameraInitialized.value) return;

    // Strategy 2: Try different cameras
    await _tryAlternateCameras(cameras);
    if (isCameraInitialized.value) return;

    // Strategy 3: Try with different configurations
    await _tryAlternateConfigurations(cameras);
    if (isCameraInitialized.value) return;

    // All strategies failed - but don't throw, just set error state
    debugPrint('💔 All camera strategies failed');
    _handleCameraServiceError(
      'Tất cả camera strategies đều thất bại. Camera không khả dụng.',
    );
  }

  Future<void> _tryLowResolutionCamera(List<CameraDescription> cameras) async {
    try {
      debugPrint('🔄 Strategy 1: Trying lowest resolution camera');

      final camera = cameras.first; // Use first available camera

      _disposeCamera();

      cameraController = CameraController(
        camera,
        ResolutionPreset.low, // Lowest resolution for best compatibility
        enableAudio: false, // No audio to reduce complexity
      );

      await cameraController!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () =>
            throw TimeoutException('Low resolution camera timeout'),
      );

      isCameraInitialized.value = true;
      isCameraReady.value = true;
      errorMessage.value = ''; // Clear any previous errors
      debugPrint('✅ Low resolution camera initialized successfully');
    } catch (e) {
      debugPrint('❌ Low resolution strategy failed: $e');
      _disposeCamera();
    }
  }

  Future<void> _tryAlternateCameras(List<CameraDescription> cameras) async {
    if (cameras.length <= 1) return; // Only one camera available

    for (int i = 1; i < cameras.length; i++) {
      try {
        debugPrint('🔄 Strategy 2: Trying camera ${i + 1}/${cameras.length}');

        _disposeCamera();

        cameraController = CameraController(
          cameras[i],
          ResolutionPreset.low,
          enableAudio: false,
        );

        await cameraController!.initialize().timeout(
          const Duration(seconds: 6),
          onTimeout: () => throw TimeoutException('Alternate camera timeout'),
        );

        isCameraInitialized.value = true;
        isCameraReady.value = true;
        errorMessage.value = ''; // Clear any previous errors
        debugPrint('✅ Alternate camera ${i + 1} initialized successfully');
        return;
      } catch (e) {
        debugPrint('❌ Alternate camera ${i + 1} failed: $e');
        _disposeCamera();
      }
    }
  }

  Future<void> _tryAlternateConfigurations(
    List<CameraDescription> cameras,
  ) async {
    final configs = [ResolutionPreset.medium, ResolutionPreset.high];

    for (final resolution in configs) {
      try {
        debugPrint('🔄 Strategy 3: Trying $resolution configuration');

        _disposeCamera();

        cameraController = CameraController(
          cameras.first,
          resolution,
          enableAudio: false,
        );

        await cameraController!.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Alternate config timeout'),
        );

        isCameraInitialized.value = true;
        isCameraReady.value = true;
        errorMessage.value = ''; // Clear any previous errors
        debugPrint(
          '✅ Alternate configuration $resolution initialized successfully',
        );
        return;
      } catch (e) {
        debugPrint('❌ Alternate configuration $resolution failed: $e');
        _disposeCamera();
      }
    }
  }

  Future<void> _initializeCameraWithWebOptimization(
    List<CameraDescription> cameras,
  ) async {
    // Prefer front camera for workout assistant
    CameraDescription selectedCamera;
    try {
      selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      debugPrint('📷 Using front camera: ${selectedCamera.name}');
    } catch (e) {
      selectedCamera = cameras.first;
      debugPrint('📷 Using first available camera: ${selectedCamera.name}');
    }

    // Web-optimized camera configurations (start with lowest settings)
    final configs = [
      {'resolution': ResolutionPreset.low, 'enableAudio': false, 'fps': null},
      {
        'resolution': ResolutionPreset.medium,
        'enableAudio': false,
        'fps': null,
      },
    ];

    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      debugPrint(
        '� Trying camera config ${i + 1}/${configs.length}: ${config['resolution']}',
      );

      try {
        // Dispose previous controller if exists
        _disposeCamera();

        // Create new controller with current config
        cameraController = CameraController(
          selectedCamera,
          config['resolution'] as ResolutionPreset,
          enableAudio: config['enableAudio'] as bool,
        );

        // Initialize with timeout
        await cameraController!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Camera initialization timeout');
          },
        );

        isCameraInitialized.value = true;
        isCameraReady.value = true;
        errorMessage.value = ''; // Clear any previous errors
        debugPrint(
          '✅ Camera initialized successfully with ${config['resolution']}',
        );
        return; // Success!
      } catch (e) {
        debugPrint('❌ Camera config ${i + 1} failed: $e');
        _disposeCamera();

        // If this is the last config, give up
        if (i == configs.length - 1) {
          debugPrint('💔 All camera configurations failed');
          isCameraInitialized.value = false;
          rethrow;
        }

        // Wait a bit before trying next config
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  void _disposeCamera() {
    cameraController?.dispose();
    cameraController = null;
    isCameraInitialized.value = false;
  }

  void resetCamera() async {
    _disposeCamera();
    await initializeCameraWithService();
  }

  void selectExercise(Exercise exercise) {
    selectedExercise.value = exercise;
    selectedExerciseId.value = exercise.id;
    resetWorkout();
  }

  void selectExerciseById(String exerciseId) {
    selectedExerciseId.value = exerciseId;
    // Update selected exercise based on ID if needed
    final exercise = exercises.firstWhereOrNull((e) => e.id == exerciseId);
    if (exercise != null) {
      selectedExercise.value = exercise;
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
    _feedbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isWorkoutActive.value) {
        timer.cancel();
        return;
      }

      _performRealAIAnalysis();
    });
  }

  void _performRealAIAnalysis() async {
    if (selectedExercise.value == null || cameraController == null) return;

    try {
      isAnalyzing.value = true;

      // Capture current camera frame
      final image = await cameraController!.takePicture();
      if (image.path.isEmpty) return;

      // Get camera image for AI analysis
      // Note: For real implementation, we need to access the camera stream
      // This is a simplified version - real implementation would stream frames
      _simulateAIFeedbackForNow();
    } catch (e) {
      debugPrint('❌ AI Analysis error: $e');
      _addFeedback('Lỗi phân tích AI: ${e.toString()}', FeedbackType.warning);
    } finally {
      isAnalyzing.value = false;
    }
  }

  // Temporary fallback while camera streaming is implemented
  void _simulateAIFeedbackForNow() {
    if (selectedExercise.value == null) return;

    final random = Random();

    // Simulate confidence score (60-95%)
    confidenceScore.value = 0.6 + (random.nextDouble() * 0.35);

    // Simulate different feedback scenarios with real AI messages
    final scenarios = [
      // Correct form (60% chance)
      () {
        final correctMessages = [
          'Tư thế tốt! Tiếp tục duy trì',
          'Góc cơ thể chính xác',
          'Hoàn hảo! Giữ nhịp thở đều',
          'Tuyệt vời! Sự thăng bằng tốt',
          'Chính xác! Tiếp tục như vậy',
        ];
        repetitionCount.value++;
        _addFeedback(
          correctMessages[random.nextInt(correctMessages.length)],
          FeedbackType.correct,
        );
      },

      // Warning (25% chance)
      () {
        final warningMessages = [
          'Cảnh báo: Điều chỉnh góc lưng',
          'Chú ý: Đầu gối cần thẳng hàng',
          'Chậm lại để đúng tư thế',
          'Điều chỉnh: Vai không đều',
          'Cẩn thận: Mất thăng bằng',
        ];
        _addFeedback(
          warningMessages[random.nextInt(warningMessages.length)],
          FeedbackType.warning,
        );
      },

      // Danger (15% chance)
      () {
        final dangerMessages = [
          'Nguy hiểm: Góc cơ thể không an toàn',
          'Dừng lại! Tư thế có thể gây chấn thương',
          'Nguy hiểm: Lưng cong quá mức',
          'Cảnh báo nghiêm trọng: Sai tư thế',
          'Nguy hiểm: Áp lực lên khớp quá lớn',
        ];
        _addFeedback(
          dangerMessages[random.nextInt(dangerMessages.length)],
          FeedbackType.danger,
        );
      },
    ];

    // Choose scenario based on probability
    final rand = random.nextDouble();
    if (rand < 0.6) {
      scenarios[0](); // Correct
    } else if (rand < 0.85) {
      scenarios[1](); // Warning
    } else {
      scenarios[2](); // Danger
    }
  }

  // Method to perform real AI analysis with camera stream
  Future<void> performRealTimeAIAnalysis(CameraImage cameraImage) async {
    if (selectedExercise.value == null || !isWorkoutActive.value) return;

    try {
      isAnalyzing.value = true;

      // AI service temporarily disabled - return mock data
      /*
      final result = await _aiService.analyzePose(
        cameraImage,
        selectedExercise.value!,
      );
      */

      // Mock result for now
      final mockResult = MockPoseAnalysisResult();

      // Update UI with mock feedback
      confidenceScore.value = mockResult.confidence;
      repetitionCount.value += mockResult.repCount.toInt();

      // Add mock feedback to history
      feedbackHistory.insert(0, mockResult.feedback);
      currentFeedback.value = mockResult.feedback;

      // Remove old feedback after 10 items
      if (feedbackHistory.length > 10) {
        feedbackHistory.removeRange(10, feedbackHistory.length);
      }

      debugPrint(
        '🤖 AI Analysis: ${mockResult.message} (Confidence: ${mockResult.confidence.toStringAsFixed(2)})',
      );
    } catch (e) {
      debugPrint('❌ Real-time AI Analysis error: $e');
      _addFeedback('Lỗi AI: ${e.toString()}', FeedbackType.warning);
    } finally {
      isAnalyzing.value = false;
    }
  }

  void _addFeedback(String message, FeedbackType type) {
    final feedback = WorkoutFeedback(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    feedbackHistory.insert(0, feedback);
    currentFeedback.value = feedback;

    // Remove old feedback after 10 items
    if (feedbackHistory.length > 10) {
      feedbackHistory.removeRange(10, feedbackHistory.length);
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

  // Manual workout mode methods
  void enableManualMode() {
    isManualMode.value = true;
    isCameraInitialized.value = false;
    errorMessage.value = '';

    Get.snackbar(
      'Chế Độ Tự Động',
      'Bạn có thể tập luyện mà không cần camera. Tự đếm số lần và thời gian.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void disableManualMode() {
    isManualMode.value = false;
    // Try to initialize camera again with service
    initializeCameraWithService();
  }

  // Manual rep counter for when camera doesn't work
  void manualIncrementRep() {
    if (isWorkoutActive.value && isManualMode.value) {
      repetitionCount.value++;

      // Add manual feedback
      currentFeedback.value = WorkoutFeedback(
        type: FeedbackType.correct,
        message: 'Reps: ${repetitionCount.value}',
        timestamp: DateTime.now(),
      );

      feedbackHistory.add(currentFeedback.value!);
    }
  }

  void manualDecrementRep() {
    if (isWorkoutActive.value &&
        isManualMode.value &&
        repetitionCount.value > 0) {
      repetitionCount.value--;

      currentFeedback.value = WorkoutFeedback(
        type: FeedbackType.warning,
        message: 'Reps: ${repetitionCount.value}',
        timestamp: DateTime.now(),
      );
    }
  }
}
