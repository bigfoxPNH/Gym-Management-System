import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

/// Splash screen hiển thị khi mới mở app
/// - Logo app ở giữa màn hình
/// - Loading indicator màu cyan
/// - Tự động chuyển đến trang login hoặc home sau khi kiểm tra auth
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Check authentication và navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Đợi animation chạy một chút
    await Future.delayed(const Duration(milliseconds: 800));

    // Kiểm tra auth status
    final authController = Get.find<AuthController>();

    // Đợi thêm một chút để user thấy splash screen
    await Future.delayed(const Duration(milliseconds: 1200));

    // Navigate dựa vào auth status
    if (authController.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logoapp/logoappgym2.png',
                        width: 265,
                        height: 265,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tagline
                    Text(
                      'Hệ thống quản lý phòng tập',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading text
                    Text(
                      'Đang khởi động...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
