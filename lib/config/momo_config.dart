class MoMoConfig {
  // Production Configuration
  static const String partnerCode = "MOMO"; // Thay bằng partnerCode thật từ MoMo
  static const String accessKey = "F8BBA842ECF85"; // Thay bằng accessKey thật
  static const String secretKey = "K951B6PE1waDMi640xX08PD3vg6EkVlz"; // Thay bằng secretKey thật
  
  // Environment URLs
  static const String sandboxEndpoint = "https://test-payment.momo.vn/v2/gateway/api/create";
  static const String productionEndpoint = "https://payment.momo.vn/v2/gateway/api/create";
  
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
  
  static String get endpoint => isProduction ? productionEndpoint : sandboxEndpoint;
  
  // MoMo App Schemes
  static const String momoAppScheme = "momo";
  static const String momoPackageAndroid = "com.mservice.moca.wallet";
  
  // Server Configuration (Deploy backend với domain thật)
  static const String serverBaseUrl = "https://your-domain.com"; // Thay bằng domain thật
  static const String localServerUrl = "http://localhost:3000"; // Chỉ dùng cho development
  
  static String get backendUrl => isProduction ? serverBaseUrl : localServerUrl;
  
  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration paymentTimeout = Duration(minutes: 10);
}
