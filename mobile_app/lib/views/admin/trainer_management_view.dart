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
          title: const Text('Quản Lý PT', style: TextStyle(fontSize: 18)),
          backgroundColor: const Color(0xFFFF9800), // Màu cam cho PT
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 48,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 11.5),
              unselectedLabelStyle: const TextStyle(fontSize: 11.5),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  icon: Icon(Icons.fitness_center, size: 18.5),
                  text: 'Danh sách PT',
                  height: 46,
                ),
                Tab(
                  icon: Icon(Icons.people, size: 18.5),
                  text: 'Phân công',
                  height: 46,
                ),
                Tab(
                  icon: Icon(Icons.analytics, size: 18.5),
                  text: 'Thống kê',
                  height: 46,
                ),
              ],
            ),
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
