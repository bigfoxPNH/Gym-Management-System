import 'package:get/get.dart';
import '../models/membership_purchase.dart';
import '../models/membership_card.dart';
import '../services/membership_purchase_service.dart';
import '../services/membership_card_service.dart';
import '../utils/sample_data_util.dart';

/// Controller for managing membership purchases
class MembershipPurchaseController extends GetxController {
  // Observable lists
  final purchases = <MembershipPurchase>[].obs;
  final availableTemplates = <MembershipCard>[].obs;
  final filteredTemplates = <MembershipCard>[].obs;

  // Loading states
  final isLoading = false.obs;
  final isLoadingTemplates = false.obs;
  final isPurchasing = false.obs;

  // Search and filter
  final searchQuery = ''.obs;
  final selectedCardType = Rxn<CardType>();
  final selectedDurationType = Rxn<DurationType>();
  final sortBy = 'name'.obs; // name, price, duration
  final sortAscending = true.obs;

  // Purchase statistics
  final statistics = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSampleData();
    loadAvailableTemplates();
    _setupSearchListener();
  }

  /// Initialize sample data if needed
  Future<void> _initializeSampleData() async {
    try {
      await SampleDataUtil.addSampleMembershipCards();
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  /// Set up search query listener
  void _setupSearchListener() {
    ever(searchQuery, (_) => _filterTemplates());
    ever(selectedCardType, (_) => _filterTemplates());
    ever(selectedDurationType, (_) => _filterTemplates());
    ever(sortBy, (_) => _sortTemplates());
    ever(sortAscending, (_) => _sortTemplates());
  }

  /// Load available membership card templates
  Future<void> loadAvailableTemplates() async {
    try {
      isLoadingTemplates.value = true;
      final service = MembershipCardService();
      final templates = await service
          .getActiveCards(); // Chỉ lấy thẻ đang hoạt động
      availableTemplates.assignAll(templates);
      _filterTemplates();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách thẻ tập: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingTemplates.value = false;
    }
  }

  /// Purchase a membership template
  Future<bool> purchaseTemplate(
    String userId,
    MembershipCard template, {
    DateTime? startDate,
  }) async {
    try {
      isPurchasing.value = true;
      print(
        'Starting purchase process for userId: $userId, template: ${template.id}',
      );

      final purchase =
          await MembershipPurchaseService.createPurchaseFromTemplate(
            userId: userId,
            template: template,
            startDate: startDate,
          );

      if (purchase != null) {
        print('Purchase successful: ${purchase.id}');
        Get.snackbar(
          'Thành công',
          'Đã mua thẻ tập "${template.cardName}" thành công!',
          snackPosition: SnackPosition.BOTTOM,
        );

        return true;
      } else {
        print('Purchase failed - service returned null');
        Get.snackbar(
          'Lỗi',
          'Không thể mua thẻ tập. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print('Error in purchaseTemplate: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi khi mua thẻ tập: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Create pending purchase for checkout process
  Future<String?> createPendingPurchase(
    String userId,
    MembershipCard template, {
    DateTime? startDate,
  }) async {
    try {
      isPurchasing.value = true;
      print(
        'Creating pending purchase for userId: $userId, template: ${template.id}',
      );

      final purchase =
          await MembershipPurchaseService.createPurchaseFromTemplate(
            userId: userId,
            template: template,
            startDate: startDate,
            status: PurchaseStatus.pending, // Explicitly set pending status
          );

      if (purchase != null) {
        print('Pending purchase created: ${purchase.id}');
        return purchase.id;
      } else {
        print('Failed to create pending purchase - service returned null');
        return null;
      }
    } catch (e) {
      print('Error in createPendingPurchase: $e');
      return null;
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Update purchase status
  Future<bool> updatePurchaseStatus(
    String purchaseId,
    PurchaseStatus status,
  ) async {
    try {
      final success = await MembershipPurchaseService.updatePurchaseStatus(
        purchaseId,
        status,
      );

      if (success) {
        Get.snackbar(
          'Thành công',
          'Đã cập nhật trạng thái thẻ tập',
          snackPosition: SnackPosition.BOTTOM,
        );

        return true;
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể cập nhật trạng thái',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Lỗi khi cập nhật: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get user's active memberships
  Future<List<MembershipPurchase>> getUserActiveMemberships(
    String userId,
  ) async {
    try {
      return await MembershipPurchaseService.getUserActivePurchases(userId);
    } catch (e) {
      print('Error getting active memberships: $e');
      return [];
    }
  }

  /// Load purchase statistics
  Future<void> loadStatistics() async {
    try {
      final stats = await MembershipPurchaseService.getPurchaseStatistics();
      statistics.assignAll(stats);
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  /// Filter templates based on search and filters
  void _filterTemplates() {
    var filtered = availableTemplates.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((template) {
        return template.cardName.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply card type filter
    if (selectedCardType.value != null) {
      filtered = filtered
          .where((template) => template.cardType == selectedCardType.value)
          .toList();
    }

    // Apply duration type filter
    if (selectedDurationType.value != null) {
      filtered = filtered
          .where(
            (template) => template.durationType == selectedDurationType.value,
          )
          .toList();
    }

    filteredTemplates.assignAll(filtered);
    _sortTemplates();
  }

  /// Sort templates
  void _sortTemplates() {
    final templates = filteredTemplates.toList();

    templates.sort((a, b) {
      int comparison = 0;

      switch (sortBy.value) {
        case 'name':
          comparison = a.cardName.compareTo(b.cardName);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'duration':
          comparison = a.duration.compareTo(b.duration);
          break;
      }

      return sortAscending.value ? comparison : -comparison;
    });

    filteredTemplates.assignAll(templates);
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Set card type filter
  void setCardTypeFilter(CardType? cardType) {
    selectedCardType.value = cardType;
  }

  /// Set duration type filter
  void setDurationTypeFilter(DurationType? durationType) {
    selectedDurationType.value = durationType;
  }

  /// Set sort options
  void setSortBy(String sortField) {
    if (sortBy.value == sortField) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortBy.value = sortField;
      sortAscending.value = true;
    }
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedCardType.value = null;
    selectedDurationType.value = null;
    sortBy.value = 'name';
    sortAscending.value = true;
  }

  /// Get template by ID
  MembershipCard? getTemplateById(String templateId) {
    try {
      return availableTemplates.firstWhere(
        (template) => template.id == templateId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user has active membership
  bool hasActiveMembership(List<MembershipPurchase> purchases) {
    final now = DateTime.now();
    return purchases.any(
      (purchase) =>
          purchase.status == PurchaseStatus.active &&
          purchase.endDate.isAfter(now),
    );
  }

  /// Get membership status text
  String getMembershipStatusText(List<MembershipPurchase> purchases) {
    if (purchases.isEmpty) {
      return 'Chưa có thẻ tập';
    }

    final activePurchases = purchases
        .where(
          (purchase) =>
              purchase.status == PurchaseStatus.active &&
              purchase.endDate.isAfter(DateTime.now()),
        )
        .toList();

    if (activePurchases.isEmpty) {
      return 'Không có thẻ tập đang hoạt động';
    }

    final nearest = activePurchases.reduce(
      (a, b) => a.endDate.isBefore(b.endDate) ? a : b,
    );

    return 'Thẻ "${nearest.cardName}" hết hạn ${_formatDate(nearest.endDate)}';
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get card type display text
  String getCardTypeText(CardType cardType) {
    switch (cardType) {
      case CardType.member:
        return 'Thẻ hội viên';
      case CardType.premium:
        return 'Thẻ Premium';
      case CardType.vip:
        return 'Thẻ VIP';
    }
  }

  /// Get duration type display text
  String getDurationTypeText(DurationType durationType) {
    switch (durationType) {
      case DurationType.days:
        return 'ngày';
      case DurationType.months:
        return 'tháng';
      case DurationType.years:
        return 'năm';
      case DurationType.custom:
        return 'tùy chỉnh';
    }
  }
}
