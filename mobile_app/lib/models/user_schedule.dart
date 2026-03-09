import 'package:cloud_firestore/cloud_firestore.dart';

enum UserScheduleStatus { active, paused, completed, cancelled }

class UserSchedule {
  final String id;
  final String userId;
  final String scheduleId;
  final UserScheduleStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? completedDate;
  final int currentWeek;
  final int currentSession;
  final List<String> completedExerciseIds;
  final Map<String, dynamic>? progress; // Tiến độ tập luyện
  final Map<String, dynamic>? notes; // Ghi chú của user
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSchedule({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.completedDate,
    this.currentWeek = 1,
    this.currentSession = 1,
    this.completedExerciseIds = const [],
    this.progress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scheduleId': scheduleId,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'currentWeek': currentWeek,
      'currentSession': currentSession,
      'completedExerciseIds': completedExerciseIds,
      'progress': progress,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserSchedule.fromMap(Map<String, dynamic> map) {
    return UserSchedule(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      status: UserScheduleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserScheduleStatus.active,
      ),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      completedDate: (map['completedDate'] as Timestamp?)?.toDate(),
      currentWeek: map['currentWeek'] ?? 1,
      currentSession: map['currentSession'] ?? 1,
      completedExerciseIds: List<String>.from(
        map['completedExerciseIds'] ?? [],
      ),
      progress: map['progress'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserSchedule copyWith({
    String? id,
    String? userId,
    String? scheduleId,
    UserScheduleStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? completedDate,
    int? currentWeek,
    int? currentSession,
    List<String>? completedExerciseIds,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completedDate: completedDate ?? this.completedDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentSession: currentSession ?? this.currentSession,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusText {
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

  double get progressPercentage {
    if (progress == null) return 0.0;
    final total = progress!['total'] ?? 0;
    final completed = progress!['completed'] ?? 0;
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }
}
