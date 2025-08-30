import 'package:dio/dio.dart';

void main() async {
  await testPaymentFlow();
}

Future<void> testPaymentFlow() async {
  final dio = Dio();
  const String serverUrl = 'http://192.168.23.1:3003';

  print('🧪 Testing MoMo Payment Flow...\n');

  try {
    // Test 1: Create payment
    print('1️⃣ Testing payment creation...');
    final createResponse = await dio.post(
      '$serverUrl/api/momo/create-payment',
      data: {
        'orderId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        'amount': 50000,
        'orderInfo': 'Test Payment Flow',
      },
    );

    if (createResponse.statusCode == 200) {
      print('✅ Payment creation successful');
      final orderId = createResponse.data['orderId'];
      final qrCodeUrl = createResponse.data['qrCodeUrl'];

      print('   Order ID: $orderId');
      print('   QR Code: $qrCodeUrl');
      print(
        '   Payment URL: $serverUrl/momo-payment?orderId=$orderId&amount=50000&orderInfo=Test%20Payment%20Flow\n',
      );

      // Test 2: Check payment status
      print('2️⃣ Testing payment status check...');
      final statusResponse = await dio.get(
        '$serverUrl/api/momo/payment-status/$orderId',
      );

      if (statusResponse.statusCode == 200) {
        print('✅ Payment status check successful');
        print('   Status: ${statusResponse.data['status']}');
        print(
          '   Time remaining: ${statusResponse.data['timeRemaining']} seconds\n',
        );

        // Test 3: Simulate QR scan payment
        print('3️⃣ Simulating QR scan payment...');
        await Future.delayed(Duration(seconds: 2));

        final scanResponse = await dio.post('$serverUrl/test/scan-qr/$orderId');

        if (scanResponse.statusCode == 200) {
          print('✅ QR scan simulation successful');
          print('   Message: ${scanResponse.data['message']}\n');

          // Test 4: Verify payment completion
          print('4️⃣ Verifying payment completion...');
          await Future.delayed(Duration(seconds: 1));

          final finalStatusResponse = await dio.get(
            '$serverUrl/api/momo/payment-status/$orderId',
          );

          if (finalStatusResponse.statusCode == 200) {
            print('✅ Payment completion verified');
            print('   Final status: ${finalStatusResponse.data['status']}');
            print('   Success: ${finalStatusResponse.data['success']}\n');

            if (finalStatusResponse.data['status'] == 'success') {
              print('🎉 Payment flow test completed successfully!');
            } else {
              print('❌ Payment did not complete successfully');
            }
          } else {
            print('❌ Failed to verify payment completion');
          }
        } else {
          print('❌ QR scan simulation failed');
        }
      } else {
        print('❌ Payment status check failed');
      }
    } else {
      print('❌ Payment creation failed');
    }
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
