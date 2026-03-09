import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../routes/app_routes.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionTitle('Giao Diện', Icons.palette),
          _buildThemeSelector(themeController),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionTitle('Thông Báo', Icons.notifications),
          _buildNotificationSettings(),
          const SizedBox(height: 24),

          // App Updates Section
          _buildSectionTitle('Cập Nhật Ứng Dụng', Icons.system_update),
          _buildUpdateSettings(),
          const SizedBox(height: 24),

          // Contact Support Section
          _buildSectionTitle('Liên Hệ Hỗ Trợ', Icons.contact_support),
          _buildContactSupport(),
          const SizedBox(height: 24),

          // Account Actions
          _buildSectionTitle('Cài Đặt Tài Khoản', Icons.account_circle),
          _buildAccountActions(authController),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeController themeController) {
    return Card(
      child: Column(
        children: [
          Obx(
            () => ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.orange),
              title: const Text('Chế Độ Sáng'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeController.changeTheme(value);
                  }
                },
              ),
            ),
          ),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.grey),
              title: const Text('Chế Độ Tối'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeController.changeTheme(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Thông Báo Đẩy'),
            subtitle: const Text('Nhận nhắc nhở tập luyện và cập nhật'),
            value: true, // You can implement notification controller
            onChanged: (value) => _showComingSoonSnackBar(),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Thông Báo Email'),
            subtitle: const Text('Nhận báo cáo tiến độ hàng tuần'),
            value: false,
            onChanged: (value) => _showComingSoonSnackBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSettings() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.update, color: Colors.green),
        title: const Text('Kiểm Tra Cập Nhật'),
        subtitle: const Text('Phiên bản 1.0.0 - Mới nhất'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showComingSoonSnackBar(),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.facebook, color: Colors.white, size: 16),
            ),
            title: const Text('Facebook'),
            subtitle: const Text('Theo dõi chúng tôi trên Facebook'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('https://www.facebook.com/pqtrung72/'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0068FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'Z',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: const Text('Zalo'),
            subtitle: const Text('Chat với chúng tôi trên Zalo'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('https://zalo.me/0326658276'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('Địa Chỉ'),
            subtitle: const Text('Gym Pro - Nhấn để xem vị trí trên bản đồ'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () =>
                _launchUrl('https://maps.app.goo.gl/JavEQA2nVqxE6mry5'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(AuthController authController) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF2196F3)),
            title: const Text('Hồ Sơ'),
            subtitle: const Text('Chỉnh Sửa Hồ Sơ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(AppRoutes.profile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text('Chính Sách Bảo Mật'),
            subtitle: const Text('Xem chính sách bảo mật đầy đủ của chúng tôi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng Xuất'),
            subtitle: const Text('Đăng xuất khỏi tài khoản của bạn'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSignOutDialog(authController),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Đăng Xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('Xác Nhận'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar() {
    Get.snackbar(
      'Sắp Ra Mắt',
      'Tính năng này sẽ có sẵn trong bản cập nhật tương lai.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2196F3),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      Get.snackbar(
        'Lỗi',
        'Không thể mở liên kết',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
