import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm PT theo tên...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFFF9800),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: () => Get.to(() => const TrainerFormView()),
                backgroundColor: const Color(0xFFFF9800),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
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
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(value),
        backgroundColor: Colors.grey[200],
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatsCards(TrainerManagementController controller) {
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
                controller.totalSessions.value.toString(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Get.to(() => TrainerDetailView(trainer: trainer)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                    backgroundImage: trainer.anhDaiDien != null
                        ? NetworkImage(trainer.anhDaiDien!)
                        : null,
                    child: trainer.anhDaiDien == null
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: Color(0xFFFF9800),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusBadge(trainer.trangThai),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trainer.soDienThoai ?? 'Chưa có SĐT',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${trainer.danhGiaTrungBinh.toStringAsFixed(1)} (${trainer.soLuotDanhGia} đánh giá)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Specialties
              if (trainer.chuyenMon.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: trainer.chuyenMon.take(3).map((specialty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF9800).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Stats row
              const SizedBox(height: 12),
              Obx(() {
                final assignments = controller.getAssignmentsForTrainer(
                  trainer.id,
                );
                final activeSessions = assignments
                    .where((a) => a.trangThai == 'active')
                    .length;
                final totalSessions = controller.getTotalSessionsForTrainer(
                  trainer.id,
                );

                return Row(
                  children: [
                    _buildInfoChip(
                      Icons.people,
                      '$activeSessions học viên',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.event_available,
                      '$totalSessions buổi',
                      Colors.green,
                    ),
                  ],
                );
              }),

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Get.to(() => TrainerFormView(trainer: trainer)),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Sửa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                        side: const BorderSide(color: Color(0xFFFF9800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Get.to(() => TrainerDetailView(trainer: trainer)),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Chi tiết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
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
