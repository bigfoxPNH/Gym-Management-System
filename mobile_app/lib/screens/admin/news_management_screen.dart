import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/news_controller.dart';
import '../../models/news.dart';
import '../../widgets/robust_image.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/loading_button.dart';

class NewsManagementScreen extends StatelessWidget {
  const NewsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewsController>(
      init: NewsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Quản Lý Bản Tin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadNews(refresh: true),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
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

                    // Filter Row
                    Row(
                      children: [
                        // Type Filter
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

                        // Published Filter
                        Expanded(
                          child: Obx(
                            () => SwitchListTile(
                              title: const Text(
                                'Chỉ hiển thị đã xuất bản',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              value: controller.showPublishedOnly.value,
                              onChanged: controller.setShowPublishedOnly,
                              activeColor: Colors.orange,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Statistics Bar
              Obx(() {
                final stats = controller.getNewsStatistics();
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Tổng số',
                        stats['total'] ?? 0,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Đã xuất bản',
                        stats['published'] ?? 0,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Bản nháp',
                        stats['draft'] ?? 0,
                        Colors.orange,
                      ),
                    ],
                  ),
                );
              }),

              // News List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.filteredNewsList.isEmpty) {
                    return const CenterLoading(
                      message: 'Đang tải danh sách bản tin...',
                    );
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
                            'Hãy tạo bản tin đầu tiên',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.loadNews(refresh: true),
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
                                      ? const CircularProgressIndicator()
                                      : TextButton(
                                          onPressed: () =>
                                              controller.loadNews(),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Get.toNamed('/admin/news-management/create'),
            icon: const Icon(Icons.add),
            label: const Text('Tạo bản tin'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    News news,
    NewsController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.toNamed('/admin/news-management/detail/${news.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(news.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTypeColor(news.type),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      news.typeDisplayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(news.type),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Published Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: news.isPublished
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          news.isPublished
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 12,
                          color: news.isPublished
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          news.isPublished ? 'Công khai' : 'Bản nháp',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: news.isPublished
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // More Options
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, news, controller),
                    itemBuilder: (context) => [
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
                      PopupMenuItem(
                        value: 'toggle_publish',
                        child: Row(
                          children: [
                            Icon(
                              news.isPublished
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(news.isPublished ? 'Ẩn bản tin' : 'Xuất bản'),
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
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Image
              if (news.mainImage.isNotEmpty)
                RobustImage(
                  imageUrl: news.mainImage,
                  height: 120,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(8),
                ),
              if (news.mainImage.isNotEmpty) const SizedBox(height: 12),

              // Title and Description
              Text(
                news.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                news.shortDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Author and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bởi ${news.authorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(news.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interaction Stats
                  Row(
                    children: [
                      _buildInteractionItem(
                        Icons.favorite,
                        news.interaction.likes,
                      ),
                      const SizedBox(width: 12),
                      _buildInteractionItem(
                        Icons.share,
                        news.interaction.shares,
                      ),
                      const SizedBox(width: 12),
                      _buildInteractionItem(
                        Icons.comment,
                        news.interaction.comments,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionItem(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action, News news, NewsController controller) {
    switch (action) {
      case 'edit':
        Get.toNamed('/admin/news-management/edit/${news.id}');
        break;
      case 'toggle_publish':
        controller.togglePublishStatus(news.id!);
        break;
      case 'delete':
        _showDeleteConfirmation(news, controller);
        break;
    }
  }

  void _showDeleteConfirmation(News news, NewsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa bản tin "${news.title}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingButton(
              text: 'Xóa',
              isLoading: controller.isLoading.value,
              backgroundColor: Colors.red,
              height: 42,
              onPressed: () async {
                await controller.deleteNews(news.id!);
                if (!controller.isLoading.value) {
                  Get.back();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
