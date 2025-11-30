import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/order_controller.dart';
import 'package:gympro/models/order.dart' as order_model;
import 'package:intl/intl.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (ctx, index) {
            final order = controller.orders[index];
            return _OrderCard(order: order, controller: controller);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Hãy đặt hàng ngay!', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.toNamed('/user/products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final order_model.Order order;
  final OrderController controller;

  const _OrderCard({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.items.length} sản phẩm',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(order.total)}đ',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (_canCancel(order.status)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Hủy đơn hàng'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canCancel(order_model.OrderStatus status) {
    return status == order_model.OrderStatus.pending ||
        status == order_model.OrderStatus.confirmed;
  }

  Widget _buildStatusChip(order_model.OrderStatus status) {
    Color color;
    switch (status) {
      case order_model.OrderStatus.pending:
        color = Colors.orange;
        break;
      case order_model.OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case order_model.OrderStatus.preparing:
        color = Colors.purple;
        break;
      case order_model.OrderStatus.shipping:
        color = Colors.cyan;
        break;
      case order_model.OrderStatus.delivered:
        color = Colors.green;
        break;
      case order_model.OrderStatus.cancelled:
        color = Colors.red;
        break;
      case order_model.OrderStatus.returned:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chi Tiết Đơn Hàng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailRow('Mã đơn:', order.orderNumber),
                    _buildDetailRow('Trạng thái:', order.status.displayName),
                    _buildDetailRow('Người nhận:', order.recipientName),
                    _buildDetailRow('SĐT:', order.phoneNumber),
                    _buildDetailRow(
                      'Địa chỉ:',
                      '${order.address}, ${order.ward}, ${order.district}, ${order.city}',
                    ),
                    if (order.createdAt != null)
                      _buildDetailRow(
                        'Ngày đặt:',
                        DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!),
                      ),
                    const Divider(height: 24),
                    const Text(
                      'Sản phẩm:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} x${item.quantity}',
                              ),
                            ),
                            Text(
                              '${formatter.format(item.total)}đ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Tạm tính:',
                      '${formatter.format(order.subtotal)}đ',
                    ),
                    _buildDetailRow(
                      'Phí vận chuyển:',
                      '${formatter.format(order.shippingFee)}đ',
                    ),
                    _buildDetailRow(
                      'Tổng cộng:',
                      '${formatter.format(order.total)}đ',
                      isBold: true,
                    ),
                    if (order.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Ghi chú:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(order.note!),
                    ],
                    if (_canCancel(order.status)) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showCancelDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hủy đơn hàng'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc muốn hủy đơn hàng này?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Lý do hủy...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty
                  ? 'Người dùng hủy'
                  : reasonController.text.trim();
              controller.cancelOrder(order.id, reason);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
