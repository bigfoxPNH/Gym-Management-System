import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../widgets/loading_overlay.dart';
import 'trainer_list_tab.dart';
import 'trainer_assignment_tab.dart';
import 'trainer_statistics_tab.dart';

/// Trang chính Quản Lý PT với 3 tabs
class TrainerManagementView extends StatelessWidget {
  const TrainerManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrainerManagementController(), permanent: true);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản Lý PT'),
          backgroundColor: const Color(0xFFFF9800), // Màu cam cho PT
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Cleanup button for invalid trainers
            IconButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Xóa PT không hợp lệ'),
                    content: const Text(
                      'Xóa tất cả PT không có tài khoản người dùng (userId = null)?\n\n'
                      'Điều này sẽ giúp dọn dẹp data lỗi trong hệ thống.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.cleanupInvalidTrainers();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Xóa PT không hợp lệ',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.fitness_center), text: 'Danh sách PT'),
              Tab(icon: Icon(Icons.people), text: 'Phân công'),
              Tab(icon: Icon(Icons.analytics), text: 'Thống kê'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.trainers.isEmpty) {
            return const CenterLoading(message: 'Đang tải dữ liệu PT...');
          }

          return const TabBarView(
            children: [
              TrainerListTab(),
              TrainerAssignmentTab(),
              TrainerStatisticsTab(),
            ],
          );
        }),
      ),
    );
  }
}
