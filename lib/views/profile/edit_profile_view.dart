import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../models/user_account.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../services/firebase_service.dart';
import '../settings/data_settings_view.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.userAccount;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fullNameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final selectedGender = Rx<Gender?>(user.gender);
    final selectedDate = Rx<DateTime?>(user.dob);
    final formKey = GlobalKey<FormState>();
    final RxBool isLoading = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Hồ Sơ'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      final currentUser = authController.userAccount;
                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                currentUser?.avatarUrl != null &&
                                    currentUser!.avatarUrl!.isNotEmpty
                                ? _getImageProvider(currentUser.avatarUrl!)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child:
                                currentUser?.avatarUrl == null ||
                                    currentUser!.avatarUrl!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF2196F3),
                                  )
                                : null,
                          ),
                          if (authController.isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Obx(() {
                        return InkWell(
                          onTap: authController.isLoading
                              ? null
                              : () => _showImageSourceDialog(authController),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: authController.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              Text(
                'Thông Tin Cá Nhân',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: fullNameController,
                labelText: 'Họ và Tên',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên của bạn';
                  }
                  if (value.length < 2) {
                    return 'Tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field (read-only)
              AppTextField(
                controller: TextEditingController(text: user.email),
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Phone field
              AppTextField(
                controller: phoneController,
                labelText: 'Số Điện Thoại',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10) {
                      return 'Số điện thoại phải có ít nhất 10 chữ số';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address field
              AppTextField(
                controller: addressController,
                labelText: 'Địa Chỉ',
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 5) {
                      return 'Địa chỉ phải có ít nhất 5 ký tự';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              Obx(
                () => DropdownButtonFormField<Gender>(
                  value: selectedGender.value,
                  decoration: const InputDecoration(
                    labelText: 'Giới Tính',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Chọn Giới Tính'),
                    ),
                    DropdownMenuItem(value: Gender.male, child: Text('Nam')),
                    DropdownMenuItem(value: Gender.female, child: Text('Nữ')),
                    DropdownMenuItem(value: Gender.other, child: Text('Khác')),
                  ],
                  onChanged: (Gender? value) {
                    selectedGender.value = value;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth picker
              Obx(
                () => InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          selectedDate.value ??
                          DateTime.now().subtract(
                            const Duration(days: 6570),
                          ), // 18 years ago
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      selectedDate.value = pickedDate;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate.value != null
                                ? '${selectedDate.value!.day}/${selectedDate.value!.month}/${selectedDate.value!.year}'
                                : 'Chọn Ngày Sinh',
                            style: TextStyle(
                              color: selectedDate.value != null
                                  ? Colors.black
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Member since (read-only)
              AppTextField(
                controller: TextEditingController(
                  text:
                      '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                labelText: 'Thành Viên Từ',
                prefixIcon: const Icon(Icons.calendar_today),
                enabled: false,
              ),
              const SizedBox(height: 32),

              // Save Button
              Obx(
                () => AppButton(
                  text: 'Lưu Thay Đổi',
                  isLoading: isLoading.value,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await _updateProfile(
                        user,
                        fullNameController.text.trim(),
                        phoneController.text.trim(),
                        addressController.text.trim(),
                        selectedGender.value,
                        selectedDate.value,
                        isLoading,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Additional Options
              Text(
                'Cài Đặt Tài Khoản',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildSettingsOption(
                context,
                icon: Icons.lock_outline,
                title: 'Đổi Mật Khẩu',
                subtitle: 'Cập nhật mật khẩu của bạn',
                onTap: () => _showChangePasswordDialog(context),
              ),
              const SizedBox(height: 12),

              _buildSettingsOption(
                context,
                icon: Icons.notifications_outlined,
                title: 'Thông Báo',
                subtitle: 'Quản lý cài đặt thông báo',
                onTap: () {
                  Get.snackbar(
                    'Sắp Ra Mắt',
                    'Cài đặt thông báo sẽ có sẵn sớm!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildSettingsOption(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Chính Sách Bảo Mật',
                subtitle: 'Xem chính sách bảo mật đầy đủ của chúng tôi',
                onTap: () {
                  Get.toNamed('/privacy-policy');
                },
              ),
              const SizedBox(height: 12),

              _buildSettingsOption(
                context,
                icon: Icons.settings_outlined,
                title: 'Data Settings',
                subtitle: 'Manage your data and privacy preferences',
                onTap: () {
                  Get.to(() => const DataSettingsView());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile(
    user,
    String newFullName,
    String newPhone,
    String newAddress,
    Gender? newGender,
    DateTime? newDob,
    RxBool isLoading,
  ) async {
    try {
      isLoading.value = true;

      final firebaseService = FirebaseService();
      await firebaseService.updateUser(user.id, {
        'fullName': newFullName,
        'phone': newPhone.isEmpty ? null : newPhone,
        'address': newAddress.isEmpty ? null : newAddress,
        'gender': UserAccount.genderToString(newGender),
        'dob': newDob?.millisecondsSinceEpoch,
      });

      // Reload user account to reflect changes immediately
      final authController = Get.find<AuthController>();
      await authController.reloadUserAccount();

      Get.back();
      Get.snackbar(
        'Thành Công',
        'Hồ sơ đã được cập nhật thành công',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật hồ sơ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi Mật Khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentPasswordController,
                labelText: 'Mật Khẩu Hiện Tại',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: newPasswordController,
                labelText: 'Mật Khẩu Mới',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: confirmPasswordController,
                labelText: 'Xác Nhận Mật Khẩu Mới',
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(() {
            final authController = Get.find<AuthController>();
            return TextButton(
              onPressed: authController.isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        Get.back();
                        await authController.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );
                      }
                    },
              child: authController.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đổi'),
            );
          }),
        ],
      ),
    );
  }

  void _showImageSourceDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Chọn Nguồn Ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư Viện'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery, authController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy Ảnh'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera, authController);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        // Base64 image - safe split
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final base64Data = parts[1];
          return MemoryImage(base64Decode(base64Data));
        }
      }
      // Network URL or fallback
      return NetworkImage(imageUrl);
    } catch (e) {
      print('Error creating image provider: $e');
      // Return a placeholder or default image provider
      return const NetworkImage('');
    }
  }

  void _pickImage(ImageSource source, AuthController authController) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512, // Match ImageService settings
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        // Show immediate feedback
        Get.snackbar(
          'Đang tải lên...',
          'Vui lòng đợi trong khi chúng tôi cập nhật ảnh đại diện của bạn',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        await authController.updateAvatar(image);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chọn ảnh: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
