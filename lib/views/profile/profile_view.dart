import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../models/user_account.dart';
import '../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.editProfile),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Obx(
        () => authController.userAccount != null
            ? _buildProfileContent(context, authController)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    AuthController authController,
  ) {
    final user = authController.userAccount!;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            color: const Color(0xFF2196F3),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? _getImageProvider(user.avatarUrl!)
                      : null,
                  backgroundColor: Colors.white,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF2196F3),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Profile Information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông Tin Tài Khoản',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'Họ và Tên',
                  subtitle: user.fullName,
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  context,
                  icon: Icons.alternate_email,
                  title: 'Tên Đăng Nhập',
                  subtitle: user.username,
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Địa Chỉ Email',
                  subtitle: user.email,
                ),
                const SizedBox(height: 12),

                if (user.phone != null && user.phone!.isNotEmpty)
                  _buildInfoCard(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Số Điện Thoại',
                    subtitle: user.phone!,
                  ),
                if (user.phone != null && user.phone!.isNotEmpty)
                  const SizedBox(height: 12),

                if (user.address != null && user.address!.isNotEmpty)
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Địa Chỉ',
                    subtitle: user.address!,
                  ),
                if (user.address != null && user.address!.isNotEmpty)
                  const SizedBox(height: 12),

                if (user.gender != null)
                  _buildInfoCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'Giới Tính',
                    subtitle: _getGenderDisplayName(user.gender!),
                  ),
                if (user.gender != null) const SizedBox(height: 12),

                if (user.dob != null)
                  _buildInfoCard(
                    context,
                    icon: Icons.cake_outlined,
                    title: 'Ngày Sinh',
                    subtitle: DateFormat('dd/MM/yyyy').format(user.dob!),
                  ),
                if (user.dob != null) const SizedBox(height: 12),

                _buildInfoCard(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Thành Viên Từ',
                  subtitle: dateFormat.format(user.createdAt),
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  context,
                  icon: Icons.update,
                  title: 'Cập Nhật Lần Cuối',
                  subtitle: dateFormat.format(user.updatedAt),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Text(
                  'Hành Động',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Chỉnh Sửa Hồ Sơ',
                  subtitle: 'Cập nhật thông tin của bạn',
                  onTap: () => Get.toNamed(AppRoutes.editProfile),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  icon: Icons.logout,
                  title: 'Đăng Xuất',
                  subtitle: 'Đăng xuất khỏi tài khoản của bạn',
                  textColor: Colors.orange,
                  onTap: () => _showSignOutDialog(context, authController),
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  context,
                  icon: Icons.delete_forever,
                  title: 'Xóa Tài Khoản',
                  subtitle: 'Xóa vĩnh viễn tài khoản của bạn',
                  textColor: Colors.red,
                  onTap: () =>
                      _showDeleteAccountDialog(context, authController),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? const Color(0xFF2196F3), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng Xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthController authController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Tài Khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tài khoản của mình không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      final base64Data = imageUrl.split(',')[1];
      return MemoryImage(base64Decode(base64Data));
    } else {
      // Network URL
      return NetworkImage(imageUrl);
    }
  }

  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }
}
