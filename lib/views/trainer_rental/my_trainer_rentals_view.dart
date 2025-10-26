import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../models/trainer_rental.dart';

/// Màn hình lịch sử thuê PT của user
class MyTrainerRentalsView extends StatelessWidget {
  const MyTrainerRentalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainerRentalController>();

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
              ...controller.myRentals.map(
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
          _buildFilterChip('Tất cả', true),
          const SizedBox(width: 8),
          _buildFilterChip('Chờ duyệt', false),
          const SizedBox(width: 8),
          _buildFilterChip('Đang tập', false),
          const SizedBox(width: 8),
          _buildFilterChip('Hoàn thành', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filter logic
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
                _buildStatusChip(rental.trangThai),
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
}
