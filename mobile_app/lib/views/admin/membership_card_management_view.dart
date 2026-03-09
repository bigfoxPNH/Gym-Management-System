import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/membership_card_controller.dart';
import '../../models/membership_card.dart';
import '../../widgets/loading_overlay.dart';

class MembershipCardManagementView extends StatelessWidget {
  const MembershipCardManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MembershipCardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Thẻ Tập',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCardDialog(context, controller),
            tooltip: 'Thêm thẻ tập mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Bar
          _buildStatisticsBar(controller),

          // Search and Filter Section
          _buildSearchAndFilterSection(controller),

          // Cards List
          Expanded(child: _buildCardsList(controller)),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar(MembershipCardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng số',
                '${controller.totalCards}',
                Icons.card_membership,
                Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Đang hoạt động',
                '${controller.activeCards}',
                Icons.check_circle,
                Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hội viên',
                '${controller.memberCards}',
                Icons.person,
                Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'VIP',
                '${controller.vipCards}',
                Icons.star,
                Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(MembershipCardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thẻ tập...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Obx(
                  () => FilterChip(
                    label: const Text('Tất cả'),
                    selected: controller.typeFilter.value == null,
                    onSelected: (_) => controller.setTypeFilter(null),
                  ),
                ),
                const SizedBox(width: 8),
                ...CardType.values.map(
                  (type) => Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.label),
                        selected: controller.typeFilter.value == type,
                        onSelected: (_) => controller.setTypeFilter(
                          controller.typeFilter.value == type ? null : type,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => FilterChip(
                    label: Text(
                      controller.isActiveFilter.value
                          ? 'Đang hoạt động'
                          : 'Tất cả trạng thái',
                    ),
                    selected: controller.isActiveFilter.value,
                    onSelected: (_) => controller.toggleActiveFilter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(MembershipCardController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const CenterLoading(message: 'Đang tải danh sách thẻ tập...');
      }

      if (controller.filteredCards.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredCards.length,
        itemBuilder: (context, index) {
          final card = controller.filteredCards[index];
          return _buildCardItem(context, card, controller);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có thẻ tập nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử thay đổi từ khóa tìm kiếm',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    MembershipCard card,
    MembershipCardController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCardTypeColor(card.cardType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.cardType.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge (template status)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Template',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!card.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Không hoạt động',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuAction(context, value, card, controller),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Xem chi tiết'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Chỉnh sửa'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          card.isActive ? Icons.pause : Icons.play_arrow,
                        ),
                        title: Text(
                          card.isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Xóa', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Name
            Text(
              card.cardName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Thời gian',
                    card.getFormattedDuration(),
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Giá tiền',
                    card.getFormattedPrice(),
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // End Date and Template Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Hiệu lực',
                    card.getFormattedDuration(),
                    Icons.schedule_outlined,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Nếu mua hôm nay',
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(card.calculateEndDateFromPurchase()),
                    Icons.today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
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

  Color _getCardTypeColor(CardType cardType) {
    switch (cardType) {
      case CardType.member:
        return Colors.blue;
      case CardType.premium:
        return Colors.orange;
      case CardType.vip:
        return Colors.purple;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    MembershipCard card,
    MembershipCardController controller,
  ) {
    switch (action) {
      case 'view':
        _showCardDetailsDialog(context, card);
        break;
      case 'edit':
        _showEditCardDialog(context, controller, card);
        break;
      case 'toggle':
        controller.toggleCardStatus(card);
        break;
      case 'delete':
        controller.deleteCard(card);
        break;
    }
  }

  void _showCreateCardDialog(
    BuildContext context,
    MembershipCardController controller,
  ) {
    controller.clearForm();
    _showCardDialog(context, controller, 'Tạo Thẻ Tập Mới', false);
  }

  void _showEditCardDialog(
    BuildContext context,
    MembershipCardController controller,
    MembershipCard card,
  ) {
    controller.loadCardForEdit(card);
    _showCardDialog(context, controller, 'Chỉnh Sửa Thẻ Tập', true);
  }

  void _showCardDialog(
    BuildContext context,
    MembershipCardController controller,
    String title,
    bool isEdit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add_circle_outline,
                    color: Colors.purple[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[900],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCardForm(context, controller),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            (isEdit
                                ? controller.isUpdating.value
                                : controller.isCreating.value)
                            ? null
                            : () async {
                                if (isEdit) {
                                  await controller.updateCard();
                                } else {
                                  await controller.createCard();
                                }
                                if (!controller.isCreating.value &&
                                    !controller.isUpdating.value) {
                                  Get.back();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            (isEdit
                                ? controller.isUpdating.value
                                : controller.isCreating.value)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
                      ),
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

  Widget _buildCardForm(
    BuildContext context,
    MembershipCardController controller,
  ) {
    return Column(
      children: [
        // Card Name
        TextField(
          controller: controller.cardNameController,
          decoration: InputDecoration(
            labelText: 'Tên thẻ tập *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.card_membership),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: controller.descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Mô tả thẻ tập *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description),
            hintText: 'Nhập mô tả chi tiết về thẻ tập...',
          ),
        ),
        const SizedBox(height: 16),

        // Card Type
        Obx(
          () => DropdownButtonFormField<CardType>(
            value: controller.selectedCardType.value,
            onChanged: (value) => controller.selectedCardType.value = value!,
            decoration: InputDecoration(
              labelText: 'Loại thẻ *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: CardType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Duration Type and Duration
        Obx(() {
          final isCustomType =
              controller.selectedDurationType.value == DurationType.custom;

          return Column(
            children: [
              // Duration Type (full width)
              DropdownButtonFormField<DurationType>(
                value: controller.selectedDurationType.value,
                onChanged: (value) {
                  controller.selectedDurationType.value = value!;
                  if (value != DurationType.custom) {
                    controller.selectedCustomEndDate.value = null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Loại thời gian *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.schedule),
                ),
                items: DurationType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Duration value (conditional)
              if (isCustomType)
                TextFormField(
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          controller.selectedCustomEndDate.value ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      controller.selectedCustomEndDate.value = date;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Ngày kết thúc *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.event),
                    hintText: 'Chọn ngày',
                  ),
                  controller: TextEditingController(
                    text: controller.selectedCustomEndDate.value != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.selectedCustomEndDate.value!)
                        : '',
                  ),
                )
              else
                TextField(
                  controller: controller.durationController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: InputDecoration(
                    labelText: 'Số lượng *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                    counterText: '',
                    hintText: 'Tối đa 5 ký tự số',
                  ),
                  onChanged: (value) {
                    if (value.length > 5) {
                      Get.snackbar(
                        'Cảnh báo',
                        'Số lượng không được vượt quá 5 ký tự',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      controller.durationController.text = value.substring(
                        0,
                        5,
                      );
                      controller.durationController.selection =
                          TextSelection.fromPosition(TextPosition(offset: 5));
                    }
                    controller.selectedDurationType.refresh();
                  },
                ),
            ],
          );
        }),
        const SizedBox(height: 16),

        // Price
        TextField(
          controller: controller.priceController,
          keyboardType: TextInputType.number,
          maxLength: 9,
          decoration: InputDecoration(
            labelText: 'Giá tiền (VND) *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.attach_money),
            counterText: '',
            helperText: 'Tối đa 9 ký tự số',
            helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          onChanged: (value) {
            // Check length limit
            if (value.length > 9) {
              Get.snackbar(
                'Cảnh báo',
                'Giá tiền không được vượt quá 9 ký tự',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
              controller.priceController.text = value.substring(0, 9);
              controller.priceController.selection = TextSelection.fromPosition(
                TextPosition(offset: 9),
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // End Date Preview (calculated automatically)
        Obx(() {
          final now = DateTime.now();
          DateTime previewEndDate;

          if (controller.selectedDurationType.value == DurationType.custom) {
            previewEndDate =
                controller.selectedCustomEndDate.value ??
                now.add(const Duration(days: 30));
          } else {
            final duration = int.tryParse(controller.durationController.text);
            if (duration != null && duration > 0) {
              previewEndDate = MembershipCard.calculateEndDate(
                now,
                controller.selectedDurationType.value,
                duration,
                null,
              );
            } else {
              // Show default preview with duration = 1
              previewEndDate = MembershipCard.calculateEndDate(
                now,
                controller.selectedDurationType.value,
                1,
                null,
              );
            }
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Preview: Nếu user mua hôm nay',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '📅 Ngày mua: ${DateFormat('dd/MM/yyyy').format(now)}',
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
                Text(
                  '⏰ Ngày hết hạn: ${DateFormat('dd/MM/yyyy').format(previewEndDate)}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '🎯 Hiệu lực: ${previewEndDate.difference(now).inDays} ngày',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showCardDetailsDialog(BuildContext context, MembershipCard card) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Chi Tiết Thẻ Tập',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Card Info
                _buildDetailRow('Tên thẻ', card.cardName),
                _buildDetailRow('Mô tả', card.description),
                _buildDetailRow('Loại thẻ', card.cardType.label),
                _buildDetailRow('Thời gian', card.getFormattedDuration()),
                _buildDetailRow('Giá tiền', card.getFormattedPrice()),
                _buildDetailRow('Preview', card.getPreviewInfo()),
                _buildDetailRow(
                  'Trạng thái',
                  card.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                ),
                _buildDetailRow(
                  'Ngày tạo',
                  DateFormat('dd/MM/yyyy HH:mm').format(card.createdAt),
                ),
                _buildDetailRow(
                  'Cập nhật lần cuối',
                  DateFormat('dd/MM/yyyy HH:mm').format(card.updatedAt),
                ),

                const SizedBox(height: 24),

                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
