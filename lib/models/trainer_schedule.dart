import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho lịch làm việc của PT
class TrainerSchedule {
  final String id;
  final String trainerId;
  final String trainerName;

  final DateTime ngay;
  final String gioStart; // '08:00'
  final String gioEnd; // '09:00'

  final String trangThai; // 'available', 'booked', 'completed', 'cancelled'
  final String? userId; // ID học viên đã đặt (nếu booked)
  final String? userName;
  final String? ghiChu;

  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerSchedule({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.ngay,
    required this.gioStart,
    required this.gioEnd,
    this.trangThai = 'available',
    this.userId,
    this.userName,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainerSchedule(
      id: doc.id,
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      ngay: (data['ngay'] as Timestamp).toDate(),
      gioStart: data['gioStart'] ?? '',
      gioEnd: data['gioEnd'] ?? '',
      trangThai: data['trangThai'] ?? 'available',
      userId: data['userId'],
      userName: data['userName'],
      ghiChu: data['ghiChu'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trainerId': trainerId,
      'trainerName': trainerName,
      'ngay': Timestamp.fromDate(ngay),
      'gioStart': gioStart,
      'gioEnd': gioEnd,
      'trangThai': trangThai,
      'userId': userId,
      'userName': userName,
      'ghiChu': ghiChu,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get thoiGian => '$gioStart - $gioEnd';

  String get trangThaiText {
    switch (trangThai) {
      case 'available':
        return 'Còn trống';
      case 'booked':
        return 'Đã đặt';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }
}
