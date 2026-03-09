import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_loading_issue_dialog.dart';

class RobustImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const RobustImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  bool _isBase64Image(String url) {
    return url.startsWith('data:image/') ||
        (url.length > 100 && !url.startsWith('http'));
  }

  Uint8List? _decodeBase64(String base64String) {
    try {
      // Remove data URL prefix if present
      if (base64String.startsWith('data:image/')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          base64String = base64String.substring(commaIndex + 1);
        }
      }

      return base64Decode(base64String);
    } catch (e) {
      print('RobustImage: Base64 decode failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    // Check if this is a base64 image
    if (_isBase64Image(imageUrl)) {
      final imageBytes = _decodeBase64(imageUrl);
      if (imageBytes != null) {
        Widget imageWidget = Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorWidget();
          },
        );

        if (borderRadius != null) {
          imageWidget = ClipRRect(
            borderRadius: borderRadius!,
            child: imageWidget,
          );
        }

        return imageWidget;
      } else {
        return errorWidget ?? _buildErrorWidget();
      }
    }

    // Handle network images
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        print('RobustImage: Failed to load image $imageUrl - $error');

        // Try with different approach for external URLs
        if (imageUrl.startsWith('http') &&
            !imageUrl.contains('localhost') &&
            !imageUrl.contains('127.0.0.1')) {
          return _buildProxyImage();
        }

        return errorWidget ?? _buildErrorWidget();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey[600], size: 32),
          const SizedBox(height: 8),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProxyImage() {
    // For CORS issues, we can try using a CORS proxy or suggest alternative loading methods
    return InkWell(
      onTap: () => ImageLoadingIssueDialog.show(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: borderRadius,
          border: Border.all(color: Colors.orange[200]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: Colors.orange[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Ảnh từ nguồn bên ngoài',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng tải ảnh lên Firebase',
              style: TextStyle(color: Colors.orange[600], fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              'để hiển thị trong ứng dụng web',
              style: TextStyle(color: Colors.orange[600], fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nhấn để xem hướng dẫn',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
