import 'package:cloud_firestore/cloud_firestore.dart';

enum ScheduleType {
  preset, // Lịch trình có sẵn từ admin
  custom, // Lịch trình tự tạo của user
}

enum DifficultyLevel { beginner, intermediate, advanced }

enum ScheduleCategory {
  weightLoss,
  muscleGain,
  strength,
  cardio,
  flexibility,
  general,
}

class WorkoutSchedule {
  final String id;
  final String title;
  final String description;
  final ScheduleType type;
  final DifficultyLevel difficulty;
  final ScheduleCategory category;
  final List<String> exerciseIds; // Danh sách ID bài tập
  final int durationWeeks;
  final int sessionsPerWeek;
  final String? createdBy; // Admin ID nếu là preset, User ID nếu là custom
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  WorkoutSchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.category,
    required this.exerciseIds,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.imageUrl,
    this.tags = const [],
    this.metadata,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'category': category.name,
      'exerciseIds': exerciseIds,
      'durationWeeks': durationWeeks,
      'sessionsPerWeek': sessionsPerWeek,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'imageUrl': imageUrl,
      'tags': tags,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory WorkoutSchedule.fromMap(Map<String, dynamic> map) {
    return WorkoutSchedule(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ScheduleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ScheduleType.custom,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      category: ScheduleCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ScheduleCategory.general,
      ),
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      durationWeeks: map['durationWeeks'] ?? 0,
      sessionsPerWeek: map['sessionsPerWeek'] ?? 0,
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      imageUrl: map['imageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  WorkoutSchedule copyWith({
    String? id,
    String? title,
    String? description,
    ScheduleType? type,
    DifficultyLevel? difficulty,
    ScheduleCategory? category,
    List<String>? exerciseIds,
    int? durationWeeks,
    int? sessionsPerWeek,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return WorkoutSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  String get difficultyText {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Người mới';
      case DifficultyLevel.intermediate:
        return 'Trung cấp';
      case DifficultyLevel.advanced:
        return 'Nâng cao';
    }
  }

  String get categoryText {
    switch (category) {
      case ScheduleCategory.weightLoss:
        return 'Giảm cân';
      case ScheduleCategory.muscleGain:
        return 'Tăng cơ';
      case ScheduleCategory.strength:
        return 'Tăng sức mạnh';
      case ScheduleCategory.cardio:
        return 'Tim mạch';
      case ScheduleCategory.flexibility:
        return 'Linh hoạt';
      case ScheduleCategory.general:
        return 'Tổng hợp';
    }
  }

  String get typeText {
    switch (type) {
      case ScheduleType.preset:
        return 'Lịch trình có sẵn';
      case ScheduleType.custom:
        return 'Lịch trình tự tạo';
    }
  }
}
