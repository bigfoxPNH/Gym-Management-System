import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/pt_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/loading_overlay.dart';

/// Dashboard dành cho Personal Trainer (PT)
class PTDashboardView extends StatelessWidget {
  const PTDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PTController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, size: 24),
            SizedBox(width: 8),
            Text('PT Dashboard'),
          ],
        ),
        backgroundColor: const Color(0xFFFF9800), // Orange theme for PT
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: const Icon(Icons.person),
            tooltip: 'Hồ sơ',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.trainerProfile == null) {
          return const CenterLoading(message: 'Đang tải...');
        }

        if (controller.trainerProfile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy hồ sơ PT',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng liên hệ quản trị viên',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          color: const Color(0xFFFF9800),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                _buildWelcomeCard(context, controller, authController),
                const SizedBox(height: 24),

                // Stats Grid
                _buildStatsGrid(context, controller),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context, controller),
                const SizedBox(height: 24),

                // Active Assignments
                _buildActiveAssignments(context, controller),
                const SizedBox(height: 24),

                // Recent Reviews
                _buildRecentReviews(context, controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    PTController controller,
    AuthController authController,
  ) {
    final trainer = controller.trainerProfile!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: trainer.anhDaiDien != null
                    ? NetworkImage(trainer.anhDaiDien!)
                    : null,
                child: trainer.anhDaiDien == null
                    ? const Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: Color(0xFFFF9800),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào,',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainer.hoTen,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      controller.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWelcomeCardStat(
                  'Học viên',
                  '${controller.activeClients}',
                ),
                _buildWelcomeCardStat(
                  'Buổi tập',
                  '${controller.completedSessions}',
                ),
                _buildWelcomeCardStat(
                  'Hoàn thành',
                  '${controller.completionRate.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCardStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, PTController controller) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Tổng học viên',
          '${controller.totalClients}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Đánh giá',
          '${controller.totalReviews}',
          Icons.reviews,
          Colors.purple,
        ),
        _buildStatCard(
          context,
          'Tổng buổi tập',
          '${controller.totalSessions}',
          Icons.calendar_today,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Doanh thu',
          _formatCurrency(controller.totalRevenue),
          Icons.attach_money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, PTController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Học viên của tôi',
                Icons.people_alt,
                Colors.blue,
                () {
                  // TODO: Navigate to my clients view
                  Get.snackbar('Thông báo', 'Tính năng đang phát triển');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Lịch tập',
                Icons.calendar_month,
                Colors.green,
                () {
                  // TODO: Navigate to schedule view
                  Get.snackbar('Thông báo', 'Tính năng đang phát triển');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Thống kê',
                Icons.bar_chart,
                Colors.purple,
                () {
                  // TODO: Navigate to stats view
                  Get.snackbar('Thông báo', 'Tính năng đang phát triển');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Hồ sơ',
                Icons.person,
                Colors.orange,
                () => Get.toNamed(AppRoutes.profile),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAssignments(
    BuildContext context,
    PTController controller,
  ) {
    final activeAssignments = controller.activeAssignments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Học viên đang tập (${activeAssignments.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (activeAssignments.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Show all assignments
                  Get.snackbar('Thông báo', 'Tính năng đang phát triển');
                },
                child: const Text('Xem tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeAssignments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có học viên nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...activeAssignments.take(3).map((assignment) {
            final progress =
                assignment.soBuoiHoanThanh / assignment.soBuoiDangKy;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFFFF9800,
                        ).withOpacity(0.1),
                        child: Text(
                          assignment.userName[0].toUpperCase(),
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
                              assignment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(assignment.ngayBatDau)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến độ: ${assignment.soBuoiHoanThanh}/${assignment.soBuoiDangKy} buổi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (assignment.mucGia != null)
                            Text(
                              _formatCurrency(assignment.mucGia!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF9800),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF9800),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showUpdateSessionDialog(
                              context,
                              controller,
                              assignment,
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Cập nhật'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF9800),
                            side: const BorderSide(color: Color(0xFFFF9800)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showCompleteDialog(
                              context,
                              controller,
                              assignment,
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Hoàn thành'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRecentReviews(BuildContext context, PTController controller) {
    final reviews = controller.recentReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá gần đây',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.star_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...reviews.map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          review.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blue,
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
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(review.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      review.comment!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  if (review.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: review.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: const Color(
                            0xFFFF9800,
                          ).withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 11,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showUpdateSessionDialog(
    BuildContext context,
    PTController controller,
    assignment,
  ) {
    final textController = TextEditingController(
      text: assignment.soBuoiHoanThanh.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Cập nhật buổi tập'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Số buổi đã hoàn thành',
            hintText: 'Nhập số buổi (max: ${assignment.soBuoiDangKy})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final newCount = int.tryParse(textController.text);
              if (newCount == null) {
                Get.snackbar('Lỗi', 'Vui lòng nhập số hợp lệ');
                return;
              }
              if (newCount > assignment.soBuoiDangKy) {
                Get.snackbar(
                  'Lỗi',
                  'Số buổi không được vượt quá ${assignment.soBuoiDangKy}',
                );
                return;
              }
              Get.back();
              controller.updateSessionCount(assignment.id, newCount);
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
    PTController controller,
    assignment,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hoàn thành phân công'),
        content: const Text(
          'Bạn có chắc muốn đánh dấu phân công này là hoàn thành?\n\n'
          'Số buổi tập sẽ được cập nhật thành số buổi đăng ký.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.completeAssignment(assignment.id);
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    if (amount >= 1000000) {
      return '${formatter.format(amount / 1000000)}M';
    } else if (amount >= 1000) {
      return '${formatter.format(amount / 1000)}K';
    }
    return formatter.format(amount);
  }
}
