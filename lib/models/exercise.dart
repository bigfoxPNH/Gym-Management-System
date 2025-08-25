import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseLevel {
  beginner('Cơ bản'),
  intermediate('Trung cấp'),
  advanced('Nâng cao');

  const ExerciseLevel(this.label);
  final String label;
}

enum ExerciseType {
  push('Đẩy'),
  pull('Kéo'),
  compound('Compound'),
  isolation('Isolation'),
  cardio('Cardio'),
  flexibility('Linh hoạt');

  const ExerciseType(this.label);
  final String label;
}

enum ExercisePosition {
  standing('Đứng'),
  sitting('Ngồi'),
  lying('Nằm'),
  kneeling('Quỳ');

  const ExercisePosition(this.label);
  final String label;
}

enum ExerciseGoal {
  strength('Sức mạnh'),
  muscle('Tăng cơ'),
  endurance('Sức bền'),
  flexibility('Linh hoạt'),
  weight_loss('Giảm cân'),
  cardio('Tim mạch');

  const ExerciseGoal(this.label);
  final String label;
}

class Exercise {
  final String id;
  final String tenBaiTap; // Tên bài tập
  final List<String> cochinh; // Nhóm cơ chính
  final List<String> coPhu; // Nhóm cơ phụ
  final List<String> loaiBaiTap; // Loại bài tập (có thể nhiều loại)
  final List<String> dungCu; // Dụng cụ
  final List<String> tuThe; // Tư thế (có thể nhiều tư thế)
  final ExerciseLevel doKho; // Độ khó
  final List<ExerciseGoal> mucTieu; // Mục tiêu
  final String moTa; // Mô tả chi tiết
  final List<String> anhMinhHoa; // Danh sách link hình ảnh (tối đa 5 ảnh)
  final String? videoMinhHoa; // Link video
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  // Static options cho UI
  static const List<String> loaiBaiTapOptions = [
    'Compound',
    'Isolation',
    'Đẩy',
    'Kéo',
    'Chân',
    'Cardio',
    'Linh hoạt',
    'Sức mạnh',
    'Sức bền',
    'Cân bằng',
    'Plyometric',
    'HIIT',
  ];

  static const List<String> tuTheOptions = [
    'Đứng',
    'Ngồi ghế',
    'Ngồi sàn',
    'Nằm ngửa',
    'Nằm sấp',
    'Nằm nghiêng',
    'Quỳ 2 chân',
    'Quỳ 1 chân',
    'Chống tay',
    'Treo xà',
    'Squat',
    'Lunge',
    'Deadlift',
    'Plank',
  ];

  Exercise({
    required this.id,
    required this.tenBaiTap,
    required this.cochinh,
    required this.coPhu,
    required this.loaiBaiTap,
    required this.dungCu,
    required this.tuThe,
    required this.doKho,
    required this.mucTieu,
    required this.moTa,
    this.anhMinhHoa = const [],
    this.videoMinhHoa,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenBaiTap': tenBaiTap,
      'cochinh': cochinh,
      'coPhu': coPhu,
      'loaiBaiTap': loaiBaiTap, // Now List<String>
      'dungCu': dungCu,
      'tuThe': tuThe, // Now List<String>
      'doKho': doKho.name,
      'mucTieu': mucTieu.map((goal) => goal.name).toList(),
      'moTa': moTa,
      'anhMinhHoa': anhMinhHoa,
      'videoMinhHoa': videoMinhHoa,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }

  // Create from Firestore Document
  factory Exercise.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise.fromMap(data);
  }

  // Create from Map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      tenBaiTap: map['tenBaiTap'] ?? '',
      cochinh: List<String>.from(map['cochinh'] ?? []),
      coPhu: List<String>.from(map['coPhu'] ?? []),
      loaiBaiTap: List<String>.from(
        map['loaiBaiTap'] ?? [],
      ), // Now List<String>
      dungCu: List<String>.from(map['dungCu'] ?? []),
      tuThe: List<String>.from(map['tuThe'] ?? []), // Now List<String>
      doKho: ExerciseLevel.values.firstWhere(
        (level) => level.name == map['doKho'],
        orElse: () => ExerciseLevel.beginner,
      ),
      mucTieu:
          (map['mucTieu'] as List<dynamic>?)
              ?.map(
                (goalName) => ExerciseGoal.values.firstWhere(
                  (goal) => goal.name == goalName,
                  orElse: () => ExerciseGoal.strength,
                ),
              )
              .toList() ??
          [],
      moTa: map['moTa'] ?? '',
      anhMinhHoa: _parseImageUrls(map['anhMinhHoa']),
      videoMinhHoa: map['videoMinhHoa'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Helper method to parse image URLs from both old (String) and new (List<String>) formats
  static List<String> _parseImageUrls(dynamic imageData) {
    if (imageData == null) return [];
    
    // If it's already a List, convert to List<String>
    if (imageData is List) {
      return List<String>.from(imageData);
    }
    
    // If it's a String (old format), put it in a List
    if (imageData is String && imageData.isNotEmpty) {
      return [imageData];
    }
    
    return [];
  }

  // Copy with method for updates
  Exercise copyWith({
    String? id,
    String? tenBaiTap,
    List<String>? cochinh,
    List<String>? coPhu,
    List<String>? loaiBaiTap, // Changed to List<String>
    List<String>? dungCu,
    List<String>? tuThe, // Changed to List<String>
    ExerciseLevel? doKho,
    List<ExerciseGoal>? mucTieu,
    String? moTa,
    List<String>? anhMinhHoa,
    String? videoMinhHoa,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Exercise(
      id: id ?? this.id,
      tenBaiTap: tenBaiTap ?? this.tenBaiTap,
      cochinh: cochinh ?? this.cochinh,
      coPhu: coPhu ?? this.coPhu,
      loaiBaiTap: loaiBaiTap ?? this.loaiBaiTap,
      dungCu: dungCu ?? this.dungCu,
      tuThe: tuThe ?? this.tuThe,
      doKho: doKho ?? this.doKho,
      mucTieu: mucTieu ?? this.mucTieu,
      moTa: moTa ?? this.moTa,
      anhMinhHoa: anhMinhHoa ?? this.anhMinhHoa,
      videoMinhHoa: videoMinhHoa ?? this.videoMinhHoa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, tenBaiTap: $tenBaiTap, loaiBaiTap: ${loaiBaiTap.join(", ")})';
  }
}

// Helper functions for enum conversions
ExerciseLevel exerciseLevelFromString(String? level) {
  if (level == null || level.isEmpty) return ExerciseLevel.beginner;
  return ExerciseLevel.values.firstWhere(
    (e) => e.name == level,
    orElse: () => ExerciseLevel.beginner,
  );
}

ExerciseType exerciseTypeFromString(String? type) {
  if (type == null || type.isEmpty) return ExerciseType.compound;
  return ExerciseType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => ExerciseType.compound,
  );
}

ExercisePosition exercisePositionFromString(String? position) {
  if (position == null || position.isEmpty) return ExercisePosition.standing;
  return ExercisePosition.values.firstWhere(
    (e) => e.name == position,
    orElse: () => ExercisePosition.standing,
  );
}

ExerciseGoal exerciseGoalFromString(String? goal) {
  if (goal == null || goal.isEmpty) return ExerciseGoal.strength;
  return ExerciseGoal.values.firstWhere(
    (e) => e.name == goal,
    orElse: () => ExerciseGoal.strength,
  );
}
