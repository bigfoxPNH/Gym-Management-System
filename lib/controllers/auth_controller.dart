import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';
import '../models/user_account.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserAccount?> _userAccount = Rx<UserAccount?>(null);
  final RxBool _isLoading = false.obs;

  User? get user => _user.value;
  UserAccount? get userAccount => _userAccount.value;
  RxBool get isLoggedIn => RxBool(_user.value != null);
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _user.value = AuthService.currentUser;

    // Listen to auth state changes
    AuthService.authStateChanges.listen((User? user) {
      _user.value = user;
      if (user != null) {
        _loadUserAccount(user.uid);
      } else {
        _userAccount.value = null;
      }
    });

    // Load user account if user is already signed in
    if (_user.value != null) {
      _loadUserAccount(_user.value!.uid);
    }
  }

  Future<void> _loadUserAccount(String userId) async {
    try {
      final firebaseService = FirebaseService();
      final account = await firebaseService.getUser(userId);
      _userAccount.value = account;

      // Safe substring to avoid RangeError
      String avatarPreview = '';
      if (account?.avatarUrl != null && account!.avatarUrl!.isNotEmpty) {
        final avatarUrl = account.avatarUrl!;
        avatarPreview = avatarUrl.length > 50
            ? '${avatarUrl.substring(0, 50)}...'
            : avatarUrl;
      }

      print('User account reloaded: $avatarPreview');
    } catch (e) {
      print('Error loading user account: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải tài khoản người dùng: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Public method to reload user account data
  Future<void> reloadUserAccount() async {
    if (_user.value != null) {
      await _loadUserAccount(_user.value!.uid);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading.value = true;
      final userCredential = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait for user account to be loaded
      if (userCredential?.user != null) {
        await _loadUserAccount(userCredential!.user!.uid);

        // Navigate based on user role
        if (_userAccount.value?.isTrainer == true) {
          Get.offAllNamed(AppRoutes.ptDashboard);
        } else {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi Đăng Nhập',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      _isLoading.value = true;
      await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Sign out after registration to force user to login
      await AuthService.signOut();

      // Navigate back to login with success message
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Đăng Ký Thành Công',
        'Tài khoản đã được tạo thành công! Vui lòng đăng nhập.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi Đăng Ký',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await AuthService.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Lỗi Đăng Xuất',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      await AuthService.resetPassword(email);
      Get.snackbar(
        'Đặt Lại Mật Khẩu',
        'Email đặt lại mật khẩu đã được gửi đến $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi Đặt Lại Mật Khẩu',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading.value = true;
      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      Get.snackbar(
        'Thành Công',
        'Mật khẩu đã được thay đổi thành công',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi Đổi Mật Khẩu',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      await AuthService.deleteAccount();

      // Đóng loading dialog nếu đang mở
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Tài Khoản Đã Xóa',
        'Tài khoản của bạn đã được xóa thành công',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Đóng loading dialog nếu đang mở
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Lỗi Xóa Tài Khoản',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateAvatar(XFile imageFile) async {
    try {
      _isLoading.value = true;

      if (_user.value == null || _userAccount.value == null) {
        throw 'User not logged in';
      }

      // Validate image file
      if (!ImageService.isValidImageFile(imageFile)) {
        throw 'Please select a valid image file (JPG, PNG)';
      }

      // Check file size (max 500KB for Firestore)
      final double fileSizeInKB = await ImageService.getImageSizeInKB(
        imageFile,
      );
      if (fileSizeInKB > 500) {
        throw 'Image size must be less than 500KB';
      }

      // Convert image to Base64
      final String base64Avatar = await ImageService.imageToBase64(imageFile);

      // Update local data immediately for instant UI update
      if (_userAccount.value != null) {
        _userAccount.value = _userAccount.value!.copyWith(
          avatarUrl: base64Avatar,
          updatedAt: DateTime.now(),
        );
      }

      // Update user account in Firestore
      final updatedData = {
        'avatarUrl': base64Avatar,
        'updatedAt': DateTime.now(),
      };

      await FirebaseService.updateUserProfile(_user.value!.uid, updatedData);

      // Double-check by reloading from Firestore
      await reloadUserAccount();

      Get.snackbar(
        'Thành Công',
        'Ảnh đại diện đã được cập nhật thành công',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi Tải Lên',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
