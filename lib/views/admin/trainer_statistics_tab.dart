import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/trainer_management_controller.dart';

/// Tab hiển thị thống kê PT
class TrainerStatisticsTab extends StatelessWidget {
  const TrainerStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainerManagementController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview stats
          _buildOverviewStats(controller),
          const SizedBox(height: 24),

          // Top Performers
          _buildTopPerformers(controller),
          const SizedBox(height: 24),

          // Revenue chart
          _buildRevenueSection(controller),
          const SizedBox(height: 24),

          // Trainer distribution
          _buildTrainerDistribution(controller),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(TrainerManagementController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFFFF9800), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Tổng Quan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Obx(
              () => Column(
                children: [
                  _buildStatRow(
                    'Tổng số PT',
                    controller.totalTrainers.value.toString(),
                    Icons.fitness_center,
                    const Color(0xFFFF9800),
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'PT đang hoạt động',
                    controller.activeTrainers.value.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Tổng buổi tập',
                    controller.totalSessions.value.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Doanh thu',
                    '${NumberFormat('#,###').format(controller.totalRevenue.value)}đ',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers(TrainerManagementController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Top PT Xuất Sắc',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() {
              // Sort trainers by rating
              final topTrainers =
                  controller.trainers.where((t) => t.soLuotDanhGia > 0).toList()
                    ..sort(
                      (a, b) =>
                          b.danhGiaTrungBinh.compareTo(a.danhGiaTrungBinh),
                    );

              if (topTrainers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Chưa có đánh giá',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topTrainers.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final trainer = topTrainers[index];
                  final rank = index + 1;
                  final sessions = controller.getTotalSessionsForTrainer(
                    trainer.id,
                  );

                  return Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRankColor(rank).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getRankColor(rank),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getRankColor(rank),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFFFF9800,
                        ).withOpacity(0.1),
                        backgroundImage: trainer.anhDaiDien != null
                            ? NetworkImage(trainer.anhDaiDien!)
                            : null,
                        child: trainer.anhDaiDien == null
                            ? const Icon(Icons.person, color: Color(0xFFFF9800))
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainer.hoTen,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$sessions buổi tập',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            trainer.danhGiaTrungBinh.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  Widget _buildRevenueSection(TrainerManagementController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Doanh Thu PT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Obx(() {
              if (controller.assignments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Chưa có dữ liệu doanh thu',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              // Calculate revenue per trainer
              final revenueMap = <String, double>{};
              for (final assignment in controller.assignments) {
                if (assignment.mucGia != null) {
                  final revenue =
                      assignment.soBuoiHoanThanh * assignment.mucGia!;
                  revenueMap[assignment.trainerName] =
                      (revenueMap[assignment.trainerName] ?? 0) + revenue;
                }
              }

              if (revenueMap.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Chưa có dữ liệu doanh thu',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              // Sort by revenue
              final sortedEntries = revenueMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: sortedEntries.first.value * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= sortedEntries.length) {
                              return const SizedBox();
                            }
                            final name = sortedEntries[value.toInt()].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.split(' ').last, // Last name only
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 11),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: sortedEntries.first.value / 5,
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: sortedEntries
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value,
                                color: const Color(0xFFFF9800),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerDistribution(TrainerManagementController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Phân Bố PT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Obx(() {
              final statusCounts = <String, int>{};
              for (final trainer in controller.trainers) {
                statusCounts[trainer.trangThai] =
                    (statusCounts[trainer.trangThai] ?? 0) + 1;
              }

              if (statusCounts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Chưa có dữ liệu',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return Column(
                children: statusCounts.entries.map((entry) {
                  final status = entry.key;
                  final count = entry.value;
                  final total = controller.trainers.length;
                  final percentage = (count / total * 100).toStringAsFixed(0);
                  final color = _getStatusColorForChart(status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusLabel(status),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$count PT ($percentage%)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / total,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColorForChart(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.orange;
      case 'on_leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Đang làm việc';
      case 'inactive':
        return 'Không hoạt động';
      case 'suspended':
        return 'Tạm ngưng';
      case 'on_leave':
        return 'Nghỉ phép';
      default:
        return status;
    }
  }
}
