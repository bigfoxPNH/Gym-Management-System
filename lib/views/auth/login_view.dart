import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_flags/country_flags.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../routes/app_routes.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final localeController = Get.find<LocaleController>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Language Switcher in Top Right
            Positioned(
              top: 16,
              right: 16,
              child: _buildLanguageSwitcher(localeController),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    const Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'app_name'.tr,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2196F3),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'sign_in_to_continue'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    AppTextField(
                      controller: emailController,
                      labelText: 'email'.tr,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    AppTextField(
                      controller: passwordController,
                      labelText: 'password'.tr,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign In Button
                    Obx(
                      () => AppButton(
                        text: 'sign_in'.tr,
                        isLoading: authController.isLoading,
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            authController.signIn(
                              emailController.text.trim(),
                              passwordController.text,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog(context, authController);
                      },
                      child: Text('forgot_password'.tr),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'dont_have_account'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: Text(
                            'sign_up'.tr,
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(
    BuildContext context,
    AuthController authController,
  ) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                authController.resetPassword(emailController.text.trim());
                Get.back();
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(LocaleController localeController) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: localeController.currentLanguage,
            onChanged: (String? newValue) {
              if (newValue != null) {
                localeController.changeLocaleFromString(newValue);
              }
            },
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryFlag.fromCountryCode('US', height: 20, width: 30),
                    const SizedBox(width: 8),
                    const Text('English'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'vi',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryFlag.fromCountryCode('VN', height: 20, width: 30),
                    const SizedBox(width: 8),
                    const Text('Tiếng Việt'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
