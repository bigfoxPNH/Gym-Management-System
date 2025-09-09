# MoMo Payment Implementation Guide

## Quick Start

### 1. Start Backend Server

```bash
cd backend
node production-server.js
```

The server will start on port 3000 with these endpoints:

- `http://localhost:3000/health` - Health check
- `http://localhost:3000/createPayment` - Create payment
- `http://localhost:3000/paymentStatus/:orderId` - Check status

### 2. Use in Flutter

#### Option A: Payment Widget

```dart
import 'package:flutter/material.dart';
import '../widgets/momo_payment_widget.dart';

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MoMo Payment')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: MoMoPaymentWidget(
          orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
          amount: 50000,
          orderInfo: 'Test Payment',
          onSuccess: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment successful!')),
            );
          },
          onFailure: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed')),
            );
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
```

#### Option B: Payment Controller

```dart
import 'package:get/get.dart';
import '../controllers/production_payment_controller.dart';

class PaymentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductionPaymentController());

    return ElevatedButton(
      onPressed: () {
        controller.showPaymentDialog(
          orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
          amount: 50000,
          orderInfo: 'Test Payment',
          onSuccess: () {
            Get.snackbar('Success', 'Payment completed!');
          },
          onFailure: () {
            Get.snackbar('Failed', 'Payment failed');
          },
        );
      },
      child: Text('Pay with MoMo'),
    );
  }
}
```

## Testing Payment Flow

### 1. Test Backend API

```bash
# Test health endpoint
curl http://localhost:3000/health

# Test payment creation
curl -X POST http://localhost:3000/createPayment \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST_123",
    "amount": 50000,
    "orderInfo": "Test Payment"
  }'

# Test payment status
curl http://localhost:3000/paymentStatus/TEST_123
```

### 2. Flutter Integration Test

Create a test screen in your app:

```dart
import 'package:flutter/material.dart';
import '../services/production_momo_service.dart';

class PaymentTestScreen extends StatefulWidget {
  @override
  _PaymentTestScreenState createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  final ProductionMoMoService _service = ProductionMoMoService();
  String _status = 'Ready';

  Future<void> _testPayment() async {
    setState(() => _status = 'Creating payment...');

    try {
      final response = await _service.createPayment(
        orderId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        amount: 10000,
        orderInfo: 'Test Payment',
      );

      if (response.success) {
        setState(() => _status = 'Payment created! QR code ready.');

        // Start polling status
        _service.pollPaymentStatus(response.orderId).listen((status) {
          setState(() => _status = 'Status: ${status.status} - ${status.message}');
        });
      } else {
        setState(() => _status = 'Error: ${response.error}');
      }
    } catch (e) {
      setState(() => _status = 'Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testPayment,
              child: Text('Test Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Configuration

### Backend Environment Variables

```bash
# MoMo Configuration
MOMO_PARTNER_CODE=MOMO0HGO20220721
MOMO_ACCESS_KEY=mTCKt9W3eU1m39TW
MOMO_SECRET_KEY=SuqieLSjmfxOEFhKdPJrQOvjaglzrNzP

# Domain Configuration (for production)
PRODUCTION_DOMAIN=https://yourdomain.com
FRONTEND_URL=http://localhost:4000

# Server Configuration
PORT=3000
```

### Flutter Configuration

Update `lib/config/momo_config.dart`:

```dart
class MoMoConfig {
  // For local development
  static const String localBackendUrl = "http://localhost:3000";

  // For production (update this!)
  static const String productionBackendUrl = "https://yourdomain.com";

  // Current environment
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static String get backendUrl => isProduction ? productionBackendUrl : localBackendUrl;
}
```

## Features

### ✅ What's Working

- Backend server with production architecture
- Payment creation via MoMo API
- QR code generation as base64 images
- Payment status polling (3-5 second intervals)
- Automatic callback handling
- Signature verification for security
- Flutter widgets for easy integration
- Clean error handling and status messages

### 🚫 What's Removed

- All ngrok dependencies
- Temporary URL generation
- update_momo_config.js script
- Old proxy servers
- ngrok.exe file

### 🔄 Payment Status Flow

1. `pending` - Payment created, waiting for user to scan QR
2. `success` - User completed payment successfully
3. `failed` - Payment failed or was rejected
4. `expired` - Payment timed out (after 2 minutes)

## Error Handling

### Common Issues

#### Backend not responding

```
Error: Network error: Connection refused
```

**Solution**: Make sure backend server is running on port 3000

#### Invalid MoMo credentials

```
Error: Failed to create payment: Invalid signature
```

**Solution**: Check MoMo configuration in environment variables

#### CORS errors (web only)

```
Error: CORS policy blocked the request
```

**Solution**: Backend includes CORS headers, but verify frontend URL configuration

## Production Deployment

### 1. Deploy Backend

```bash
# Install dependencies
npm install

# Set production environment variables
export NODE_ENV=production
export MOMO_PARTNER_CODE=your_production_code
export MOMO_ACCESS_KEY=your_production_key
export MOMO_SECRET_KEY=your_production_secret
export PRODUCTION_DOMAIN=https://yourdomain.com

# Start server
npm start
```

### 2. Update Flutter Config

```dart
static const String productionBackendUrl = "https://yourdomain.com";
```

### 3. Build Flutter App

```bash
flutter build apk --release
# or
flutter build web --release
```

## Next Steps

1. **Replace In-Memory Storage**: Implement database storage for transactions
2. **Add Logging**: Implement proper logging with timestamps and request IDs
3. **Add Monitoring**: Set up health checks and error alerting
4. **Add Rate Limiting**: Prevent abuse of payment endpoints
5. **Add Payment Reconciliation**: Compare your records with MoMo's records

This implementation provides a solid foundation for production MoMo payments without any ngrok dependencies!
