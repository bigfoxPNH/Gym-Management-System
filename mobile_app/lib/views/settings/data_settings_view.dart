import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataSettingsView extends StatelessWidget {
  const DataSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt Riêng Tư & Dữ Liệu'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Collection Section
            _buildSection(
              title: 'Thu Thập Dữ Liệu',
              description:
                  'Kiểm soát dữ liệu chúng tôi thu thập từ việc sử dụng của bạn',
              children: [
                _buildSwitchTile(
                  title: 'Dữ Liệu Phân Tích',
                  subtitle:
                      'Giúp cải thiện ứng dụng bằng dữ liệu sử dụng ẩn danh',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Dữ Liệu Hiệu Suất',
                  subtitle:
                      'Chia sẻ số liệu hiệu suất để giúp chúng tôi tối ưu hóa',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Báo Cáo Lỗi',
                  subtitle: 'Gửi báo cáo lỗi để giúp sửa chữa lỗi',
                  value: true.obs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Usage Section
            _buildSection(
              title: 'Sử Dụng Dữ Liệu',
              description:
                  'Quản lý cách dữ liệu của bạn được sử dụng để cá nhân hóa',
              children: [
                _buildSwitchTile(
                  title: 'Đề Xuất Cá Nhân Hóa',
                  subtitle:
                      'Sử dụng dữ liệu của bạn để cung cấp gợi ý tập luyện tốt hơn',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Thông Tin Tiếp Thị',
                  subtitle: 'Nhận mẹo thể dục và ưu đãi cá nhân hóa',
                  value: false.obs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Export & Deletion
            _buildSection(
              title: 'Quyền Dữ Liệu Của Bạn',
              description: 'Tải xuống hoặc xóa dữ liệu cá nhân của bạn',
              children: [
                _buildActionTile(
                  title: 'Tải Xuống Dữ Liệu Của Tôi',
                  subtitle: 'Xuất tất cả dữ liệu cá nhân của bạn',
                  icon: Icons.download_outlined,
                  onTap: () => _showDataExportDialog(context),
                ),
                _buildActionTile(
                  title: 'Xóa Dữ Liệu Của Tôi',
                  subtitle: 'Xóa vĩnh viễn tất cả dữ liệu của bạn',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                  onTap: () => _showDataDeletionDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacy Policy Link
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.policy_outlined,
                  color: Color(0xFF2196F3),
                ),
                title: const Text('Xem Chính Sách Riêng Tư Đầy Đủ'),
                subtitle: const Text(
                  'Đọc chính sách riêng tư đầy đủ của chúng tôi',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Get.toNamed('/privacy-policy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required RxBool value,
  }) {
    return Obx(
      () => SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        value: value.value,
        onChanged: (bool newValue) {
          value.value = newValue;
          _savePreference(title, newValue);
        },
        activeColor: const Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF2196F3),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _savePreference(String key, bool value) {
    // Here you would typically save to SharedPreferences or similar
    Get.snackbar(
      'Cài Đặt Đã Cập Nhật',
      '$key đã được ${value ? 'bật' : 'tắt'}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showDataExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xuất Dữ Liệu Của Bạn'),
        content: const Text(
          'Chúng tôi sẽ chuẩn bị một tập tin chứa tất cả dữ liệu cá nhân của bạn và gửi đến địa chỉ email đã đăng ký. Quá trình này có thể mất đến 24 giờ.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Yêu Cầu Xuất Dữ Liệu',
                'Yêu cầu xuất dữ liệu của bạn đã được gửi. Bạn sẽ nhận được email sớm.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Xuất'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa Tất Cả Dữ Liệu'),
        content: const Text(
          'Điều này sẽ xóa vĩnh viễn tất cả dữ liệu cá nhân của bạn khỏi máy chủ của chúng tôi. Hành động này không thể hoàn tác. Tài khoản của bạn cũng sẽ bị xóa.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDataDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa Tất Cả Dữ Liệu'),
          ),
        ],
      ),
    );
  }

  void _confirmDataDeletion() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác Nhận Cuối Cùng'),
        content: const Text(
          'Bạn có hoàn toàn chắc chắn không? Điều này sẽ xóa tài khoản của bạn và tất cả dữ liệu liên quan vĩnh viễn.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Here you would call the actual deletion logic
              Get.snackbar(
                'Yêu Cầu Xóa Dữ Liệu',
                'Yêu cầu xóa dữ liệu của bạn đã được gửi. Điều này sẽ được xử lý trong vòng 7 ngày.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Có, Xóa Mọi Thứ'),
          ),
        ],
      ),
    );
  }
}
