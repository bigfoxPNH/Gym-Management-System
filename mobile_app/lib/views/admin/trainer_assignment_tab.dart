import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/loading_overlay.dart';

/// Tab hiển thị phân công PT cho học viên (Admin view)
class TrainerAssignmentTab extends StatefulWidget {
  const TrainerAssignmentTab({super.key});

  @override
  State<TrainerAssignmentTab> createState() => _TrainerAssignmentTabState();
}

class _TrainerAssignmentTabState extends State<TrainerAssignmentTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _activeRentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveRentals();
  }

  Future<void> _loadActiveRentals() async {
    try {
      setState(() => _isLoading = true);

      // Load all approved rentals (without orderBy to avoid composite index requirement)
      final rentalsSnapshot = await _firestore
          .collection('trainer_rentals')
          .where('trangThai', isEqualTo: 'approved')
          .get();

      final rentals = <Map<String, dynamic>>[];

      for (final doc in rentalsSnapshot.docs) {
        final data = doc.data();
        final trainerId = data['trainerId'] as String?;
        final userId = data['userId'] as String?;

        // Get trainer info
        String? trainerAvatar;
        if (trainerId != null) {
          final trainerDoc = await _firestore
              .collection('trainers')
              .doc(trainerId)
              .get();
          if (trainerDoc.exists) {
            final trainerData = trainerDoc.data();
            trainerAvatar = trainerData?['hinhAnh'];
          }
        }

        // Get user info
        String? userAvatar;
        if (userId != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            userAvatar = userData?['avatarUrl'];
          }
        }

        rentals.add({
          'id': doc.id,
          'trainerId': trainerId,
          'trainerName': data['trainerName'] ?? 'N/A',
          'trainerAvatar': trainerAvatar,
          'userId': userId,
          'userName': data['userName'] ?? 'N/A',
          'userAvatar': userAvatar,
          'startDate': (data['startDate'] as Timestamp?)?.toDate(),
          'endDate': (data['endDate'] as Timestamp?)?.toDate(),
          'soGio': data['soGio'] ?? 0,
          'tongTien': (data['tongTien'] as num?)?.toDouble() ?? 0,
          'goiTap': data['goiTap'] ?? '',
          'ghiChu': data['ghiChu'],
          'sessions': data['sessions'] ?? [],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        });
      }

      // Sort by createdAt descending
      rentals.sort((a, b) {
        final aDate = a['createdAt'] as DateTime?;
        final bDate = b['createdAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _activeRentals = rentals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active rentals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân Công PT',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_activeRentals.length} phân công đang hoạt động',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Rentals list
        Expanded(
          child: _isLoading
              ? const CenterLoading(message: 'Đang tải phân công...')
              : _activeRentals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadActiveRentals,
                  color: const Color(0xFFFF9800),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activeRentals.length,
                    itemBuilder: (context, index) {
                      final rental = _activeRentals[index];
                      return _buildRentalCard(context, rental);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 92, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có phân công nào đang hoạt động',
            style: TextStyle(fontSize: 18.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(BuildContext context, Map<String, dynamic> rental) {
    final trainerName = rental['trainerName'] as String? ?? 'N/A';
    final trainerAvatar = rental['trainerAvatar'] as String?;
    final userName = rental['userName'] as String? ?? 'N/A';
    final userAvatar = rental['userAvatar'] as String?;
    final startDate = rental['startDate'] as DateTime?;
    final endDate = rental['endDate'] as DateTime?;
    final sessions = rental['sessions'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRentalDetail(context, rental),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PT and User info
              Row(
                children: [
                  // Trainer avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
                    backgroundImage:
                        trainerAvatar != null && trainerAvatar.isNotEmpty
                        ? NetworkImage(trainerAvatar)
                        : null,
                    child: trainerAvatar == null || trainerAvatar.isEmpty
                        ? Text(
                            trainerName.isNotEmpty
                                ? trainerName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trainerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'dạy',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // User avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.deepPurple.withOpacity(0.2),
                    backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                        ? NetworkImage(userAvatar)
                        : null,
                    child: userAvatar == null || userAvatar.isEmpty
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đang hoạt động',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Info
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (startDate != null && endDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      '${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM/yy').format(endDate)}',
                      Colors.blue,
                    ),
                  _buildInfoChip(
                    Icons.event,
                    '${sessions.length} buổi tập',
                    Colors.green,
                  ),
                  _buildInfoChip(
                    Icons.remove_red_eye,
                    'Xem chi tiết',
                    const Color(0xFFFF9800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRentalDetail(BuildContext context, Map<String, dynamic> rental) {
    final rentalId = rental['id'] as String;
    Get.to(() => AdminRentalDetailView(rentalId: rentalId));
  }
}

/// Màn hình chi tiết phân công (Admin view)
class AdminRentalDetailView extends StatefulWidget {
  final String rentalId;

  const AdminRentalDetailView({super.key, required this.rentalId});

  @override
  State<AdminRentalDetailView> createState() => _AdminRentalDetailViewState();
}

class _AdminRentalDetailViewState extends State<AdminRentalDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _rentalData;
  Map<String, dynamic>? _trainerData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      setState(() => _isLoading = true);

      // Load rental
      final rentalDoc = await _firestore
          .collection('trainer_rentals')
          .doc(widget.rentalId)
          .get();

      if (!rentalDoc.exists) {
        Get.back();
        Get.snackbar('Lỗi', 'Không tìm thấy thông tin phân công');
        return;
      }

      _rentalData = rentalDoc.data();

      // Load trainer
      final trainerId = _rentalData!['trainerId'] as String?;
      if (trainerId != null) {
        final trainerDoc = await _firestore
            .collection('trainers')
            .doc(trainerId)
            .get();
        if (trainerDoc.exists) {
          _trainerData = trainerDoc.data();
        }
      }

      // Load user
      final userId = _rentalData!['userId'] as String?;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _userData = userDoc.data();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading detail: $e');
      setState(() => _isLoading = false);
      Get.snackbar('Lỗi', 'Không thể tải thông tin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: CenterLoading(message: 'Đang tải...'));
    }

    if (_rentalData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết phân công'),
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Không tìm thấy dữ liệu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phân công'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainerInfo(),
            const SizedBox(height: 16),
            _buildUserInfo(),
            const SizedBox(height: 16),
            _buildPackageInfo(),
            const SizedBox(height: 16),
            _buildRequestInfo(),
            const SizedBox(height: 16),
            _buildSessionsInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerInfo() {
    final trainerName = _rentalData!['trainerName'] as String? ?? 'N/A';
    final trainerAvatar = _trainerData?['hinhAnh'] as String?;
    final chuyenMon = _trainerData?['chuyenMon'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin PT',
              style: TextStyle(fontSize: 20.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
                  backgroundImage:
                      trainerAvatar != null && trainerAvatar.isNotEmpty
                      ? NetworkImage(trainerAvatar)
                      : null,
                  child: trainerAvatar == null || trainerAvatar.isEmpty
                      ? Text(
                          trainerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 27.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainerName,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (chuyenMon.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Chuyên môn: ${chuyenMon.join(", ")}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final userName = _rentalData!['userName'] as String? ?? 'N/A';
    final userAvatar = _userData?['avatarUrl'] as String?;
    final userEmail = _userData?['email'] as String?;
    final userPhone = _userData?['phone'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin hội viên',
              style: TextStyle(fontSize: 20.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple.withOpacity(0.2),
                  backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                      ? NetworkImage(userAvatar)
                      : null,
                  child: userAvatar == null || userAvatar.isEmpty
                      ? Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 27.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userEmail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (userPhone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageInfo() {
    final startDate = (_rentalData!['startDate'] as Timestamp?)?.toDate();
    final endDate = (_rentalData!['endDate'] as Timestamp?)?.toDate();
    final soGio = _rentalData!['soGio'] as int? ?? 0;
    final tongTien = (_rentalData!['tongTien'] as num?)?.toDouble() ?? 0;
    final goiTap = _rentalData!['goiTap'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin gói tập',
              style: TextStyle(fontSize: 20.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.fitness_center, 'Gói tập', goiTap),
            const Divider(),
            _buildInfoRow(Icons.access_time, 'Số giờ/buổi', '$soGio giờ'),
            const Divider(),
            if (startDate != null && endDate != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Thời gian',
                '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              ),
            const Divider(),
            _buildInfoRow(
              Icons.payments,
              'Tổng tiền',
              NumberFormat('#,###').format(tongTien) + 'đ',
              valueColor: const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfo() {
    final ghiChu = _rentalData!['ghiChu'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yêu cầu từ hội viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ghiChu != null && ghiChu.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ghiChu, style: const TextStyle(fontSize: 14)),
              )
            else
              Text(
                'Không có yêu cầu đặc biệt',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsInfo() {
    final sessions = _rentalData!['sessions'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${sessions.length} buổi',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Chưa có lịch tập cụ thể',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                ),
              )
            else
              ...sessions.asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value as Map<String, dynamic>;
                final ngay = (session['ngay'] as Timestamp?)?.toDate();
                final gioBatDau = session['gioBatDau'] as String? ?? '';
                final gioKetThuc = session['gioKetThuc'] as String? ?? '';
                final diaDiem = session['diaDiem'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Buổi ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (ngay != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd/MM/yyyy').format(ngay),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$gioBatDau - $gioKetThuc',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      if (diaDiem != null && diaDiem.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                diaDiem,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
