import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../models/trainer.dart';
import 'trainer_rental_detail_view.dart';
import 'user_trainer_detail_view.dart';

/// Màn hình danh sách PT có thể thuê
class TrainerRentalView extends StatelessWidget {
  const TrainerRentalView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrainerRentalController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuê Personal Trainer'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed('/my-trainer-rentals'),
            tooltip: 'Lịch sử thuê PT',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadAvailableTrainers,
        child: Obx(() {
          if (controller.isLoadingTrainers.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.availableTrainers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có PT nào đang hoạt động',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.loadAvailableTrainers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏋️ Chọn PT Phù Hợp Với Bạn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Có ${controller.availableTrainers.length} PT đang sẵn sàng hỗ trợ bạn',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Gói tập phổ biến
              _buildPackageInfo(),
              const SizedBox(height: 24),

              // Danh sách PT
              ...controller.availableTrainers.map(
                (trainer) => _buildTrainerCard(context, trainer),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPackageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Gói Tập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPackageItem('Cá nhân 1-1', '300,000đ/giờ', Icons.person),
          _buildPackageItem('Nhóm nhỏ', '150,000đ/giờ', Icons.people),
          _buildPackageItem('Online', '200,000đ/giờ', Icons.videocam),
        ],
      ),
    );
  }

  Widget _buildPackageItem(String name, String price, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text('$name: ', style: const TextStyle(fontSize: 14)),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(BuildContext context, Trainer trainer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => UserTrainerDetailView(trainer: trainer)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với "Xem chi tiết"
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () =>
                        Get.to(() => UserTrainerDetailView(trainer: trainer)),
                    child: Row(
                      children: [
                        Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: trainer.anhDaiDien != null
                          ? NetworkImage(trainer.anhDaiDien!)
                          : null,
                      child: trainer.anhDaiDien == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          trainer.hoTen,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trainer.danhGiaTrungBinh.toStringAsFixed(1)} (${trainer.soLuotDanhGia} đánh giá)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Chuyên môn
                        if (trainer.chuyenMon.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: trainer.chuyenMon.take(3).map((skill) {
                              return Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.deepPurple.shade50,
                                padding: const EdgeInsets.all(0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),

                        // Kinh nghiệm
                        Text(
                          'Kinh nghiệm: ${trainer.namKinhNghiem} năm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Get.to(
                              () => TrainerRentalDetailView(trainer: trainer),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Thuê PT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ], // End of Row children
              ), // End of Row
            ], // End of Column children
          ), // End of Column (Padding child)
        ), // End of Padding
      ), // End of InkWell
    ); // End of Card
  }
}
