import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/membership_card.dart';
import '../../models/payment_models.dart';
import '../../services/payment_service_v2.dart';

class PaymentTestView extends StatefulWidget {
  const PaymentTestView({super.key});

  @override
  State<PaymentTestView> createState() => _PaymentTestViewState();
}

class _PaymentTestViewState extends State<PaymentTestView> {
  final PaymentServiceV2 _paymentService = PaymentServiceV2();

  // Test data
  final MembershipCard _testCard = MembershipCard(
    id: 'test_card_001',
    cardName: 'Thẻ Premium Test',
    description: 'Thẻ test cho demo thanh toán',
    cardType: CardType.premium,
    durationType: DurationType.months,
    duration: 3,
    price: 500000,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    createdBy: 'admin',
    isActive: true,
  );

  String? _paymentId;
  Map<String, dynamic>? _paymentResult;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Payment Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Card Info
            _buildTestCardInfo(),
            const SizedBox(height: 24),

            // Payment Methods
            _buildPaymentMethods(),
            const SizedBox(height: 24),

            // Payment Result
            if (_paymentResult != null) ...[
              _buildPaymentResult(),
              const SizedBox(height: 24),
            ],

            // Backend Status
            _buildBackendStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎫 Test Membership Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('📛 Tên: ${_testCard.cardName}'),
            Text('💰 Giá: ${_testCard.getFormattedPrice()}'),
            Text('⏱️ Thời gian: ${_testCard.getFormattedDuration()}'),
            Text('📝 Mô tả: ${_testCard.description}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${_testCard.getPreviewInfo()}',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💳 Choose Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // MoMo Payment
            _buildPaymentButton(
              title: '📱 MoMo Payment',
              subtitle: 'Test real MoMo QR (requires backend)',
              method: PaymentMethod.momo,
              icon: Icons.smartphone,
              color: Colors.pink,
            ),
            const SizedBox(height: 8),

            // Banking Payment
            _buildPaymentButton(
              title: '🏦 Banking QR',
              subtitle: 'VietQR banking transfer',
              method: PaymentMethod.banking,
              icon: Icons.account_balance,
              color: Colors.green,
            ),
            const SizedBox(height: 8),

            // Cash Payment
            _buildPaymentButton(
              title: '💰 Cash Payment',
              subtitle: 'Pay at counter',
              method: PaymentMethod.cash,
              icon: Icons.money,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required String title,
    required String subtitle,
    required PaymentMethod method,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _createPayment(method),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentResult() {
    final success = _paymentResult!['success'] as bool;
    final data = _paymentResult!['data'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? '✅ Payment Created' : '❌ Payment Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (success && data != null) ...[
              _buildResultInfo('💳 Payment ID', _paymentId ?? 'N/A'),
              _buildResultInfo('🔄 Method', _paymentResult!['method'] ?? 'N/A'),
              _buildResultInfo('🎯 Type', data['type'] ?? 'N/A'),

              if (data['message'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    data['message'],
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                  ),
                ),
              ],

              // QR Code
              if (data['qrCodeUrl'] != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '📱 Scan QR Code:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['qrCodeUrl'],
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text('QR Load Error'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            data['isReal'] == true
                                ? Icons.verified
                                : Icons.warning,
                            color: data['isReal'] == true
                                ? Colors.green
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['isReal'] == true ? 'Real QR' : 'Demo QR',
                            style: TextStyle(
                              color: data['isReal'] == true
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (!success) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _paymentResult!['error'] ?? 'Unknown error',
                  style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _paymentResult = null;
                    _paymentId = null;
                  });
                },
                child: const Text('🔄 Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBackendStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Backend Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            FutureBuilder<bool>(
              future: _paymentService.checkBackendHealth(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Checking backend status...'),
                    ],
                  );
                }

                final isHealthy = snapshot.data ?? false;
                return Row(
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.error_outline,
                      color: isHealthy ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHealthy
                          ? 'Backend is running'
                          : 'Backend is not available',
                      style: TextStyle(
                        color: isHealthy ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Setup Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('1. cd backend'),
                  Text('2. npm install'),
                  Text('3. npm start'),
                  Text('4. Server runs at http://192.168.23.1:3000'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPayment(PaymentMethod method) async {
    setState(() {
      _isLoading = true;
      _paymentResult = null;
      _paymentId = null;
    });

    try {
      final result = await _paymentService.createPayment(
        userId: 'test_user_001',
        membershipCard: _testCard,
        method: method,
        notes: 'Test payment from PaymentTestView',
      );

      setState(() {
        _paymentResult = result;
        _paymentId = result['paymentId'];
      });

      // Show success/error snackbar
      if (result['success'] == true) {
        Get.snackbar(
          '✅ Success',
          'Payment created successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          '❌ Error',
          result['error'] ?? 'Unknown error',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      setState(() {
        _paymentResult = {'success': false, 'error': e.toString()};
      });

      Get.snackbar(
        '💥 Exception',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
