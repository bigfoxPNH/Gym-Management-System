import 'package:cloud_firestore/cloud_firestore.dart';

/// Script để thêm PT mẫu vào Firestore
/// Chạy trong initState của màn hình nào đó hoặc qua terminal
Future<void> addSampleTrainers() async {
  final firestore = FirebaseFirestore.instance;

  // Sample trainers data
  final List<Map<String, dynamic>> sampleTrainers = [
    {
      'hoTen': 'Nguyễn Văn Mạnh',
      'email': 'manh.pt@gympro.vn',
      'soDienThoai': '0901234567',
      'gioiTinh': 'male',
      'namSinh': DateTime(1990, 5, 15),
      'anhDaiDien': null,
      'diaChi': '123 Nguyễn Huệ, Quận 1, TP.HCM',
      'bangCap': ['Cử nhân TDTT', 'ISSA Certified Personal Trainer'],
      'chuyenMon': ['Tăng cơ', 'Boxing', 'HIIT'],
      'moTa': '5 năm kinh nghiệm huấn luyện. Chuyên về tăng cơ và giảm mỡ.',
      'chungChi': ['ISSA-CPT-2019', 'CrossFit-Level1-2020'],
      'trangThai': 'active',
      'mucLuongCoBan': 15000000,
      'hoaHongPhanTram': 15,
      'ngayVaoLam': DateTime(2020, 1, 15),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.8,
      'soLuotDanhGia': 45,
      'facebookUrl': 'https://fb.com/manh.pt',
      'instagramUrl': 'https://instagram.com/manh_pt_coach',
      'ghiChu': 'PT xuất sắc tháng 3/2025',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Trần Thị Hương',
      'email': 'huong.yoga@gympro.vn',
      'soDienThoai': '0902345678',
      'gioiTinh': 'female',
      'namSinh': DateTime(1992, 8, 20),
      'anhDaiDien': null,
      'diaChi': '456 Lê Lợi, Quận 3, TP.HCM',
      'bangCap': ['Cử nhân TDTT', 'Yoga Alliance RYT-200'],
      'chuyenMon': ['Yoga', 'Pilates', 'Cardio'],
      'moTa':
          'Chuyên gia Yoga với 6 năm kinh nghiệm. Tập trung vào sức khỏe tinh thần.',
      'chungChi': ['RYT-200-2019', 'Pilates-Mat-2020'],
      'trangThai': 'active',
      'mucLuongCoBan': 12000000,
      'hoaHongPhanTram': 12,
      'ngayVaoLam': DateTime(2019, 6, 1),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.9,
      'soLuotDanhGia': 68,
      'facebookUrl': null,
      'instagramUrl': 'https://instagram.com/huong_yoga',
      'ghiChu': 'Chuyên viên Yoga hàng đầu',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Lê Hoàng Nam',
      'email': 'nam.crossfit@gympro.vn',
      'soDienThoai': '0903456789',
      'gioiTinh': 'male',
      'namSinh': DateTime(1988, 12, 10),
      'anhDaiDien': null,
      'diaChi': '789 Trần Hưng Đạo, Quận 5, TP.HCM',
      'bangCap': ['Cử nhân TDTT', 'CrossFit Level 2'],
      'chuyenMon': ['CrossFit', 'HIIT', 'Tăng cơ'],
      'moTa':
          'Chuyên gia CrossFit với 8 năm kinh nghiệm. Từng tham gia các giải thi đấu.',
      'chungChi': ['CrossFit-L2-2018', 'Olympic-Weightlifting-2019'],
      'trangThai': 'active',
      'mucLuongCoBan': 18000000,
      'hoaHongPhanTram': 18,
      'ngayVaoLam': DateTime(2017, 3, 20),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.7,
      'soLuotDanhGia': 52,
      'facebookUrl': 'https://fb.com/nam.crossfit',
      'instagramUrl': 'https://instagram.com/nam_crossfit_coach',
      'ghiChu': null,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Phạm Thị Lan',
      'email': 'lan.zumba@gympro.vn',
      'soDienThoai': '0904567890',
      'gioiTinh': 'female',
      'namSinh': DateTime(1995, 3, 25),
      'anhDaiDien': null,
      'diaChi': '321 Võ Văn Tần, Quận 3, TP.HCM',
      'bangCap': ['Cử nhân TDTT'],
      'chuyenMon': ['Zumba', 'Cardio', 'Giảm cân'],
      'moTa':
          'Huấn luyện viên Zumba nhiệt huyết. Chuyên về giảm cân và tăng sức bền.',
      'chungChi': ['Zumba-Instructor-2020', 'Aerobics-Instructor-2019'],
      'trangThai': 'active',
      'mucLuongCoBan': 10000000,
      'hoaHongPhanTram': 10,
      'ngayVaoLam': DateTime(2021, 1, 15),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.6,
      'soLuotDanhGia': 38,
      'facebookUrl': null,
      'instagramUrl': 'https://instagram.com/lan_zumba',
      'ghiChu': null,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Đỗ Minh Tuấn',
      'email': 'tuan.boxing@gympro.vn',
      'soDienThoai': '0905678901',
      'gioiTinh': 'male',
      'namSinh': DateTime(1991, 7, 18),
      'anhDaiDien': null,
      'diaChi': '654 Lý Thường Kiệt, Quận 10, TP.HCM',
      'bangCap': ['Cử nhân TDTT', 'WBC Boxing Instructor'],
      'chuyenMon': ['Boxing', 'Kickboxing', 'Cardio'],
      'moTa': 'Cựu võ sĩ Boxing chuyên nghiệp. 7 năm kinh nghiệm huấn luyện.',
      'chungChi': ['WBC-Boxing-2018', 'Kickboxing-Level2-2019'],
      'trangThai': 'active',
      'mucLuongCoBan': 16000000,
      'hoaHongPhanTram': 16,
      'ngayVaoLam': DateTime(2018, 9, 1),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.85,
      'soLuotDanhGia': 41,
      'facebookUrl': 'https://fb.com/tuan.boxing',
      'instagramUrl': null,
      'ghiChu': 'Chuyên gia Boxing số 1',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Võ Thị Mai',
      'email': 'mai.pilates@gympro.vn',
      'soDienThoai': '0906789012',
      'gioiTinh': 'female',
      'namSinh': DateTime(1993, 11, 5),
      'anhDaiDien': null,
      'diaChi': '147 Cách Mạng Tháng 8, Quận 3, TP.HCM',
      'bangCap': ['Cử nhân TDTT', 'Pilates Comprehensive'],
      'chuyenMon': ['Pilates', 'Yoga', 'Stretching'],
      'moTa': 'Chuyên viên Pilates cao cấp. Tập trung vào phục hồi chức năng.',
      'chungChi': ['Pilates-Comprehensive-2020', 'Rehab-Specialist-2021'],
      'trangThai': 'on_leave',
      'mucLuongCoBan': 13000000,
      'hoaHongPhanTram': 13,
      'ngayVaoLam': DateTime(2020, 5, 10),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.75,
      'soLuotDanhGia': 32,
      'facebookUrl': null,
      'instagramUrl': 'https://instagram.com/mai_pilates',
      'ghiChu': 'Đang nghỉ phép thai sản',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
    {
      'hoTen': 'Nguyễn Quang Huy',
      'email': 'huy.spinning@gympro.vn',
      'soDienThoai': '0907890123',
      'gioiTinh': 'male',
      'namSinh': DateTime(1994, 4, 30),
      'anhDaiDien': null,
      'diaChi': '258 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
      'bangCap': ['Cử nhân TDTT'],
      'chuyenMon': ['Spinning', 'Cardio', 'Giảm cân'],
      'moTa':
          'Huấn luyện viên Spinning năng động. Chuyên về cardio và giảm cân.',
      'chungChi': ['Spinning-Instructor-2021', 'Indoor-Cycling-2020'],
      'trangThai': 'active',
      'mucLuongCoBan': 11000000,
      'hoaHongPhanTram': 11,
      'ngayVaoLam': DateTime(2021, 7, 1),
      'ngayNghiViec': null,
      'danhGiaTrungBinh': 4.5,
      'soLuotDanhGia': 28,
      'facebookUrl': 'https://fb.com/huy.spinning',
      'instagramUrl': null,
      'ghiChu': null,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'createdBy': 'admin',
    },
  ];

  try {
    print('🚀 Bắt đầu thêm ${sampleTrainers.length} PT mẫu...');

    for (var i = 0; i < sampleTrainers.length; i++) {
      final trainerData = sampleTrainers[i];

      // Convert DateTime to Timestamp
      final firestoreData = Map<String, dynamic>.from(trainerData);
      if (firestoreData['namSinh'] != null) {
        firestoreData['namSinh'] = Timestamp.fromDate(firestoreData['namSinh']);
      }
      firestoreData['ngayVaoLam'] = Timestamp.fromDate(
        firestoreData['ngayVaoLam'],
      );
      if (firestoreData['ngayNghiViec'] != null) {
        firestoreData['ngayNghiViec'] = Timestamp.fromDate(
          firestoreData['ngayNghiViec'],
        );
      }
      firestoreData['createdAt'] = Timestamp.fromDate(
        firestoreData['createdAt'],
      );
      firestoreData['updatedAt'] = Timestamp.fromDate(
        firestoreData['updatedAt'],
      );

      await firestore.collection('trainers').add(firestoreData);
      print('✅ Đã thêm PT ${i + 1}: ${trainerData['hoTen']}');
    }

    print('🎉 Hoàn tất! Đã thêm ${sampleTrainers.length} PT thành công!');
    print('📊 Thống kê:');
    print(
      '   - Active: ${sampleTrainers.where((t) => t['trangThai'] == 'active').length}',
    );
    print(
      '   - On Leave: ${sampleTrainers.where((t) => t['trangThai'] == 'on_leave').length}',
    );
    print(
      '   - Nam: ${sampleTrainers.where((t) => t['gioiTinh'] == 'male').length}',
    );
    print(
      '   - Nữ: ${sampleTrainers.where((t) => t['gioiTinh'] == 'female').length}',
    );
  } catch (e) {
    print('❌ Lỗi khi thêm PT: $e');
  }
}

/// Sample assignments
Future<void> addSampleAssignments() async {
  final firestore = FirebaseFirestore.instance;

  // Lấy danh sách trainers
  final trainersSnapshot = await firestore
      .collection('trainers')
      .limit(3)
      .get();
  if (trainersSnapshot.docs.isEmpty) {
    print('❌ Không có trainer nào. Vui lòng chạy addSampleTrainers() trước.');
    return;
  }

  final List<Map<String, dynamic>> sampleAssignments = [
    {
      'trainerId': trainersSnapshot.docs[0].id,
      'trainerName': trainersSnapshot.docs[0].data()['hoTen'],
      'userId': 'user123',
      'userName': 'Nguyễn Văn A',
      'soBuoiDangKy': 20,
      'soBuoiHoanThanh': 8,
      'mucGia': 300000,
      'trangThai': 'active',
      'ngayBatDau': DateTime.now().subtract(const Duration(days: 15)),
      'ngayKetThuc': null,
      'ghiChu': 'Tập buổi sáng',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    },
    {
      'trainerId': trainersSnapshot.docs[1].id,
      'trainerName': trainersSnapshot.docs[1].data()['hoTen'],
      'userId': 'user456',
      'userName': 'Trần Thị B',
      'soBuoiDangKy': 30,
      'soBuoiHoanThanh': 30,
      'mucGia': 250000,
      'trangThai': 'completed',
      'ngayBatDau': DateTime.now().subtract(const Duration(days: 60)),
      'ngayKetThuc': DateTime.now().subtract(const Duration(days: 5)),
      'ghiChu': 'Hoàn thành xuất sắc',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    },
  ];

  try {
    print('🚀 Bắt đầu thêm ${sampleAssignments.length} phân công mẫu...');

    for (var assignment in sampleAssignments) {
      final firestoreData = Map<String, dynamic>.from(assignment);
      firestoreData['ngayBatDau'] = Timestamp.fromDate(
        firestoreData['ngayBatDau'],
      );
      if (firestoreData['ngayKetThuc'] != null) {
        firestoreData['ngayKetThuc'] = Timestamp.fromDate(
          firestoreData['ngayKetThuc'],
        );
      }
      firestoreData['createdAt'] = Timestamp.fromDate(
        firestoreData['createdAt'],
      );
      firestoreData['updatedAt'] = Timestamp.fromDate(
        firestoreData['updatedAt'],
      );

      await firestore.collection('trainer_assignments').add(firestoreData);
      print('✅ Đã thêm phân công: ${assignment['userName']}');
    }

    print('🎉 Hoàn tất! Đã thêm ${sampleAssignments.length} phân công!');
  } catch (e) {
    print('❌ Lỗi khi thêm phân công: $e');
  }
}

/// Sample reviews
Future<void> addSampleReviews() async {
  final firestore = FirebaseFirestore.instance;

  final trainersSnapshot = await firestore
      .collection('trainers')
      .limit(3)
      .get();
  if (trainersSnapshot.docs.isEmpty) {
    print('❌ Không có trainer nào.');
    return;
  }

  final List<Map<String, dynamic>> sampleReviews = [
    {
      'trainerId': trainersSnapshot.docs[0].id,
      'userId': 'user123',
      'userName': 'Nguyễn Văn A',
      'userAvatar': null,
      'rating': 5.0,
      'comment':
          'PT rất nhiệt tình và chuyên nghiệp. Tôi đã giảm được 5kg trong 2 tháng!',
      'tags': ['Nhiệt tình', 'Chuyên nghiệp', 'Hiệu quả'],
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      'updatedAt': DateTime.now().subtract(const Duration(days: 10)),
    },
    {
      'trainerId': trainersSnapshot.docs[0].id,
      'userId': 'user789',
      'userName': 'Lê Văn C',
      'userAvatar': null,
      'rating': 4.5,
      'comment': 'Tập luyện khoa học, có lộ trình rõ ràng.',
      'tags': ['Khoa học', 'Tận tâm'],
      'createdAt': DateTime.now().subtract(const Duration(days: 20)),
      'updatedAt': DateTime.now().subtract(const Duration(days: 20)),
    },
  ];

  try {
    print('🚀 Bắt đầu thêm ${sampleReviews.length} đánh giá mẫu...');

    for (var review in sampleReviews) {
      final firestoreData = Map<String, dynamic>.from(review);
      firestoreData['createdAt'] = Timestamp.fromDate(
        firestoreData['createdAt'],
      );
      firestoreData['updatedAt'] = Timestamp.fromDate(
        firestoreData['updatedAt'],
      );

      await firestore.collection('trainer_reviews').add(firestoreData);
      print('✅ Đã thêm đánh giá từ: ${review['userName']}');
    }

    print('🎉 Hoàn tất! Đã thêm ${sampleReviews.length} đánh giá!');
  } catch (e) {
    print('❌ Lỗi khi thêm đánh giá: $e');
  }
}

/// Chạy tất cả
Future<void> addAllSampleData() async {
  print('=' * 50);
  print('🎯 THÊM DỮ LIỆU MẪU CHO PT MANAGEMENT');
  print('=' * 50);

  await addSampleTrainers();
  print('\n');
  await addSampleAssignments();
  print('\n');
  await addSampleReviews();

  print('\n' + '=' * 50);
  print('✨ HOÀN TẤT! Tất cả dữ liệu mẫu đã được thêm!');
  print('=' * 50);
}
