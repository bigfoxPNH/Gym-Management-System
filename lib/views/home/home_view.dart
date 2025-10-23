import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final user = authController.userAccount;
          return Row(
            children: [
              const Text('Gym Pro'),
              if (user != null && user.isAdmin) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Obx(
        () => authController.userAccount != null
            ? _buildHomeContent(context, authController)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    AuthController authController,
  ) {
    final user = authController.userAccount!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF90CAF9), const Color(0xFF81C784)]
                    : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF90CAF9)
                              : const Color(0xFF2196F3))
                          .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng trở lại,',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sẵn sàng cho buổi tập hôm nay chưa?',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Admin Features (chỉ hiển thị cho admin)
          if (user.isAdmin) ...[
            Text(
              'Quản Trị Viên',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildAdminActionCard(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Quản Lý Bài Tập',
                  subtitle: 'Tạo & chỉnh sửa động tác',
                  color: Colors.red,
                  onTap: () {
                    Get.toNamed('/admin/exercise-management');
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.card_membership,
                  title: 'Quản Lý Thẻ Tập',
                  subtitle: 'Ngày, tháng, năm...',
                  color: Colors.deepPurple,
                  onTap: () {
                    Get.toNamed('/admin/membership-card-management');
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.people,
                  title: 'Quản Lý Thành Viên',
                  subtitle: 'Xem & quản lý users',
                  color: Colors.indigo,
                  onTap: () {
                    Get.toNamed(AppRoutes.memberManagement);
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.schedule,
                  title: 'Quản Lý Lịch Trình',
                  subtitle: 'Tạo & quản lý lịch tập',
                  color: Colors.orange,
                  onTap: () {
                    Get.toNamed(AppRoutes.scheduleManagement);
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.check_circle,
                  title: 'Checkin/Checkout',
                  subtitle: 'Quản lý ra vào',
                  color: Colors.green,
                  onTap: () {
                    Get.toNamed(AppRoutes.checkinCheckout);
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Báo cáo & Thống kê',
                  subtitle: 'Thống kê chi tiết',
                  color: Colors.teal,
                  onTap: () {
                    Get.toNamed(AppRoutes.adminStatistics);
                  },
                ),
                _buildAdminActionCard(
                  context,
                  icon: Icons.article,
                  title: 'Quản Lý Bản Tin',
                  subtitle: 'Tạo & quản lý tin tức',
                  color: Colors.blue,
                  onTap: () {
                    Get.toNamed('/admin/news-management');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions (cho tất cả users)
          Text(
            'Thao Tác Nhanh',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _buildActionCard(
                context,
                icon: Icons.fitness_center,
                title: 'Kho Bài Tập',
                subtitle: 'Xem bài tập',
                color: Colors.orange,
                onTap: () {
                  Get.toNamed('/exercises');
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.card_membership,
                title: 'Thẻ Tập Của Tôi',
                subtitle: 'Xem chi tiết thẻ tập',
                color: Colors.green,
                onTap: () {
                  Get.toNamed(AppRoutes.myMembershipCards);
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.card_membership,
                title: 'Xuất Thẻ Tập',
                subtitle: 'Hiển thị thông tin thẻ',
                color: Colors.blue,
                onTap: () {
                  Get.toNamed(AppRoutes.membershipCardExport);
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'Lịch Trình',
                subtitle: 'Lập kế hoạch tập',
                color: Colors.teal,
                onTap: () {
                  Get.toNamed(AppRoutes.userScheduleSelection);
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.shopping_cart,
                title: 'Mua Thẻ Tập',
                subtitle: 'Mua thẻ thành viên',
                color: Colors.indigo,
                onTap: () {
                  Get.toNamed(AppRoutes.membershipPurchase);
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.article,
                title: 'Bảng Tin',
                subtitle: 'Tin tức & thông báo',
                color: Colors.cyan,
                onTap: () {
                  Get.toNamed(AppRoutes.newsFeed);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Hoạt Động Gần Đây',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D2D30)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: const Color(0xFF4A4A4A), width: 0.5)
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB0B0B0)
                      : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Không có hoạt động gần đây',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE8E8E8)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bắt đầu buổi tập đầu tiên để xem hoạt động tại đây',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB0B0B0)
                        : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFB0B0B0)
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFB0B0B0)
                    : Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'ADMIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
