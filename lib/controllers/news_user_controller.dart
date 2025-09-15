import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/news.dart';
import '../models/comment.dart';
import '../routes/app_routes.dart';
import 'auth_controller.dart';

class NewsUserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _newsCollection = 'news';
  final String _commentsCollection = 'comments';
  final String _userInteractionsCollection = 'user_news_interactions';

  // Observable lists
  final RxList<News> newsList = <News>[].obs;
  final RxList<News> filteredNewsList = <News>[].obs;
  final RxMap<String, List<Comment>> newsComments =
      <String, List<Comment>>{}.obs;
  final RxMap<String, bool> userLikedNews = <String, bool>{}.obs;
  final RxMap<String, bool> userSharedNews = <String, bool>{}.obs;

  // Realtime interaction counts
  final RxMap<String, int> newsLikeCount = <String, int>{}.obs;
  final RxMap<String, int> newsCommentCount = <String, int>{}.obs;
  final RxMap<String, int> newsShareCount = <String, int>{}.obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool isSubmittingComment = false.obs;
  final RxBool isSubmittingInteraction = false.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final Rx<NewsType?> selectedType = Rx<NewsType?>(null);

  // Pagination
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  final RxBool hasMore = true.obs;

  // Realtime listeners
  late StreamSubscription<QuerySnapshot>? _newsListener;
  late StreamSubscription<QuerySnapshot>? _commentsListener;

  @override
  void onInit() {
    super.onInit();
    print('NewsUserController: onInit() called');

    // Check if user is authenticated
    final authController = Get.find<AuthController>();
    if (authController.user == null) {
      print('NewsUserController: User not authenticated, redirecting to login');
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập để xem bản tin');
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    print('NewsUserController: User authenticated, loading news');
    loadPublishedNews();
    _setupRealtimeListeners();

    // Setup search and filter listeners
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedType, (_) => _applyFilters());
  }

  // Load published news only
  Future<void> loadPublishedNews({bool refresh = false}) async {
    try {
      print(
        'NewsUserController: Starting loadPublishedNews, refresh: $refresh',
      );

      if (refresh) {
        _lastDocument = null;
        hasMore.value = true;
        newsList.clear();
        userLikedNews.clear();
        userSharedNews.clear();
      }

      if (!hasMore.value) return;

      isLoading.value = true;
      print('NewsUserController: Setting isLoading to true');

      // Simplified query to avoid composite index requirement
      Query query = _firestore
          .collection(_newsCollection)
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      print('NewsUserController: Executing Firebase query...');
      final snapshot = await query.get();
      print('NewsUserController: Received ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        print('NewsUserController: No documents found');
        return;
      }

      print('NewsUserController: Converting documents to News objects...');
      final List<News> loadedNews = snapshot.docs
          .map((doc) {
            print('NewsUserController: Processing doc ${doc.id}');
            return News.fromFirestore(doc);
          })
          .where((news) => news.isPublished)
          .toList(); // Filter published news in code

      print(
        'NewsUserController: Successfully loaded ${loadedNews.length} published news items',
      );

      if (refresh) {
        newsList.assignAll(loadedNews);
      } else {
        newsList.addAll(loadedNews);
      }

      // Initialize realtime interaction counts
      for (final news in loadedNews) {
        if (news.id != null) {
          newsLikeCount[news.id!] = news.interaction.likes;
          newsShareCount[news.id!] = news.interaction.shares;
          // Don't set comment count here, let the realtime listener handle it
        }
      }

      // Sync comment counts with actual Firebase data
      _syncCommentCounts();

      print(
        'NewsUserController: Updated newsList, total count: ${newsList.length}',
      );

      _lastDocument = snapshot.docs.last;
      hasMore.value = snapshot.docs.length == _limit;

      // Load user interactions for these news
      await _loadUserInteractions(loadedNews.map((n) => n.id!).toList());

      _applyFilters();
      print(
        'NewsUserController: Applied filters, filteredNewsList count: ${filteredNewsList.length}',
      );
    } catch (e) {
      print('NewsUserController Error loading news: $e');
      Get.snackbar('Lỗi', 'Không thể tải bản tin');
    } finally {
      isLoading.value = false;
      print('NewsUserController: Setting isLoading to false');
    }
  }

  // Load user interactions (likes, shares)
  Future<void> _loadUserInteractions(List<String> newsIds) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.uid;

      if (userId == null) return;

      for (final newsId in newsIds) {
        final doc = await _firestore
            .collection(_userInteractionsCollection)
            .doc('${userId}_$newsId')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          userLikedNews[newsId] = data['liked'] ?? false;
          userSharedNews[newsId] = data['shared'] ?? false;
        }
      }
    } catch (e) {
      print('Error loading user interactions: $e');
    }
  }

  // Toggle like for news
  Future<void> toggleLike(String newsId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.uid;
      final userName = authController.userAccount?.fullName ?? 'User';

      if (userId == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập để thích bài viết');
        return;
      }

      isSubmittingInteraction.value = true;

      final currentLiked = userLikedNews[newsId] ?? false;
      final newLikedState = !currentLiked;

      // Optimistically update UI
      userLikedNews[newsId] = newLikedState;

      // Update realtime counts
      final currentCount = newsLikeCount[newsId] ?? 0;
      newsLikeCount[newsId] = newLikedState
          ? currentCount + 1
          : currentCount - 1;

      // Update news interaction count
      final newsIndex = newsList.indexWhere((n) => n.id == newsId);
      if (newsIndex != -1) {
        final news = newsList[newsIndex];
        final newLikes = newLikedState
            ? news.interaction.likes + 1
            : news.interaction.likes - 1;

        final updatedInteraction = NewsInteraction(
          likes: newLikes,
          shares: news.interaction.shares,
          comments: news.interaction.comments,
          reports: news.interaction.reports,
        );

        newsList[newsIndex] = news.copyWith(interaction: updatedInteraction);
        _applyFilters();

        // Update Firebase
        await _firestore.collection(_newsCollection).doc(newsId).update({
          'interaction.likes': newLikes,
        });
      }

      // Save user interaction
      await _firestore
          .collection(_userInteractionsCollection)
          .doc('${userId}_$newsId')
          .set({
            'userId': userId,
            'userName': userName,
            'newsId': newsId,
            'liked': newLikedState,
            'shared': userSharedNews[newsId] ?? false,
            'likedAt': newLikedState ? Timestamp.now() : null,
            'updatedAt': Timestamp.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error toggling like: $e');
      // Revert optimistic update
      userLikedNews[newsId] = !(userLikedNews[newsId] ?? false);
      Get.snackbar('Lỗi', 'Không thể thích bài viết');
    } finally {
      isSubmittingInteraction.value = false;
    }
  }

  // Share news
  Future<void> shareNews(String newsId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.uid;
      final userName = authController.userAccount?.fullName ?? 'User';

      if (userId == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập để chia sẻ bài viết');
        return;
      }

      isSubmittingInteraction.value = true;

      final currentShared = userSharedNews[newsId] ?? false;

      if (currentShared) {
        Get.snackbar('Thông báo', 'Bạn đã chia sẻ bài viết này rồi');
        return;
      }

      // Update UI
      userSharedNews[newsId] = true;

      // Update realtime counts
      final currentCount = newsShareCount[newsId] ?? 0;
      newsShareCount[newsId] = currentCount + 1;

      // Update news interaction count
      final newsIndex = newsList.indexWhere((n) => n.id == newsId);
      if (newsIndex != -1) {
        final news = newsList[newsIndex];
        final newShares = news.interaction.shares + 1;

        final updatedInteraction = NewsInteraction(
          likes: news.interaction.likes,
          shares: newShares,
          comments: news.interaction.comments,
          reports: news.interaction.reports,
        );

        newsList[newsIndex] = news.copyWith(interaction: updatedInteraction);
        _applyFilters();

        // Update Firebase
        await _firestore.collection(_newsCollection).doc(newsId).update({
          'interaction.shares': newShares,
        });
      }

      // Save user interaction
      await _firestore
          .collection(_userInteractionsCollection)
          .doc('${userId}_$newsId')
          .set({
            'userId': userId,
            'userName': userName,
            'newsId': newsId,
            'liked': userLikedNews[newsId] ?? false,
            'shared': true,
            'sharedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          }, SetOptions(merge: true));

      Get.snackbar('Thành công', 'Đã chia sẻ bài viết');
    } catch (e) {
      print('Error sharing news: $e');
      userSharedNews[newsId] = false;
      Get.snackbar('Lỗi', 'Không thể chia sẻ bài viết');
    } finally {
      isSubmittingInteraction.value = false;
    }
  }

  // Load comments for a news item
  Future<void> loadComments(String newsId) async {
    try {
      isLoadingComments.value = true;

      // Even simpler query - just get all comments for this news
      final snapshot = await _firestore
          .collection(_commentsCollection)
          .where('newsId', isEqualTo: newsId)
          .get();

      final comments = snapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .where((comment) => !comment.isDeleted) // Filter in code
          .toList();

      // Sort in code instead of using orderBy
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      newsComments[newsId] = comments;
    } catch (e) {
      print('Error loading comments: $e');
      Get.snackbar('Lỗi', 'Không thể tải bình luận');
    } finally {
      isLoadingComments.value = false;
    }
  }

  // Add comment to news
  Future<void> addComment(String newsId, String content) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.uid;
      final userName = authController.userAccount?.fullName ?? 'User';

      if (userId == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập để bình luận');
        return;
      }

      if (content.trim().isEmpty) {
        Get.snackbar('Lỗi', 'Nội dung bình luận không được để trống');
        return;
      }

      isSubmittingComment.value = true;

      final comment = Comment(
        newsId: newsId,
        userId: userId,
        userName: userName,
        userAvatar: authController.userAccount?.avatarUrl ?? '',
        content: content.trim(),
      );

      // Add to Firebase
      await _firestore.collection(_commentsCollection).add(comment.toJson());

      // Update news comment count in Firebase
      final newsIndex = newsList.indexWhere((n) => n.id == newsId);
      if (newsIndex != -1) {
        final news = newsList[newsIndex];
        final newComments = news.interaction.comments + 1;

        // Update Firebase news document
        await _firestore.collection(_newsCollection).doc(newsId).update({
          'interaction.comments': newComments,
        });
      }

      // Reload comments to show the new one immediately
      await loadComments(newsId);

      Get.snackbar('Thành công', 'Đã thêm bình luận');
    } catch (e) {
      print('Error adding comment: $e');
      Get.snackbar('Lỗi', 'Không thể thêm bình luận');
    } finally {
      isSubmittingComment.value = false;
    }
  }

  // Report news
  Future<void> reportNews(String newsId, String reason) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.uid;
      final userName = authController.userAccount?.fullName ?? 'User';

      if (userId == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập để báo cáo');
        return;
      }

      isSubmittingInteraction.value = true;

      // Add report to Firebase
      await _firestore.collection('news_reports').add({
        'newsId': newsId,
        'userId': userId,
        'userName': userName,
        'reason': reason,
        'createdAt': Timestamp.now(),
      });

      // Update news report count
      final newsIndex = newsList.indexWhere((n) => n.id == newsId);
      if (newsIndex != -1) {
        final news = newsList[newsIndex];
        final newReports = news.interaction.reports + 1;

        final updatedInteraction = NewsInteraction(
          likes: news.interaction.likes,
          shares: news.interaction.shares,
          comments: news.interaction.comments,
          reports: newReports,
        );

        newsList[newsIndex] = news.copyWith(interaction: updatedInteraction);
        _applyFilters();

        // Update Firebase news
        await _firestore.collection(_newsCollection).doc(newsId).update({
          'interaction.reports': newReports,
        });
      }

      Get.snackbar('Thành công', 'Đã gửi báo cáo. Cảm ơn bạn!');
    } catch (e) {
      print('Error reporting news: $e');
      Get.snackbar('Lỗi', 'Không thể gửi báo cáo');
    } finally {
      isSubmittingInteraction.value = false;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();
  }

  void setSelectedType(NewsType? type) {
    selectedType.value = type;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedType.value = null;
  }

  // Apply filters to news list
  void _applyFilters() {
    print('NewsUserController: _applyFilters() called');
    print('NewsUserController: newsList.length = ${newsList.length}');
    print('NewsUserController: searchQuery = "${searchQuery.value}"');
    print('NewsUserController: selectedType = ${selectedType.value}');

    List<News> filtered = List.from(newsList);

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((news) {
        return news.title.toLowerCase().contains(searchQuery.value) ||
            news.description.toLowerCase().contains(searchQuery.value);
      }).toList();
    }

    // Filter by type
    if (selectedType.value != null) {
      filtered = filtered
          .where((news) => news.type == selectedType.value)
          .toList();
    }

    filteredNewsList.assignAll(filtered);
    print(
      'NewsUserController: filteredNewsList.length = ${filteredNewsList.length}',
    );
  }

  // Get news by ID
  News? getNewsById(String newsId) {
    try {
      return newsList.firstWhere((news) => news.id == newsId);
    } catch (e) {
      return null;
    }
  }

  // Check if user liked a news
  bool isLiked(String newsId) {
    return userLikedNews[newsId] ?? false;
  }

  // Check if user shared a news
  bool isShared(String newsId) {
    return userSharedNews[newsId] ?? false;
  }

  // Get comments for a news
  List<Comment> getComments(String newsId) {
    return newsComments[newsId] ?? [];
  }

  // Setup realtime listeners for interactions
  void _setupRealtimeListeners() {
    print('NewsUserController: Setting up realtime listeners');

    // Listen to comments for realtime comment count updates
    _commentsListener = _firestore
        .collection(_commentsCollection)
        .snapshots()
        .listen((snapshot) {
          // Count comments for each news
          final Map<String, int> commentCounts = {};

          for (final doc in snapshot.docs) {
            final comment = Comment.fromFirestore(doc);
            final newsId = comment.newsId;
            commentCounts[newsId] = (commentCounts[newsId] ?? 0) + 1;
          }

          // Update comment counts
          for (final entry in commentCounts.entries) {
            newsCommentCount[entry.key] = entry.value;
          }

          // Handle document changes for real-time comment list updates
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final comment = Comment.fromFirestore(change.doc);
              final newsId = comment.newsId;

              // Add to comments list if we're tracking this news
              if (newsComments.containsKey(newsId)) {
                final currentComments = List<Comment>.from(
                  newsComments[newsId]!,
                );
                // Check if comment already exists to avoid duplicates
                if (!currentComments.any((c) => c.id == comment.id)) {
                  currentComments.add(comment);
                  newsComments[newsId] = currentComments;
                }
              }
            }
          }
        });

    // Listen to news for realtime interaction updates (likes and shares only)
    _newsListener = _firestore.collection(_newsCollection).snapshots().listen((
      snapshot,
    ) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final updatedNews = News.fromFirestore(change.doc);
          if (updatedNews.id != null) {
            // Update likes and shares counts only (comments handled separately)
            newsLikeCount[updatedNews.id!] = updatedNews.interaction.likes;
            newsShareCount[updatedNews.id!] = updatedNews.interaction.shares;

            // Don't override comment count from comments listener
            if (!newsCommentCount.containsKey(updatedNews.id!)) {
              newsCommentCount[updatedNews.id!] =
                  updatedNews.interaction.comments;
            }

            // Update the news in our list
            final index = newsList.indexWhere((n) => n.id == updatedNews.id);
            if (index != -1) {
              newsList[index] = updatedNews;
              _applyFilters();
              update(); // Refresh UI to show updated news
            }
          }
        }
      }
    });
  }

  @override
  void onClose() {
    _newsListener?.cancel();
    _commentsListener?.cancel();
    super.onClose();
  }

  // Sync comment counts with actual Firebase data
  Future<void> _syncCommentCounts() async {
    try {
      final snapshot = await _firestore.collection(_commentsCollection).get();
      final Map<String, int> commentCounts = {};

      for (final doc in snapshot.docs) {
        final comment = Comment.fromFirestore(doc);
        final newsId = comment.newsId;
        commentCounts[newsId] = (commentCounts[newsId] ?? 0) + 1;
      }

      // Update comment counts
      for (final entry in commentCounts.entries) {
        newsCommentCount[entry.key] = entry.value;
      }

      print('NewsUserController: Synced comment counts: $commentCounts');
    } catch (e) {
      print('Error syncing comment counts: $e');
    }
  }
}
