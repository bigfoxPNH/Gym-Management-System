import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleWebImagePicker {
  static Future<String?> pickImageAsBase64() async {
    if (!kIsWeb) {
      print('SimpleWebImagePicker: Not available on non-web platforms');
      return null;
    }
    return null;
  }

  static Uint8List? base64ToBytes(String base64String) {
    try {
      if (base64String.startsWith('data:image/')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          base64String = base64String.substring(commaIndex + 1);
        }
      }
      return base64Decode(base64String);
    } catch (e) {
      print('SimpleWebImagePicker: Base64 decode failed: ');
      return null;
    }
  }

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
