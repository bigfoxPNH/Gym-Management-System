import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/my_membership_cards_controller.dart';

class MyMembershipCardsView extends StatelessWidget {
  const MyMembershipCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyMembershipCardsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ Tập Của Tôi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.offAllNamed('/home'),
          icon: const Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: controller.loadMyMembershipCards,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.membershipCards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_membership, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thẻ tập nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy mua thẻ tập để bắt đầu!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/membership-purchase'),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Mua thẻ tập'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.membershipCards.length,
                itemBuilder: (context, index) {
                  final card = controller.membershipCards[index];
                  return _buildMembershipCard(context, card, controller);
                },
              ),
            ),
            // Home button at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMembershipCard(
    BuildContext context,
    Map<String, dynamic> card,
    MyMembershipCardsController controller,
  ) {
    final status = controller.getCardStatus(card);
    final statusColor = controller.getStatusColor(status);
    final daysRemaining = controller.getDaysRemaining(card);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCardDetails(context, card, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with card name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      card['membershipCardName'] ?? 'Thẻ tập',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Card details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Ngày bắt đầu',
                      value: controller.formatDate(card['startDate']),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.event,
                      label: 'Ngày hết hạn',
                      value: controller.formatDate(card['endDate']),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.payments,
                      label: 'Giá',
                      value: '${(card['price'] ?? 0).toStringAsFixed(0)} VNĐ',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.payment,
                      label: 'Thanh toán',
                      value: _getPaymentMethodName(card['paymentMethod']),
                    ),
                  ),
                ],
              ),

              // Days remaining (only for active cards)
              if (status == 'Đang hoạt động' && daysRemaining > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Còn $daysRemaining ngày',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCardDetails(context, card, controller),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Xem chi tiết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'direct':
        return 'Trực tiếp';
      case 'momo':
        return 'MoMo';
      case 'banking':
        return 'Ngân hàng';
      default:
        return 'Không xác định';
    }
  }

  void _showCardDetails(
    BuildContext context,
    Map<String, dynamic> card,
    MyMembershipCardsController controller,
  ) {
    final status = controller.getCardStatus(card);
    final statusColor = controller.getStatusColor(status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.card_membership, color: statusColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Chi tiết thẻ tập')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Tên thẻ',
                card['membershipCardName'] ?? 'Không xác định',
              ),
              _buildDetailRow('Trạng thái', status, valueColor: statusColor),
              _buildDetailRow(
                'Ngày bắt đầu',
                controller.formatDate(card['startDate']),
              ),
              _buildDetailRow(
                'Ngày hết hạn',
                controller.formatDate(card['endDate']),
              ),
              _buildDetailRow(
                'Giá',
                '${(card['price'] ?? 0).toStringAsFixed(0)} VNĐ',
              ),
              _buildDetailRow(
                'Phương thức thanh toán',
                _getPaymentMethodName(card['paymentMethod']),
              ),
              _buildDetailRow(
                'Mã giao dịch',
                card['transactionId'] ?? 'Không có',
              ),
              _buildDetailRow(
                'Ngày tạo',
                controller.formatDate(card['createdAt']),
              ),

              if (status == 'Đang hoạt động') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(height: 4),
                      Text(
                        'Thẻ đang hoạt động',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Còn ${controller.getDaysRemaining(card)} ngày',
                        style: TextStyle(color: Colors.green[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
