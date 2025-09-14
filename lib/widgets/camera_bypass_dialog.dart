import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/workout_assistant_controller.dart';
import '../views/workout/manual_workout_view.dart';

class CameraBypassDialog extends StatelessWidget {
  const CameraBypassDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Camera Không Khả Dụng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Camera bị lỗi hardware hoặc browser không hỗ trợ. Bạn vẫn có thể:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Option 1: Use without camera
          _buildOption(
            icon: Icons.sports_gymnastics,
            title: 'Tập Luyện Thủ Công',
            subtitle: 'Theo dõi thời gian và số lần tự động',
            color: Colors.green,
            onTap: () {
              Navigator.pop(context);
              _startWorkoutWithoutCamera();
            },
          ),

          const SizedBox(height: 12),

          // Option 2: Photo analysis
          _buildOption(
            icon: Icons.camera_alt,
            title: 'Phân Tích Ảnh',
            subtitle: 'Chụp ảnh để AI đánh giá tư thế',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              _showPhotoAnalysisInfo();
            },
          ),

          const SizedBox(height: 12),

          // Option 3: Try mobile app
          _buildOption(
            icon: Icons.phone_android,
            title: 'Sử Dụng Mobile App',
            subtitle: 'Camera hoạt động tốt hơn trên điện thoại',
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              _showMobileAppInfo();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _retryCamera();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Thử Lại Camera'),
        ),
      ],
    );
  }

  Widget _buildOption({
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
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkoutWithoutCamera() {
    final controller = Get.find<WorkoutAssistantController>();

    // Enable manual mode
    controller.enableManualMode();

    // Navigate to manual workout view
    Get.to(() => const ManualWorkoutView());
  }

  void _showPhotoAnalysisInfo() {
    Get.snackbar(
      'Phân Tích Ảnh',
      'Tính năng sắp ra mắt! Hiện tại hãy sử dụng chế độ thủ công.',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  void _showMobileAppInfo() {
    Get.snackbar(
      'Mobile App',
      'Camera hoạt động tốt nhất trên Android/iOS. Thử sử dụng điện thoại!',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.phone_android, color: Colors.white),
    );
  }

  void _retryCamera() async {
    final controller = Get.find<WorkoutAssistantController>();

    Get.snackbar(
      'Đang Thử Lại',
      'Đang khởi tạo camera với cài đặt mới...',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
    );

    await controller.initializeCameraWithService();
  }
}
