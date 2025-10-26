import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../models/trainer.dart';
import '../../models/trainer_assignment.dart';
import '../../models/trainer_review.dart';
import 'trainer_form_view.dart';

/// Chi tiết thông tin PT
class TrainerDetailView extends StatelessWidget {
  final Trainer trainer;

  const TrainerDetailView({super.key, required this.trainer});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainerManagementController>();

    // Load assignments và reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAssignments(trainer.id);
      controller.loadReviews(trainer.id);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(trainer.hoTen),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.to(() => TrainerFormView(trainer: trainer)),
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với avatar và thông tin cơ bản
            _buildHeader(trainer),

            // Stats cards
            _buildStatsSection(controller, trainer.id),

            // Thông tin chi tiết
            _buildInfoSection(trainer),

            // Chuyên môn & Chứng chỉ
            _buildSkillsSection(trainer),

            // Danh sách học viên
            _buildAssignmentsSection(controller, trainer.id),

            // Đánh giá
            _buildReviewsSection(controller, trainer.id),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Trainer trainer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9800),
            const Color(0xFFFF9800).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: trainer.anhDaiDien != null
                      ? NetworkImage(trainer.anhDaiDien!)
                      : null,
                  child: trainer.anhDaiDien == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFFFF9800),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Tên
              Text(
                trainer.hoTen,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < trainer.danhGiaTrungBinh.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${trainer.danhGiaTrungBinh.toStringAsFixed(1)} (${trainer.soLuotDanhGia} đánh giá)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(trainer.trangThai),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trainer.trangThaiText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    TrainerManagementController controller,
    String trainerId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final assignments = controller.getAssignmentsForTrainer(trainerId);
        final activeAssignments = assignments
            .where((a) => a.trangThai == 'active')
            .length;
        final totalSessions = controller.getTotalSessionsForTrainer(trainerId);
        final reviews = controller.getReviewsForTrainer(trainerId);

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Học viên',
                activeAssignments.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Buổi tập',
                totalSessions.toString(),
                Icons.fitness_center,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Đánh giá',
                reviews.length.toString(),
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        );
      }),
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
        children: [
          Icon(icon, color: color, size: 32),
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

  Widget _buildInfoSection(Trainer trainer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Thông tin cơ bản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.phone,
              'Điện thoại',
              trainer.soDienThoai ?? 'N/A',
            ),
            _buildInfoRow(Icons.email, 'Email', trainer.email ?? 'N/A'),
            _buildInfoRow(
              Icons.cake,
              'Tuổi',
              trainer.namSinh != null
                  ? '${trainer.tuoi} (${DateFormat('dd/MM/yyyy').format(trainer.namSinh!)})'
                  : 'N/A',
            ),
            _buildInfoRow(
              Icons.person,
              'Giới tính',
              trainer.gioiTinh == 'male' || trainer.gioiTinh == 'Nam'
                  ? 'Nam'
                  : 'Nữ',
            ),
            if (trainer.diaChi != null && trainer.diaChi!.isNotEmpty)
              _buildInfoRow(Icons.location_on, 'Địa chỉ', trainer.diaChi!),

            const Divider(height: 24),

            _buildInfoRow(
              Icons.attach_money,
              'Lương cơ bản',
              '${NumberFormat('#,###').format(trainer.mucLuongCoBan)}đ/tháng',
            ),
            _buildInfoRow(
              Icons.trending_up,
              'Hoa hồng',
              '${trainer.hoaHongPhanTram}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(Trainer trainer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Chuyên môn & Chứng chỉ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chuyên môn
            if (trainer.chuyenMon.isNotEmpty) ...[
              Text(
                'Chuyên môn:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trainer.chuyenMon.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Bằng cấp
            if (trainer.bangCap.isNotEmpty) ...[
              Text(
                'Bằng cấp:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...trainer.bangCap.map(
                (degree) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(degree)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Chứng chỉ
            if (trainer.chungChi.isNotEmpty) ...[
              Text(
                'Chứng chỉ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...trainer.chungChi.map(
                (cert) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cert)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsSection(
    TrainerManagementController controller,
    String trainerId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Học viên được phân công',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() {
              final assignments = controller
                  .getAssignmentsForTrainer(trainerId)
                  .where((a) => a.trangThai == 'active')
                  .toList();

              if (assignments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Chưa có học viên nào',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return _buildAssignmentCard(assignment);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(TrainerAssignment assignment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFFF9800),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${assignment.userId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${assignment.soBuoiHoanThanh}/${assignment.soBuoiDangKy} buổi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: assignment.tienDoPercent / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          assignment.tienDoPercent >= 100
                              ? Colors.green
                              : const Color(0xFFFF9800),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
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
                DateFormat('dd/MM/yyyy').format(assignment.ngayBatDau),
                Colors.blue,
              ),
              if (assignment.mucGia != null)
                _buildInfoChip(
                  Icons.attach_money,
                  '${NumberFormat('#,###').format(assignment.mucGia)}đ',
                  Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
    TrainerManagementController controller,
    String trainerId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rate_review, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Đánh giá từ học viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() {
              final reviews = controller.getReviewsForTrainer(trainerId);

              if (reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Chưa có đánh giá nào',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(review);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(TrainerReview review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFF9800),
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),

          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],

          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: review.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.orange;
      case 'on_leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
