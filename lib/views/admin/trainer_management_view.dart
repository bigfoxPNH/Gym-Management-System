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
