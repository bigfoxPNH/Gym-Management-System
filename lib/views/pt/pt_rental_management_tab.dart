import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/trainer_rental.dart';
import '../../controllers/pt_controller.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../widgets/loading_overlay.dart';

/// Tab quản lý đơn thuê PT trong PT Dashboard
class PTRentalManagementTab extends StatefulWidget {
  const PTRentalManagementTab({super.key});

  @override
  State<PTRentalManagementTab> createState() => _PTRentalManagementTabState();
}

class _PTRentalManagementTabState extends State<PTRentalManagementTab> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = Get.find<PTController>();
  TrainerRentalController? _rentalController;

  List<TrainerRental> _rentals = [];
  bool _isLoading = false;
  String _selectedStatus =
      'all'; // all, pending, approved, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    // Khởi tạo hoặc lấy TrainerRentalController
    try {
      _rentalController = Get.find<TrainerRentalController>();
    } catch (e) {
      _rentalController = Get.put(TrainerRentalController());
    }
    _loadRentals();
  }

  /// Helper method để kiểm tra xem rental có đang active không
  bool _isRentalActive(TrainerRental rental) {
    if (_rentalController == null) return false;
    return _rentalController!.isRentalActive(rental);
  }

  Future<void> _loadRentals() async {
    if (_controller.trainerProfile == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Query rentals where trainerId = trainer document ID
      Query query = _firestore
          .collection('trainer_rentals')
          .where('trainerId', isEqualTo: _controller.trainerProfile!.id)
          .orderBy('createdAt', descending: true);

      // Filter by status if not 'all'
      if (_selectedStatus != 'all') {
        query = query.where('trangThai', isEqualTo: _selectedStatus);
      }

      final snapshot = await query.get();

      if (!mounted) return;
      setState(() {
        _rentals = snapshot.docs
            .map((doc) => TrainerRental.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải đơn thuê: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String?>> _getUserContactInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return {
          'email': data?['email'] as String?,
          'phone': data?['soDienThoai'] as String? ?? data?['phone'] as String?,
        };
      }
    } catch (e) {
      print('Error loading user contact info: $e');
    }
    return {'email': null, 'phone': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn thuê PT'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Filter
          _buildStatusFilter(),

          // Rentals List
          Expanded(
            child: _isLoading
                ? const CenterLoading(message: 'Đang tải...')
                : _rentals.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadRentals,
                    color: const Color(0xFFFF9800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rentals.length,
                      itemBuilder: (context, index) {
                        return _buildRentalCard(_rentals[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 'all', _rentals.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Chờ duyệt',
              'pending',
              _rentals.where((r) => r.trangThai == 'pending').length,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Đã duyệt',
              'approved',
              _rentals.where((r) => r.trangThai == 'approved').length,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Đang hoạt động',
              'active',
              _rentals.where((r) => r.trangThai == 'active').length,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Hoàn thành',
              'completed',
              _rentals.where((r) => r.trangThai == 'completed').length,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Đã hủy',
              'cancelled',
              _rentals.where((r) => r.trangThai == 'cancelled').length,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    int count, {
    Color? color,
  }) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && mounted) {
          setState(() => _selectedStatus = value);
          _loadRentals();
        }
      },
      selectedColor: (color ?? const Color(0xFFFF9800)).withOpacity(0.2),
      checkmarkColor: color ?? const Color(0xFFFF9800),
      labelStyle: TextStyle(
        color: isSelected
            ? (color ?? const Color(0xFFFF9800))
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn thuê nào',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Các đơn thuê sẽ hiển thị tại đây',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(TrainerRental rental) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRentalDetail(rental),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User info & Status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
                    child: Text(
                      rental.userName.isNotEmpty ? rental.userName[0] : 'U',
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Đơn #${rental.id.substring(0, 8)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(rental.trangThai),
                      // Hiển thị thêm chip "Đang hoạt động" nếu đơn đang active
                      if (_isRentalActive(rental)) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.cyan,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Đang hoạt động',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rental details
              _buildDetailRow(
                Icons.calendar_today,
                'Thời gian',
                '${DateFormat('dd/MM/yyyy').format(rental.startDate)} - ${DateFormat('dd/MM/yyyy').format(rental.endDate)}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.access_time,
                'Số giờ',
                '${rental.soGio} giờ',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.fitness_center,
                'Gói tập',
                _getPackageLabel(rental.goiTap),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.attach_money,
                'Tổng tiền',
                NumberFormat.currency(
                  locale: 'vi',
                  symbol: 'đ',
                ).format(rental.tongTien),
                valueColor: const Color(0xFFFF9800),
              ),

              if (rental.ghiChu != null && rental.ghiChu!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rental.ghiChu!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (rental.trangThai == 'pending') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRental(rental),
                        icon: const Icon(Icons.close),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRental(rental),
                        icon: const Icon(Icons.check),
                        label: const Text('Chấp nhận'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (rental.trangThai == 'approved' ||
                  rental.trangThai == 'active') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Nút "Hoàn thành" chỉ hiện khi đơn đang active
                    if (_isRentalActive(rental)) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completeRental(rental),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Hoàn thành'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Nút "Liên hệ học viên"
                    Expanded(
                      flex: _isRentalActive(rental) ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _contactUser(rental),
                        icon: const Icon(Icons.phone),
                        label: const Text('Liên hệ học viên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'approved':
        color = Colors.blue;
        label = 'Đã duyệt';
        break;
      case 'active':
        color = Colors.green;
        label = 'Hoạt động';
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'expired':
        color = Colors.brown;
        label = 'Hết hạn';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getPackageLabel(String goiTap) {
    switch (goiTap) {
      case 'personal':
        return 'Cá nhân (1-1)';
      case 'group':
        return 'Nhóm nhỏ';
      case 'online':
        return 'Online';
      default:
        return goiTap;
    }
  }

  void _showRentalDetail(TrainerRental rental) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.7,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Chi tiết đơn thuê PT',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đơn #${rental.id}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),

                        // Status
                        _buildDetailSection(
                          'Trạng thái',
                          _buildStatusBadge(rental.trangThai),
                        ),
                        const Divider(height: 32),

                        // User info
                        _buildDetailSection(
                          'Thông tin học viên',
                          FutureBuilder<Map<String, String?>>(
                            future: _getUserContactInfo(rental.userId),
                            builder: (context, snapshot) {
                              final email = snapshot.data?['email'];
                              final phone = snapshot.data?['phone'];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(
                                          0xFFFF9800,
                                        ).withOpacity(0.2),
                                        child: Text(
                                          rental.userName.isNotEmpty
                                              ? rental.userName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF9800),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rental.userName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${rental.userId.substring(0, 8)}...',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (email != null || phone != null) ...[
                                    const SizedBox(height: 16),
                                    if (phone != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            phone,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (email != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const Divider(height: 32),

                        // Rental details
                        _buildDetailSection(
                          'Thông tin thuê',
                          Column(
                            children: [
                              _buildInfoRow(
                                'Ngày bắt đầu',
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(rental.startDate),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Ngày kết thúc',
                                DateFormat('dd/MM/yyyy').format(rental.endDate),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Số giờ', '${rental.soGio} giờ'),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Gói tập',
                                _getPackageLabel(rental.goiTap),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Tổng tiền',
                                NumberFormat.currency(
                                  locale: 'vi',
                                  symbol: 'đ',
                                ).format(rental.tongTien),
                                valueColor: const Color(0xFFFF9800),
                              ),
                            ],
                          ),
                        ),

                        // Sessions (Lịch các buổi tập)
                        const Divider(height: 32),
                        _buildDetailSection(
                          rental.sessions.isNotEmpty
                              ? 'Lịch các buổi tập (${rental.sessions.length} buổi)'
                              : 'Lịch các buổi tập',
                          rental.sessions.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange[200]!,
                                    ),
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
                                          'Chưa có lịch tập cụ thể. Hãy liên hệ với học viên để sắp xếp lịch tập sau khi chấp nhận đơn.',
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: rental.sessions.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final session = entry.value;
                                    return Container(
                                      margin: EdgeInsets.only(
                                        bottom:
                                            index < rental.sessions.length - 1
                                            ? 12
                                            : 0,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getSessionStatusColor(
                                          session.trangThai,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getSessionStatusColor(
                                            session.trangThai,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFF9800,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getSessionStatusColor(
                                                    session.trangThai,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _getSessionStatusLabel(
                                                    session.trangThai,
                                                  ),
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
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(session.ngay),
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
                                                '${session.gioBatDau} - ${session.gioKetThuc}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (session.diaDiem != null &&
                                              session.diaDiem!.isNotEmpty) ...[
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
                                                    session.diaDiem!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (session.ghiChu != null &&
                                              session.ghiChu!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.note,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      session.ghiChu!,
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
                                  }).toList(),
                                ),
                        ),

                        if (rental.ghiChu != null &&
                            rental.ghiChu!.isNotEmpty) ...[
                          const Divider(height: 32),
                          _buildDetailSection(
                            'Ghi chú từ học viên',
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(rental.ghiChu!),
                            ),
                          ),
                        ],

                        if (rental.phanHoi != null &&
                            rental.phanHoi!.isNotEmpty) ...[
                          const Divider(height: 32),
                          _buildDetailSection(
                            'Phản hồi của bạn',
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                ),
                              ),
                              child: Text(rental.phanHoi!),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100), // Space for action buttons
                      ],
                    ),
                  ),
                ),

                // Action buttons (fixed at bottom)
                if (rental.trangThai == 'pending' ||
                    rental.trangThai == 'approved' ||
                    rental.trangThai == 'active')
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: rental.trangThai == 'pending'
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _rejectRental(rental);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Từ chối'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _approveRental(rental);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Chấp nhận'),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _contactUser(rental);
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Liên hệ học viên'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
        ),
      ],
    );
  }

  Future<void> _approveRental(TrainerRental rental) async {
    // Show response dialog
    final TextEditingController responseController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Chấp nhận đơn thuê'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn xác nhận chấp nhận đơn thuê từ ${rental.userName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Phản hồi (tùy chọn)',
                hintText: 'Nhập lời nhắn cho học viên...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('trainer_rentals').doc(rental.id).update({
        'trangThai': 'approved',
        'phanHoi': responseController.text.trim().isNotEmpty
            ? responseController.text.trim()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Thành công',
        'Đã chấp nhận đơn thuê',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _loadRentals();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _completeRental(TrainerRental rental) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hoàn thành đơn thuê'),
        content: Text(
          'Bạn xác nhận đã hoàn thành tất cả buổi tập với ${rental.userName}?\n\n'
          'Sau khi hoàn thành, học viên sẽ có thể đánh giá bạn.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_rentalController == null) {
      Get.snackbar('Lỗi', 'Không thể hoàn thành đơn');
      return;
    }

    final success = await _rentalController!.completeRental(rental.id);
    if (success) {
      _loadRentals();
    }
  }

  Future<void> _rejectRental(TrainerRental rental) async {
    // Show reason dialog
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Từ chối đơn thuê'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn xác nhận từ chối đơn thuê từ ${rental.userName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lưu ý',
                  'Vui lòng nhập lý do từ chối',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('trainer_rentals').doc(rental.id).update({
        'trangThai': 'cancelled',
        'phanHoi': reasonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Đã từ chối',
        'Đã từ chối đơn thuê',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      _loadRentals();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _contactUser(TrainerRental rental) async {
    // Show contact options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liên hệ ${rental.userName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.phone, color: Colors.white),
                ),
                title: const Text('Gọi điện'),
                subtitle: Text('Liên hệ trực tiếp với ${rental.userName}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Thông tin',
                    'Chức năng gọi điện sẽ được cập nhật sau',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.message, color: Colors.white),
                ),
                title: const Text('Nhắn tin'),
                subtitle: Text('Gửi tin nhắn cho ${rental.userName}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Thông tin',
                    'Chức năng nhắn tin sẽ được cập nhật sau',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Color _getSessionStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getSessionStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
