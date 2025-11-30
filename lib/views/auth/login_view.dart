import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../routes/app_routes.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  // Launch Zalo support
  Future<void> _launchZaloSupport() async {
    final Uri zaloUri = Uri.parse('https://zalo.me/0326658276');
    try {
      if (await canLaunchUrl(zaloUri)) {
        await launchUrl(zaloUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: open in browser
        await launchUrl(zaloUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể mở Zalo. Vui lòng thử lại sau.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main login form
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logoapp/logoappgym.png',
                          width: 175,
                          height: 175,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          isAntiAlias: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đăng nhập để tiếp tục',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    AppTextField(
                      controller: emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email của bạn';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Vui lòng nhập email hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    AppTextField(
                      controller: passwordController,
                      labelText: 'Mật khẩu',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu của bạn';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign In Button
                    Obx(
                      () => LoadingButton(
                        text: 'Đăng Nhập',
                        isLoading: authController.isLoading,
                        backgroundColor: const Color(0xFF00BCD4), // Cyan color
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
                      child: const Text('Quên mật khẩu?'),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Chưa có tài khoản?",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: const Text(
                            'Đăng Ký',
                            style: TextStyle(
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

            // 🎧 Support button - Top right corner
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _launchZaloSupport,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Color(0xFF2196F3),
                      size: 28,
                    ),
                  ),
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
    final isSubmitting = false.obs;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt Lại Mật Khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập địa chỉ email của bạn để nhận liên kết đặt lại mật khẩu.',
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
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          Obx(
            () => LoadingTextButton(
              text: 'Gửi',
              isLoading: isSubmitting.value,
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  isSubmitting.value = true;
                  await authController.resetPassword(
                    emailController.text.trim(),
                  );
                  isSubmitting.value = false;
                  Get.back();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
