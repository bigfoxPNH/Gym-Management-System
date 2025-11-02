import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../models/trainer_rental.dart';
import '../../widgets/review_trainer_dialog.dart';

/// Màn hình lịch sử thuê PT của user
class MyTrainerRentalsView extends StatefulWidget {
  const MyTrainerRentalsView({super.key});

  @override
  State<MyTrainerRentalsView> createState() => _MyTrainerRentalsViewState();
}

class _MyTrainerRentalsViewState extends State<MyTrainerRentalsView> {
  String selectedFilter = 'all';

  List<TrainerRental> _getFilteredRentals(List<TrainerRental> rentals) {
    if (selectedFilter == 'all') return rentals;
    if (selectedFilter == 'pending') {
      return rentals.where((r) => r.trangThai == 'pending').toList();
    }
    if (selectedFilter == 'active') {
      return rentals.where((r) => r.trangThai == 'active').toList();
    }
    if (selectedFilter == 'completed') {
      return rentals.where((r) => r.trangThai == 'completed').toList();
    }
    return rentals;
  }

  @override
  Widget build(BuildContext context) {
    // Khởi tạo hoặc lấy controller
    final controller = Get.put(TrainerRentalController(), permanent: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Thuê PT'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadMyRentals,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.myRentals.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredRentals = _getFilteredRentals(controller.myRentals);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats
              _buildStatsRow(controller),
              const SizedBox(height: 16),

              // Filter tabs
              _buildFilterTabs(),
              const SizedBox(height: 16),

              // List
              if (filteredRentals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Không có đơn thuê nào',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...filteredRentals.map(
                  (rental) => _buildRentalCard(context, rental, controller),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử thuê PT',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thuê PT để bắt đầu hành trình',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Tìm PT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(TrainerRentalController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng cộng',
            controller.totalRentals.toString(),
            Colors.blue,
            Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Đang tập',
            controller.activeRentals.toString(),
            Colors.green,
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hoàn thành',
            controller.completedRentals.toString(),
            Colors.orange,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tất cả', 'all', selectedFilter == 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Chờ duyệt', 'pending', selectedFilter == 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Đang tập', 'active', selectedFilter == 'active'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Hoàn thành',
            'completed',
            selectedFilter == 'completed',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.deepPurple.shade100,
      checkmarkColor: Colors.deepPurple,
    );
  }

  Widget _buildRentalCard(
    BuildContext context,
    TrainerRental rental,
    TrainerRentalController controller,
  ) {
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(context, rental, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rental.trainerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                rental.goiTapText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(rental.trangThai),
                      // Hiển thị thêm chip "Đang hoạt động" nếu đơn đang active
                      if (controller.isRentalActive(rental)) ...[
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
              const Divider(height: 24),

              // Info rows
              _buildInfoRow(
                Icons.calendar_today,
                'Thời gian',
                '${dateFormat.format(rental.startDate)} - ${dateFormat.format(rental.endDate)}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Số giờ', '${rental.soGio} giờ'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                'Tổng tiền',
                '${numberFormat.format(rental.tongTien)}đ',
                valueColor: Colors.deepPurple,
                valueBold: true,
              ),

              // Ghi chú
              if (rental.ghiChu != null && rental.ghiChu!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Ghi chú:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rental.ghiChu!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ],

              // Phản hồi từ PT
              if (rental.phanHoi != null && rental.phanHoi!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: Colors.deepPurple.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Phản hồi từ PT:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rental.phanHoi!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Lịch tập chi tiết
              if (rental.sessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 8, top: 8),
                  leading: Icon(
                    Icons.calendar_month,
                    color: Colors.deepPurple.shade700,
                  ),
                  title: Text(
                    'Lịch tập chi tiết (${rental.sessions.length} buổi)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    ...rental.sessions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Buổi ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildSessionStatusChip(session.trangThai),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy (EEEE)',
                                      'vi',
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
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${session.gioBatDau} - ${session.gioKetThuc}',
                                    style: const TextStyle(fontSize: 13),
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
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        session.diaDiem!,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (session.ghiChu != null &&
                                  session.ghiChu!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],

              // Actions
              if (rental.trangThai == 'pending') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(rental.id, controller),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Hủy yêu cầu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],

              // Nút đánh giá cho đơn hoàn thành
              if (rental.trangThai == 'completed') ...[
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: controller.canReviewTrainer(rental.trainerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final canReview = snapshot.data ?? false;
                    if (!canReview) return const SizedBox.shrink();

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showReviewDialog(context, rental, controller),
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Đánh giá PT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case 'approved':
        color = Colors.blue;
        text = 'Đã duyệt';
        break;
      case 'active':
        color = Colors.green;
        text = 'Đang tập';
        break;
      case 'completed':
        color = Colors.grey;
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _confirmCancel(String rentalId, TrainerRentalController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu thuê PT này?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Không')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelRental(rentalId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    TrainerRental rental,
    TrainerRentalController controller,
  ) {
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateDayFormat = DateFormat('dd/MM/yyyy');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chi tiết đơn thuê',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Trạng thái
                    _buildDetailRow(
                      'Trạng thái',
                      '',
                      trailing: _buildStatusChip(rental.trangThai),
                    ),
                    const Divider(height: 24),

                    // PT
                    _buildDetailRow('Huấn luyện viên', rental.trainerName),
                    const SizedBox(height: 12),

                    // Gói tập
                    _buildDetailRow('Gói tập', rental.goiTapText),
                    const SizedBox(height: 12),

                    // Thời gian
                    _buildDetailRow(
                      'Thời gian',
                      '${dateDayFormat.format(rental.startDate)} - ${dateDayFormat.format(rental.endDate)}',
                    ),
                    const SizedBox(height: 12),

                    // Số giờ
                    _buildDetailRow('Tổng số giờ', '${rental.soGio} giờ'),
                    const SizedBox(height: 12),

                    // Tổng tiền
                    _buildDetailRow(
                      'Tổng tiền',
                      '${numberFormat.format(rental.tongTien)}đ',
                      valueColor: Colors.deepPurple,
                      valueBold: true,
                    ),
                    const Divider(height: 24),

                    // Lịch các buổi tập
                    if (rental.sessions.isNotEmpty) ...[
                      const Text(
                        'Lịch các buổi tập:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...rental.sessions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final session = entry.value;
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: index < rental.sessions.length - 1 ? 12 : 0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getSessionColor(
                              session.trangThai,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getSessionColor(
                                session.trangThai,
                              ).withOpacity(0.3),
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
                                      color: Colors.deepPurple,
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
                                      color: _getSessionColor(
                                        session.trangThai,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getSessionLabel(session.trangThai),
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
                                    dateDayFormat.format(session.ngay),
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
                                    style: const TextStyle(fontSize: 13),
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
                                        style: const TextStyle(fontSize: 13),
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
                                    borderRadius: BorderRadius.circular(6),
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
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
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
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Chưa có lịch tập cụ thể',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Thời gian đặt
                    _buildDetailRow(
                      'Thời gian đặt',
                      dateFormat.format(rental.createdAt),
                    ),

                    // Ghi chú
                    if (rental.ghiChu != null && rental.ghiChu!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Ghi chú:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rental.ghiChu!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],

                    // Phản hồi từ PT
                    if (rental.phanHoi != null &&
                        rental.phanHoi!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Phản hồi từ PT:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Text(
                          rental.phanHoi!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.deepPurple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (rental.trangThai == 'pending')
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        _confirmCancel(rental.id, controller);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy yêu cầu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Widget? trailing,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          flex: 3,
          child:
              trailing ??
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
        ),
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    TrainerRental rental,
    TrainerRentalController controller,
  ) {
    // Import ReviewTrainerDialog
    Get.dialog(
      ReviewTrainerDialog(
        trainerId: rental.trainerId,
        trainerName: rental.trainerName,
        onSubmit: (rating, comment, tags) async {
          await controller.submitReview(
            trainerId: rental.trainerId,
            trainerName: rental.trainerName,
            rating: rating,
            comment: comment,
            tags: tags,
          );
          // Reload để cập nhật UI
          await controller.loadMyRentals();
        },
      ),
    );
  }

  Widget _buildSessionStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'scheduled':
        color = Colors.blue;
        text = 'Đã lên lịch';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSessionColor(String status) {
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

  String _getSessionLabel(String status) {
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
