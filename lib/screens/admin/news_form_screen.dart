import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/news_controller.dart';
import '../../models/news.dart';
import '../../widgets/image_base64_widget.dart';

class NewsFormScreen extends StatefulWidget {
  final String? newsId;

  const NewsFormScreen({super.key, this.newsId});

  @override
  State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();

  // Image URL controllers
  final List<String> _imageUrls = [];
  final List<String> _detailImageUrls = [];

  NewsType _selectedType = NewsType.general;
  bool _isPublished = true;
  News? _currentNews;

  bool get _isEditing => widget.newsId != null;

  @override
  void initState() {
    super.initState();
    _initializeImageControllers();
    if (_isEditing) {
      _loadExistingNews();
    }
  }

  void _initializeImageControllers() {
    // Initialize 5 empty strings for main images
    for (int i = 0; i < 5; i++) {
      _imageUrls.add('');
    }

    // Initialize 5 empty strings for detail images
    for (int i = 0; i < 5; i++) {
      _detailImageUrls.add('');
    }
  }

  Future<void> _loadExistingNews() async {
    final controller = Get.find<NewsController>();
    final news = await controller.getNewsById(widget.newsId!);

    if (news != null) {
      setState(() {
        _currentNews = news;
        _titleController.text = news.title;
        _descriptionController.text = news.description;
        _videoUrlController.text = news.videoUrl ?? '';
        _selectedType = news.type;
        _isPublished = news.isPublished;

        // Load image URLs
        for (int i = 0; i < news.images.length && i < 5; i++) {
          if (i < _imageUrls.length) {
            _imageUrls[i] = news.images[i];
          }
        }

        for (int i = 0; i < news.detailImages.length && i < 5; i++) {
          if (i < _detailImageUrls.length) {
            _detailImageUrls[i] = news.detailImages[i];
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _isEditing ? 'Chỉnh Sửa Bản Tin' : 'Tạo Bản Tin Mới',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Preview Button
              IconButton(
                icon: const Icon(Icons.preview),
                onPressed: _isFormValid() ? _previewNews : null,
              ),
              // Save Button
              Obx(
                () => TextButton(
                  onPressed:
                      controller.isCreating.value || controller.isUpdating.value
                      ? null
                      : _saveNews,
                  child:
                      controller.isCreating.value || controller.isUpdating.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Lưu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  _buildSectionCard(
                    title: 'Thông Tin Cơ Bản',
                    icon: Icons.info_outline,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Nhập tiêu đề bản tin',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<NewsType>(
                        value: _selectedType,
                        onChanged: (NewsType? value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Loại tin *',
                          border: OutlineInputBorder(),
                        ),
                        items: NewsType.values.map((type) {
                          return DropdownMenuItem<NewsType>(
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
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả *',
                          hintText: 'Nhập mô tả chi tiết về bản tin',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                        maxLines: 6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main Images Card
                  _buildSectionCard(
                    title: 'Hình Ảnh Chính (Tối đa 5)',
                    icon: Icons.image,
                    children: [
                      ...List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < 4 ? 16 : 0),
                          child: ImageBase64Widget(
                            key: ValueKey('main_image_$index'),
                            initialImageBase64: _imageUrls.length > index
                                ? _imageUrls[index]
                                : null,
                            onImageUploaded: (base64) {
                              setState(() {
                                if (_imageUrls.length <= index) {
                                  _imageUrls.addAll(
                                    List.filled(
                                      index + 1 - _imageUrls.length,
                                      '',
                                    ),
                                  );
                                }
                                _imageUrls[index] = base64;
                              });
                            },
                            label: 'Ảnh chính ${index + 1}',
                            width: 150,
                            height: 150,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detail Images Card
                  _buildSectionCard(
                    title: 'Ảnh Chi Tiết/Ảnh Phụ (Tối đa 5)',
                    icon: Icons.photo_library,
                    children: [
                      ...List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < 4 ? 16 : 0),
                          child: ImageBase64Widget(
                            key: ValueKey('detail_image_$index'),
                            initialImageBase64: _detailImageUrls.length > index
                                ? _detailImageUrls[index]
                                : null,
                            onImageUploaded: (base64) {
                              setState(() {
                                if (_detailImageUrls.length <= index) {
                                  _detailImageUrls.addAll(
                                    List.filled(
                                      index + 1 - _detailImageUrls.length,
                                      '',
                                    ),
                                  );
                                }
                                _detailImageUrls[index] = base64;
                              });
                            },
                            label: 'Ảnh chi tiết ${index + 1}',
                            width: 150,
                            height: 150,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Video Card
                  _buildSectionCard(
                    title: 'Video',
                    icon: Icons.videocam,
                    children: [
                      TextFormField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Link video',
                          hintText: 'https://youtube.com/watch?v=...',
                          border: OutlineInputBorder(),
                          helperText: 'Để trống nếu không có video',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!_isValidUrl(value)) {
                              return 'URL video không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Publishing Options Card
                  _buildSectionCard(
                    title: 'Tùy Chọn Xuất Bản',
                    icon: Icons.publish,
                    children: [
                      SwitchListTile(
                        title: const Text('Xuất bản ngay'),
                        subtitle: Text(
                          _isPublished
                              ? 'Bản tin sẽ hiển thị công khai'
                              : 'Lưu thành bản nháp',
                        ),
                        value: _isPublished,
                        onChanged: (bool value) {
                          setState(() {
                            _isPublished = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool _isFormValid() {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = Get.find<NewsController>();

    final images = _imageUrls.where((url) => url.isNotEmpty).toList();
    final detailImages = _detailImageUrls
        .where((url) => url.isNotEmpty)
        .toList();
    final videoUrl = _videoUrlController.text.trim();

    final news = News(
      id: _currentNews?.id,
      title: _titleController.text.trim(),
      type: _selectedType,
      images: images,
      description: _descriptionController.text.trim(),
      detailImages: detailImages,
      videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
      isPublished: _isPublished,
      authorId: _currentNews?.authorId ?? '',
      authorName: _currentNews?.authorName ?? '',
      createdAt: _currentNews?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await controller.updateNews(news);
    } else {
      success = await controller.createNews(news);
    }

    if (success) {
      Get.back();
    }
  }

  void _previewNews() {
    if (!_isFormValid()) {
      Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ thông tin cơ bản');
      return;
    }

    final images = _imageUrls.where((url) => url.isNotEmpty).toList();
    final detailImages = _detailImageUrls
        .where((url) => url.isNotEmpty)
        .toList();
    final videoUrl = _videoUrlController.text.trim();

    final previewNews = News(
      title: _titleController.text.trim(),
      type: _selectedType,
      images: images,
      description: _descriptionController.text.trim(),
      detailImages: detailImages,
      videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
      isPublished: _isPublished,
      authorId: 'preview',
      authorName: 'Preview',
    );

    Get.toNamed('/admin/news-management/preview', arguments: previewNews);
  }
}
