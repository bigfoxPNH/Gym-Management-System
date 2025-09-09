class MoMoConfig {
  // Production Configuration - Backend handles all MoMo keys
  // Flutter app NEVER stores secret keys for security

  // Production Backend URLs (NO ngrok dependency)
  static const String productionBackendUrl = "https://yourproductiondomain.com";
  static const String localBackendUrl = "http://localhost:3000";

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  // Backend endpoints
  static String get backendUrl =>
      isProduction ? productionBackendUrl : localBackendUrl;
  static String get createPaymentEndpoint => "$backendUrl/createPayment";
  static String get paymentStatusEndpoint => "$backendUrl/paymentStatus";

  // App Deep Link Configuration
  static const String appScheme = "gympro";
  static const String paymentHost = "payment";
  static const String deepLinkUrl = "$appScheme://$paymentHost";

  // Request Types
  static const String captureWallet = "captureWallet";
  static const String payWithATM = "payWithATM";
  static const String payWithCC = "payWithCC";

  // MoMo App Schemes
  static const String momoAppScheme = "momo";
  static const String momoPackageAndroid = "com.mservice.moca.wallet";

  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration paymentTimeout = Duration(minutes: 10);
  static const Duration pollingInterval = Duration(seconds: 3);

  // Payment status polling configuration
  static const int maxPollingAttempts = 40; // 40 * 3s = 2 minutes max

  // Language setting
  static const String lang = "vi";
}
