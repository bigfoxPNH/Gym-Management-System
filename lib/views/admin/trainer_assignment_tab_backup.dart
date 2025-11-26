import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../models/trainer_assignment.dart';
import '../../widgets/loading_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tab hiển thị phân công PT cho học viên
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

      // Load all approved rentals
      final rentalsSnapshot = await _firestore
          .collection('trainer_rentals')
          .where('trangThai', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      final rentals = <Map<String, dynamic>>[];

      for (final doc in rentalsSnapshot.docs) {
        final data = doc.data();
        final trainerId = data['trainerId'] as String?;
        final userId = data['userId'] as String?;

        // Get trainer info
        String? trainerAvatar;
        if (trainerId != null) {
          final trainerDoc =
              await _firestore.collection('trainers').doc(trainerId).get();
          if (trainerDoc.exists) {
            final trainerData = trainerDoc.data();
            trainerAvatar = trainerData?['hinhAnh'];
          }
        }

        // Get user info
        String? userAvatar;
        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_activeRentals.length} phân công đang hoạt động',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            Row(
              children: [
                // Trainer icon
                CircleAvatar(
                  backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.trainerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              assignment.userName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    assignment.trangThaiText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ: ${assignment.soBuoiHoanThanh}/${assignment.soBuoiDangKy} buổi',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${assignment.tienDoPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: assignment.tienDoPercent / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.calendar_today,
                  'Bắt đầu: ${dateFormat.format(assignment.ngayBatDau)}',
                  Colors.blue,
                ),
                if (assignment.ngayKetThuc != null)
                  _buildInfoChip(
                    Icons.event_available,
                    'Kết thúc: ${dateFormat.format(assignment.ngayKetThuc!)}',
                    Colors.green,
                  ),
                if (assignment.mucGia != null)
                  _buildInfoChip(
                    Icons.attach_money,
                    '${NumberFormat('#,###').format(assignment.mucGia)}đ/buổi',
                    const Color(0xFFFF9800),
                  ),
              ],
            ),

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showEditSessionDialog(context, assignment, controller),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Cập nhật buổi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9800),
                      side: const BorderSide(color: Color(0xFFFF9800)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showCompleteDialog(context, assignment, controller),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Hoàn thành'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có phân công nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để phân công PT cho học viên',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ============ DIALOGS ============

  void _showAddAssignmentDialog(
    BuildContext context,
    TrainerManagementController controller,
  ) {
    final trainerIdController = TextEditingController();
    final userIdController = TextEditingController();
    final trainerNameController = TextEditingController();
    final userNameController = TextEditingController();
    final sessionsController = TextEditingController(text: '10');
    final priceController = TextEditingController(text: '200000');

    Get.dialog(
      AlertDialog(
        title: const Text('Phân Công PT'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: trainerNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên PT *',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trainerIdController,
                decoration: const InputDecoration(
                  labelText: 'ID PT *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: 'Firestore document ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên học viên *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'ID học viên *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: 'Firestore document ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sessionsController,
                decoration: const InputDecoration(
                  labelText: 'Số buổi đăng ký',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá mỗi buổi (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (trainerIdController.text.isEmpty ||
                  userIdController.text.isEmpty ||
                  trainerNameController.text.isEmpty ||
                  userNameController.text.isEmpty) {
                Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ thông tin');
                return;
              }

              controller.assignTrainerToUser(
                trainerId: trainerIdController.text.trim(),
                userId: userIdController.text.trim(),
                trainerName: trainerNameController.text.trim(),
                userName: userNameController.text.trim(),
                soBuoi: int.tryParse(sessionsController.text) ?? 10,
                mucGia: double.tryParse(priceController.text) ?? 200000,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: const Text('Phân công'),
          ),
        ],
      ),
    );
  }

  void _showEditSessionDialog(
    BuildContext context,
    TrainerAssignment assignment,
    TrainerManagementController controller,
  ) {
    final sessionsController = TextEditingController(
      text: assignment.soBuoiHoanThanh.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Cập nhật buổi tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${assignment.trainerName} → ${assignment.userName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sessionsController,
              decoration: InputDecoration(
                labelText: 'Số buổi đã hoàn thành',
                prefixIcon: const Icon(Icons.event_available),
                border: const OutlineInputBorder(),
                helperText: 'Tối đa: ${assignment.soBuoiDangKy} buổi',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final newSessions = int.tryParse(sessionsController.text) ?? 0;
              if (newSessions > assignment.soBuoiDangKy) {
                Get.snackbar('Lỗi', 'Số buổi vượt quá số đăng ký');
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('trainer_assignments')
                    .doc(assignment.id)
                    .update({
                      'soBuoiHoanThanh': newSessions,
                      'updatedAt': Timestamp.now(),
                    });
                Get.back();
                Get.snackbar('Thành công', 'Đã cập nhật buổi tập');
                controller.loadAssignments();
              } catch (e) {
                Get.snackbar('Lỗi', 'Không thể cập nhật: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    TrainerAssignment assignment,
    TrainerManagementController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hoàn thành phân công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác nhận hoàn thành phân công này?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${assignment.trainerName} → ${assignment.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã hoàn thành: ${assignment.soBuoiHoanThanh}/${assignment.soBuoiDangKy} buổi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('trainer_assignments')
                    .doc(assignment.id)
                    .update({
                      'trangThai': 'completed',
                      'ngayKetThuc': Timestamp.now(),
                      'updatedAt': Timestamp.now(),
                    });
                Get.back();
                Get.snackbar('Thành công', 'Đã hoàn thành phân công');
                controller.loadAssignments();
              } catch (e) {
                Get.snackbar('Lỗi', 'Không thể cập nhật: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }
}
