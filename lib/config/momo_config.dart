class MoMoConfig {
  // Production Configuration
  // Thay bằng key thật khi lên production
  static const String partnerCode = "YOUR_PARTNER_CODE";
  static const String accessKey = "YOUR_ACCESS_KEY";
  static const String secretKey = "YOUR_SECRET_KEY";

  // Environment URLs (MoMo trực tiếp)
  static const String sandboxEndpoint =
      "https://test-payment.momo.vn/v2/gateway/api/create";
  static const String productionEndpoint =
      "https://payment.momo.vn/v2/gateway/api/create";

  // Backend Proxy Endpoint (domain ngrok, tự động cập nhật)
  // Domain ngrok sẽ được script tự động cập nhật
  static const String proxyEndpoint =
      "https://REPLACE_ME_NGROK_DOMAIN/api/momo/create-payment";
  static const String proxyQueryEndpoint =
      "https://REPLACE_ME_NGROK_DOMAIN/api/momo/query";

  // App Deep Link Configuration
  static const String appScheme = "gympro";
  static const String paymentHost = "payment";
  static const String deepLinkUrl = "$appScheme://$paymentHost";

  // Request Types
  static const String captureWallet = "captureWallet"; // Thanh toán qua ví MoMo
  static const String payWithATM = "payWithATM"; // Thanh toán qua ATM
  static const String payWithCC = "payWithCC"; // Thanh toán qua Credit Card

  // Environment Selection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  // Sử dụng endpoint backend proxy cho web, MoMo trực tiếp cho production
  static String get endpoint =>
      isProduction ? productionEndpoint : proxyEndpoint;
  static String get queryEndpoint =>
      isProduction ? productionEndpoint : proxyQueryEndpoint;

  // MoMo App Schemes
  static const String momoAppScheme = "momo";
  static const String momoPackageAndroid = "com.mservice.moca.wallet";

  // Server Configuration
  // Auto-detect local IP or use fallback
  // URL public, không dùng IP LAN
  static const String serverBaseUrl =
      "https://REPLACE_ME_NGROK_DOMAIN"; // hoặc domain thật
  static const String localServerUrl =
      "http://192.168.23.1:3000"; // chỉ dùng test nội bộ
  static const String frontendUrl =
      "http://192.168.23.1:4000"; // IP address của frontend

  static String get backendUrl => isProduction ? serverBaseUrl : localServerUrl;

  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration paymentTimeout = Duration(minutes: 10);

  // Missing getters
  static const String notifyUrl = "https://your-notify-url.com";
  static const String returnUrl = "https://your-return-url.com";
  static const String requestType = "captureWallet";
  static const String lang = "vi";
}
