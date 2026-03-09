import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsType {
  general, // Tin tức chung
  promotion, // Khuyến mãi
  event, // Sự kiện
  announcement, // Thông báo
  fitness, // Thể hình
  nutrition, // Dinh dưỡng
}

class NewsInteraction {
  final int likes;
  final int shares;
  final int comments;
  final int reports;

  NewsInteraction({
    this.likes = 0,
    this.shares = 0,
    this.comments = 0,
    this.reports = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'likes': likes,
      'shares': shares,
      'comments': comments,
      'reports': reports,
    };
  }

  factory NewsInteraction.fromJson(Map<String, dynamic> json) {
    return NewsInteraction(
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      comments: json['comments'] ?? 0,
      reports: json['reports'] ?? 0,
    );
  }
}

class News {
  final String? id;
  final String title;
  final NewsType type;
  final List<String> images; // Tối đa 5 link ảnh chính
  final String description; // Mô tả text
  final List<String> detailImages; // Ảnh phụ/chi tiết tối đa 5 ảnh
  final String? videoUrl; // Link video
  final NewsInteraction interaction;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorId;
  final String authorName;
  final bool isPublished;

  News({
    this.id,
    required this.title,
    required this.type,
    this.images = const [],
    required this.description,
    this.detailImages = const [],
    this.videoUrl,
    NewsInteraction? interaction,
    DateTime? createdAt,
    this.updatedAt,
    required this.authorId,
    required this.authorName,
    this.isPublished = true,
  }) : interaction = interaction ?? NewsInteraction(),
       createdAt = createdAt ?? DateTime.now();

  // Kiểm tra số lượng ảnh hợp lệ
  bool get isValidImageCount => images.length <= 5;
  bool get isValidDetailImageCount => detailImages.length <= 5;

  String get typeDisplayName {
    switch (type) {
      case NewsType.general:
        return 'Tin tức chung';
      case NewsType.promotion:
        return 'Khuyến mãi';
      case NewsType.event:
        return 'Sự kiện';
      case NewsType.announcement:
        return 'Thông báo';
      case NewsType.fitness:
        return 'Thể hình';
      case NewsType.nutrition:
        return 'Dinh dưỡng';
    }
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'images': images,
      'description': description,
      'detailImages': detailImages,
      'videoUrl': videoUrl,
      'interaction': interaction.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'authorId': authorId,
      'authorName': authorName,
      'isPublished': isPublished,
    };
  }

  factory News.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return News.fromJson(data, doc.id);
  }

  factory News.fromJson(Map<String, dynamic> json, [String? id]) {
    return News(
      id: id,
      title: json['title'] ?? '',
      type: NewsType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NewsType.general,
      ),
      images: List<String>.from(json['images'] ?? []),
      description: json['description'] ?? '',
      detailImages: List<String>.from(json['detailImages'] ?? []),
      videoUrl: json['videoUrl'],
      interaction: NewsInteraction.fromJson(json['interaction'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      isPublished: json['isPublished'] ?? true,
    );
  }

  News copyWith({
    String? id,
    String? title,
    NewsType? type,
    List<String>? images,
    String? description,
    List<String>? detailImages,
    String? videoUrl,
    NewsInteraction? interaction,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    String? authorName,
    bool? isPublished,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      images: images ?? this.images,
      description: description ?? this.description,
      detailImages: detailImages ?? this.detailImages,
      videoUrl: videoUrl ?? this.videoUrl,
      interaction: interaction ?? this.interaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  @override
  String toString() {
    return 'News{id: $id, title: $title, type: $type, isPublished: $isPublished}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is News && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
