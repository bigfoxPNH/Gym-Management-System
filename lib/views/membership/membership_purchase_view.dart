import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/membership_purchase_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/membership_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class MembershipPurchaseView extends GetView<MembershipPurchaseController> {
  const MembershipPurchaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mua thẻ tập'), elevation: 0),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: Obx(() => _buildContent())),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm thẻ tập...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: controller.setSearchQuery,
          ),

          const SizedBox(height: 12),

          // Filter and sort row
          Row(
            children: [
              // Card type filter
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<CardType?>(
                    decoration: const InputDecoration(
                      labelText: 'Loại thẻ',
                      border: OutlineInputBorder(),
                    ),
                    value: controller.selectedCardType.value,
                    items: [
                      const DropdownMenuItem<CardType?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...CardType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(controller.getCardTypeText(type)),
                        ),
                      ),
                    ],
                    onChanged: controller.setCardTypeFilter,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Duration type filter
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<DurationType?>(
                    decoration: const InputDecoration(
                      labelText: 'Thời hạn',
                      border: OutlineInputBorder(),
                    ),
                    value: controller.selectedDurationType.value,
                    items: [
                      const DropdownMenuItem<DurationType?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...DurationType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(controller.getDurationTypeText(type)),
                        ),
                      ),
                    ],
                    onChanged: controller.setDurationTypeFilter,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: controller.setSortBy,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'name', child: Text('Tên')),
                  const PopupMenuItem(value: 'price', child: Text('Giá')),
                  const PopupMenuItem(
                    value: 'duration',
                    child: Text('Thời hạn'),
                  ),
                ],
              ),

              // Clear filters
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: controller.clearFilters,
                tooltip: 'Xóa bộ lọc',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoadingTemplates.value) {
      return const CenterLoading(message: 'Đang tải danh sách thẻ tập...');
    }

    if (controller.filteredTemplates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTemplateList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy thẻ tập nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = controller.filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(MembershipCard template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.cardName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          controller.getCardTypeText(template.cardType),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: _getCardTypeColor(template.cardType),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat('#,###', 'vi_VN').format(template.price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(' VNĐ', style: TextStyle(color: Colors.green)),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (template.description.isNotEmpty)
              Text(
                template.description,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),

            const SizedBox(height: 12),

            // Duration info
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getDurationText(template),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showTemplatePreview(template),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => LoadingButton(
                      text: 'Mua ngay',
                      isLoading: controller.isPurchasing.value,
                      backgroundColor: const Color(0xFF00BCD4),
                      onPressed: () => _confirmPurchase(template),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardTypeColor(CardType cardType) {
    switch (cardType) {
      case CardType.member:
        return Colors.blue.shade100;
      case CardType.premium:
        return Colors.orange.shade100;
      case CardType.vip:
        return Colors.purple.shade100;
    }
  }

  String _getDurationText(MembershipCard template) {
    if (template.durationType == DurationType.custom &&
        template.customEndDate != null) {
      return 'Đến ${DateFormat('dd/MM/yyyy').format(template.customEndDate!)}';
    } else {
      return '${template.duration} ${controller.getDurationTypeText(template.durationType)}';
    }
  }

  void _showTemplatePreview(MembershipCard template) {
    Get.dialog(
      Dialog(
        child: Container(
          width: Get.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.cardName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details
              _buildDetailRow(
                'Loại thẻ',
                controller.getCardTypeText(template.cardType),
              ),
              _buildDetailRow('Mô tả', template.description),
              _buildDetailRow('Thời hạn', _getDurationText(template)),
              _buildDetailRow(
                'Giá',
                '${NumberFormat('#,###', 'vi_VN').format(template.price)} VNĐ',
              ),

              // Preview dates
              const SizedBox(height: 16),
              const Text(
                'Nếu mua hôm nay:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPreviewDates(template),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => LoadingButton(
                        text: 'Mua ngay',
                        isLoading: controller.isPurchasing.value,
                        backgroundColor: const Color(0xFF00BCD4),
                        onPressed: () {
                          Get.back();
                          _confirmPurchase(template);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPreviewDates(MembershipCard template) {
    final now = DateTime.now();
    final endDate = MembershipCard.calculateEndDate(
      now,
      template.durationType,
      template.duration,
      template.customEndDate,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ngày bắt đầu:'),
              Text(
                DateFormat('dd/MM/yyyy').format(now),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ngày kết thúc:'),
              Text(
                DateFormat('dd/MM/yyyy').format(endDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmPurchase(MembershipCard template) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận mua thẻ tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn mua thẻ "${template.cardName}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Tên thẻ:'), Text(template.cardName)],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời hạn:'),
                      Text(_getDurationText(template)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá:'),
                      Text(
                        '${NumberFormat('#,###', 'vi_VN').format(template.price)} VNĐ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: 'Xác nhận',
              isLoading: controller.isPurchasing.value,
              backgroundColor: const Color(0xFF00BCD4),
              height: 42,
              onPressed: () => _processPurchase(template),
            ),
          ),
        ],
      ),
    );
  }

  void _processPurchase(MembershipCard template) async {
    Get.back(); // Close dialog first

    final authController = Get.find<AuthController>();
    final userId = authController.user?.uid;

    if (userId == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng đăng nhập để mua thẻ tập',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Create purchase record first (with pending status)
      final purchaseId = await controller.createPendingPurchase(
        userId,
        template,
      );

      if (purchaseId != null) {
        // Navigate to checkout page
        Get.toNamed(
          '/checkout',
          arguments: {'membershipCard': template, 'purchaseId': purchaseId},
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể tạo đơn hàng. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
