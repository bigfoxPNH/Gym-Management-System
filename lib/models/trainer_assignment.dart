import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho việc phân công PT cho học viên
class TrainerAssignment {
  final String id;
  final String trainerId; // ID của PT
  final String userId; // ID của học viên
  final String trainerName;
  final String userName;

  final DateTime ngayBatDau;
  final DateTime? ngayKetThuc;
  final int soBuoiDangKy; // Số buổi tập đã đăng ký
  final int soBuoiHoanThanh; // Số buổi đã hoàn thành

  final String trangThai; // 'active', 'completed', 'cancelled'
  final String? ghiChuTienDo; // Ghi chú về tiến độ học viên
  final double? mucGia; // Giá mỗi buổi

  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  TrainerAssignment({
    required this.id,
    required this.trainerId,
    required this.userId,
    required this.trainerName,
    required this.userName,
    required this.ngayBatDau,
    this.ngayKetThuc,
    required this.soBuoiDangKy,
    this.soBuoiHoanThanh = 0,
    this.trangThai = 'active',
    this.ghiChuTienDo,
    this.mucGia,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory TrainerAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainerAssignment(
      id: doc.id,
      trainerId: data['trainerId'] ?? '',
      userId: data['userId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      userName: data['userName'] ?? '',
      ngayBatDau: (data['ngayBatDau'] as Timestamp).toDate(),
      ngayKetThuc: data['ngayKetThuc'] != null
          ? (data['ngayKetThuc'] as Timestamp).toDate()
          : null,
      soBuoiDangKy: data['soBuoiDangKy'] ?? 0,
      soBuoiHoanThanh: data['soBuoiHoanThanh'] ?? 0,
      trangThai: data['trangThai'] ?? 'active',
      ghiChuTienDo: data['ghiChuTienDo'],
      mucGia: data['mucGia']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trainerId': trainerId,
      'userId': userId,
      'trainerName': trainerName,
      'userName': userName,
      'ngayBatDau': Timestamp.fromDate(ngayBatDau),
      'ngayKetThuc': ngayKetThuc != null
          ? Timestamp.fromDate(ngayKetThuc!)
          : null,
      'soBuoiDangKy': soBuoiDangKy,
      'soBuoiHoanThanh': soBuoiHoanThanh,
      'trangThai': trangThai,
      'ghiChuTienDo': ghiChuTienDo,
      'mucGia': mucGia,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  double get tienDoPercent {
    if (soBuoiDangKy == 0) return 0;
    return (soBuoiHoanThanh / soBuoiDangKy * 100).clamp(0, 100);
  }

  String get trangThaiText {
    switch (trangThai) {
      case 'active':
        return 'Đang tập';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }
}
