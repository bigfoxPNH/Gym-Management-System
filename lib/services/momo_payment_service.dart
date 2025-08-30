import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:app_links/app_links.dart';
import '../config/momo_config.dart';
import '../models/momo_models.dart';

class MoMoPaymentService {
  static final MoMoPaymentService _instance = MoMoPaymentService._internal();
  factory MoMoPaymentService() => _instance;
  MoMoPaymentService._internal();

  final Dio _dio = Dio();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback controllers
  final StreamController<MoMoCallbackResult> _callbackController =
      StreamController<MoMoCallbackResult>.broadcast();
  Stream<MoMoCallbackResult> get callbackStream => _callbackController.stream;

  /// Initialize deep link listening
  Future<void> initialize() async {
    try {
      // Check if app was launched from a deep link
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null && _isPaymentCallback(initialUri)) {
        _handlePaymentCallback(initialUri);
      }

      // Listen for incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          if (_isPaymentCallback(uri)) {
            _handlePaymentCallback(uri);
          }
        },
        onError: (err) {
          print('Deep link error: $err');
        },
      );

      print('✅ MoMo Payment Service initialized');
    } catch (e) {
      print('❌ Error initializing MoMo Payment Service: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _callbackController.close();
  }

  /// Create payment request
  Future<MoMoPaymentResponse?> createPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
    String requestType = MoMoConfig.captureWallet,
    String extraData = "",
  }) async {
    try {
      print('🚀 Creating MoMo payment for order: $orderId, amount: $amount');

      final request = MoMoPaymentRequest(
        orderId: orderId,
        amount: amount,
        orderInfo: orderInfo,
        requestType: requestType,
        extraData: extraData,
      );

      // Call backend API to create MoMo payment
      print(
        '🔄 Calling MoMo backend: ${MoMoConfig.backendUrl}/api/momo/create-payment',
      );
      print('📝 Request data: ${request.toJson()}');

      final response = await _dio.post(
        '${MoMoConfig.backendUrl}/api/momo/create-payment',
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: MoMoConfig.requestTimeout,
          sendTimeout: MoMoConfig.requestTimeout,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ MoMo API response: ${response.data}');
        final momoResponse = MoMoPaymentResponse.fromJson(response.data);
        print('✅ MoMo payment created successfully');
        return momoResponse;
      } else {
        print('❌ Failed to create MoMo payment: ${response.statusCode}');
        print('❌ Response data: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      print('❌ Network error creating MoMo payment: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error creating MoMo payment: $e');
      return null;
    }
  }

  /// Launch MoMo app for payment
  Future<bool> launchMoMoPayment(MoMoPaymentResponse paymentResponse) async {
    try {
      if (!paymentResponse.isSuccess) {
        print('❌ Cannot launch MoMo: Payment response unsuccessful');
        return false;
      }

      String? launchUrl;

      // Priority order: deeplink > payUrl
      if (paymentResponse.deeplink != null &&
          paymentResponse.deeplink!.isNotEmpty) {
        launchUrl = paymentResponse.deeplink!;
      } else if (paymentResponse.payUrl != null &&
          paymentResponse.payUrl!.isNotEmpty) {
        launchUrl = paymentResponse.payUrl!;
      }

      if (launchUrl == null) {
        print('❌ No valid URL to launch MoMo payment');
        return false;
      }

      print('🚀 Launching MoMo with URL: $launchUrl');

      final uri = Uri.parse(launchUrl);
      final canLaunch = await launcher.canLaunchUrl(uri);

      if (canLaunch) {
        await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );

        print('✅ Successfully launched MoMo app');
        return true;
      } else {
        print('❌ Cannot launch MoMo URL: $launchUrl');

        // Fallback: Try to open MoMo app directly
        return await _openMoMoApp();
      }
    } catch (e) {
      print('❌ Error launching MoMo payment: $e');
      return false;
    }
  }

  /// Check if MoMo app is installed
  Future<bool> isMoMoInstalled() async {
    try {
      if (Platform.isAndroid) {
        // Try to launch MoMo scheme
        final uri = Uri.parse('${MoMoConfig.momoAppScheme}://');
        return await launcher.canLaunchUrl(uri);
      } else if (Platform.isIOS) {
        // Check if MoMo scheme can be opened
        final uri = Uri.parse('${MoMoConfig.momoAppScheme}://');
        return await launcher.canLaunchUrl(uri);
      }
      return false;
    } catch (e) {
      print('❌ Error checking MoMo installation: $e');
      return false;
    }
  }

  /// Open MoMo app store page if not installed
  Future<void> openMoMoStore() async {
    try {
      Uri storeUri;
      if (Platform.isAndroid) {
        storeUri = Uri.parse(
          'market://details?id=${MoMoConfig.momoPackageAndroid}',
        );
      } else if (Platform.isIOS) {
        storeUri = Uri.parse(
          'https://apps.apple.com/vn/app/momo-wallet/id918751124',
        );
      } else {
        return;
      }

      if (await launcher.canLaunchUrl(storeUri)) {
        await launcher.launchUrl(
          storeUri,
          mode: launcher.LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('❌ Error opening MoMo store: $e');
    }
  }

  /// Generate signature for MoMo request (for backend use)
  static String generateSignature({
    required String accessKey,
    required int amount,
    required String extraData,
    required String ipnUrl,
    required String orderId,
    required String orderInfo,
    required String partnerCode,
    required String redirectUrl,
    required String requestId,
    required String requestType,
    required String secretKey,
  }) {
    final rawSignature =
        'accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType';

    final bytes = utf8.encode(rawSignature);
    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(bytes);

    return digest.toString();
  }

  /// Verify callback signature
  bool verifyCallback(MoMoCallbackResult callback) {
    try {
      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}&amount=${callback.amount}&extraData=${callback.extraData}&message=${callback.message}&orderId=${callback.orderId}&orderInfo=${callback.orderInfo}&orderType=${callback.orderType}&partnerCode=${callback.partnerCode}&payType=${callback.payType}&requestId=${callback.requestId}&responseTime=${callback.responseTime}&resultCode=${callback.resultCode}&transId=${callback.transId}';

      final bytes = utf8.encode(rawSignature);
      final hmacSha256 = Hmac(sha256, utf8.encode(MoMoConfig.secretKey));
      final digest = hmacSha256.convert(bytes);
      final expectedSignature = digest.toString();

      final isValid = expectedSignature == callback.signature;
      print(
        isValid ? '✅ Callback signature valid' : '❌ Callback signature invalid',
      );

      return isValid;
    } catch (e) {
      print('❌ Error verifying callback signature: $e');
      return false;
    }
  }

  // Private methods
  bool _isPaymentCallback(Uri uri) {
    return uri.scheme == MoMoConfig.appScheme &&
        uri.host == MoMoConfig.paymentHost;
  }

  void _handlePaymentCallback(Uri uri) {
    try {
      print('📱 Received payment callback: ${uri.toString()}');

      final callback = MoMoCallbackResult.fromUri(uri);

      // Verify signature if needed
      // final isValidSignature = verifyCallback(callback);
      // if (!isValidSignature) {
      //   print('❌ Invalid callback signature, ignoring');
      //   return;
      // }

      print('✅ Payment callback processed: ${callback.statusMessage}');

      // Notify listeners
      _callbackController.add(callback);
    } catch (e) {
      print('❌ Error handling payment callback: $e');
    }
  }

  Future<bool> _openMoMoApp() async {
    try {
      final uri = Uri.parse('${MoMoConfig.momoAppScheme}://');
      if (await launcher.canLaunchUrl(uri)) {
        return await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      print('❌ Error opening MoMo app: $e');
      return false;
    }
  }

  /// Get QR code image as base64 string from backend
  Future<String> getQRCodeImage(String payUrl) async {
    try {
      print('🔍 Getting QR code from backend for payUrl: $payUrl');

      final response = await _dio.get(
        'http://localhost:3000/api/momo/qr-code',
        queryParameters: {'payUrl': payUrl},
      );

      if (response.statusCode == 200 && response.data['qrCodeBase64'] != null) {
        return response.data['qrCodeBase64'] as String;
      } else {
        print('❌ Failed to get QR code: ${response.data}');
        return '';
      }
    } catch (e) {
      print('❌ Error getting QR code: $e');
      return '';
    }
  }
}
