import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

abstract class CameraServiceInterface {
  Future<bool> initializeCamera();
  Future<void> dispose();
  CameraController? get controller;
  bool get isInitialized;
  String get errorMessage;
}

class CameraService implements CameraServiceInterface {
  CameraController? _controller;
  bool _isInitialized = false;
  String _errorMessage = '';

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String get errorMessage => _errorMessage;

  @override
  Future<bool> initializeCamera() async {
    try {
      _errorMessage = '';

      if (kIsWeb) {
        return await _initializeCameraForWeb();
      } else {
        return await _initializeCameraForMobile();
      }
    } catch (e) {
      debugPrint('❌ Camera service error: $e');
      _errorMessage = _parseErrorMessage(e.toString());
      return false;
    }
  }

  Future<bool> _initializeCameraForWeb() async {
    debugPrint('🌐 Initializing camera for web...');

    try {
      // Check browser capabilities first
      if (!await _checkWebCameraSupport()) {
        _errorMessage = 'Browser không hỗ trợ camera API';
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Không tìm thấy camera nào';
        return false;
      }

      // For web, use most basic configuration
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.low, // Start with lowest resolution
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Camera timeout trên web'),
      );

      _isInitialized = true;
      debugPrint('✅ Web camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Web camera failed: $e');
      _dispose();

      // Web-specific error handling
      if (e.toString().contains('cameraNotReadable')) {
        _errorMessage =
            'Camera đang được sử dụng bởi app khác. Đóng các tab/app khác đang dùng camera.';
      } else if (e.toString().contains('NotAllowedError')) {
        _errorMessage =
            'Quyền camera bị từ chối. Cho phép camera trong browser settings.';
      } else if (e.toString().contains('NotFoundError')) {
        _errorMessage = 'Không tìm thấy camera. Kiểm tra kết nối camera.';
      } else if (e.toString().contains('timeout')) {
        _errorMessage = 'Camera không phản hồi. Thử refresh trang.';
      } else {
        _errorMessage = 'Lỗi camera trên web: ${e.toString()}';
      }
      return false;
    }
  }

  Future<bool> _initializeCameraForMobile() async {
    debugPrint('📱 Initializing camera for mobile...');

    try {
      // Request permissions
      final permission = await Permission.camera.request();
      if (permission != PermissionStatus.granted) {
        _errorMessage = 'Cần quyền truy cập camera';
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Không tìm thấy camera nào';
        return false;
      }

      // For mobile, try higher quality
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Camera timeout trên mobile'),
      );

      _isInitialized = true;
      debugPrint('✅ Mobile camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Mobile camera failed: $e');
      _dispose();
      _errorMessage = 'Lỗi camera mobile: ${e.toString()}';
      return false;
    }
  }

  Future<bool> _checkWebCameraSupport() async {
    if (!kIsWeb) return true;

    try {
      // This is a basic check - in real implementation, you might use js interop
      // to check navigator.mediaDevices.getUserMedia availability
      return true;
    } catch (e) {
      return false;
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('cameraNotReadable')) {
      return 'Camera hardware error - có thể đang được sử dụng bởi app khác';
    } else if (error.contains('permission') ||
        error.contains('NotAllowedError')) {
      return 'Quyền camera bị từ chối';
    } else if (error.contains('NotFoundError')) {
      return 'Không tìm thấy camera';
    } else if (error.contains('timeout')) {
      return 'Camera không phản hồi - thử lại';
    } else {
      return 'Lỗi camera không xác định';
    }
  }

  void _dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  Future<void> dispose() async {
    _dispose();
  }
}

// Factory để tạo camera service theo platform
class CameraServiceFactory {
  static CameraServiceInterface create() {
    if (kIsWeb) {
      // For web, we could return a specialized web implementation
      return CameraService();
    } else {
      // For mobile platforms
      return CameraService();
    }
  }
}
