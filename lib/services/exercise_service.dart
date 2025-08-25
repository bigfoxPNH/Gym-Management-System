import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get exercisesCollection =>
      _firestore.collection('exercises');

  // Create new exercise
  Future<void> createExercise(Exercise exercise) async {
    try {
      await exercisesCollection.doc(exercise.id).set(exercise.toMap());
    } catch (e) {
      throw Exception('Không thể tạo bài tập: $e');
    }
  }

  // Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    try {
      final snapshot = await exercisesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách bài tập: $e');
    }
  }

  // Get exercise by ID
  Future<Exercise?> getExercise(String exerciseId) async {
    try {
      final doc = await exercisesCollection.doc(exerciseId).get();
      if (doc.exists) {
        return Exercise.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải bài tập: $e');
    }
  }

  // Update exercise
  Future<void> updateExercise(String exerciseId, Exercise exercise) async {
    try {
      final updateData = exercise.copyWith(updatedAt: DateTime.now()).toMap();

      await exercisesCollection.doc(exerciseId).update(updateData);
    } catch (e) {
      throw Exception('Không thể cập nhật bài tập: $e');
    }
  }

  // Delete exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      await exercisesCollection.doc(exerciseId).delete();
    } catch (e) {
      throw Exception('Không thể xóa bài tập: $e');
    }
  }

  // Search exercises
  Future<List<Exercise>> searchExercises(String query) async {
    try {
      final snapshot = await exercisesCollection
          .where('tenBaiTap', isGreaterThanOrEqualTo: query)
          .where('tenBaiTap', isLessThan: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tìm kiếm bài tập: $e');
    }
  }

  // Get exercises by muscle group
  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    try {
      final snapshot = await exercisesCollection
          .where('cochinh', arrayContains: muscleGroup)
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tải bài tập theo nhóm cơ: $e');
    }
  }

  // Get exercises by level
  Future<List<Exercise>> getExercisesByLevel(ExerciseLevel level) async {
    try {
      final snapshot = await exercisesCollection
          .where('doKho', isEqualTo: level.name)
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tải bài tập theo độ khó: $e');
    }
  }

  // Get exercises by type
  Future<List<Exercise>> getExercisesByType(String exerciseType) async {
    try {
      final snapshot = await exercisesCollection
          .where('loaiBaiTap', arrayContains: exerciseType)
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tải bài tập theo loại: $e');
    }
  }

  // Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    try {
      final snapshot = await exercisesCollection
          .where('dungCu', arrayContains: equipment)
          .get();

      return snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Không thể tải bài tập theo dụng cụ: $e');
    }
  }

  // Stream for real-time exercise updates
  Stream<List<Exercise>> exercisesStream() {
    return exercisesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Exercise.fromDocument(doc)).toList(),
        );
  }

  // Get exercise statistics
  Future<Map<String, int>> getExerciseStats() async {
    try {
      final snapshot = await exercisesCollection.get();
      final exercises = snapshot.docs
          .map((doc) => Exercise.fromDocument(doc))
          .toList();

      final stats = <String, int>{
        'total': exercises.length,
        'beginner': exercises
            .where((e) => e.doKho == ExerciseLevel.beginner)
            .length,
        'intermediate': exercises
            .where((e) => e.doKho == ExerciseLevel.intermediate)
            .length,
        'advanced': exercises
            .where((e) => e.doKho == ExerciseLevel.advanced)
            .length,
        'push': exercises
            .where((e) => e.loaiBaiTap.contains('Đẩy'))
            .length,
        'pull': exercises
            .where((e) => e.loaiBaiTap.contains('Kéo'))
            .length,
        'compound': exercises
            .where((e) => e.loaiBaiTap.contains('Compound'))
            .length,
        'isolation': exercises
            .where((e) => e.loaiBaiTap.contains('Isolation'))
            .length,
        'cardio': exercises
            .where((e) => e.loaiBaiTap.contains('Cardio'))
            .length,
        'flexibility': exercises
            .where((e) => e.loaiBaiTap.contains('Linh hoạt'))
            .length,
      };

      return stats;
    } catch (e) {
      throw Exception('Không thể tải thống kê bài tập: $e');
    }
  }

  // Validate video URL (YouTube, Vimeo, etc.)
  bool isValidVideoUrl(String url) {
    if (url.isEmpty) return true; // Optional field

    // YouTube patterns
    final youtubePatterns = [
      RegExp(r'^https?:\/\/(www\.)?youtube\.com\/watch\?v=[\w-]+'),
      RegExp(r'^https?:\/\/youtu\.be\/[\w-]+'),
      RegExp(r'^https?:\/\/(www\.)?youtube\.com\/embed\/[\w-]+'),
    ];

    // Vimeo patterns
    final vimeoPatterns = [
      RegExp(r'^https?:\/\/(www\.)?vimeo\.com\/\d+'),
      RegExp(r'^https?:\/\/player\.vimeo\.com\/video\/\d+'),
    ];

    // Check if URL matches any pattern
    for (final pattern in [...youtubePatterns, ...vimeoPatterns]) {
      if (pattern.hasMatch(url)) return true;
    }

    return false;
  }

  // Extract video ID from URL for embedding
  String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // YouTube video ID extraction
    final youtubePatterns = [
      RegExp(r'youtube\.com\/watch\?v=([\w-]+)'),
      RegExp(r'youtu\.be\/([\w-]+)'),
      RegExp(r'youtube\.com\/embed\/([\w-]+)'),
    ];

    for (final pattern in youtubePatterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }

    // Vimeo video ID extraction
    final vimeoPattern = RegExp(r'vimeo\.com\/(\d+)');
    final vimeoMatch = vimeoPattern.firstMatch(url);
    if (vimeoMatch != null) return vimeoMatch.group(1);

    return null;
  }
}
