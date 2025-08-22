import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../models/user_account.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../services/firebase_service.dart';

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
    final usernameController = TextEditingController(text: user.username);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final selectedGender = Rx<Gender?>(user.gender);
    final selectedDate = Rx<DateTime?>(user.dob);
    final formKey = GlobalKey<FormState>();
    final RxBool isLoading = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                'Personal Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: fullNameController,
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: usernameController,
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
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
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address field
              AppTextField(
                controller: addressController,
                labelText: 'Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 2,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 5) {
                      return 'Address must be at least 5 characters';
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
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Select Gender')),
                    DropdownMenuItem(value: Gender.male, child: Text('Male')),
                    DropdownMenuItem(
                      value: Gender.female,
                      child: Text('Female'),
                    ),
                    DropdownMenuItem(value: Gender.other, child: Text('Other')),
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
                                : 'Select Date of Birth',
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
                labelText: 'Member Since',
                prefixIcon: const Icon(Icons.calendar_today),
                enabled: false,
              ),
              const SizedBox(height: 32),

              // Save Button
              Obx(
                () => AppButton(
                  text: 'Save Changes',
                  isLoading: isLoading.value,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await _updateProfile(
                        user,
                        fullNameController.text.trim(),
                        usernameController.text.trim(),
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
                'Account Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildSettingsOption(
                context,
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              const SizedBox(height: 12),

              _buildSettingsOption(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification settings',
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Notification settings will be available soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildSettingsOption(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Privacy and data settings',
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Privacy settings will be available soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
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
    String newUsername,
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
        'username': newUsername,
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
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
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
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentPasswordController,
                labelText: 'Current Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: newPasswordController,
                labelText: 'New Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: confirmPasswordController,
                labelText: 'Confirm New Password',
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
                  : const Text('Change'),
            );
          }),
        ],
      ),
    );
  }

  void _showImageSourceDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery, authController);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera, authController);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      final base64Data = imageUrl.split(',')[1];
      return MemoryImage(base64Decode(base64Data));
    } else {
      // Network URL
      return NetworkImage(imageUrl);
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
          'Uploading...',
          'Please wait while we update your profile picture',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        await authController.updateAvatar(image);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
