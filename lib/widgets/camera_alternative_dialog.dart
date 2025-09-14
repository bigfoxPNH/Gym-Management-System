import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/workout_assistant_controller.dart';
import '../../models/exercise_model.dart';

class CameraAlternativeDialog extends StatelessWidget {
  const CameraAlternativeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.camera_alt_outlined, color: Colors.orange),
          SizedBox(width: 10),
          Text('Lỗi Camera'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Camera không thể hoạt động. Bạn có thể:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.refresh,
            title: 'Thử lại Camera',
            subtitle: 'Restart camera initialization',
            color: Colors.blue,
            onTap: () async {
              Navigator.pop(context);
              final controller = Get.find<WorkoutAssistantController>();
              await controller.initializeCameraWithService();
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.photo_camera,
            title: 'Chụp ảnh để phân tích',
            subtitle: 'Sử dụng camera phone/tablet để chụp ảnh',
            color: Colors.green,
            onTap: () async {
              Navigator.pop(context);
              await _captureImageForAnalysis();
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.photo_library,
            title: 'Chọn ảnh từ thư viện',
            subtitle: 'Upload ảnh từ gallery để phân tích tư thế',
            color: Colors.purple,
            onTap: () async {
              Navigator.pop(context);
              await _selectImageFromGallery();
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.sports_gymnastics,
            title: 'Tập không cần camera',
            subtitle: 'Theo dõi bài tập thủ công',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _startManualWorkout();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImageForAnalysis() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        Get.snackbar(
          'Thành công',
          'Đã chụp ảnh. AI sẽ phân tích tư thế...',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // TODO: Process image with AI
        _processImageWithAI(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chụp ảnh: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        Get.snackbar(
          'Thành công',
          'Đã chọn ảnh. AI sẽ phân tích tư thế...',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // TODO: Process image with AI
        _processImageWithAI(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _processImageWithAI(String imagePath) {
    // TODO: Implement AI processing for static images
    Get.snackbar(
      'AI Analysis',
      'Đang phân tích ảnh với AI... (Feature sẽ được implement)',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _startManualWorkout() {
    final controller = Get.find<WorkoutAssistantController>();

    // Start workout without camera
    controller.startWorkout();

    Get.snackbar(
      'Bắt đầu tập',
      'Bạn có thể theo dõi thời gian và đếm số lần tự động',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}
