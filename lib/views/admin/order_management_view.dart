import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gympro/models/order.dart' as order_model;
import 'package:intl/intl.dart';

class OrderManagementView extends StatefulWidget {
  const OrderManagementView({super.key});

  @override
  State<OrderManagementView> createState() => _OrderManagementViewState();
}

class _OrderManagementViewState extends State<OrderManagementView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<order_model.Order> allOrders = [];
  List<order_model.Order> filteredOrders = [];
  bool isLoading = true;
  String selectedStatus = 'all';
  String searchQuery = '';

  final Map<String, String> statusLabels = {
    'all': 'Tất cả',
    'pending': 'Chờ xác nhận',
    'confirmed': 'Đã xác nhận',
    'shipping': 'Đang giao',
    'delivered': 'Đã giao',
    'cancelled': 'Đã hủy',
  };

  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'shipping': Colors.purple,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => isLoading = true);

      // Get all orders
      final snapshot = await _firestore.collection('orders').get();

      allOrders = snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending
      allOrders.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      _filterOrders();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải đơn hàng: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        final matchesStatus =
            selectedStatus == 'all' || order.status.value == selectedStatus;
        final matchesSearch =
            searchQuery.isEmpty ||
            order.orderNumber.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            order.recipientName.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            order.phoneNumber.contains(searchQuery);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updateOrderStatus(
    String orderId,
    order_model.OrderStatus newStatus,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.value,
      });

      Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn hàng');
      await _loadOrders();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái: $e');
    }
  }

  Future<void> _showOrderDetails(order_model.Order order) async {
    await showDialog(
      context: context,
      builder: (context) => _OrderDetailsDialog(
        order: order,
        onStatusUpdate: (newStatus) {
          _updateOrderStatus(order.id, newStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quản Lý Đơn Mua',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          _buildOrderStats(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm mã đơn, tên, SĐT...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          searchQuery = value;
          _filterOrders();
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: statusLabels.entries.map((entry) {
          final isSelected = selectedStatus == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedStatus = entry.key;
                  _filterOrders();
                });
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderStats() {
    final stats = {
      'Tổng đơn': allOrders.length,
      'Chờ xác nhận': allOrders
          .where((o) => o.status == order_model.OrderStatus.pending)
          .length,
      'Đang giao': allOrders
          .where((o) => o.status == order_model.OrderStatus.shipping)
          .length,
      'Hoàn thành': allOrders
          .where((o) => o.status == order_model.OrderStatus.delivered)
          .length,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.entries.map((entry) {
          return Column(
            children: [
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                entry.key,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có đơn hàng nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(order_model.Order order) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final statusColor = statusColors[order.status.value] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
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
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    order.recipientName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    order.phoneNumber,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.address}, ${order.ward}, ${order.district}, ${order.city}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} sản phẩm',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${formatter.format(order.total)}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (order.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  final order_model.Order order;
  final Function(order_model.OrderStatus) onStatusUpdate;

  const _OrderDetailsDialog({
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Dialog(
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoRow('Mã đơn:', order.orderNumber),
                  _buildInfoRow('Trạng thái:', order.status.displayName),
                  _buildInfoRow('Người nhận:', order.recipientName),
                  _buildInfoRow('SĐT:', order.phoneNumber),
                  _buildInfoRow(
                    'Địa chỉ:',
                    '${order.address}, ${order.ward}, ${order.district}, ${order.city}',
                  ),
                  if (order.createdAt != null)
                    _buildInfoRow(
                      'Ngày đặt:',
                      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!),
                    ),
                  const Divider(height: 24),
                  const Text(
                    'Sản phẩm:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => _buildProductItem(item, formatter),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Tạm tính:',
                    '${formatter.format(order.subtotal)}đ',
                  ),
                  _buildInfoRow(
                    'Phí vận chuyển:',
                    '${formatter.format(order.shippingFee)}đ',
                  ),
                  _buildInfoRow(
                    'Tổng cộng:',
                    '${formatter.format(order.total)}đ',
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  if (order.note?.isNotEmpty == true) ...[
                    const Text(
                      'Ghi chú:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(order.note!),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Cập nhật trạng thái:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
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

  Widget _buildProductItem(order_model.OrderItem item, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text('${item.productName} x${item.quantity}')),
          Text(
            '${formatter.format(item.total)}đ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context) {
    final statuses = [
      order_model.OrderStatus.pending,
      order_model.OrderStatus.confirmed,
      order_model.OrderStatus.shipping,
      order_model.OrderStatus.delivered,
      order_model.OrderStatus.cancelled,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isCurrentStatus = order.status == status;
        return ElevatedButton(
          onPressed: isCurrentStatus
              ? null
              : () {
                  onStatusUpdate(status);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrentStatus ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(status.displayName),
        );
      }).toList(),
    );
  }
}
