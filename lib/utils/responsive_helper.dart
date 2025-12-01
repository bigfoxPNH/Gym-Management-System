import 'package:flutter/material.dart';
import 'dart:io';

class ResponsiveHelper {
  static bool isWeb() {
    return !Platform.isAndroid && !Platform.isIOS;
  }

  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  static double getIconSize(BuildContext context) {
    if (isMobile()) {
      return 48; // Smaller for mobile
    }
    return 64; // Larger for web
  }

  static double getIconContainerSize(BuildContext context) {
    if (isMobile()) {
      return 56; // Smaller for mobile
    }
    return 64; // Larger for web
  }

  static double getCardHeight(BuildContext context) {
    if (isMobile()) {
      return 250; // Smaller card height for mobile
    }
    return 270; // Larger for web
  }

  static double getNewsCardHeight(BuildContext context) {
    if (isMobile()) {
      return 200; // Smaller for mobile
    }
    return 220; // Larger for web
  }

  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 5; // Desktop
    } else if (width > 800) {
      return 4; // Tablet
    } else {
      return 4; // Mobile
    }
  }

  static double getFontSize(BuildContext context, double webSize) {
    if (isMobile()) {
      return webSize - 1; // Slightly smaller for mobile
    }
    return webSize;
  }
}
