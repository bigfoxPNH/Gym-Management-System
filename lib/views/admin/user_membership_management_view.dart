import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/member_management_controller.dart';

class UserMembershipManagementView extends StatelessWidget {
  const UserMembershipManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MemberManagementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Thẻ Hội Viên'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => controller.loadAllUserMemberships(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildStatsBar(controller),
          Expanded(child: _buildMembershipsList(controller)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(MemberManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                onPressed: () => controller.updateSearchQuery(''),
                icon: const Icon(Icons.clear),
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(MemberManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final memberships = controller.userMemberships;
        final activeCount = memberships.where((m) {
          final status = controller.getMembershipStatus(m);
          return status == 'Đang hoạt động';
        }).length;
        final pendingCount = memberships.where((m) {
          final status = controller.getMembershipStatus(m);
          return status == 'Chờ thanh toán';
        }).length;
        final expiredCount = memberships.where((m) {
          final status = controller.getMembershipStatus(m);
          return status == 'Đã hết hạn';
        }).length;

        return Row(
          children: [
            _buildStatCard(
              'Tổng số',
              memberships.length.toString(),
              Colors.blue,
              false,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Hoạt động',
              activeCount.toString(),
              Colors.green,
              false,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Chờ thanh toán',
              pendingCount.toString(),
              Colors.orange,
              false,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Hết hạn',
              expiredCount.toString(),
              Colors.red,
              false,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    bool isSelected,
  ) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipsList(MemberManagementController controller) {
    return Obx(() {
      if (controller.userMemberships.isEmpty) {
        return _buildNoMembershipsState();
      }

      final memberships = controller.userMemberships;
      final searchQuery = controller.searchQuery.value.toLowerCase();

      final filteredMemberships = searchQuery.isEmpty
          ? memberships
          : memberships.where((m) {
              final userName = (m['userName'] ?? '').toLowerCase();
              final userEmail = (m['userEmail'] ?? '').toLowerCase();
              return userName.contains(searchQuery) ||
                  userEmail.contains(searchQuery);
            }).toList();

      if (filteredMemberships.isEmpty) {
        return _buildNoResultsState();
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredMemberships.length,
        itemBuilder: (context, index) {
          final membership = filteredMemberships[index];
          return _buildMembershipCard(context, membership, controller);
        },
      );
    });
  }

  Widget _buildNoMembershipsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có thẻ hội viên nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thẻ hội viên sẽ hiển thị ở đây khi có thành viên mua thẻ',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(
    BuildContext context,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    final detailedStatus = controller.getMembershipDetailedStatus(membership);
    final primaryStatus = detailedStatus['primary'] ?? '';
    final secondaryStatus = detailedStatus['secondary'] ?? '';
    final primaryColor = controller.getStatusColor(primaryStatus);
    final secondaryColor = _getSecondaryStatusColor(secondaryStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Primary Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPrimaryStatusIcon(primaryStatus),
                        size: 12,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        primaryStatus,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Secondary Status Badge (Payment Status)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: secondaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSecondaryStatusIcon(secondaryStatus),
                        size: 11,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        secondaryStatus,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMembershipAction(
                    context,
                    value,
                    membership,
                    controller,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Xem chi tiết'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'extend',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16),
                          SizedBox(width: 8),
                          Text('Gia hạn'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membership['userName'] ?? 'Người dùng không xác định',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        membership['userEmail'] ?? 'Email không xác định',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            _buildMembershipInfoRow(
              'Loại thẻ:',
              membership['membershipType'] ?? 'Không xác định',
            ),
            _buildMembershipInfoRow(
              'Ngày bắt đầu:',
              controller.formatDate(membership['startDate']),
            ),
            _buildMembershipInfoRow(
              'Ngày kết thúc:',
              controller.formatDate(membership['endDate']),
            ),
            _buildMembershipInfoRow(
              'Số tiền:',
              '${controller.formatAmount(membership['price'] ?? membership['amount'] ?? 0)} VNĐ',
            ),
            _buildMembershipInfoRow(
              'Phương thức thanh toán:',
              controller.formatPaymentMethod(membership['paymentMethod']),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSecondaryStatusColor(String status) {
    switch (status) {
      case 'Đã thanh toán':
        return Colors.green;
      case 'Chờ thanh toán':
        return Colors.orange;
      case 'Thanh toán thất bại':
        return Colors.red;
      case 'Chưa thanh toán':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPrimaryStatusIcon(String status) {
    switch (status) {
      case 'Đang hoạt động':
        return Icons.check_circle;
      case 'Chờ thanh toán':
        return Icons.schedule;
      case 'Chưa kích hoạt':
        return Icons.radio_button_unchecked;
      case 'Đã hết hạn':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getSecondaryStatusIcon(String status) {
    switch (status) {
      case 'Đã thanh toán':
        return Icons.payment;
      case 'Chờ thanh toán':
        return Icons.schedule;
      case 'Thanh toán thất bại':
        return Icons.error;
      case 'Chưa thanh toán':
        return Icons.pending_actions;
      default:
        return Icons.help;
    }
  }

  Widget _buildMembershipInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMembershipAction(
    BuildContext context,
    String action,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    switch (action) {
      case 'view':
        _showMembershipDetailsDialog(context, membership, controller);
        break;
      case 'edit':
        _showEditMembershipDialog(context, membership, controller);
        break;
      case 'extend':
        _showExtendMembershipDialog(context, membership, controller);
        break;
      case 'delete':
        _showDeleteMembershipDialog(context, membership, controller);
        break;
    }
  }

  void _showMembershipDetailsDialog(
    BuildContext context,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    final detailedStatus = controller.getMembershipDetailedStatus(membership);
    final primaryStatus = detailedStatus['primary'] ?? '';
    final secondaryStatus = detailedStatus['secondary'] ?? '';
    final primaryColor = controller.getStatusColor(primaryStatus);
    final secondaryColor = _getSecondaryStatusColor(secondaryStatus);

    // Calculate remaining days
    final endDate = membership['endDate'];
    int? remainingDays;
    if (endDate != null) {
      DateTime endDateTime;
      if (endDate is Timestamp) {
        endDateTime = endDate.toDate();
      } else if (endDate is DateTime) {
        endDateTime = endDate;
      } else {
        endDateTime = DateTime.now();
      }
      remainingDays = endDateTime.difference(DateTime.now()).inDays;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.card_membership, color: Colors.amber),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chi tiết thẻ hội viên',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badges at top
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPrimaryStatusIcon(primaryStatus),
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            primaryStatus,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: secondaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSecondaryStatusIcon(secondaryStatus),
                            size: 16,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            secondaryStatus,
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // User Information
                const Text(
                  'THÔNG TIN THÀNH VIÊN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  'Người dùng:',
                  membership['userName'] ?? 'N/A',
                  icon: Icons.person,
                ),
                _buildDialogDetailRow(
                  'Email:',
                  membership['userEmail'] ?? 'N/A',
                  icon: Icons.email,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Membership Information
                const Text(
                  'THÔNG TIN THẺ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  'Loại thẻ:',
                  membership['membershipType'] ?? 'N/A',
                  icon: Icons.card_membership,
                ),
                _buildDialogDetailRow(
                  'Mã thẻ:',
                  membership['id'] ?? 'N/A',
                  icon: Icons.qr_code,
                ),
                _buildDialogDetailRow(
                  'Ngày bắt đầu:',
                  controller.formatDate(membership['startDate']),
                  icon: Icons.calendar_today,
                ),
                _buildDialogDetailRow(
                  'Ngày kết thúc:',
                  controller.formatDate(membership['endDate']),
                  icon: Icons.event,
                ),
                if (remainingDays != null)
                  _buildDialogDetailRow(
                    'Còn lại:',
                    remainingDays > 0
                        ? '$remainingDays ngày'
                        : remainingDays == 0
                        ? 'Hết hạn hôm nay'
                        : 'Đã hết hạn ${-remainingDays} ngày',
                    icon: Icons.timelapse,
                    valueColor: remainingDays > 7
                        ? Colors.green
                        : remainingDays > 0
                        ? Colors.orange
                        : Colors.red,
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Payment Information
                const Text(
                  'THÔNG TIN THANH TOÁN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  'Số tiền:',
                  '${controller.formatAmount(membership['price'] ?? membership['amount'] ?? 0)} VNĐ',
                  icon: Icons.attach_money,
                ),
                _buildDialogDetailRow(
                  'Phương thức:',
                  controller.formatPaymentMethod(membership['paymentMethod']),
                  icon: Icons.payment,
                ),
                _buildDialogDetailRow(
                  'Trạng thái thanh toán:',
                  controller.formatPaymentStatus(membership['paymentStatus']),
                  icon: Icons.receipt_long,
                  valueColor: secondaryColor,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Status Information
                const Text(
                  'TRẠNG THÁI KÍCH HOẠT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  'Trạng thái:',
                  controller.getMembershipStatus(membership),
                  icon: Icons.info,
                  valueColor: primaryColor,
                ),
                _buildDialogDetailRow(
                  'Kích hoạt:',
                  (membership['isActive'] ?? false) ? 'Có' : 'Không',
                  icon: Icons.check_circle,
                  valueColor: (membership['isActive'] ?? false)
                      ? Colors.green
                      : Colors.grey,
                ),

                // Additional metadata
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'THÔNG TIN BỔ SUNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (membership['createdAt'] != null)
                  _buildDialogDetailRow(
                    'Ngày tạo:',
                    controller.formatDate(membership['createdAt']),
                    icon: Icons.add_circle,
                  ),
                if (membership['updatedAt'] != null)
                  _buildDialogDetailRow(
                    'Cập nhật lần cuối:',
                    controller.formatDate(membership['updatedAt']),
                    icon: Icons.update,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 110 : 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMembershipDialog(
    BuildContext context,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa thẻ hội viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thẻ của: ${membership['userName'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              const Text('Cập nhật trạng thái:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateUserMembershipStatus(
                          membership['id'],
                          true,
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Kích hoạt',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.setMembershipExpired(membership['id']);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Hết hạn',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Cập nhật thanh toán:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateUserMembershipPaymentStatus(
                          membership['id'],
                          'completed',
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Đã thanh toán',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateUserMembershipPaymentStatus(
                          membership['id'],
                          'pending',
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'Chờ thanh toán',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showExtendMembershipDialog(
    BuildContext context,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    final daysController = TextEditingController();
    DateTime? selectedDate;

    // Get current end date
    DateTime currentEndDate = DateTime.now();
    final endDateData = membership['endDate'];
    if (endDateData != null) {
      if (endDateData is Timestamp) {
        currentEndDate = endDateData.toDate();
      } else if (endDateData is DateTime) {
        currentEndDate = endDateData;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Gia hạn thẻ hội viên'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gia hạn thẻ của: ${membership['userName'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text(
                  'Ngày hết hạn hiện tại: ${DateFormat('dd/MM/yyyy').format(currentEndDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn phương thức gia hạn:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Option 1: Extend by days
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Gia hạn theo số ngày',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: daysController,
                        decoration: const InputDecoration(
                          labelText: 'Số ngày gia hạn',
                          hintText: 'Ví dụ: 30, 60, 90...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Clear selected date when typing days
                          if (value.isNotEmpty) {
                            setState(() {
                              selectedDate = null;
                            });
                          }
                        },
                      ),
                      if (daysController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ngày hết hạn mới: ${DateFormat('dd/MM/yyyy').format(currentEndDate.add(Duration(days: int.tryParse(daysController.text) ?? 0)))}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HOẶC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 2: Select specific date
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Chọn ngày hết hạn cụ thể',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: currentEndDate.add(
                              const Duration(days: 30),
                            ),
                            firstDate: currentEndDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                            helpText: 'Chọn ngày hết hạn mới',
                            cancelText: 'Hủy',
                            confirmText: 'Chọn',
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              daysController.clear(); // Clear days input
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                              : 'Chọn ngày hết hạn',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (selectedDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Gia hạn thêm: ${selectedDate!.difference(currentEndDate).inDays} ngày',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                // Check if either method is selected
                final days = int.tryParse(daysController.text);

                if (days != null && days > 0) {
                  // Method 1: Extend by days
                  controller.extendMembership(membership['id'], days);
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'Thành công',
                    'Đã gia hạn thẻ thêm $days ngày',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else if (selectedDate != null) {
                  // Method 2: Set specific end date
                  final daysToExtend = selectedDate!
                      .difference(currentEndDate)
                      .inDays;
                  if (daysToExtend > 0) {
                    controller.extendMembership(membership['id'], daysToExtend);
                    Navigator.of(context).pop();
                    Get.snackbar(
                      'Thành công',
                      'Đã gia hạn thẻ đến ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar(
                      'Lỗi',
                      'Ngày hết hạn mới phải sau ngày hết hạn hiện tại',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                } else {
                  Get.snackbar(
                    'Lỗi',
                    'Vui lòng nhập số ngày hoặc chọn ngày hết hạn',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Gia hạn'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMembershipDialog(
    BuildContext context,
    Map<String, dynamic> membership,
    MemberManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa thẻ của ${membership['userName'] ?? 'N/A'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteUserMembership(membership['id']);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
