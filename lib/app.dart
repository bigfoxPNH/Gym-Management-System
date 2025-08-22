import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/locale_controller.dart';
import 'translations/app_translations.dart';

class GymProApp extends StatelessWidget {
  const GymProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controllers
    Get.put(AuthController());
    Get.put(LocaleController());

    return GetMaterialApp(
      title: 'Gym Pro',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: Get.find<LocaleController>().locale,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.initial,
      getPages: AppPages.routes,
    );
  }
}
