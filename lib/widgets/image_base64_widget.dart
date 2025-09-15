import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/image_base64_service.dart';

class ImageBase64Widget extends StatefulWidget {
  final String? initialImageBase64;
  final Function(String) onImageUploaded;
  final String label;
  final double? width;
  final double? height;
  final bool isRequired;

  const ImageBase64Widget({
    Key? key,
    this.initialImageBase64,
    required this.onImageUploaded,
    this.label = 'Chọn ảnh',
    this.width = 200,
    this.height = 200,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<ImageBase64Widget> createState() => _ImageBase64WidgetState();
}

class _ImageBase64WidgetState extends State<ImageBase64Widget> {
  String? _currentImageBase64;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImageBase64 = widget.initialImageBase64;
  }

  Future<void> _selectAndProcessImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Pick and convert image to base64
      final String? base64Image =
          await ImageBase64Service.pickAndConvertImage();

      if (base64Image != null) {
        setState(() {
          _currentImageBase64 = base64Image;
        });

        widget.onImageUploaded(base64Image);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xử lý ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _currentImageBase64 = null;
    });

    widget.onImageUploaded(''); // Pass empty string to indicate removal
  }

  Widget _buildImageDisplay() {
    if (_currentImageBase64 == null || _currentImageBase64!.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Nhấn để chọn ảnh',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '(Tối đa 1MB)',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Convert base64 to display
    final Uint8List? imageBytes = ImageBase64Service.base64ToBytes(
      _currentImageBase64!,
    );

    if (imageBytes == null) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error, color: Colors.red, size: 50),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            imageBytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red, size: 50),
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
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: _removeImage,
            ),
          ),
        ),
        // Show file size info
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${ImageBase64Service.getBase64SizeInMB(_currentImageBase64!).toStringAsFixed(1)}MB',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
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
              color:
                  widget.isRequired &&
                      (_currentImageBase64 == null ||
                          _currentImageBase64!.isEmpty)
                  ? Colors.red
                  : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isProcessing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Đang xử lý...'),
                    ],
                  ),
                )
              : InkWell(
                  onTap: _selectAndProcessImage,
                  child: _buildImageDisplay(),
                ),
        ),
        if (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectAndProcessImage,
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
