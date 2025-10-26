import 'package:cloud_firestore/cloud_firestore.dart';
import 'certificate.dart';

/// Model cho Personal Trainer (PT)
class Trainer {
  final String id;
  final String? userId; // Link to UserAccount.id (for PT login)
  final String hoTen;
  final String? email;
  final String? soDienThoai;
  final String? gioiTinh; // 'Nam', 'Nữ', 'Khác'
  final DateTime? namSinh;
  final String? anhDaiDien;
  final String? diaChi;

  // Thông tin chuyên môn
  final List<Certificate> bangCap; // Danh sách bằng cấp với ảnh & mô tả
  final List<String> chuyenMon; // ['Yoga', 'Boxing', 'Cardio', ...]
  final String? moTa;
  final List<Certificate> chungChi; // Danh sách chứng chỉ với ảnh & mô tả
  final int namKinhNghiem; // Số năm kinh nghiệm
  final String trinhDoPT; // 'moi', 'trung_cap', 'chuyen_nghiep', 'ifbb_pro'

  // Thông tin làm việc
  final String trangThai; // 'active', 'inactive', 'suspended', 'on_leave'
  final double mucLuongCoBan; // Lương cơ bản
  final double hoaHongPhanTram; // % hoa hồng trên mỗi buổi
  final DateTime ngayVaoLam;
  final DateTime? ngayNghiViec;

  // Đánh giá
  final double danhGiaTrungBinh; // 0-5 sao
  final int soLuotDanhGia;

  // Social & Notes
  final String? facebookUrl;
  final String? instagramUrl;
  final String? ghiChu;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Trainer({
    required this.id,
    this.userId,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.gioiTinh,
    this.namSinh,
    this.anhDaiDien,
    this.diaChi,
    this.bangCap = const [],
    this.chuyenMon = const [],
    this.moTa,
    this.chungChi = const [],
    this.namKinhNghiem = 0,
    this.trinhDoPT = 'moi',
    this.trangThai = 'active',
    this.mucLuongCoBan = 0,
    this.hoaHongPhanTram = 0,
    required this.ngayVaoLam,
    this.ngayNghiViec,
    this.danhGiaTrungBinh = 0,
    this.soLuotDanhGia = 0,
    this.facebookUrl,
    this.instagramUrl,
    this.ghiChu,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Convert từ Firestore
  factory Trainer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trainer(
      id: doc.id,
      userId: data['userId'],
      hoTen: data['hoTen'] ?? '',
      email: data['email'],
      soDienThoai: data['soDienThoai'],
      gioiTinh: data['gioiTinh'],
      namSinh: data['namSinh'] != null
          ? (data['namSinh'] as Timestamp).toDate()
          : null,
      anhDaiDien: data['anhDaiDien'],
      diaChi: data['diaChi'],
      bangCap:
          (data['bangCap'] as List<dynamic>?)
              ?.map(
                (item) => item is String
                    ? Certificate(ten: item) // Backward compatibility
                    : Certificate.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      chuyenMon: List<String>.from(data['chuyenMon'] ?? []),
      moTa: data['moTa'],
      chungChi:
          (data['chungChi'] as List<dynamic>?)
              ?.map(
                (item) => item is String
                    ? Certificate(ten: item) // Backward compatibility
                    : Certificate.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      namKinhNghiem: data['namKinhNghiem'] ?? 0,
      trinhDoPT: data['trinhDoPT'] ?? 'moi',
      trangThai: data['trangThai'] ?? 'active',
      mucLuongCoBan: (data['mucLuongCoBan'] ?? 0).toDouble(),
      hoaHongPhanTram: (data['hoaHongPhanTram'] ?? 0).toDouble(),
      ngayVaoLam: (data['ngayVaoLam'] as Timestamp).toDate(),
      ngayNghiViec: data['ngayNghiViec'] != null
          ? (data['ngayNghiViec'] as Timestamp).toDate()
          : null,
      danhGiaTrungBinh: (data['danhGiaTrungBinh'] ?? 0).toDouble(),
      soLuotDanhGia: data['soLuotDanhGia'] ?? 0,
      facebookUrl: data['facebookUrl'],
      instagramUrl: data['instagramUrl'],
      ghiChu: data['ghiChu'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Convert sang Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'hoTen': hoTen,
      'email': email,
      'soDienThoai': soDienThoai,
      'gioiTinh': gioiTinh,
      'namSinh': namSinh != null ? Timestamp.fromDate(namSinh!) : null,
      'anhDaiDien': anhDaiDien,
      'diaChi': diaChi,
      'bangCap': bangCap.map((cert) => cert.toMap()).toList(),
      'chuyenMon': chuyenMon,
      'moTa': moTa,
      'chungChi': chungChi.map((cert) => cert.toMap()).toList(),
      'namKinhNghiem': namKinhNghiem,
      'trinhDoPT': trinhDoPT,
      'trangThai': trangThai,
      'mucLuongCoBan': mucLuongCoBan,
      'hoaHongPhanTram': hoaHongPhanTram,
      'ngayVaoLam': Timestamp.fromDate(ngayVaoLam),
      'ngayNghiViec': ngayNghiViec != null
          ? Timestamp.fromDate(ngayNghiViec!)
          : null,
      'danhGiaTrungBinh': danhGiaTrungBinh,
      'soLuotDanhGia': soLuotDanhGia,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'ghiChu': ghiChu,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Trainer copyWith({
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? gioiTinh,
    DateTime? namSinh,
    String? anhDaiDien,
    String? diaChi,
    List<Certificate>? bangCap,
    List<String>? chuyenMon,
    String? moTa,
    List<Certificate>? chungChi,
    int? namKinhNghiem,
    String? trinhDoPT,
    String? trangThai,
    double? mucLuongCoBan,
    double? hoaHongPhanTram,
    DateTime? ngayVaoLam,
    DateTime? ngayNghiViec,
    double? danhGiaTrungBinh,
    int? soLuotDanhGia,
    String? facebookUrl,
    String? instagramUrl,
    String? ghiChu,
    DateTime? updatedAt,
  }) {
    return Trainer(
      id: id,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      namSinh: namSinh ?? this.namSinh,
      anhDaiDien: anhDaiDien ?? this.anhDaiDien,
      diaChi: diaChi ?? this.diaChi,
      bangCap: bangCap ?? this.bangCap,
      chuyenMon: chuyenMon ?? this.chuyenMon,
      moTa: moTa ?? this.moTa,
      chungChi: chungChi ?? this.chungChi,
      namKinhNghiem: namKinhNghiem ?? this.namKinhNghiem,
      trinhDoPT: trinhDoPT ?? this.trinhDoPT,
      trangThai: trangThai ?? this.trangThai,
      mucLuongCoBan: mucLuongCoBan ?? this.mucLuongCoBan,
      hoaHongPhanTram: hoaHongPhanTram ?? this.hoaHongPhanTram,
      ngayVaoLam: ngayVaoLam ?? this.ngayVaoLam,
      ngayNghiViec: ngayNghiViec ?? this.ngayNghiViec,
      danhGiaTrungBinh: danhGiaTrungBinh ?? this.danhGiaTrungBinh,
      soLuotDanhGia: soLuotDanhGia ?? this.soLuotDanhGia,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
    );
  }

  // Helper methods
  String get tuoi {
    if (namSinh == null) return 'N/A';
    final age = DateTime.now().year - namSinh!.year;
    return '$age tuổi';
  }

  String get trangThaiText {
    switch (trangThai) {
      case 'active':
        return 'Đang làm việc';
      case 'inactive':
        return 'Không hoạt động';
      case 'suspended':
        return 'Tạm ngưng';
      case 'on_leave':
        return 'Nghỉ phép';
      default:
        return trangThai;
    }
  }

  String get trinhDoPTText {
    switch (trinhDoPT) {
      case 'moi':
        return 'Huấn luyện viên mới';
      case 'trung_cap':
        return 'HLV Trung cấp';
      case 'chuyen_nghiep':
        return 'HLV Chuyên nghiệp';
      case 'ifbb_pro':
        return 'IFBB Pro';
      default:
        return 'Huấn luyện viên mới';
    }
  }

  // Lấy giá thuê theo giờ dựa trên trình độ
  double get giaMoiGio {
    switch (trinhDoPT) {
      case 'moi':
        return 100000; // 100k/giờ
      case 'trung_cap':
        return 150000; // 150k/giờ
      case 'chuyen_nghiep':
        return 200000; // 200k/giờ
      case 'ifbb_pro':
        return 300000; // 300k/giờ
      default:
        return 100000;
    }
  }

  String get chuyenMonText {
    if (chuyenMon.isEmpty) return 'Chưa có chuyên môn';
    return chuyenMon.join(', ');
  }
}
