import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/purchase_history_service.dart';
import '../../controllers/auth_controller.dart';

class PurchaseHistoryController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> purchaseHistory =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, dynamic> stats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPurchaseHistory();
  }

  Future<void> loadPurchaseHistory() async {
    if (_authController.userAccount?.id == null) {
      errorMessage.value = 'Vui lòng đăng nhập để xem lịch sử';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load purchase history
      final history = await PurchaseHistoryService.getUserPurchaseHistory(
        _authController.userAccount!.id,
      );

      // Load stats
      final userStats = await PurchaseHistoryService.getPurchaseStats(
        _authController.userAccount!.id,
      );

      purchaseHistory.value = history;
      stats.assignAll(userStats);

      print('✅ Loaded ${history.length} purchase records');
    } catch (e) {
      print('❌ Error loading purchase history: $e');
      errorMessage.value = 'Không thể tải lịch sử mua hàng: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHistory() async {
    await loadPurchaseHistory();
    Get.snackbar(
      'Đã làm mới',
      'Lịch sử mua hàng đã được cập nhật',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  String formatCurrency(dynamic amount) {
    if (amount == null) return '0 ₫';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Thất bại';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }
}

class PurchaseHistoryView extends StatelessWidget {
  const PurchaseHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseHistoryController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lịch sử mua thẻ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB0006D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshHistory,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFB0006D)),
                SizedBox(height: 16),
                Text('Đang tải lịch sử...'),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadPurchaseHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB0006D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (controller.purchaseHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử mua thẻ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Các giao dịch mua thẻ sẽ hiển thị ở đây',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshHistory,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(controller),
                const SizedBox(height: 16),
                _buildHistoryList(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard(PurchaseHistoryController controller) {
    final stats = controller.stats;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tổng giao dịch',
                    '${stats['totalPurchases'] ?? 0}',
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thành công',
                    '${stats['successfulPurchases'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tổng chi tiêu',
                    controller.formatCurrency(stats['totalAmount'] ?? 0),
                    Icons.attach_money,
                    const Color(0xFFB0006D),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Trung bình',
                    controller.formatCurrency(stats['averageAmount'] ?? 0),
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(PurchaseHistoryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.purchaseHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final purchase = controller.purchaseHistory[index];
            return _buildHistoryCard(controller, purchase);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    PurchaseHistoryController controller,
    Map<String, dynamic> purchase,
  ) {
    final status = purchase['paymentStatus'] ?? 'unknown';
    final statusColor = controller.getStatusColor(status);
    final statusLabel = controller.getStatusLabel(status);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    purchase['cardName'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${purchase['duration'] ?? 0} ${purchase['durationType'] ?? 'days'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  purchase['paymentMethod'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số tiền',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      controller.formatCurrency(purchase['amount']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB0006D),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ngày mua',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      controller.formatDate(purchase['createdAt']),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            if (purchase['transactionId'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mã GD: ${purchase['transactionId']}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
