import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/news_user_controller.dart';
import '../../models/news.dart';
import '../../models/comment.dart';
import '../../widgets/robust_image.dart';
import '../../widgets/loading_overlay.dart';

class NewsDetailUserScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailUserScreen({super.key, required this.newsId});

  @override
  State<NewsDetailUserScreen> createState() => _NewsDetailUserScreenState();
}

class _NewsDetailUserScreenState extends State<NewsDetailUserScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewsUserController>(
      builder: (controller) {
        print('NewsDetailUserScreen: Looking for newsId: ${widget.newsId}');
        print(
          'NewsDetailUserScreen: Available news IDs: ${controller.newsList.map((n) => n.id).toList()}',
        );

        final news = controller.getNewsById(widget.newsId);

        // If news not found, try to load it from Firestore
        if (news == null) {
          print(
            'NewsDetailUserScreen: News not found, loading from Firestore...',
          );

          return Scaffold(
            appBar: AppBar(
              title: const Text('Bản tin'),
              backgroundColor: Colors.cyan[600],
              foregroundColor: Colors.white,
            ),
            body: FutureBuilder<News?>(
              future: controller.loadNewsById(widget.newsId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải bản tin...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
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
                        const Text('Không tìm thấy bản tin'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  );
                }

                // News loaded, rebuild to show it
                print(
                  'NewsDetailUserScreen: News loaded successfully, triggering rebuild',
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.update();
                });

                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang hiển thị...'),
                    ],
                  ),
                );
              },
            ),
          );
        }

        // Load comments when screen opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadComments(widget.newsId);
        });

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Chi Tiết Bản Tin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.cyan[600],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
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
                        Text('Báo cáo', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // News Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.cyan[600],
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
                              // Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
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
                                  const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
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
                              _buildImageSection(news.images),
                              const SizedBox(height: 24),
                            ],

                            // Description
                            _buildDescriptionSection(news.description),
                            const SizedBox(height: 24),

                            // Detail Images
                            if (news.detailImages.isNotEmpty) ...[
                              _buildDetailImageSection(news.detailImages),
                              const SizedBox(height: 24),
                            ],

                            // Video
                            if (news.videoUrl != null &&
                                news.videoUrl!.isNotEmpty) ...[
                              _buildVideoSection(news.videoUrl!),
                              const SizedBox(height: 24),
                            ],

                            // Interaction Section
                            _buildInteractionSection(news, controller),
                            const SizedBox(height: 24),

                            // Comments Section
                            _buildCommentsSection(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comment Input
              _buildCommentInput(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(List<String> images) {
    if (images.length == 1) {
      return RobustImage(
        imageUrl: images[0],
        width: double.infinity,
        height: 250,
        borderRadius: BorderRadius.circular(12),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < images.length - 1 ? 12 : 0),
            child: RobustImage(
              imageUrl: images[index],
              width: 300,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
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
        Text(description, style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    );
  }

  Widget _buildDetailImageSection(List<String> detailImages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình Ảnh Chi Tiết',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: detailImages.length,
          itemBuilder: (context, index) {
            return RobustImage(
              imageUrl: detailImages[index],
              borderRadius: BorderRadius.circular(8),
            );
          },
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

        // Video thumbnail container with play button overlay
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
            image: DecorationImage(
              image: NetworkImage(_getYoutubeThumbnail(videoUrl)),
              fit: BoxFit.cover,
              onError: (error, stackTrace) {
                // Fallback if thumbnail fails to load
              },
            ),
          ),
          child: Stack(
            children: [
              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              // Play button in center
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Video action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openVideoUrl(videoUrl),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Xem video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openYouTube(videoUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở YouTube'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _shareVideo(videoUrl),
              icon: const Icon(Icons.share),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to get YouTube thumbnail
  String _getYoutubeThumbnail(String videoUrl) {
    try {
      // Extract video ID from various YouTube URL formats
      String videoId = '';

      if (videoUrl.contains('youtube.com/watch?v=')) {
        videoId = videoUrl.split('watch?v=')[1].split('&')[0];
      } else if (videoUrl.contains('youtu.be/')) {
        videoId = videoUrl.split('youtu.be/')[1].split('?')[0];
      } else if (videoUrl.contains('youtube.com/embed/')) {
        videoId = videoUrl.split('embed/')[1].split('?')[0];
      }

      if (videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    } catch (e) {
      print('Error getting YouTube thumbnail: $e');
    }

    // Fallback: return a placeholder image URL
    return 'https://via.placeholder.com/480x360/cccccc/ffffff?text=VIDEO';
  }

  // Open video directly in YouTube
  Future<void> _openVideoUrl(String videoUrl) async {
    await _openYouTube(videoUrl);
  }

  // Open video in YouTube
  Future<void> _openYouTube(String videoUrl) async {
    try {
      final Uri url = Uri.parse(videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể mở video. Vui lòng kiểm tra lại đường dẫn.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi khi mở video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Share video
  Future<void> _shareVideo(String videoUrl) async {
    try {
      final Uri url = Uri.parse(videoUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chia sẻ video',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildInteractionSection(News news, NewsUserController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like Button
          Obx(
            () => InkWell(
              onTap: () => controller.toggleLike(news.id!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: controller.isLiked(news.id!)
                      ? Colors.red[50]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      controller.isLiked(news.id!)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: controller.isLiked(news.id!)
                          ? Colors.red
                          : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (controller.newsLikeCount[news.id!] ??
                              news.interaction.likes)
                          .toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: controller.isLiked(news.id!)
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Thích',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Share Button
          InkWell(
            onTap: () => controller.shareNews(news.id!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Icon(Icons.share, color: Colors.grey[600], size: 24),
                  const SizedBox(height: 4),
                  Text(
                    (controller.newsShareCount[news.id!] ??
                            news.interaction.shares)
                        .toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Chia sẻ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

          // Comment Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Icon(Icons.comment, color: Colors.grey[600], size: 24),
                const SizedBox(height: 4),
                Text(
                  (controller.newsCommentCount[news.id!] ??
                          news.interaction.comments)
                      .toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Bình luận',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(NewsUserController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bình Luận',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Obx(() {
          if (controller.isLoadingComments.value) {
            return const CenterLoading(message: 'Đang tải bình luận...');
          }

          final comments = controller.getComments(widget.newsId);

          if (comments.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có bình luận nào',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hãy là người đầu tiên bình luận!',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentItem(comment);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.cyan[100],
                backgroundImage: comment.userAvatar.isNotEmpty
                    ? NetworkImage(comment.userAvatar)
                    : null,
                child: comment.userAvatar.isEmpty
                    ? Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.cyan[700],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCommentInput(NewsUserController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => IconButton(
              onPressed: controller.isSubmittingComment.value
                  ? null
                  : () => _submitComment(controller),
              icon: controller.isSubmittingComment.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: InlineLoading(message: ''),
                    )
                  : Icon(Icons.send, color: Colors.cyan[600]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(NewsUserController controller) async {
    final content = _commentController.text.trim();
    if (content.isNotEmpty) {
      await controller.addComment(widget.newsId, content);
      _commentController.clear();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
