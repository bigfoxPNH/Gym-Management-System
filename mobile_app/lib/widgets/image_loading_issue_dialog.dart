import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageLoadingIssueDialog {
  static void show() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Thông tin về tải ảnh'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tại sao ảnh không hiển thị?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ứng dụng web không thể tải ảnh từ các trang web bên ngoài do chính sách bảo mật CORS của trình duyệt.',
            ),
            SizedBox(height: 16),
            Text('Giải pháp:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Tải ảnh lên Firebase Storage'),
            Text('• Sử dụng URL từ Firebase Storage'),
            Text('• Hoặc sử dụng ảnh từ cùng domain'),
            SizedBox(height: 16),
            Text(
              'Lưu ý:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ảnh sẽ hiển thị bình thường trên ứng dụng mobile.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đã hiểu')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showFirebaseStorageGuide();
            },
            child: const Text('Hướng dẫn Firebase'),
          ),
        ],
      ),
    );
  }

  static void _showFirebaseStorageGuide() {
    Get.dialog(
      AlertDialog(
        title: const Text('Hướng dẫn sử dụng Firebase Storage'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bước 1: Truy cập Firebase Console',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Mở https://console.firebase.google.com'),
              Text('• Chọn project GymPro'),
              SizedBox(height: 12),

              Text(
                'Bước 2: Tải ảnh lên Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Vào mục "Storage" > "Files"'),
              Text('• Click "Upload file"'),
              Text('• Chọn ảnh cần tải lên'),
              SizedBox(height: 12),

              Text(
                'Bước 3: Lấy URL công khai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Click vào file vừa tải lên'),
              Text('• Copy "Download URL"'),
              Text('• Sử dụng URL này trong bài viết'),
              SizedBox(height: 12),

              Text(
                'Lợi ích:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('✓ Hiển thị trên cả web và mobile'),
              Text('✓ Tốc độ tải nhanh'),
              Text('✓ Bảo mật tốt'),
              Text('✓ Không giới hạn CORS'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
