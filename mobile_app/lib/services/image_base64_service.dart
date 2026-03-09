import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'simple_web_image_picker.dart';

class ImageBase64Service {
  static final ImagePicker _picker = ImagePicker();

  // Convert image to base64 string
  static Future<String?> convertImageToBase64({
    required XFile imageFile,
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      // Read image bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // For web, we can compress the image
      if (kIsWeb) {
        // Simple compression by resizing would need additional packages
        // For now, we'll just convert to base64
        String base64String = base64Encode(imageBytes);
        return 'data:image/jpeg;base64,$base64String';
      } else {
        // For mobile, convert to base64
        String base64String = base64Encode(imageBytes);
        return 'data:image/jpeg;base64,$base64String';
      }
    } catch (e) {
      print('ImageBase64Service: Convert to base64 failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xử lý ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Pick and convert image to base64
  static Future<String?> pickAndConvertImage() async {
    try {
      // Use different approach for web vs mobile
      if (kIsWeb) {
        // Use HTML input for web
        return await SimpleWebImagePicker.pickImageAsBase64();
      } else {
        // Use image_picker for mobile
        final XFile? selectedImage = await showImageSourceDialog();

        if (selectedImage != null) {
          // Check file size (limit to 1MB for Firestore)
          final bytes = await selectedImage.readAsBytes();
          final sizeInMB = bytes.length / (1024 * 1024);

          if (sizeInMB > 1.0) {
            Get.snackbar(
              'Lỗi',
              'Ảnh quá lớn (${sizeInMB.toStringAsFixed(1)}MB). Vui lòng chọn ảnh nhỏ hơn 1MB.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return null;
          }

          // Convert to base64
          final base64String = await convertImageToBase64(
            imageFile: selectedImage,
          );

          if (base64String != null) {
            Get.snackbar(
              'Thành công',
              'Đã xử lý ảnh thành công!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }

          return base64String;
        }
      }

      return null;
    } catch (e) {
      print('ImageBase64Service: Pick and convert failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Pick single image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('ImageBase64Service: Pick image failed: $e');
      return null;
    }
  }

  // Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('ImageBase64Service: Pick image from camera failed: $e');
      return null;
    }
  }

  // Show image source selection dialog
  static Future<XFile?> showImageSourceDialog() async {
    XFile? selectedImage;

    await Get.dialog(
      AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện ảnh'),
              onTap: () async {
                Get.back();
                selectedImage = await pickImageFromGallery();
              },
            ),
            if (!kIsWeb) // Camera không hoạt động tốt trên web
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () async {
                  Get.back();
                  selectedImage = await pickImageFromCamera();
                },
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
        ],
      ),
    );

    return selectedImage;
  }

  // Convert base64 string back to Uint8List for display
  static Uint8List? base64ToBytes(String base64String) {
    if (kIsWeb) {
      return SimpleWebImagePicker.base64ToBytes(base64String);
    }

    try {
      // Remove data URL prefix if present
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          base64String = base64String.substring(commaIndex + 1);
        }
      }

      return base64Decode(base64String);
    } catch (e) {
      print('ImageBase64Service: Base64 decode failed: $e');
      return null;
    }
  }

  // Check if string is valid base64 image
  static bool isValidBase64Image(String? value) {
    if (value == null || value.isEmpty) return false;

    // Check if it starts with data URL prefix
    if (value.startsWith('data:image/')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) return false;

      final base64Part = value.substring(commaIndex + 1);
      try {
        base64Decode(base64Part);
        return true;
      } catch (e) {
        return false;
      }
    }

    // Check if it's pure base64
    try {
      base64Decode(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get file size of base64 string in MB
  static double getBase64SizeInMB(String base64String) {
    try {
      final bytes = base64ToBytes(base64String);
      if (bytes != null) {
        return bytes.length / (1024 * 1024);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
