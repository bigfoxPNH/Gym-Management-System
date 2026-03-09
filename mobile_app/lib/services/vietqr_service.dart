import 'package:dio/dio.dart';

class VietQRConfig {
  // VietQR API endpoint
  static const String baseUrl = 'https://img.vietqr.io/image';

  // Bank account info - Thay đổi thành thông tin thật
  static const String bankCode = '970415'; // Vietinbank code
  static const String accountNumber = '1234567890123456'; // Account number
  static const String accountName =
      'CONG TY TNHH GYM PRO'; // Account holder name
  static const String template = 'compact2'; // QR template
}

class VietQRRequest {
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String description;
  final String template;

  VietQRRequest({
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.description,
    this.template = 'compact2',
  });

  String toUrl() {
    final encodedAccountName = Uri.encodeComponent(accountName);
    final encodedDescription = Uri.encodeComponent(description);

    return '${VietQRConfig.baseUrl}/$bankCode-$accountNumber-$template.jpg'
        '?amount=${amount.toInt()}'
        '&addInfo=$encodedDescription'
        '&accountName=$encodedAccountName';
  }
}

class VietQRService {
  final Dio _dio = Dio();

  // Generate VietQR URL
  String generateQRUrl({
    required double amount,
    required String description,
    String? customAccountNumber,
    String? customBankCode,
    String? customAccountName,
  }) {
    final request = VietQRRequest(
      bankCode: customBankCode ?? VietQRConfig.bankCode,
      accountNumber: customAccountNumber ?? VietQRConfig.accountNumber,
      accountName: customAccountName ?? VietQRConfig.accountName,
      amount: amount,
      description: description,
    );

    return request.toUrl();
  }

  // Verify QR URL is accessible
  Future<bool> verifyQRUrl(String qrUrl) async {
    try {
      final response = await _dio.head(qrUrl);
      return response.statusCode == 200;
    } catch (e) {
      print('VietQR URL verification error: $e');
      return false;
    }
  }

  // Get bank transfer info
  Map<String, String> getBankTransferInfo({
    required double amount,
    required String transferCode,
    required String description,
    String? customAccountNumber,
    String? customBankCode,
    String? customAccountName,
  }) {
    final bankName = _getBankName(customBankCode ?? VietQRConfig.bankCode);
    final accountNumber = customAccountNumber ?? VietQRConfig.accountNumber;
    final accountName = customAccountName ?? VietQRConfig.accountName;

    return {
      'bankName': bankName,
      'bankCode': customBankCode ?? VietQRConfig.bankCode,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'amount': amount.toStringAsFixed(0),
      'transferContent': '$transferCode $description',
      'transferCode': transferCode,
    };
  }

  // Get bank name from bank code
  String _getBankName(String bankCode) {
    final bankNames = {
      '970415': 'Ngân hàng Công thương Việt Nam (VietinBank)',
      '970422': 'Ngân hàng Quân đội (MB)',
      '970418': 'Ngân hàng BIDV',
      '970405': 'Ngân hàng Ngoại thương Việt Nam (Vietcombank)',
      '970436': 'Ngân hàng Kỹ thương Việt Nam (Techcombank)',
      '970432': 'Ngân hàng Việt Nam Thịnh Vượng (VPBank)',
      '970423': 'Ngân hàng Tiên Phong (TPBank)',
      '970403': 'Ngân hàng Sài Gòn Thương Tín (Sacombank)',
      '970407': 'Ngân hàng Kỹ thương Việt Nam (Techcombank)',
      '970448': 'Ngân hàng Phương Đông (OCB)',
      '970454': 'Ngân hàng Việt Á (VietABank)',
      '970426': 'Ngân hàng Hàng Hải Việt Nam (MSB)',
      '970412': 'Ngân hàng Đầu tư và Phát triển Việt Nam (BIDV)',
      '970414': 'Ngân hàng Đại chúng Việt Nam (PVcomBank)',
      '970429': 'Ngân hàng Sài Gòn Công Thương (SaigonBank)',
      '970441': 'Ngân hàng Việt Nam Thịnh Vượng (VIB)',
      '970443': 'Ngân hàng Sài Gòn - Hà Nội (SHB)',
      '970431': 'Ngân hàng Xuất Nhập khẩu Việt Nam (Eximbank)',
      '970408': 'Ngân hàng Phương Đông (OCB)',
      '970416': 'Ngân hàng An Bình (ABBANK)',
    };

    return bankNames[bankCode] ?? 'Ngân hàng không xác định';
  }

  // Generate transfer code
  String generateTransferCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'GYM${timestamp.substring(timestamp.length - 8)}';
  }

  // List of popular bank codes for selection
  static List<Map<String, String>> getPopularBanks() {
    return [
      {'code': '970415', 'name': 'VietinBank', 'shortName': 'VTB'},
      {'code': '970422', 'name': 'Military Bank', 'shortName': 'MB'},
      {'code': '970418', 'name': 'BIDV', 'shortName': 'BIDV'},
      {'code': '970405', 'name': 'Vietcombank', 'shortName': 'VCB'},
      {'code': '970436', 'name': 'Techcombank', 'shortName': 'TCB'},
      {'code': '970432', 'name': 'VPBank', 'shortName': 'VPB'},
      {'code': '970423', 'name': 'TPBank', 'shortName': 'TPB'},
      {'code': '970403', 'name': 'Sacombank', 'shortName': 'SCB'},
      {'code': '970448', 'name': 'OCB', 'shortName': 'OCB'},
      {'code': '970426', 'name': 'MSB', 'shortName': 'MSB'},
    ];
  }
}
