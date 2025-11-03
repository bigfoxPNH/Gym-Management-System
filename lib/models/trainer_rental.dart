import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho việc thuê PT
class TrainerRental {
  final String id;
  final String userId; // Member thuê
  final String userName;
  final String trainerId; // PT được thuê
  final String trainerName;
  final DateTime startDate; // Ngày bắt đầu
  final DateTime endDate; // Ngày kết thúc
  final int soGio; // Số giờ thuê
  final double tongTien; // Tổng tiền
  final String goiTap; // Gói tập: personal, group, online
  final String trangThai; // pending, approved, active, completed, cancelled
  final String? ghiChu; // Ghi chú từ member
  final String? phanHoi; // Phản hồi từ PT
  final List<TrainerSession> sessions; // Các buổi tập
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerRental({
    required this.id,
    required this.userId,
    required this.userName,
    required this.trainerId,
    required this.trainerName,
    required this.startDate,
    required this.endDate,
    required this.soGio,
    required this.tongTien,
    required this.goiTap,
    required this.trangThai,
    this.ghiChu,
    this.phanHoi,
    this.sessions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerRental.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainerRental(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      soGio: data['soGio'] ?? 0,
      tongTien: (data['tongTien'] ?? 0).toDouble(),
      goiTap: data['goiTap'] ?? 'personal',
      trangThai: data['trangThai'] ?? 'pending',
      ghiChu: data['ghiChu'],
      phanHoi: data['phanHoi'],
      sessions:
          (data['sessions'] as List<dynamic>?)
              ?.map((s) => TrainerSession.fromMap(s))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'soGio': soGio,
      'tongTien': tongTien,
      'goiTap': goiTap,
      'trangThai': trangThai,
      'ghiChu': ghiChu,
      'phanHoi': phanHoi,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TrainerRental copyWith({
    String? id,
    String? userId,
    String? userName,
    String? trainerId,
    String? trainerName,
    DateTime? startDate,
    DateTime? endDate,
    int? soGio,
    double? tongTien,
    String? goiTap,
    String? trangThai,
    String? ghiChu,
    String? phanHoi,
    List<TrainerSession>? sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerRental(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      soGio: soGio ?? this.soGio,
      tongTien: tongTien ?? this.tongTien,
      goiTap: goiTap ?? this.goiTap,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      phanHoi: phanHoi ?? this.phanHoi,
      sessions: sessions ?? this.sessions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get trangThaiText {
    switch (trangThai) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'active':
        return 'Đang tập';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return trangThai;
    }
  }

  String get goiTapText {
    switch (goiTap) {
      case 'personal':
        return 'Cá nhân 1-1';
      case 'group':
        return 'Nhóm nhỏ';
      case 'online':
        return 'Online';
      default:
        return goiTap;
    }
  }
}

/// Buổi tập trong gói thuê PT
class TrainerSession {
  final DateTime ngay;
  final String gioBatDau;
  final String gioKetThuc;
  final String? diaDiem;
  final String trangThai; // scheduled, completed, cancelled
  final String? ghiChu;

  TrainerSession({
    required this.ngay,
    required this.gioBatDau,
    required this.gioKetThuc,
    this.diaDiem,
    required this.trangThai,
    this.ghiChu,
  });

  factory TrainerSession.fromMap(Map<String, dynamic> map) {
    return TrainerSession(
      ngay: (map['ngay'] as Timestamp).toDate(),
      gioBatDau: map['gioBatDau'] ?? '',
      gioKetThuc: map['gioKetThuc'] ?? '',
      diaDiem: map['diaDiem'],
      trangThai: map['trangThai'] ?? 'scheduled',
      ghiChu: map['ghiChu'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngay': Timestamp.fromDate(ngay),
      'gioBatDau': gioBatDau,
      'gioKetThuc': gioKetThuc,
      'diaDiem': diaDiem,
      'trangThai': trangThai,
      'ghiChu': ghiChu,
    };
  }
}
