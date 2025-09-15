import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/news_controller.dart';
import '../../models/news.dart';

class NewsDetailScreen extends StatelessWidget {
  final String newsId;
  final News? previewNews;

  const NewsDetailScreen({super.key, required this.newsId, this.previewNews});

  bool get _isPreview => previewNews != null;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewsController>(
      init: NewsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _isPreview ? 'Xem Trước Bản Tin' : 'Chi Tiết Bản Tin',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: _isPreview ? Colors.orange[600] : Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (!_isPreview) ...[
                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      Get.toNamed('/admin/news-management/edit/$newsId'),
                ),
                // More Options
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, controller),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'toggle_publish',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Thay đổi trạng thái'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 16),
                          SizedBox(width: 8),
                          Text('Sao chép'),
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
            ],
          ),
          body: _isPreview
              ? _buildNewsContent(previewNews!)
              : FutureBuilder<News?>(
                  future: controller.getNewsById(newsId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không thể tải bản tin',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              child: const Text('Quay lại'),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildNewsContent(snapshot.data!);
                  },
                ),
        );
      },
    );
  }

  Widget _buildNewsContent(News news) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isPreview ? Colors.orange[600] : Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type and Status Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          news.typeDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: news.isPublished
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              news.isPublished
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              news.isPublished ? 'Công khai' : 'Bản nháp',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isPreview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'XEM TRƯỚC',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Author and Date
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        news.authorName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.schedule,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(news.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Images
                if (news.images.isNotEmpty) ...[
                  _buildImageSection('Hình Ảnh Chính', news.images),
                  const SizedBox(height: 24),
                ],

                // Description
                _buildDescriptionSection(news.description),
                const SizedBox(height: 24),

                // Detail Images
                if (news.detailImages.isNotEmpty) ...[
                  _buildImageSection('Hình Ảnh Chi Tiết', news.detailImages),
                  const SizedBox(height: 24),
                ],

                // Video
                if (news.videoUrl != null && news.videoUrl!.isNotEmpty) ...[
                  _buildVideoSection(news.videoUrl!),
                  const SizedBox(height: 24),
                ],

                // Interaction Statistics
                if (!_isPreview) ...[
                  _buildInteractionSection(news.interaction),
                  const SizedBox(height: 24),
                ],

                // Metadata
                _buildMetadataSection(news),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (images.length == 1)
          // Single image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images[0],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          // Multiple images grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội Dung',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            description,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(String videoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.videocam, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Link Video:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      videoUrl,
                      style: TextStyle(
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Implement video opening logic
                  Get.snackbar(
                    'Thông báo',
                    'Tính năng mở video sẽ được triển khai sau',
                  );
                },
                icon: Icon(Icons.open_in_new, color: Colors.blue[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionSection(NewsInteraction interaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống Kê Tương Tác',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInteractionItem(
                Icons.favorite,
                'Thích',
                interaction.likes,
                Colors.red,
              ),
              _buildInteractionItem(
                Icons.share,
                'Chia sẻ',
                interaction.shares,
                Colors.blue,
              ),
              _buildInteractionItem(
                Icons.comment,
                'Bình luận',
                interaction.comments,
                Colors.orange,
              ),
              _buildInteractionItem(
                Icons.report,
                'Báo cáo',
                interaction.reports,
                Colors.red[700]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionItem(
    IconData icon,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMetadataSection(News news) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông Tin Bổ Sung',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('ID:', news.id ?? 'Chưa có'),
          _buildMetadataRow('Tác giả:', news.authorName),
          _buildMetadataRow('Ngày tạo:', _formatDate(news.createdAt)),
          if (news.updatedAt != null)
            _buildMetadataRow(
              'Cập nhật lần cuối:',
              _formatDate(news.updatedAt!),
            ),
          _buildMetadataRow('Số ảnh chính:', news.images.length.toString()),
          _buildMetadataRow(
            'Số ảnh chi tiết:',
            news.detailImages.length.toString(),
          ),
          _buildMetadataRow(
            'Có video:',
            news.videoUrl != null ? 'Có' : 'Không',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action, NewsController controller) {
    switch (action) {
      case 'toggle_publish':
        controller.togglePublishStatus(newsId);
        break;
      case 'duplicate':
        Get.snackbar('Thông báo', 'Tính năng sao chép sẽ được triển khai sau');
        break;
      case 'delete':
        _showDeleteConfirmation(controller);
        break;
    }
  }

  void _showDeleteConfirmation(NewsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bản tin này?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteNews(newsId);
              Get.back(); // Return to list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
