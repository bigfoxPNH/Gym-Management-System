import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/news_user_controller.dart';
import '../../models/news.dart';
import '../../routes/app_routes.dart';
import '../../widgets/robust_image.dart';
import '../../widgets/loading_overlay.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('NewsFeedScreen: build() called');
    return GetX<NewsUserController>(
      init: NewsUserController(),
      builder: (controller) {
        print('NewsFeedScreen: builder called, controller loaded');
        print('NewsFeedScreen: isLoading: ${controller.isLoading.value}');
        print(
          'NewsFeedScreen: filteredNewsList.length: ${controller.filteredNewsList.length}',
        );
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Bảng Tin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.cyan[600],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadPublishedNews(refresh: true),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyan[600],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: controller.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bản tin...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Type Filter
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => DropdownButtonFormField<NewsType?>(
                              value: controller.selectedType.value,
                              onChanged: controller.setSelectedType,
                              decoration: InputDecoration(
                                labelText: 'Loại tin',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<NewsType?>(
                                  value: null,
                                  child: Text('Tất cả'),
                                ),
                                ...NewsType.values.map(
                                  (type) => DropdownMenuItem<NewsType?>(
                                    value: type,
                                    child: Text(
                                      News(
                                        title: '',
                                        type: type,
                                        description: '',
                                        authorId: '',
                                        authorName: '',
                                      ).typeDisplayName,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: controller.clearFilters,
                          icon: const Icon(Icons.clear, color: Colors.white),
                          tooltip: 'Xóa bộ lọc',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // News List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.filteredNewsList.isEmpty) {
                    return const CenterLoading(message: 'Đang tải bản tin...');
                  }

                  if (controller.filteredNewsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bản tin nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy kiểm tra lại sau',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        controller.loadPublishedNews(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.filteredNewsList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == controller.filteredNewsList.length) {
                          // Load more indicator
                          if (controller.hasMore.value) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Obx(
                                  () => controller.isLoading.value
                                      ? const InlineLoading(
                                          message: 'Đang tải...',
                                        )
                                      : TextButton(
                                          onPressed: () =>
                                              controller.loadPublishedNews(),
                                          child: const Text('Tải thêm'),
                                        ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final news = controller.filteredNewsList[index];
                        return _buildNewsCard(context, news, controller);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    News news,
    NewsUserController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Get.toNamed('/news-detail/${news.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(news.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getTypeColor(news.type),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      news.typeDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(news.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(news.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Main Image
            if (news.mainImage.isNotEmpty)
              RobustImage(
                imageUrl: news.mainImage,
                height: 200,
                width: double.infinity,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    news.shortDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Author
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        news.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interaction Bar
                  Row(
                    children: [
                      // Like Button
                      Obx(
                        () => InkWell(
                          onTap: () => controller.toggleLike(news.id!),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: controller.isLiked(news.id!)
                                  ? Colors.red[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.isLiked(news.id!)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: controller.isLiked(news.id!)
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (controller.newsLikeCount[news.id!] ??
                                          news.interaction.likes)
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: controller.isLiked(news.id!)
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Share Button
                      InkWell(
                        onTap: () => controller.shareNews(news.id!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.share,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (controller.newsShareCount[news.id!] ??
                                        news.interaction.shares)
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Comment Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.comment,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (controller.newsCommentCount[news.id!] ??
                                      news.interaction.comments)
                                  .toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // More Options
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleMenuAction(value, news, controller),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Báo cáo',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(Icons.more_vert, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NewsType type) {
    switch (type) {
      case NewsType.general:
        return Colors.blue;
      case NewsType.promotion:
        return Colors.orange;
      case NewsType.event:
        return Colors.purple;
      case NewsType.announcement:
        return Colors.red;
      case NewsType.fitness:
        return Colors.green;
      case NewsType.nutrition:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _handleMenuAction(
    String action,
    News news,
    NewsUserController controller,
  ) {
    switch (action) {
      case 'report':
        _showReportDialog(news, controller);
        break;
    }
  }

  void _showReportDialog(News news, NewsUserController controller) {
    String selectedReason = 'Nội dung không phù hợp';
    final List<String> reasons = [
      'Nội dung không phù hợp',
      'Thông tin sai lệch',
      'Spam hoặc quảng cáo',
      'Nội dung xúc phạm',
      'Khác',
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('Báo cáo bài viết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lý do báo cáo:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedReason,
              onChanged: (String? value) {
                if (value != null) {
                  selectedReason = value;
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: reasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.reportNews(news.id!, selectedReason);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Báo cáo'),
          ),
        ],
      ),
    );
  }
}
