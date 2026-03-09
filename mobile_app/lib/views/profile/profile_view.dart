import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_account.dart';
import '../../routes/app_routes.dart';
import '../../services/qr_checkin_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

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
            : const CenterLoading(message: 'Đang tải hồ sơ...'),
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
                Stack(
                  children: [
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
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showQRDialog(context, user),
                          icon: const Icon(
                            Icons.qr_code,
                            color: Color(0xFF2196F3),
                            size: 24,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: 'Xem QR Code thông tin cá nhân',
                        ),
                      ),
                    ),
                  ],
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

                // Role Information
                _buildInfoCard(
                  context,
                  icon: user.isAdmin
                      ? Icons.admin_panel_settings
                      : user.isManager
                      ? Icons.manage_accounts
                      : user.isStaff
                      ? Icons.work
                      : Icons.person,
                  title: 'Vai Trò',
                  subtitle: _getRoleDisplayName(user.role),
                  specialColor: user.isAdmin ? Colors.red[600] : null,
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
    Color? specialColor,
  }) {
    final iconColor = specialColor ?? const Color(0xFF2196F3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: specialColor != null
            ? Border.all(color: specialColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color:
                specialColor?.withOpacity(0.1) ??
                Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (specialColor != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: specialColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: specialColor != null ? specialColor : null,
                  ),
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
              _showFinalDeleteConfirmation(context, authController);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(
    BuildContext context,
    AuthController authController,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87, // Màn hình tối nhẹ lại
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Xác Nhận Cuối Cùng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CẢNH BÁO: Hành động này sẽ:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text('• Xóa vĩnh viễn tất cả dữ liệu của bạn'),
            const Text('• Xóa toàn bộ lịch sử tập luyện'),
            const Text('• Xóa thông tin hồ sơ cá nhân'),
            const Text('• Không thể khôi phục lại'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Nếu bạn chắc chắn muốn tiếp tục, vui lòng nhấn "XÁC NHẬN XÓA" bên dưới.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy Bỏ', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDeleteAccount(authController);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'XÁC NHẬN XÓA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteAccount(AuthController authController) {
    // Hiển thị loading dialog
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: CenterLoading(
            message: 'Đang xóa tài khoản...\nVui lòng đợi trong giây lát',
          ),
        ),
      ),
    );

    // Thực hiện xóa tài khoản
    authController.deleteAccount();
  }

  ImageProvider _getImageProvider(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        // Base64 image - safe split
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final base64Data = parts[1];
          return MemoryImage(base64Decode(base64Data));
        }
      }
      // Network URL or fallback
      return NetworkImage(imageUrl);
    } catch (e) {
      print('Error creating image provider: $e');
      // Return a placeholder or default image provider
      return const NetworkImage('');
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

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.admin:
        return 'Quản Trị Viên';
      case Role.manager:
        return 'Quản Lý';
      case Role.staff:
        return 'Nhân Viên';
      case Role.member:
        return 'Thành Viên';
      case Role.membershipCard:
        return 'Thẻ Hội Viên';
      case Role.trainer:
        return 'Huấn Luyện Viên';
    }
  }

  void _showQRDialog(BuildContext context, UserAccount user) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'QR Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Tab bar
                Container(
                  color: Colors.grey.shade100,
                  child: const TabBar(
                    labelColor: Color(0xFF2196F3),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF2196F3),
                    tabs: [
                      Tab(text: 'Thông tin', icon: Icon(Icons.person)),
                      Tab(text: 'Check-in', icon: Icon(Icons.qr_code_scanner)),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildContactQRTab(user),
                      _buildCheckinQRTab(user),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactQRTab(UserAccount user) {
    final qrData = _generateQRData(user);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User info preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? _getImageProvider(user.avatarUrl!)
                      : null,
                  backgroundColor: const Color(0xFF2196F3),
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
            padding: const EdgeInsets.all(16),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quét mã QR này để lưu thông tin liên hệ vào danh bạ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinQRTab(UserAccount user) {
    final checkinQRData = QRCheckinService.generateUserQRData(
      user.id,
      user.email,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Check-in/Checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Đưa QR này cho nhân viên quét để check-in/out',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
            padding: const EdgeInsets.all(16),
            child: QrImageView(
              data: checkinQRData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'QR code này dùng để check-in/checkout tại phòng gym',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _generateQRData(UserAccount user) {
    // Tạo dữ liệu QR theo định dạng vCard (danh bạ điện tử)
    final vCard = StringBuffer();
    vCard.writeln('BEGIN:VCARD');
    vCard.writeln('VERSION:3.0');
    vCard.writeln('FN:${user.fullName}');
    vCard.writeln('EMAIL:${user.email}');

    if (user.phone != null && user.phone!.isNotEmpty) {
      vCard.writeln('TEL:${user.phone}');
    }

    if (user.address != null && user.address!.isNotEmpty) {
      vCard.writeln('ADR:;;${user.address};;;;');
    }

    vCard.writeln('NOTE:Gym Pro Member');
    vCard.writeln('END:VCARD');

    return vCard.toString();
  }
}
