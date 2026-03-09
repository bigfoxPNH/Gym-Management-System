import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../models/trainer.dart';
import 'trainer_detail_view.dart';
import 'trainer_form_view.dart';

class TrainerListTab extends StatelessWidget {
  const TrainerListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainerManagementController>();

    return Column(
      children: [
        // Search & Filter bar
        _buildSearchBar(controller),

        // Stats cards
        _buildStatsCards(controller),

        // Trainers list
        Expanded(
          child: Obx(() {
            if (controller.filteredTrainers.isEmpty) {
              return _buildEmptyState(controller);
            }

            return RefreshIndicator(
              onRefresh: controller.loadTrainers,
              color: const Color(0xFFFF9800),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredTrainers.length,
                itemBuilder: (context, index) {
                  final trainer = controller.filteredTrainers[index];
                  return _buildTrainerCard(context, trainer, controller);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar(TrainerManagementController controller) {
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
      child: Column(
        children: [
          TextField(
            onChanged: controller.updateSearchQuery,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm PT theo tên...',
              hintStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFFFF9800),
                size: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF9800),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8.5,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Status filter chips
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Tất cả',
                    'all',
                    controller.selectedStatus.value,
                    controller.updateStatusFilter,
                    Colors.grey,
                  ),
                  _buildFilterChip(
                    'Đang làm',
                    'active',
                    controller.selectedStatus.value,
                    controller.updateStatusFilter,
                    Colors.green,
                  ),
                  _buildFilterChip(
                    'Không hoạt động',
                    'inactive',
                    controller.selectedStatus.value,
                    controller.updateStatusFilter,
                    Colors.grey,
                  ),
                  _buildFilterChip(
                    'Tạm ngưng',
                    'suspended',
                    controller.selectedStatus.value,
                    controller.updateStatusFilter,
                    Colors.orange,
                  ),
                  _buildFilterChip(
                    'Nghỉ phép',
                    'on_leave',
                    controller.selectedStatus.value,
                    controller.updateStatusFilter,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onTap,
    Color color,
  ) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(value),
        backgroundColor: Colors.grey[200],
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: TextStyle(
          fontSize: 9.5,
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatsCards(TrainerManagementController controller) {
    // Load tổng số buổi tập từ trainer_rentals
    controller.loadTotalSessionsFromRentals();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng PT',
                controller.totalTrainers.value.toString(),
                Icons.fitness_center,
                const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Đang hoạt động',
                controller.activeTrainers.value.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Buổi tập',
                controller.totalSessionsFromRentals.value.toString(),
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(
    BuildContext context,
    Trainer trainer,
    TrainerManagementController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Get.to(() => TrainerDetailView(trainer: trainer)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                    backgroundImage: trainer.anhDaiDien != null
                        ? NetworkImage(trainer.anhDaiDien!)
                        : null,
                    child: trainer.anhDaiDien == null
                        ? const Icon(
                            Icons.person,
                            size: 24,
                            color: Color(0xFFFF9800),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trainer.hoTen,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusBadge(trainer.trangThai),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              trainer.soDienThoai ?? 'Chưa có SĐT',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Rating - Real-time từ reviews
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('trainer_reviews')
                              .where('trainerId', isEqualTo: trainer.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            double avgRating = 0.0;
                            int reviewCount = 0;

                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              reviewCount = snapshot.data!.docs.length;
                              final totalRating = snapshot.data!.docs.fold<int>(
                                0,
                                (sum, doc) =>
                                    sum +
                                    ((doc.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['rating']
                                            as int? ??
                                        0),
                              );
                              avgRating = totalRating / reviewCount;
                            }

                            return Row(
                              children: [
                                Icon(Icons.star, size: 11, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text(
                                  reviewCount > 0
                                      ? '${avgRating.toStringAsFixed(1)} ($reviewCount đánh giá)'
                                      : 'Chưa có đánh giá',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Get.to(() => TrainerFormView(trainer: trainer)),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                        side: const BorderSide(color: Color(0xFFFF9800)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Get.to(() => TrainerDetailView(trainer: trainer)),
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text(
                        'Chi tiết',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Hoạt động';
        break;
      case 'inactive':
        color = Colors.grey;
        text = 'Không hoạt động';
        break;
      case 'suspended':
        color = Colors.orange;
        text = 'Tạm ngưng';
        break;
      case 'on_leave':
        color = Colors.blue;
        text = 'Nghỉ phép';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(TrainerManagementController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isEmpty
                ? 'Chưa có PT nào'
                : 'Không tìm thấy PT',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isEmpty
                ? 'Nhấn nút + để thêm PT mới'
                : 'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
