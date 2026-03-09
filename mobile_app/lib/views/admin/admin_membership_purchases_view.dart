import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminMembershipPurchasesView extends StatefulWidget {
  const AdminMembershipPurchasesView({super.key});

  @override
  State<AdminMembershipPurchasesView> createState() =>
      _AdminMembershipPurchasesViewState();
}

class _AdminMembershipPurchasesViewState
    extends State<AdminMembershipPurchasesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> purchases = [];
  List<Map<String, dynamic>> filteredPurchases = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await _firestore.collection('user_memberships').get();

      List<Map<String, dynamic>> loadedPurchases = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Load user info
        if (data['userId'] != null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(data['userId'])
                .get();
            if (userDoc.exists) {
              data['userName'] = userDoc.data()?['fullName'] ?? 'Không có tên';
              data['userEmail'] = userDoc.data()?['email'] ?? '';
              data['userPhone'] = userDoc.data()?['phone'] ?? '';
            }
          } catch (e) {
            print('Error loading user info: $e');
          }
        }

        loadedPurchases.add(data);
      }

      // Sort by createdAt descending
      loadedPurchases.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        DateTime aDate = aTime is Timestamp ? aTime.toDate() : aTime;
        DateTime bDate = bTime is Timestamp ? bTime.toDate() : bTime;
        return bDate.compareTo(aDate);
      });

      setState(() {
        purchases = loadedPurchases;
        _filterPurchases();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading purchases: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách thẻ mua');
      setState(() => isLoading = false);
    }
  }

  void _filterPurchases() {
    setState(() {
      filteredPurchases = purchases.where((purchase) {
        final matchesSearch =
            searchQuery.isEmpty ||
            (purchase['userName']?.toLowerCase() ?? '').contains(
              searchQuery.toLowerCase(),
            ) ||
            (purchase['cardName']?.toLowerCase() ?? '').contains(
              searchQuery.toLowerCase(),
            ) ||
            (purchase['membershipCardName']?.toLowerCase() ?? '').contains(
              searchQuery.toLowerCase(),
            );

        final status = _getStatus(purchase);
        final matchesStatus =
            selectedStatus == 'all' || status == selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _getStatus(Map<String, dynamic> purchase) {
    final paymentStatus = purchase['paymentStatus'] ?? '';
    final isActive = purchase['isActive'] ?? false;
    final endDate = purchase['endDate'];

    if (paymentStatus == 'pending') return 'pending';
    if (!isActive) return 'inactive';

    if (endDate != null) {
      DateTime endDateTime = endDate is Timestamp ? endDate.toDate() : endDate;
      if (endDateTime.isBefore(DateTime.now())) return 'expired';
      return 'active';
    }

    return 'active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'pending':
        return 'Chờ xác nhận';
      case 'inactive':
        return 'Chưa kích hoạt';
      case 'expired':
        return 'Đã hết hạn';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quản Lý Thẻ Mua',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: TextField(
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, thẻ...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      _filterPurchases();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Tất cả', 'all'),
                      _buildFilterChip('Đang hoạt động', 'active'),
                      _buildFilterChip('Chờ xác nhận', 'pending'),
                      _buildFilterChip('Chưa kích hoạt', 'inactive'),
                      _buildFilterChip('Đã hết hạn', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Tổng',
                  purchases.length.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  'Chờ duyệt',
                  purchases
                      .where((p) => _getStatus(p) == 'pending')
                      .length
                      .toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  'Hoạt động',
                  purchases
                      .where((p) => _getStatus(p) == 'active')
                      .length
                      .toString(),
                  Colors.green,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPurchases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_membership,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có dữ liệu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPurchases.length,
                    itemBuilder: (context, index) {
                      return _buildPurchaseCard(filteredPurchases[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedStatus = value;
            _filterPurchases();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    final status = _getStatus(purchase);
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPurchaseDetail(purchase),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase['userName'] ?? 'Không có tên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase['membershipCardName'] ??
                              purchase['cardName'] ??
                              'Thẻ không xác định',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bắt đầu: ${_formatDate(purchase['startDate'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Kết thúc: ${_formatDate(purchase['endDate'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Giá: ${NumberFormat('#,###', 'vi_VN').format(purchase['price'] ?? 0)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _confirmPurchase(purchase),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    DateTime dateTime = date is Timestamp ? date.toDate() : date;
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  void _showPurchaseDetail(Map<String, dynamic> purchase) {
    final status = _getStatus(purchase);
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi Tiết Thẻ Mua'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Người mua', purchase['userName'] ?? 'N/A'),
              _buildDetailRow('Email', purchase['userEmail'] ?? 'N/A'),
              _buildDetailRow('SĐT', purchase['userPhone'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow(
                'Thẻ',
                purchase['membershipCardName'] ?? purchase['cardName'] ?? 'N/A',
              ),
              _buildDetailRow('Loại thẻ', purchase['cardType'] ?? 'N/A'),
              _buildDetailRow('Mô tả', purchase['description'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow(
                'Trạng thái',
                statusText,
                valueColor: statusColor,
              ),
              const SizedBox(height: 8),
              // Change Status Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thay đổi trạng thái:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusButton(
                          purchase,
                          'Đang hoạt động',
                          'active',
                          Colors.green,
                        ),
                        _buildStatusButton(
                          purchase,
                          'Chờ xác nhận',
                          'pending',
                          Colors.orange,
                        ),
                        _buildStatusButton(
                          purchase,
                          'Chưa kích hoạt',
                          'inactive',
                          Colors.blue,
                        ),
                        _buildStatusButton(
                          purchase,
                          'Đã hết hạn',
                          'expired',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildDetailRow(
                'Ngày mua',
                _formatDate(purchase['purchaseDate']),
              ),
              _buildDetailRow(
                'Ngày bắt đầu',
                _formatDate(purchase['startDate']),
              ),
              _buildDetailRow(
                'Ngày kết thúc',
                _formatDate(purchase['endDate']),
              ),
              if (purchase['customEndDate'] != null)
                _buildDetailRow(
                  'Ngày kết thúc tùy chỉnh',
                  _formatDate(purchase['customEndDate']),
                ),
              const Divider(),
              _buildDetailRow(
                'Giá',
                '${NumberFormat('#,###', 'vi_VN').format(purchase['price'] ?? 0)}đ',
              ),
              _buildDetailRow(
                'Thời hạn',
                '${purchase['duration'] ?? 0} ${purchase['durationType'] ?? 'ngày'}',
              ),
              _buildDetailRow('Ngày tạo', _formatDate(purchase['createdAt'])),
              if (purchase['updatedAt'] != null)
                _buildDetailRow('Cập nhật', _formatDate(purchase['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    Map<String, dynamic> purchase,
    String label,
    String statusValue,
    Color color,
  ) {
    final currentStatus = _getStatus(purchase);
    final isSelected = currentStatus == statusValue;

    return ElevatedButton(
      onPressed: () => _changeStatus(purchase, statusValue),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
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

  Future<void> _confirmPurchase(Map<String, dynamic> purchase) async {
    try {
      await _firestore
          .collection('user_memberships')
          .doc(purchase['id'])
          .update({
            'paymentStatus': 'completed',
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Get.snackbar('Thành công', 'Đã xác nhận đơn mua thẻ');
      _loadPurchases();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xác nhận: $e');
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> purchase,
    String newStatus,
  ) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (newStatus) {
        case 'active':
          updateData['isActive'] = true;
          updateData['paymentStatus'] = 'completed';
          break;
        case 'pending':
          updateData['paymentStatus'] = 'pending';
          updateData['isActive'] = false;
          break;
        case 'inactive':
          updateData['isActive'] = false;
          updateData['paymentStatus'] = 'completed';
          break;
        case 'expired':
          updateData['isActive'] = true;
          updateData['paymentStatus'] = 'completed';
          // Force set endDate to past to make it expired
          updateData['endDate'] = Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          break;
      }

      await _firestore
          .collection('user_memberships')
          .doc(purchase['id'])
          .update(updateData);

      Get.back(); // Close dialog
      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái thành ${_getStatusText(newStatus)}',
      );
      _loadPurchases();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái: $e');
    }
  }
}
