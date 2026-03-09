import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/cleanup_test_data.dart';

class CleanupTestView extends StatelessWidget {
  const CleanupTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧹 Cleanup Test Data'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Card
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '⚠️ CẢNH BÁO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thao tác này sẽ XÓA VĨNH VIỄN tất cả dữ liệu test từ Firebase.\n'
                        'Dữ liệu sẽ không thể khôi phục sau khi xóa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '🎯 Các thao tác có sẵn:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List all cards button
                      ElevatedButton.icon(
                        onPressed: () => _listAllCards(),
                        icon: const Icon(Icons.list),
                        label: const Text('📋 Xem tất cả thẻ tập'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete test cards only
                      ElevatedButton.icon(
                        onPressed: () => _deleteTestCards(),
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('🗑️ Xóa thẻ "Thẻ Tập Test"'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete test purchases only
                      ElevatedButton.icon(
                        onPressed: () => _deleteTestPurchases(),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('🛒 Xóa giao dịch test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Complete cleanup
                      ElevatedButton.icon(
                        onPressed: () => _completeCleanup(),
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('🧹 XÓA TẤT CẢ dữ liệu test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Instructions
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Nhấn "Xem tất cả thẻ tập" để kiểm tra dữ liệu hiện tại\n'
                        '2. Nhấn "XÓA TẤT CẢ dữ liệu test" để xóa hoàn toàn\n'
                        '3. Kiểm tra console để xem kết quả chi tiết',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _listAllCards() async {
    try {
      Get.dialog(
        const AlertDialog(
          title: Text('🔄 Đang tải...'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang lấy danh sách thẻ tập...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      await CleanupTestDataUtil.listAllCards();

      Get.back(); // Close loading dialog
      Get.snackbar(
        '✅ Hoàn thành',
        'Đã liệt kê tất cả thẻ tập trong console',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        '❌ Lỗi',
        'Không thể lấy danh sách: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _deleteTestCards() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('⚠️ Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả thẻ tập có tên "Thẻ Tập Test"?\n\n'
          'Thao tác này KHÔNG THỂ hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        Get.dialog(
          const AlertDialog(
            title: Text('🗑️ Đang xóa...'),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang xóa thẻ test...'),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        await CleanupTestDataUtil.deleteTestCards();

        Get.back(); // Close loading dialog
        Get.snackbar(
          '🎉 Thành công',
          'Đã xóa tất cả thẻ "Thẻ Tập Test"',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          '❌ Lỗi',
          'Không thể xóa thẻ test: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  void _deleteTestPurchases() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('⚠️ Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả giao dịch mua liên quan đến thẻ test?\n\n'
          'Thao tác này KHÔNG THỂ hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('XÓA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        Get.dialog(
          const AlertDialog(
            title: Text('🛒 Đang xóa...'),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang xóa giao dịch test...'),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        await CleanupTestDataUtil.deleteTestPurchases();

        Get.back(); // Close loading dialog
        Get.snackbar(
          '🎉 Thành công',
          'Đã xóa tất cả giao dịch test',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          '❌ Lỗi',
          'Không thể xóa giao dịch test: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  void _completeCleanup() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('🚨 XÁC NHẬN XÓA TẤT CẢ'),
        content: const Text(
          '⚠️ CẢNH BÁO NGHIÊM TRỌNG ⚠️\n\n'
          'Bạn sắp XÓA TẤT CẢ:\n'
          '• Tất cả thẻ tập có tên "Thẻ Tập Test"\n'
          '• Tất cả giao dịch mua liên quan\n\n'
          'DỮ LIỆU SẼ MẤT VĨNH VIỄN!\n\n'
          'Bạn có CHẮC CHẮN muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('❌ HỦY BỎ'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              '🗑️ XÓA TẤT CẢ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        Get.dialog(
          const AlertDialog(
            title: Text('🧹 Đang thực hiện cleanup...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang xóa tất cả dữ liệu test...'),
                SizedBox(height: 8),
                Text(
                  'Vui lòng chờ và KHÔNG đóng cửa sổ này!',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        await CleanupTestDataUtil.cleanupAllTestData();

        Get.back(); // Close loading dialog
        Get.snackbar(
          '🎉 HOÀN THÀNH',
          'Đã xóa thành công tất cả dữ liệu test!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          '💥 LỖI NGHIÊM TRỌNG',
          'Không thể hoàn thành cleanup: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 10),
        );
      }
    }
  }
}
