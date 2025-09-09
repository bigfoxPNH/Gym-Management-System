# GymPro Production MoMo Payment Integration

## Overview

This is a production-ready MoMo payment integration for GymPro that **completely removes ngrok dependency** and implements a stable backend-centric QR payment flow.

## Architecture

### Backend (Node.js)

- **Production Server**: `backend/production-server.js`
- **Domain**: Must run on a real server with fixed HTTPS domain
- **No ngrok**: All ngrok references have been removed
- **Database Ready**: Uses in-memory storage with database abstraction layer

### Flutter App

- **No Direct MoMo API calls**: All payment operations go through backend
- **QR Code Display**: Uses `qr_flutter` package to show payment QR codes
- **Status Polling**: Polls backend every 3-5 seconds for payment status
- **Production Service**: `lib/services/production_momo_service.dart`

## API Endpoints

### POST /createPayment

Creates a new MoMo payment and returns QR code data.

**Request:**

```json
{
  "orderId": "string",
  "amount": number,
  "orderInfo": "string"
}
```

**Response:**

```json
{
  "success": true,
  "orderId": "string",
  "payUrl": "string",
  "qrCodeUrl": "data:image/png;base64,..QR_CODE..",
  "deepLink": "string",
  "amount": number,
  "orderInfo": "string",
  "message": "Payment created successfully"
}
```

### GET /paymentStatus/:orderId

Returns current payment status.

**Response:**

```json
{
  "success": true,
  "orderId": "string",
  "status": "pending|success|failed|expired",
  "amount": number,
  "orderInfo": "string",
  "transId": "string",
  "message": "string"
}
```

### POST /momo/callback

Handles MoMo IPN callbacks (webhook).

**Features:**

- Signature verification
- Transaction status updates
- Automatic retry mechanism

## Security Features

1. **HMAC-SHA256 Signature Verification**: All MoMo callbacks are verified
2. **No Secret Keys in Flutter**: All MoMo credentials stay on backend
3. **Production Domain**: No temporary URLs or ngrok tunnels
4. **CORS Protection**: Configured for production environments

## Setup Instructions

### 1. Backend Setup

```bash
cd backend
npm install
```

Set environment variables:

```bash
export MOMO_PARTNER_CODE=your_partner_code
export MOMO_ACCESS_KEY=your_access_key
export MOMO_SECRET_KEY=your_secret_key
export PRODUCTION_DOMAIN=https://yourdomain.com
export FRONTEND_URL=https://yourfrontend.com
```

Start production server:

```bash
npm start
```

### 2. Flutter Configuration

Update `lib/config/momo_config.dart`:

```dart
static const String productionBackendUrl = "https://yourdomain.com";
```

### 3. Domain Configuration

**Important**: You need a real domain with HTTPS. Update these URLs:

- MoMo callback URL: `https://yourdomain.com/momo/callback`
- Redirect URL: `https://yourdomain.com/momo/redirect`

## Usage in Flutter

### Simple Payment Widget

```dart
import '../widgets/momo_payment_widget.dart';

MoMoPaymentWidget(
  orderId: 'ORDER_123',
  amount: 50000,
  orderInfo: 'Test Payment',
  onSuccess: () => print('Payment successful'),
  onFailure: () => print('Payment failed'),
  onCancel: () => print('Payment cancelled'),
)
```

### Controller Usage

```dart
import '../controllers/production_payment_controller.dart';

final controller = Get.put(ProductionPaymentController());

// Show payment dialog
controller.showPaymentDialog(
  orderId: 'ORDER_123',
  amount: 50000,
  orderInfo: 'Test Payment',
  onSuccess: () {
    // Handle success
  },
  onFailure: () {
    // Handle failure
  },
);
```

## Payment Flow

1. **Create Payment**: Flutter app calls backend `/createPayment`
2. **Backend processes**:
   - Calls MoMo API with production credentials
   - Generates QR code as base64 image
   - Stores transaction in database
   - Returns QR data to Flutter
3. **Display QR**: Flutter shows QR code using `qr_flutter`
4. **User Scans**: User scans QR with MoMo app
5. **MoMo Callback**: MoMo sends IPN to backend `/momo/callback`
6. **Status Update**: Backend updates transaction status
7. **Flutter Polling**: Flutter polls `/paymentStatus/:orderId` every 3s
8. **Completion**: Flutter detects success/failure and shows result

## Database Schema

### Transactions Table

```sql
CREATE TABLE transactions (
  orderId VARCHAR(255) PRIMARY KEY,
  requestId VARCHAR(255),
  amount INTEGER,
  orderInfo TEXT,
  status VARCHAR(50), -- pending, success, failed, expired
  transId VARCHAR(255),
  resultCode INTEGER,
  momoMessage TEXT,
  createdAt TIMESTAMP,
  updatedAt TIMESTAMP
);
```

## Production Checklist

- [ ] Set up real HTTPS domain
- [ ] Configure MoMo merchant account with production credentials
- [ ] Set up production database (replace in-memory storage)
- [ ] Configure load balancer and SSL certificates
- [ ] Set up monitoring and logging
- [ ] Test payment flow end-to-end
- [ ] Configure backup and disaster recovery
- [ ] Set up payment reconciliation process

## Testing

### Local Testing

```bash
# Start backend
npm run dev

# Start Flutter app
flutter run
```

### UAT Testing

1. Use MoMo UAT environment credentials
2. Deploy backend to staging server with HTTPS
3. Update MoMo callback URLs in MoMo portal
4. Test with MoMo UAT app

### Production Testing

1. Deploy to production server
2. Use production MoMo credentials
3. Test with real MoMo transactions
4. Monitor logs and payment status

## Monitoring

### Key Metrics

- Payment creation success rate
- Payment completion rate
- Average payment processing time
- Callback delivery success rate
- Error rates by type

### Alerts

- Payment creation failures
- Callback verification failures
- High error rates
- Payment timeouts

## Support

For production support:

1. Check server logs for payment errors
2. Verify MoMo callback delivery
3. Check database transaction status
4. Review Flutter app logs
5. Contact MoMo support if needed

## Migration from ngrok

All ngrok dependencies have been removed:

- ❌ Deleted `ngrok.exe`
- ❌ Deleted `update_momo_config.js`
- ❌ Deleted old ngrok-based servers
- ❌ Updated VS Code tasks
- ✅ New production-ready backend
- ✅ New Flutter service and widgets
- ✅ Database-ready architecture
- ✅ Production security measures
