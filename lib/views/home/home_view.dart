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
        title: const Text('Gym Pro'),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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

          // Quick Actions
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
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                icon: Icons.fitness_center,
                title: 'Bắt Đầu Tập',
                subtitle: 'Bắt đầu buổi tập',
                color: Colors.orange,
                onTap: () {
                  Get.snackbar(
                    'Sắp Ra Mắt',
                    'Tính năng tập luyện sẽ sớm có sẵn!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.timeline,
                title: 'Tiến Trình',
                subtitle: 'Theo dõi kết quả',
                color: Colors.green,
                onTap: () {
                  Get.snackbar(
                    'Sắp Ra Mắt',
                    'Theo dõi tiến trình sẽ sớm có sẵn!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.restaurant_menu,
                title: 'Dinh Dưỡng',
                subtitle: 'Lập kế hoạch bữa ăn',
                color: Colors.purple,
                onTap: () {
                  Get.snackbar(
                    'Sắp Ra Mắt',
                    'Theo dõi dinh dưỡng sẽ sớm có sẵn!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'Lịch Trình',
                subtitle: 'Lập kế hoạch tập',
                color: Colors.teal,
                onTap: () {
                  Get.snackbar(
                    'Sắp Ra Mắt',
                    'Lập lịch tập luyện sẽ sớm có sẵn!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Không có hoạt động gần đây',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bắt đầu buổi tập đầu tiên để xem hoạt động tại đây',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
