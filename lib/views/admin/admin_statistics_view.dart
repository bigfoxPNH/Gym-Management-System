import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_statistics_controller.dart';
import '../../widgets/loading_overlay.dart';

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
          return const CenterLoading(message: 'Đang tải dữ liệu thống kê...');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilterSection(controller),
              const SizedBox(height: 24),
              _buildSummaryCards(controller),
              const SizedBox(height: 24),
              _buildRevenueSection(controller),
              const SizedBox(height: 24),
              _buildMembershipPlanSection(controller),
              const SizedBox(height: 24),
              _buildActiveMembershipSection(controller),
              const SizedBox(height: 24),
              _buildUserStatistics(controller),
              const SizedBox(height: 24),
              _buildWorkoutStatistics(controller),
              const SizedBox(height: 24),
              _buildPTRevenueSection(controller),
              const SizedBox(height: 24),
              _buildProductRevenueSection(controller),
            ],
          ),
        );
      }),
    );
  }

  // ============ DATE FILTER SECTION ============
  Widget _buildDateFilterSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Bộ lọc thời gian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('Hôm nay')),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('30 ngày qua'),
                        ),
                        DropdownMenuItem(
                          value: 'year',
                          child: Text('1 năm qua'),
                        ),
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
                          prefixIcon: Icon(Icons.calendar_today),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                          prefixIcon: Icon(Icons.calendar_today),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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

  // ============ SUMMARY CARDS ============
  Widget _buildSummaryCards(AdminStatisticsController controller) {
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng doanh thu',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(controller.totalRevenue.value),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Giao dịch',
                  controller.totalTransactions.value.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'TB/Giao dịch',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(controller.averageTransactionValue.value),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Thẻ đang hoạt động',
                  controller.totalActiveMemberships.value.toString(),
                  Icons.card_membership,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Doanh thu từ Sản phẩm',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(controller.totalProductRevenue.value),
                  Icons.shopping_bag,
                  Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Đơn hàng hoàn thành',
                  controller.totalProductOrders.value.toString(),
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container()), // Empty space
              const SizedBox(width: 12),
              Expanded(child: Container()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============ REVENUE SECTION ============
  Widget _buildRevenueSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Doanh thu từ Thẻ Tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.revenueChartType.value == 'line',
                      controller.revenueChartType.value == 'pie',
                      controller.revenueChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      final types = ['line', 'pie', 'bar'];
                      controller.updateRevenueChartType(types[index]);
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.show_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar for revenue
            TextField(
              onChanged: (value) => controller.updateRevenueSearch(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm loại thẻ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.revenueChartType.value == 'line') {
                  return _buildRevenueLineChart(controller);
                } else if (controller.revenueChartType.value == 'pie') {
                  return _buildRevenuePieChart(controller);
                } else {
                  return _buildRevenueBarChart(controller);
                }
              }),
            ),
            const SizedBox(height: 16),
            _buildRevenueLegend(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.revenueTimeSeriesData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: controller.totalRevenue.value / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
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
                interval: controller.revenueTimeSeriesData.length > 10
                    ? (controller.revenueTimeSeriesData.length / 5)
                          .ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < controller.revenueTimeSeriesData.length) {
                    final data =
                        controller.revenueTimeSeriesData[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data.title.length > 8
                            ? '${data.title.substring(0, 5)}...'
                            : data.title,
                        style: const TextStyle(fontSize: 9),
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
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: controller.revenueTimeSeriesData
                  .asMap()
                  .entries
                  .map(
                    (entry) => FlSpot(entry.key.toDouble(), entry.value.value),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.green,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final data =
                      controller.revenueTimeSeriesData[barSpot.x.toInt()];
                  return LineTooltipItem(
                    '${data.title}\n${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(barSpot.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRevenuePieChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredRevenueData;
      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: data.map((chartData) {
            final percentage =
                (chartData.value / controller.totalRevenue.value * 100);
            return PieChartSectionData(
              value: chartData.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: chartData.color,
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
      final data = controller.filteredRevenueData;
      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: data.asMap().entries.map((entry) {
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildRevenueLegend(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredRevenueData;
      if (data.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: data.map((chartData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: chartData.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${chartData.title}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(chartData.value)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  // ============ MEMBERSHIP PLAN SECTION ============
  Widget _buildMembershipPlanSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_membership, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'Các Loại Thẻ Tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) =>
                  controller.updateMembershipPlanSearch(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm loại thẻ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.membershipPlanChartType.value == 'pie') {
                  return _buildGenericPieChart(
                    controller.filteredMembershipPlanData,
                  );
                } else {
                  return _buildGenericBarChart(
                    controller.filteredMembershipPlanData,
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ACTIVE MEMBERSHIP SECTION ============
  Widget _buildActiveMembershipSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Thẻ Đang Hoạt Động',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) =>
                  controller.updateActiveMembershipSearch(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm loại thẻ đang hoạt động...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.activeMembershipChartType.value == 'pie') {
                  return _buildGenericPieChart(
                    controller.filteredActiveMembershipData,
                  );
                } else {
                  return _buildGenericBarChart(
                    controller.filteredActiveMembershipData,
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============ GENERIC CHART WIDGETS ============
  Widget _buildGenericPieChart(List<ChartData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return PieChart(
      PieChartData(
        sections: data.map((chartData) {
          final percentage = (chartData.value / total * 100);
          return PieChartSectionData(
            value: chartData.value,
            title:
                '${chartData.value.toInt()}\n(${percentage.toStringAsFixed(1)}%)',
            color: chartData.color,
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 11,
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
  }

  Widget _buildGenericBarChart(List<ChartData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((entry) {
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
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].title,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
  }

  // ============ USER STATISTICS ============
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
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Thống kê Người dùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
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
                  return _buildGenericPieChart(controller.userData);
                } else {
                  return _buildGenericBarChart(controller.userData);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============ WORKOUT STATISTICS ============
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
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Thống kê Bài tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
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
                  return _buildGenericPieChart(controller.workoutData);
                } else {
                  return _buildGenericBarChart(controller.workoutData);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PT REVENUE SECTION ============
  Widget _buildPTRevenueSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Doanh Thu PT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.ptRevenueChartType.value == 'line',
                      controller.ptRevenueChartType.value == 'pie',
                      controller.ptRevenueChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updatePTRevenueChartType(
                        index == 0 ? 'line' : (index == 1 ? 'pie' : 'bar'),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.show_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // PT Revenue summary cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Tổng doanh thu PT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: '₫',
                              ).format(controller.totalPTRevenue.value),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Tổng buổi tập',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              NumberFormat(
                                '#,###',
                              ).format(controller.totalPTSessions.value),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar for PT revenue
            TextField(
              onChanged: (value) => controller.updatePTRevenueSearch(value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên PT...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: Obx(() {
                if (controller.ptRevenueChartType.value == 'line') {
                  return _buildPTRevenueLineChart(controller);
                } else if (controller.ptRevenueChartType.value == 'pie') {
                  return _buildPTRevenuePieChart(controller);
                } else {
                  return _buildPTRevenueBarChart(controller);
                }
              }),
            ),
            const SizedBox(height: 16),
            _buildPTRevenueLegend(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPTRevenueLineChart(AdminStatisticsController controller) {
    return Obx(() {
      if (controller.filteredPTRevenueTimeSeriesData.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: controller.totalPTRevenue.value / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
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
                interval: controller.filteredPTRevenueTimeSeriesData.length > 10
                    ? (controller.filteredPTRevenueTimeSeriesData.length / 5)
                          .ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() <
                      controller.filteredPTRevenueTimeSeriesData.length) {
                    final data = controller
                        .filteredPTRevenueTimeSeriesData[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data.title.length > 8
                            ? '${data.title.substring(0, 5)}...'
                            : data.title,
                        style: const TextStyle(fontSize: 9),
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
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: controller.filteredPTRevenueTimeSeriesData
                  .asMap()
                  .entries
                  .map(
                    (entry) => FlSpot(entry.key.toDouble(), entry.value.value),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.orange,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final data = controller
                      .filteredPTRevenueTimeSeriesData[barSpot.x.toInt()];
                  return LineTooltipItem(
                    '${data.title}\n${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(barSpot.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPTRevenuePieChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredPTRevenueData;
      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: data.map((chartData) {
            final percentage =
                (chartData.value / controller.totalPTRevenue.value * 100);
            return PieChartSectionData(
              value: chartData.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: chartData.color,
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

  Widget _buildPTRevenueBarChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredPTRevenueData;
      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          barGroups: data.asMap().entries.map((entry) {
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPTRevenueLegend(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredPTRevenueData;
      if (data.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: data.map((chartData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: chartData.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${chartData.title}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(chartData.value)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  // ============ PRODUCT REVENUE SECTION ============
  Widget _buildProductRevenueSection(AdminStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.pink),
                    const SizedBox(width: 8),
                    const Text(
                      'Doanh thu từ Sản phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => ToggleButtons(
                    isSelected: [
                      controller.productRevenueChartType.value == 'line',
                      controller.productRevenueChartType.value == 'pie',
                      controller.productRevenueChartType.value == 'bar',
                    ],
                    onPressed: (index) {
                      controller.updateProductRevenueChartType(
                        index == 0 ? 'line' : (index == 1 ? 'pie' : 'bar'),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.show_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.pie_chart, size: 20),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: controller.updateProductRevenueSearch,
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.filteredProductRevenueData.isEmpty &&
                  controller.filteredProductRevenueTimeSeriesData.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Không có dữ liệu'),
                  ),
                );
              }

              return SizedBox(
                height: 300,
                child: _buildProductRevenueChart(controller),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRevenueChart(AdminStatisticsController controller) {
    return Obx(() {
      final chartType = controller.productRevenueChartType.value;

      if (chartType == 'line') {
        return _buildProductLineChart(controller);
      } else if (chartType == 'bar') {
        return _buildProductBarChart(controller);
      } else {
        return _buildProductPieChart(controller);
      }
    });
  }

  Widget _buildProductLineChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredProductRevenueTimeSeriesData;

      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact(locale: 'vi_VN').format(value),
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
                  if (value.toInt() < 0 || value.toInt() >= data.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].title,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
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
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: Colors.pink,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductBarChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredProductRevenueData;

      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact(locale: 'vi_VN').format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= data.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        data[value.toInt()].title,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
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
          borderData: FlBorderData(show: true),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 20,
                ),
              ],
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildProductPieChart(AdminStatisticsController controller) {
    return Obx(() {
      final data = controller.filteredProductRevenueData;

      if (data.isEmpty) {
        return const Center(child: Text('Không có dữ liệu'));
      }

      return PieChart(
        PieChartData(
          sections: data.map((item) {
            final percentage =
                (item.value / controller.totalProductRevenue.value) * 100;
            return PieChartSectionData(
              value: item.value,
              title: '${percentage.toStringAsFixed(1)}%',
              color: item.color,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ============ HELPER METHODS ============
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
