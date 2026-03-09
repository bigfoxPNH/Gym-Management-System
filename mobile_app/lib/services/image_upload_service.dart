import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Upload single image
  static Future<String?> uploadImage({
    required String folder,
    XFile? imageFile,
    Uint8List? imageData,
    String? fileName,
  }) async {
    try {
      // Generate unique filename if not provided
      fileName ??= 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create reference
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // For web, use imageData
        if (imageData == null && imageFile != null) {
          imageData = await imageFile.readAsBytes();
        }
        if (imageData == null) {
          throw Exception('No image data provided for web upload');
        }
        uploadTask = ref.putData(imageData);
      } else {
        // For mobile, use file
        if (imageFile == null) {
          throw Exception('No image file provided for mobile upload');
        }
        uploadTask = ref.putFile(File(imageFile.path));
      }

      // Wait for upload completion
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('ImageUploadService: Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('ImageUploadService: Upload failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải ảnh lên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages({
    required String folder,
    required List<XFile> imageFiles,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      Get.snackbar(
        'Đang tải ảnh',
        'Đang tải ảnh ${i + 1}/${imageFiles.length}...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );

      final url = await uploadImage(
        folder: folder,
        imageFile: imageFiles[i],
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );

      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Pick single image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('ImageUploadService: Pick image failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // Pick multiple images from gallery
  static Future<List<XFile>> pickMultipleImagesFromGallery({
    int maxImages = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        Get.snackbar(
          'Thông báo',
          'Chỉ có thể chọn tối đa $maxImages ảnh. Đã chọn ${images.length} ảnh.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return images.take(maxImages).toList();
      }

      return images;
    } catch (e) {
      print('ImageUploadService: Pick multiple images failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }

  // Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('ImageUploadService: Pick image from camera failed: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể chụp ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
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
            if (!kIsWeb) // Camera không hoạt động trên web
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

  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('ImageUploadService: Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      print('ImageUploadService: Delete failed: $e');
      return false;
    }
  }
}
