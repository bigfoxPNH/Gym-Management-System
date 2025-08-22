import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
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
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user account: $e',
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
      await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Sign In Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> register(
    String email,
    String password,
    String fullName, {
    String? username,
  }) async {
    try {
      _isLoading.value = true;
      await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
      );

      // Sign out after registration to force user to login
      await AuthService.signOut();

      // Navigate back to login with success message
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Registration Successful',
        'Account created successfully! Please sign in.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Registration Error',
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
        'Sign Out Error',
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
        'Password Reset',
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Password Reset Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      await AuthService.deleteAccount();
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Account Deleted',
        'Your account has been successfully deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Delete Account Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
