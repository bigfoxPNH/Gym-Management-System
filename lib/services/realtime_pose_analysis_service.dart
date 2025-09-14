import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';

enum PoseAnalysisStatus { idle, analyzing, error }

class PoseKeyPoint {
  final String name;
  final double x;
  final double y;
  final double confidence;

  PoseKeyPoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });
}

class PoseAnalysisResult {
  final List<PoseKeyPoint> keyPoints;
  final double overallConfidence;
  final WorkoutFeedback feedback;
  final int repCount;
  final Map<String, double> angles;

  PoseAnalysisResult({
    required this.keyPoints,
    required this.overallConfidence,
    required this.feedback,
    required this.repCount,
    required this.angles,
  });
}

class RealtimePoseAnalysisService {
  static final RealtimePoseAnalysisService _instance =
      RealtimePoseAnalysisService._internal();
  factory RealtimePoseAnalysisService() => _instance;
  RealtimePoseAnalysisService._internal();

  final StreamController<PoseAnalysisResult> _resultController =
      StreamController<PoseAnalysisResult>.broadcast();
  Stream<PoseAnalysisResult> get analysisStream => _resultController.stream;

  final ValueNotifier<PoseAnalysisStatus> _status = ValueNotifier(
    PoseAnalysisStatus.idle,
  );
  ValueNotifier<PoseAnalysisStatus> get status => _status;

  Timer? _analysisTimer;
  Exercise? _currentExercise;
  int _repCount = 0;
  bool _isInDownPosition = false;
  List<PoseAnalysisResult> _recentResults = [];

  bool get isInitialized => true; // Always ready for both platforms

  Future<void> initialize() async {
    try {
      // Initialize any platform-specific components here
      if (kIsWeb) {
        await _initializeWebPoseDetection();
      } else {
        await _initializeMobilePoseDetection();
      }
      _status.value = PoseAnalysisStatus.idle;
      debugPrint(
        '✅ Realtime Pose Analysis Service initialized for ${kIsWeb ? 'Web' : 'Mobile'}',
      );
    } catch (e) {
      _status.value = PoseAnalysisStatus.error;
      debugPrint('❌ Failed to initialize pose analysis: $e');
      rethrow;
    }
  }

  Future<void> _initializeWebPoseDetection() async {
    // For web, we'll use MediaPipe or TensorFlow.js
    // This is a placeholder for the actual implementation
    debugPrint('Initializing web pose detection...');
  }

  Future<void> _initializeMobilePoseDetection() async {
    // For mobile, we'll use ML Kit or TensorFlow Lite
    debugPrint('Initializing mobile pose detection...');
  }

  void startAnalysis(Exercise exercise) {
    _currentExercise = exercise;
    _repCount = 0;
    _isInDownPosition = false;
    _recentResults.clear();
    _status.value = PoseAnalysisStatus.analyzing;

    // Start continuous analysis (simulating real-time processing)
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _performAnalysis();
    });

    debugPrint('🎯 Started pose analysis for: ${exercise.name}');
  }

  void stopAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _status.value = PoseAnalysisStatus.idle;
    debugPrint('⏹️ Stopped pose analysis');
  }

  void _performAnalysis() {
    if (_currentExercise == null) return;

    try {
      // Simulate real pose detection with realistic data
      final result = _generateRealisticPoseData(_currentExercise!);
      _recentResults.add(result);

      // Keep only last 10 results for trend analysis
      if (_recentResults.length > 10) {
        _recentResults.removeAt(0);
      }

      _resultController.add(result);
    } catch (e) {
      debugPrint('❌ Analysis error: $e');
      _status.value = PoseAnalysisStatus.error;
    }
  }

  PoseAnalysisResult _generateRealisticPoseData(Exercise exercise) {
    final random = Random();

    // Generate realistic pose keypoints
    final keyPoints = _generateKeyPoints();

    // Calculate angles based on exercise type
    final angles = _calculateAngles(keyPoints, exercise);

    // Determine feedback based on form analysis
    final feedback = _analyzePoseForm(exercise, angles, keyPoints);

    // Count repetitions
    final repCount = _countRepetitions(exercise, angles);

    // Overall confidence (varies realistically)
    final confidence = 0.7 + (random.nextDouble() * 0.3);

    return PoseAnalysisResult(
      keyPoints: keyPoints,
      overallConfidence: confidence,
      feedback: feedback,
      repCount: repCount,
      angles: angles,
    );
  }

  List<PoseKeyPoint> _generateKeyPoints() {
    final random = Random();
    final keyPointNames = [
      'nose',
      'left_eye',
      'right_eye',
      'left_ear',
      'right_ear',
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle',
    ];

    return keyPointNames.map((name) {
      return PoseKeyPoint(
        name: name,
        x: random.nextDouble(),
        y: random.nextDouble(),
        confidence: 0.8 + (random.nextDouble() * 0.2),
      );
    }).toList();
  }

  Map<String, double> _calculateAngles(
    List<PoseKeyPoint> keyPoints,
    Exercise exercise,
  ) {
    final angles = <String, double>{};
    final random = Random();

    switch (exercise.id) {
      case 'squat':
        // Hip angle: 90-180 degrees
        angles['hip'] = 90 + (random.nextDouble() * 90);
        // Knee angle: 70-180 degrees
        angles['knee'] = 70 + (random.nextDouble() * 110);
        // Back angle: 70-90 degrees (straighter is better)
        angles['back'] = 70 + (random.nextDouble() * 20);
        break;

      case 'pushup':
        // Elbow angle: 70-180 degrees
        angles['elbow'] = 70 + (random.nextDouble() * 110);
        // Body line angle: 170-180 degrees (straighter is better)
        angles['body_line'] = 170 + (random.nextDouble() * 10);
        break;

      case 'shoulder_press':
        // Shoulder angle: 90-180 degrees
        angles['shoulder'] = 90 + (random.nextDouble() * 90);
        // Elbow angle: 90-180 degrees
        angles['elbow'] = 90 + (random.nextDouble() * 90);
        // Back straight: 170-180 degrees
        angles['back'] = 170 + (random.nextDouble() * 10);
        break;

      default:
        angles['general'] = random.nextDouble() * 180;
    }

    return angles;
  }

  WorkoutFeedback _analyzePoseForm(
    Exercise exercise,
    Map<String, double> angles,
    List<PoseKeyPoint> keyPoints,
  ) {
    final random = Random();
    final messages = _getExerciseSpecificMessages(exercise, angles);

    // Select a random message based on current form
    final messageData = messages[random.nextInt(messages.length)];

    return WorkoutFeedback(
      message: messageData['message'],
      type: messageData['type'],
      timestamp: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _getExerciseSpecificMessages(
    Exercise exercise,
    Map<String, double> angles,
  ) {
    switch (exercise.id) {
      case 'squat':
        return [
          {'message': 'Đúng rồi, tiếp tục!', 'type': FeedbackType.correct},
          {'message': 'Tuyệt vời! Form chuẩn!', 'type': FeedbackType.correct},
          {'message': 'Cảnh báo: Lưng hơi cong', 'type': FeedbackType.warning},
          {'message': 'Sai tư thế lưng', 'type': FeedbackType.incorrect},
          {
            'message': 'Nguy hiểm: Đầu gối vượt quá ngón chân',
            'type': FeedbackType.danger,
          },
          {'message': 'Xuống sâu hơn một chút', 'type': FeedbackType.guidance},
          {'message': 'Giữ ngực thẳng', 'type': FeedbackType.guidance},
        ];

      case 'pushup':
        return [
          {'message': 'Hoàn hảo! Tiếp tục!', 'type': FeedbackType.correct},
          {'message': 'Form đẹp, giữ vững!', 'type': FeedbackType.correct},
          {'message': 'Cảnh báo: Hông hơi cao', 'type': FeedbackType.warning},
          {
            'message': 'Sai tư thế: Cơ thể không thẳng',
            'type': FeedbackType.incorrect,
          },
          {'message': 'Nguy hiểm: Tay quá rộng', 'type': FeedbackType.danger},
          {'message': 'Siết chặt cơ bụng', 'type': FeedbackType.guidance},
          {'message': 'Xuống sâu hơn', 'type': FeedbackType.guidance},
        ];

      case 'shoulder_press':
        return [
          {'message': 'Tốt lắm! Vai thẳng!', 'type': FeedbackType.correct},
          {'message': 'Excellent form!', 'type': FeedbackType.correct},
          {'message': 'Cảnh báo: Lưng hơi võng', 'type': FeedbackType.warning},
          {'message': 'Sai tư thế vai', 'type': FeedbackType.incorrect},
          {'message': 'Nguy hiểm: Tay quá sâu', 'type': FeedbackType.danger},
          {'message': 'Giữ lưng thẳng', 'type': FeedbackType.guidance},
          {'message': 'Đẩy thẳng lên trên', 'type': FeedbackType.guidance},
        ];

      default:
        return [
          {'message': 'Đúng rồi, tiếp tục!', 'type': FeedbackType.correct},
          {'message': 'Tốt lắm!', 'type': FeedbackType.correct},
          {'message': 'Cần điều chỉnh tư thế', 'type': FeedbackType.warning},
          {'message': 'Form chưa chuẩn', 'type': FeedbackType.incorrect},
          {'message': 'Cẩn thận với tư thế', 'type': FeedbackType.danger},
        ];
    }
  }

  int _countRepetitions(Exercise exercise, Map<String, double> angles) {
    switch (exercise.id) {
      case 'squat':
        final hipAngle = angles['hip'] ?? 180;
        if (hipAngle < 100 && !_isInDownPosition) {
          _isInDownPosition = true;
        } else if (hipAngle > 160 && _isInDownPosition) {
          _isInDownPosition = false;
          _repCount++;
        }
        break;

      case 'pushup':
        final elbowAngle = angles['elbow'] ?? 180;
        if (elbowAngle < 100 && !_isInDownPosition) {
          _isInDownPosition = true;
        } else if (elbowAngle > 160 && _isInDownPosition) {
          _isInDownPosition = false;
          _repCount++;
        }
        break;

      case 'shoulder_press':
        final shoulderAngle = angles['shoulder'] ?? 90;
        if (shoulderAngle < 120 && !_isInDownPosition) {
          _isInDownPosition = true;
        } else if (shoulderAngle > 170 && _isInDownPosition) {
          _isInDownPosition = false;
          _repCount++;
        }
        break;
    }

    return _repCount;
  }

  // Get current statistics
  double get averageConfidence {
    if (_recentResults.isEmpty) return 0.0;
    return _recentResults
            .map((r) => r.overallConfidence)
            .reduce((a, b) => a + b) /
        _recentResults.length;
  }

  int get currentRepCount => _repCount;

  WorkoutFeedback? get latestFeedback {
    return _recentResults.isNotEmpty ? _recentResults.last.feedback : null;
  }

  void dispose() {
    _analysisTimer?.cancel();
    _resultController.close();
    _status.dispose();
  }
}
