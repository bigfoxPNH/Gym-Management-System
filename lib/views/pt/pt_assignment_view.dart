import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/pt_controller.dart';
import '../../widgets/loading_overlay.dart';

/// Màn hình quản lý phân công - hiển thị danh sách hội viên đang hoạt động
class PTAssignmentView extends StatelessWidget {
  const PTAssignmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PTController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công hội viên'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.activeRentals.isEmpty) {
          return const CenterLoading(message: 'Đang tải...');
        }

        final activeRentals = controller.activeRentals
            .where((r) => r['trangThai'] == 'approved')
            .toList();

        if (activeRentals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có hội viên nào đang hoạt động',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          color: const Color(0xFFFF9800),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeRentals.length,
            itemBuilder: (context, index) {
              final rental = activeRentals[index];
              return _MemberCard(rental: rental);
            },
          ),
        );
      }),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> rental;

  const _MemberCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final userName = rental['userName'] as String? ?? 'N/A';
    final userAvatar = rental['userAvatar'] as String?;
    final startDate = rental['startDate'] as DateTime?;
    final endDate = rental['endDate'] as DateTime?;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final rentalId = rental['rentalId'] as String;
          Get.to(() => PTAssignmentDetailView(rentalId: rentalId));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Đang hoạt động',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (startDate != null && endDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình chi tiết phân công hội viên
class PTAssignmentDetailView extends StatefulWidget {
  final String rentalId;

  const PTAssignmentDetailView({super.key, required this.rentalId});

  @override
  State<PTAssignmentDetailView> createState() => _PTAssignmentDetailViewState();
}

class _PTAssignmentDetailViewState extends State<PTAssignmentDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _rentalData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentalDetail();
  }

  Future<void> _loadRentalDetail() async {
    try {
      setState(() => _isLoading = true);

      // Load rental data
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

      // Load user data
      final userId = _rentalData!['userId'] as String?;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _userData = userDoc.data();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading rental detail: $e');
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
            _buildUserInfoSection(),
            const SizedBox(height: 24),
            _buildPackageInfoSection(),
            const SizedBox(height: 24),
            _buildRequestSection(),
            const SizedBox(height: 24),
            _buildSessionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final userName = _rentalData!['userName'] as String? ?? 'N/A';
    final userAvatar = _userData?['avatarUrl'] as String?;
    final userEmail = _userData?['email'] as String?;
    final userPhone = _userData?['phone'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin hội viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                      ? NetworkImage(userAvatar)
                      : null,
                  child: userAvatar == null || userAvatar.isEmpty
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userEmail != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (userPhone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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

  Widget _buildPackageInfoSection() {
    final startDate = (_rentalData!['startDate'] as Timestamp?)?.toDate();
    final endDate = (_rentalData!['endDate'] as Timestamp?)?.toDate();
    final soGio = _rentalData!['soGio'] as int? ?? 0;
    final tongTien = (_rentalData!['tongTien'] as num?)?.toDouble() ?? 0;
    final goiTap = _rentalData!['goiTap'] as String? ?? 'N/A';
    final trangThai = _rentalData!['trangThai'] as String? ?? 'N/A';

    // Parse goiTap để lấy số buổi/tuần
    String goiTapDisplay = goiTap;
    if (goiTap.contains('buoi')) {
      final match = RegExp(r'(\d+)buoi').firstMatch(goiTap);
      if (match != null) {
        final soBuoi = match.group(1);
        goiTapDisplay = 'Khóa $soBuoi buổi/tuần';
      }
    }

    // Tính số ngày còn lại
    int? daysRemaining;
    if (endDate != null) {
      daysRemaining = endDate.difference(DateTime.now()).inDays;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin gói tập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.fitness_center, 'Gói tập', goiTapDisplay),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time, 'Số giờ mỗi buổi', '$soGio giờ'),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Thời gian',
              startDate != null && endDate != null
                  ? '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'
                  : 'N/A',
            ),
            if (daysRemaining != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.timelapse,
                'Còn lại',
                daysRemaining > 0 ? '$daysRemaining ngày' : 'Đã hết hạn',
                valueColor: daysRemaining > 0 ? Colors.green : Colors.red,
              ),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              Icons.payments,
              'Tổng tiền',
              NumberFormat('#,###').format(tongTien) + 'đ',
              valueColor: const Color(0xFFFF9800),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.info,
              'Trạng thái',
              _getStatusText(trangThai),
              valueColor: _getStatusColor(trangThai),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSection() {
    final ghiChu = _rentalData!['ghiChu'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                child: Text(
                  ghiChu,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
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

  Widget _buildSessionsSection() {
    final sessions = _rentalData!['sessions'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chưa có lịch tập cụ thể. Hãy liên hệ với học viên để sắp xếp lịch tập.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                final trangThai =
                    session['trangThai'] as String? ?? 'scheduled';
                final ghiChu = session['ghiChu'] as String?;

                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < sessions.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSessionStatusColor(trangThai).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSessionStatusColor(trangThai).withOpacity(0.3),
                    ),
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSessionStatusColor(trangThai),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getSessionStatusLabel(trangThai),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd/MM/yyyy').format(ngay),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$gioBatDau - $gioKetThuc',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      if (diaDiem != null && diaDiem.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
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
                      if (ghiChu != null && ghiChu.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ghiChu,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Color _getSessionStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
      default:
        return Colors.blue;
    }
  }

  String _getSessionStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Đã lên lịch';
      case 'cancelled':
        return 'Đã hủy';
      case 'scheduled':
      default:
        return 'Đã lên lịch';
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'active':
        return 'Đang hoạt động';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
