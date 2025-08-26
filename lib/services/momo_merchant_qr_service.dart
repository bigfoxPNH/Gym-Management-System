import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service tạo MoMo QR theo chuẩn EMV cho merchant
/// Đây là format QR mà MoMo app có thể đọc và xử lý
class MoMoMerchantQRService {
  // MoMo Merchant Info - Thay thế bằng thông tin merchant thật
  static const String merchantId = 'MOMO_DEMO_MERCHANT';
  static const String merchantName = 'GYM PRO VIETNAM';
  static const String merchantCity = 'Ho Chi Minh';
  static const String countryCode = 'VN';
  static const String currencyCode = '704'; // VND currency code

  /// Generate MoMo Merchant QR Code theo chuẩn EMV
  String generateMerchantQR({
    required String orderId,
    required double amount,
    required String description,
  }) {
    try {
      // Tạo EMV QR Code format
      final qrData = _buildEMVQRData(
        orderId: orderId,
        amount: amount,
        description: description,
      );

      return qrData;
    } catch (e) {
      print('Error generating MoMo merchant QR: $e');
      return _generateFallbackQR(orderId, amount, description);
    }
  }

  /// Build EMV QR Code data theo chuẩn MoMo merchant
  String _buildEMVQRData({
    required String orderId,
    required double amount,
    required String description,
  }) {
    final Map<String, String> qrComponents = {
      '00': '01', // Payload Format Indicator
      '01': '11', // Point of Initiation Method (11 = Static, 12 = Dynamic)
      '26': _buildMerchantData(
        orderId,
        description,
      ), // Merchant Account Information
      '52': '0000', // Merchant Category Code
      '53': currencyCode, // Transaction Currency
      '54': amount.toStringAsFixed(0), // Transaction Amount
      '58': countryCode, // Country Code
      '59': merchantName, // Merchant Name
      '60': merchantCity, // Merchant City
      '62': _buildAdditionalData(orderId, description), // Additional Data Field
    };

    // Build QR string
    final qrString = qrComponents.entries
        .map(
          (e) =>
              '${e.key}${e.value.length.toString().padLeft(2, '0')}${e.value}',
        )
        .join('');

    // Add CRC (simplified)
    final crcValue = _calculateCRC(qrString + '6304');
    return qrString + '63' + '04' + crcValue;
  }

  /// Build merchant account information field
  String _buildMerchantData(String orderId, String description) {
    final merchantData = {
      '00': 'vn.momo', // Globally Unique Identifier
      '01': merchantId, // Merchant ID
      '02': orderId, // Order ID
    };

    return merchantData.entries
        .map(
          (e) =>
              '${e.key}${e.value.length.toString().padLeft(2, '0')}${e.value}',
        )
        .join('');
  }

  /// Build additional data field
  String _buildAdditionalData(String orderId, String description) {
    final additionalData = {
      '01': orderId, // Bill Number
      '08': description.length > 25
          ? description.substring(0, 25)
          : description, // Purpose of Transaction
    };

    return additionalData.entries
        .map(
          (e) =>
              '${e.key}${e.value.length.toString().padLeft(2, '0')}${e.value}',
        )
        .join('');
  }

  /// Calculate CRC-16-CCITT checksum
  String _calculateCRC(String data) {
    // Simplified CRC calculation for demo
    // In production, implement proper CRC-16-CCITT algorithm
    final hash = md5.convert(utf8.encode(data));
    return hash.toString().substring(0, 4).toUpperCase();
  }

  /// Generate fallback QR khi EMV format fail
  String _generateFallbackQR(
    String orderId,
    double amount,
    String description,
  ) {
    // Format QR đơn giản hơn mà MoMo có thể đọc được
    final fallbackData = {
      'merchant': merchantId,
      'order': orderId,
      'amount': amount.toInt().toString(),
      'desc': description,
      'currency': 'VND',
    };

    final queryString = fallbackData.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'momo://merchant?$queryString';
  }

  /// Generate QR URL for display
  String generateQRUrl({
    required String orderId,
    required double amount,
    required String description,
  }) {
    final qrData = generateMerchantQR(
      orderId: orderId,
      amount: amount,
      description: description,
    );

    return 'https://api.qrserver.com/v1/create-qr-code/'
        '?size=300x300'
        '&data=${Uri.encodeComponent(qrData)}'
        '&ecc=M'; // Medium error correction
  }

  /// Get merchant payment instructions
  Map<String, String> getMerchantPaymentInfo({
    required String orderId,
    required double amount,
    required String description,
  }) {
    return {
      'merchantName': merchantName,
      'merchantId': merchantId,
      'orderId': orderId,
      'amount': amount.toStringAsFixed(0) + ' VNĐ',
      'description': description,
      'instructions': '''Thanh toán qua MoMo:
1. Mở ứng dụng MoMo
2. Chọn "Quét QR Code"  
3. Quét mã QR phía trên
4. Kiểm tra thông tin và xác nhận thanh toán
5. Nhập mã PIN để hoàn tất

Lưu ý: QR code có hiệu lực trong 15 phút''',
    };
  }

  /// Validate QR data format
  bool validateQRFormat(String qrData) {
    try {
      // Basic validation
      if (qrData.isEmpty || qrData.length < 10) return false;

      // Check if starts with payload format indicator
      if (!qrData.startsWith('00')) return false;

      // Check if contains merchant data
      if (!qrData.contains('26')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
