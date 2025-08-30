import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/momo_service.dart';

class PaymentDemoScreen extends StatefulWidget {
  @override
  _PaymentDemoScreenState createState() => _PaymentDemoScreenState();
}

class _PaymentDemoScreenState extends State<PaymentDemoScreen> {
  final MoMoService _momoService = MoMoService();

  String? _qrCodeUrl;
  String? _payUrl;
  bool _isLoading = false;
  String? _message;

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _momoService.createPayment(10000, "Test Payment");
      setState(() {
        _payUrl = response.payUrl;
        _qrCodeUrl = response.qrCodeUrl;
        _message = "Payment request successful!";
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MoMo Payment Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (!_isLoading)
              ElevatedButton(
                onPressed: _initiatePayment,
                child: Text("Thanh toán MoMo"),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (_payUrl != null)
              ElevatedButton(
                onPressed: () => launchUrl(Uri.parse(_payUrl!)),
                child: Text("Mở Pay URL"),
              ),
            if (_qrCodeUrl != null)
              Center(child: QrImage(data: _qrCodeUrl!, size: 200.0)),
          ],
        ),
      ),
    );
  }
}
