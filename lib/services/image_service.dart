import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery or camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Smaller size for Firestore
        maxHeight: 512,
        imageQuality: 70, // Lower quality to reduce size
      );
      return pickedFile;
    } catch (e) {
      throw 'Failed to pick image: $e';
    }
  }

  /// Convert image to Base64 for Firestore storage
  static Future<String> imageToBase64(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      // Check file size (max 500KB for Firestore)
      if (bytes.length > 500 * 1024) {
        throw 'Image size too large. Please select a smaller image.';
      }

      final String base64String = base64Encode(bytes);
      final String mimeType = _getContentType(imageFile.name);

      // Return data URL format
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      throw 'Failed to convert image: $e';
    }
  }

  /// Validate image file
  static bool isValidImageFile(XFile file) {
    final String extension = path.extension(file.name).toLowerCase();
    final List<String> allowedExtensions = ['.jpg', '.jpeg', '.png'];
    return allowedExtensions.contains(extension);
  }

  /// Get image file size in KB
  static Future<double> getImageSizeInKB(XFile file) async {
    final int sizeInBytes = await file.length();
    return sizeInBytes / 1024;
  }

  /// Get content type from file extension
  static String _getContentType(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }
}
