import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String) onImageUploaded;
  final String label;
  final double? width;
  final double? height;
  final bool isRequired;

  const ImageUploadWidget({
    Key? key,
    this.initialImageUrl,
    required this.onImageUploaded,
    this.label = 'Chọn ảnh',
    this.width = 200,
    this.height = 200,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  Future<void> _selectAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Show image source dialog
      final XFile? selectedImage =
          await ImageUploadService.showImageSourceDialog();

      if (selectedImage != null) {
        // Upload to Firebase Storage
        final String? uploadedUrl = await ImageUploadService.uploadImage(
          folder: 'news_images',
          imageFile: selectedImage,
        );

        if (uploadedUrl != null) {
          setState(() {
            _currentImageUrl = uploadedUrl;
          });

          widget.onImageUploaded(uploadedUrl);

          Get.snackbar(
            'Thành công',
            'Đã tải ảnh lên thành công!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải ảnh lên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removeImage() async {
    if (_currentImageUrl != null) {
      // Optionally delete from Firebase Storage
      // await ImageUploadService.deleteImage(_currentImageUrl!);

      setState(() {
        _currentImageUrl = null;
      });

      widget.onImageUploaded(''); // Pass empty string to indicate removal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label + (widget.isRequired ? ' *' : ''),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isRequired && _currentImageUrl == null
                  ? Colors.red
                  : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isUploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Đang tải lên...'),
                    ],
                  ),
                )
              : _currentImageUrl != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _currentImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _selectAndUploadImage,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn để chọn ảnh',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_currentImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectAndUploadImage,
                    icon: const Icon(Icons.edit),
                    label: const Text('Thay đổi ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
