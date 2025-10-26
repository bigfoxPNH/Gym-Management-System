import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho Chứng chỉ/Bằng cấp
class Certificate {
  final String ten; // Tên chứng chỉ/bằng cấp
  final String? moTa; // Mô tả chi tiết
  final String? anhUrl; // URL ảnh chứng chỉ
  final DateTime? ngayCap; // Ngày cấp (nếu có)

  Certificate({required this.ten, this.moTa, this.anhUrl, this.ngayCap});

  // Convert từ Map
  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      ten: map['ten'] ?? '',
      moTa: map['moTa'],
      anhUrl: map['anhUrl'],
      ngayCap: map['ngayCap'] != null
          ? (map['ngayCap'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert sang Map
  Map<String, dynamic> toMap() {
    return {
      'ten': ten,
      'moTa': moTa,
      'anhUrl': anhUrl,
      'ngayCap': ngayCap != null ? Timestamp.fromDate(ngayCap!) : null,
    };
  }

  Certificate copyWith({
    String? ten,
    String? moTa,
    String? anhUrl,
    DateTime? ngayCap,
  }) {
    return Certificate(
      ten: ten ?? this.ten,
      moTa: moTa ?? this.moTa,
      anhUrl: anhUrl ?? this.anhUrl,
      ngayCap: ngayCap ?? this.ngayCap,
    );
  }
}
