import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleWebImagePicker {
  // Pick image using HTML input element (web only)
  static Future<String?> pickImageAsBase64() async {
    if (!kIsWeb) {
      throw Exception('This method is only for web platform');
    }

    try {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      final completer = Completer<String?>();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) {
          completer.complete(null);
          return;
        }

        final file = files[0];

        // Check file size (max 1MB)
        if (file.size > 1024 * 1024) {
          Get.snackbar(
            'Lỗi',
            'File quá lớn (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB). Tối đa 1MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          completer.complete(null);
          return;
        }

        // Check file type
        if (!file.type.startsWith('image/')) {
          Get.snackbar(
            'Lỗi',
            'Vui lòng chọn file ảnh (JPG, PNG, etc.)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          completer.complete(null);
          return;
        }

        print(
          'SimpleWebImagePicker: Selected file: ${file.name}, size: ${file.size}, type: ${file.type}',
        );

        // Read file as base64
        final reader = html.FileReader();
        reader.readAsDataUrl(file);

        reader.onLoadEnd.listen((e) {
          final result = reader.result as String;
          print(
            'SimpleWebImagePicker: Converted to base64, length: ${result.length}',
          );

          Get.snackbar(
            'Thành công',
            'Đã tải ảnh thành công! (${(file.size / 1024).toInt()}KB)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          completer.complete(result);
        });

        reader.onError.listen((e) {
          print('SimpleWebImagePicker: FileReader error: $e');
          Get.snackbar(
            'Lỗi',
            'Không thể đọc file ảnh',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          completer.complete(null);
        });
      });

      return await completer.future;
    } catch (e) {
      print('SimpleWebImagePicker: Error: $e');
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

  // Convert base64 to bytes for display
  static Uint8List? base64ToBytes(String base64String) {
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
      print('SimpleWebImagePicker: Base64 decode failed: $e');
      return null;
    }
  }

  // Get file size in MB
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
