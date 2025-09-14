import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_statistics_controller.dart';

class AdminStatisticsView extends StatelessWidget {
  const AdminStatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminStatisticsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilterSection(controller),
              const SizedBox(height: 24),
              _buildRevenueStatistics(controller),
              const SizedBox(height: 24),
              _buildUserStatistics(controller),
              const SizedBox(height: 24),
              _buildWorkoutStatistics(controller),
              const SizedBox(height: 24),
              _buildMembershipPlanStatistics(controller),
              const SizedBox(height: 24),
              _buildActiveMembershipStatistics(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateFilterSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bộ lọc thời gian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.selectedTimeFilter.value,
                      decoration: const InputDecoration(
                        labelText: 'Khoảng thời gian',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('Ngày')),
                        DropdownMenuItem(value: 'month', child: Text('Tháng')),
                        DropdownMenuItem(value: 'year', child: Text('Năm')),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Tùy chọn'),
                        ),
                      ],
                      onChanged: (value) => controller.updateTimeFilter(value!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedTimeFilter.value == 'custom') {
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Từ ngày',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(controller, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller.endDateController,
                        decoration: const InputDecoration(
                          labelText: 'Đến ngày',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(controller, false),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStatistics(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê doanh thu (Thẻ tập)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.revenueChartType.value == 'pie',
                      controller.revenueChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateRevenueChartType(
                        index == 0 ? 'pie' : 'bar',
                      );
                    },
                    children: const [
                      Icon(Icons.pie_chart),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.revenueChartType.value == 'pie') {
                  return _buildRevenuePieChart(controller);
                } else {
                  return _buildRevenueBarChart(controller);
                }
              }),
            ),
            const SizedBox(height: 16),
            _buildRevenueStats(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenuePieChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.revenueData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: controller.revenueData.map((data) {
            return PieChartSectionData(
              value: data.value,
              title:
                  '${(data.value / controller.totalRevenue.value * 100).toStringAsFixed(1)}%',
              color: data.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    });
  }

  Widget _buildRevenueBarChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.revenueData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: controller.revenueData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.revenueData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.revenueData[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      );
    });
  }

  Widget _buildRevenueStats(AdminStatisticsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Tổng doanh thu',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                    ).format(controller.totalRevenue.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Số lượng giao dịch',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.totalTransactions.value.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatistics(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê người dùng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.userChartType.value == 'pie',
                      controller.userChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateUserChartType(
                        index == 0 ? 'pie' : 'bar',
                      );
                    },
                    children: const [
                      Icon(Icons.pie_chart),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.userChartType.value == 'pie') {
                  return _buildUserPieChart(controller);
                } else {
                  return _buildUserBarChart(controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPieChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.userData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: controller.userData.map((data) {
            return PieChartSectionData(
              value: data.value,
              title: '${data.value.toInt()}',
              color: data.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    });
  }

  Widget _buildUserBarChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.userData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: controller.userData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.userData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.userData[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      );
    });
  }

  Widget _buildWorkoutStatistics(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê bài tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.workoutChartType.value == 'pie',
                      controller.workoutChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateWorkoutChartType(
                        index == 0 ? 'pie' : 'bar',
                      );
                    },
                    children: const [
                      Icon(Icons.pie_chart),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.workoutChartType.value == 'pie') {
                  return _buildWorkoutPieChart(controller);
                } else {
                  return _buildWorkoutBarChart(controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPieChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.workoutData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: controller.workoutData.map((data) {
            return PieChartSectionData(
              value: data.value,
              title: '${data.value.toInt()}',
              color: data.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    });
  }

  Widget _buildWorkoutBarChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.workoutData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: controller.workoutData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.workoutData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.workoutData[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      );
    });
  }

  Widget _buildMembershipPlanStatistics(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê thẻ tập (do admin tạo)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.membershipPlanChartType.value == 'pie',
                      controller.membershipPlanChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateMembershipPlanChartType(
                        index == 0 ? 'pie' : 'bar',
                      );
                    },
                    children: const [
                      Icon(Icons.pie_chart),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.membershipPlanChartType.value == 'pie') {
                  return _buildMembershipPlanPieChart(controller);
                } else {
                  return _buildMembershipPlanBarChart(controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipPlanPieChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.membershipPlanData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: controller.membershipPlanData.map((data) {
            return PieChartSectionData(
              value: data.value,
              title: '${data.value.toInt()}',
              color: data.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    });
  }

  Widget _buildMembershipPlanBarChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.membershipPlanData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: controller.membershipPlanData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.membershipPlanData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.membershipPlanData[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      );
    });
  }

  Widget _buildActiveMembershipStatistics(
    AdminStatisticsController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống kê thẻ tập đang hoạt động',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.activeMembershipChartType.value == 'pie',
                      controller.activeMembershipChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateActiveMembershipChartType(
                        index == 0 ? 'pie' : 'bar',
                      );
                    },
                    children: const [
                      Icon(Icons.pie_chart),
                      Icon(Icons.bar_chart),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.activeMembershipChartType.value == 'pie') {
                  return _buildActiveMembershipPieChart(controller);
                } else {
                  return _buildActiveMembershipBarChart(controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMembershipPieChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.activeMembershipData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: controller.activeMembershipData.map((data) {
            return PieChartSectionData(
              value: data.value,
              title: '${data.value.toInt()}',
              color: data.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    });
  }

  Widget _buildActiveMembershipBarChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.activeMembershipData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: controller.activeMembershipData.asMap().entries.map((
            entry,
          ) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.activeMembershipData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.activeMembershipData[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      );
    });
  }

  Future<void> _selectDate(
    AdminStatisticsController controller,
    bool isStartDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      if (isStartDate) {
        controller.startDateController.text = formattedDate;
        controller.updateStartDate(picked);
      } else {
        controller.endDateController.text = formattedDate;
        controller.updateEndDate(picked);
      }
    }
  }
}
