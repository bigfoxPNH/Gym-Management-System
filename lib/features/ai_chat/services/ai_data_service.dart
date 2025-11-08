import 'dart:convert';
import 'package:flutter/services.dart';

/// Service để đọc và quản lý tất cả dữ liệu JSON cho AI
class AIDataService {
  // Cache dữ liệu
  Map<String, dynamic>? _bmiData;
  Map<String, dynamic>? _bmrData;
  Map<String, dynamic>? _tdeeData;
  Map<String, dynamic>? _exercisesData;
  Map<String, dynamic>? _nutritionData;
  Map<String, dynamic>? _membershipData;
  Map<String, dynamic>? _workoutData;

  bool _isInitialized = false;

  /// Khởi tạo và load tất cả dữ liệu JSON
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load tất cả file JSON song song
      final results = await Future.wait([
        rootBundle.loadString('lib/features/ai_chat/data/bmi.json'),
        rootBundle.loadString('lib/features/ai_chat/data/bmr.json'),
        rootBundle.loadString('lib/features/ai_chat/data/tdee.json'),
        rootBundle.loadString('lib/features/ai_chat/data/exercises.json'),
        rootBundle.loadString('lib/features/ai_chat/data/nutrition.json'),
        rootBundle.loadString(
          'lib/features/ai_chat/data/membership_cards.json',
        ),
        rootBundle.loadString('lib/features/ai_chat/data/workout.json'),
      ]);

      _bmiData = json.decode(results[0]);
      _bmrData = json.decode(results[1]);
      _tdeeData = json.decode(results[2]);
      _exercisesData = json.decode(results[3]);
      _nutritionData = json.decode(results[4]);
      _membershipData = json.decode(results[5]);
      _workoutData = json.decode(results[6]);

      _isInitialized = true;
      print('✅ AI Data Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing AI Data Service: $e');
      rethrow;
    }
  }

  /// Getters để truy cập dữ liệu
  Map<String, dynamic> get bmiData => _bmiData ?? {};
  Map<String, dynamic> get bmrData => _bmrData ?? {};
  Map<String, dynamic> get tdeeData => _tdeeData ?? {};
  Map<String, dynamic> get exercisesData => _exercisesData ?? {};
  Map<String, dynamic> get nutritionData => _nutritionData ?? {};
  Map<String, dynamic> get membershipData => _membershipData ?? {};
  Map<String, dynamic> get workoutData => _workoutData ?? {};

  bool get isInitialized => _isInitialized;
}
