import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';
import 'auth_controller.dart';

class NewsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'news';

  // Observable lists
  final RxList<News> newsList = <News>[].obs;
  final RxList<News> filteredNewsList = <News>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final Rx<NewsType?> selectedType = Rx<NewsType?>(null);
  final RxBool showPublishedOnly = true.obs;

  // Pagination
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  final RxBool hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadNews();

    // Setup search and filter listeners
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedType, (_) => _applyFilters());
    ever(showPublishedOnly, (_) => _applyFilters());
  }

  // Load news with pagination
  Future<void> loadNews({bool refresh = false}) async {
    try {
      if (refresh) {
        _lastDocument = null;
        hasMore.value = true;
        newsList.clear();
      }

      if (!hasMore.value) return;

      isLoading.value = true;

      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        return;
      }

      final List<News> loadedNews = snapshot.docs
          .map((doc) => News.fromFirestore(doc))
          .toList();

      if (refresh) {
        newsList.assignAll(loadedNews);
      } else {
        newsList.addAll(loadedNews);
      }

      _lastDocument = snapshot.docs.last;
      hasMore.value = snapshot.docs.length == _limit;

      _applyFilters();
    } catch (e) {
      print('Error loading news: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách bản tin');
    } finally {
      isLoading.value = false;
    }
  }

  // Create new news
  Future<bool> createNews(News news) async {
    try {
      isCreating.value = true;

      // Validate input
      if (!_validateNews(news)) return false;

      // Add author info
      final authController = Get.find<AuthController>();
      final newsWithAuthor = news.copyWith(
        authorId: authController.user?.uid ?? '',
        authorName: authController.userAccount?.fullName ?? 'Admin',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(newsWithAuthor.toJson());

      Get.snackbar('Thành công', 'Tạo bản tin thành công');
      await loadNews(refresh: true);
      return true;
    } catch (e) {
      print('Error creating news: $e');
      Get.snackbar('Lỗi', 'Không thể tạo bản tin');
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Update existing news
  Future<bool> updateNews(News news) async {
    try {
      if (news.id == null) return false;

      isUpdating.value = true;

      if (!_validateNews(news)) return false;

      final updatedNews = news.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_collection)
          .doc(news.id)
          .update(updatedNews.toJson());

      Get.snackbar('Thành công', 'Cập nhật bản tin thành công');
      await loadNews(refresh: true);
      return true;
    } catch (e) {
      print('Error updating news: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật bản tin');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Delete news
  Future<bool> deleteNews(String newsId) async {
    try {
      isDeleting.value = true;

      await _firestore.collection(_collection).doc(newsId).delete();

      newsList.removeWhere((news) => news.id == newsId);
      _applyFilters();

      Get.snackbar('Thành công', 'Xóa bản tin thành công');
      return true;
    } catch (e) {
      print('Error deleting news: $e');
      Get.snackbar('Lỗi', 'Không thể xóa bản tin');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  // Get news by ID
  Future<News?> getNewsById(String newsId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(newsId).get();
      if (doc.exists) {
        return News.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting news by ID: $e');
      return null;
    }
  }

  // Toggle publish status
  Future<bool> togglePublishStatus(String newsId) async {
    try {
      final news = newsList.firstWhereOrNull((n) => n.id == newsId);
      if (news == null) return false;

      final updatedNews = news.copyWith(
        isPublished: !news.isPublished,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(newsId).update({
        'isPublished': updatedNews.isPublished,
      });

      // Update local list
      final index = newsList.indexWhere((n) => n.id == newsId);
      if (index != -1) {
        newsList[index] = updatedNews;
        _applyFilters();
      }

      return true;
    } catch (e) {
      print('Error toggling publish status: $e');
      Get.snackbar('Lỗi', 'Không thể thay đổi trạng thái bản tin');
      return false;
    }
  }

  // Update interaction (like, share, comment, report)
  Future<bool> updateInteraction(
    String newsId,
    NewsInteraction interaction,
  ) async {
    try {
      await _firestore.collection(_collection).doc(newsId).update({
        'interaction': interaction.toJson(),
      });

      // Update local list
      final index = newsList.indexWhere((n) => n.id == newsId);
      if (index != -1) {
        final updatedNews = newsList[index].copyWith(interaction: interaction);
        newsList[index] = updatedNews;
        _applyFilters();
      }

      return true;
    } catch (e) {
      print('Error updating interaction: $e');
      return false;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();
  }

  void setSelectedType(NewsType? type) {
    selectedType.value = type;
  }

  void setShowPublishedOnly(bool value) {
    showPublishedOnly.value = value;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedType.value = null;
    showPublishedOnly.value = true;
  }

  // Apply filters to news list
  void _applyFilters() {
    List<News> filtered = List.from(newsList);

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((news) {
        return news.title.toLowerCase().contains(searchQuery.value) ||
            news.description.toLowerCase().contains(searchQuery.value) ||
            news.authorName.toLowerCase().contains(searchQuery.value);
      }).toList();
    }

    // Filter by type
    if (selectedType.value != null) {
      filtered = filtered
          .where((news) => news.type == selectedType.value)
          .toList();
    }

    // Filter by published status
    if (showPublishedOnly.value) {
      filtered = filtered.where((news) => news.isPublished).toList();
    }

    filteredNewsList.assignAll(filtered);
  }

  // Validate news data
  bool _validateNews(News news) {
    if (news.title.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Tiêu đề không được để trống');
      return false;
    }

    if (news.description.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Mô tả không được để trống');
      return false;
    }

    if (!news.isValidImageCount) {
      Get.snackbar('Lỗi', 'Số lượng ảnh chính không được vượt quá 5');
      return false;
    }

    if (!news.isValidDetailImageCount) {
      Get.snackbar('Lỗi', 'Số lượng ảnh chi tiết không được vượt quá 5');
      return false;
    }

    // Validate image URLs
    for (final imageUrl in [...news.images, ...news.detailImages]) {
      if (imageUrl.isNotEmpty && !_isValidUrl(imageUrl)) {
        Get.snackbar('Lỗi', 'URL ảnh không hợp lệ: $imageUrl');
        return false;
      }
    }

    // Validate video URL
    if (news.videoUrl != null &&
        news.videoUrl!.isNotEmpty &&
        !_isValidUrl(news.videoUrl!)) {
      Get.snackbar('Lỗi', 'URL video không hợp lệ');
      return false;
    }

    return true;
  }

  // Basic URL validation (supports both HTTP URLs and Base64 data URLs)
  bool _isValidUrl(String url) {
    try {
      // Check if it's a base64 data URL
      if (url.startsWith('data:image/')) {
        return url.contains(',') && url.length > 100; // Basic base64 validation
      }

      // Check if it's a regular HTTP/HTTPS URL
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Get statistics
  Map<String, int> getNewsStatistics() {
    final Map<String, int> stats = {};

    for (final type in NewsType.values) {
      stats[type.name] = newsList.where((news) => news.type == type).length;
    }

    stats['total'] = newsList.length;
    stats['published'] = newsList.where((news) => news.isPublished).length;
    stats['draft'] = newsList.where((news) => !news.isPublished).length;

    return stats;
  }

  // Get most interacted news
  List<News> getMostInteractedNews({int limit = 5}) {
    final sortedNews = List<News>.from(newsList);
    sortedNews.sort((a, b) {
      final aTotal =
          a.interaction.likes + a.interaction.shares + a.interaction.comments;
      final bTotal =
          b.interaction.likes + b.interaction.shares + b.interaction.comments;
      return bTotal.compareTo(aTotal);
    });

    return sortedNews.take(limit).toList();
  }
}
