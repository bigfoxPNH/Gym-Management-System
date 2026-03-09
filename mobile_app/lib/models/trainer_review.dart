import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho đánh giá PT từ học viên
class TrainerReview {
  final String id;
  final String trainerId;
  final String userId;
  final String userName;
  final String? userAvatar;

  final double rating; // 1-5 sao
  final String? comment;
  final List<String> tags; // ['Nhiệt tình', 'Chuyên nghiệp', 'Vui vẻ', ...]

  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerReview({
    required this.id,
    required this.trainerId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainerReview(
      id: doc.id,
      trainerId: data['trainerId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trainerId': trainerId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
