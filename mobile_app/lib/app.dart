import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';

class GymProApp extends StatelessWidget {
  const GymProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controllers in order
    Get.put(AuthController(), permanent: true);
    final themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        title: 'Gym Pro',
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.poppins().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.poppins().fontFamily,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF90CAF9), // Xanh nhạt dịu mắt
            secondary: Color(0xFF81C784), // Xanh lá nhạt
            surface: Color(0xFF2D2D30), // Xám nhạt thay vì đen
            background: Color(0xFF1A1A1C), // Background nhẹ hơn
            onPrimary: Color(0xFF1A1A1C),
            onSecondary: Color(0xFF1A1A1C),
            onSurface: Color(0xFFF5F5F5), // Text sáng nhẹ
            onBackground: Color(0xFFE8E8E8), // Text background nhẹ
            outline: Color(0xFF4A4A4A), // Border nhẹ
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A1C), // Background nhẹ
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2D2D30), // AppBar nhẹ hơn
            foregroundColor: Color(0xFFF5F5F5),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF2D2D30), // Card màu nhẹ
            elevation: 2,
            surfaceTintColor: Colors.transparent,
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0xFF2D2D30),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF2D2D30),
            selectedItemColor: Color(0xFF90CAF9), // Xanh nhạt
            unselectedItemColor: Color(0xFFB0B0B0), // Xám sáng
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF90CAF9), // FAB xanh nhạt
            foregroundColor: Color(0xFF1A1A1C),
          ),
          dividerColor: const Color(0xFF4A4A4A), // Divider nhẹ
          iconTheme: const IconThemeData(
            color: Color(0xFFE8E8E8), // Icon sáng nhẹ
          ),
        ),
        initialRoute: AppRoutes.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
