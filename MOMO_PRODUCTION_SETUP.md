/// Hướng dẫn thiết lập thanh toán MoMo thật cho production
///
/// VẤN ĐỀ HIỆN TẠI:
/// - MoMo API không thể gọi trực tiếp từ web browser do CORS policy
/// - QR code demo không được MoMo app nhận diện
///
/// GIẢI PHÁP PRODUCTION:

## 1. BACKEND PROXY SERVER (KHUYẾN CÁO)

### Node.js/Express Proxy Server:

```javascript
const express = require("express");
const axios = require("axios");
const crypto = require("crypto");
const app = express();

// MoMo API endpoint
const MOMO_ENDPOINT = "https://test-payment.momo.vn/v2/gateway/api/create";

// Proxy endpoint để call MoMo API
app.post("/api/momo/create-payment", async (req, res) => {
  try {
    // Forward request to MoMo API
    const response = await axios.post(MOMO_ENDPOINT, req.body);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000);
```

### Flutter Service Update:

```dart
// Thay đổi endpoint từ MoMo trực tiếp sang proxy server
static const String endpoint = 'https://your-backend.com/api/momo/create-payment';
```

## 2. FLUTTER MOBILE APP (ALTERNATIVE)

### Chạy trên mobile thay vì web:

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Mobile sẽ bypass CORS và gọi MoMo API trực tiếp:

```dart
final response = await _dio.post(
  'https://test-payment.momo.vn/v2/gateway/api/create',
  data: request.toJson(),
);
```

## 3. WEBHOOK SETUP

### Cần setup webhook endpoint thật:

```dart
// Thay vì localhost
static const String notifyUrl = 'https://your-domain.com/webhooks/momo';
static const String returnUrl = 'https://your-domain.com/payment/success';
```

### Backend webhook handler:

```javascript
app.post("/webhooks/momo", (req, res) => {
  const callbackData = req.body;

  // Verify signature
  if (verifyMoMoSignature(callbackData)) {
    // Update payment status in database
    updatePaymentStatus(callbackData.orderId, "success");

    // Send notification to Flutter app via Firebase
    sendPushNotification(callbackData.orderId);

    res.json({ RspCode: "00", Message: "Success" });
  } else {
    res.json({ RspCode: "01", Message: "Invalid signature" });
  }
});
```

## 4. PRODUCTION CHECKLIST

### MoMo Production Setup:

- [ ] Đăng ký merchant account với MoMo
- [ ] Lấy production credentials (partnerCode, accessKey, secretKey)
- [ ] Setup domain và SSL certificate
- [ ] Cấu hình webhook endpoints
- [ ] Test với MoMo sandbox
- [ ] Submit cho MoMo review và approve

### Technical Setup:

- [ ] Deploy backend proxy server
- [ ] Setup database để lưu payment transactions
- [ ] Implement webhook security (signature verification)
- [ ] Setup monitoring và logging
- [ ] Configure error handling và fallbacks

## 5. TEST SCENARIOS

### Sandbox Testing:

```dart
// Test data cho MoMo sandbox
final testPayment = {
  'amount': 10000,
  'orderInfo': 'Test payment',
  'orderId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
};
```

### Production Testing:

- Test với số tiền nhỏ (1,000 VND)
- Test các scenarios: success, failed, timeout
- Test webhook callbacks
- Test mobile vs web behavior

## KẾT LUẬN:

Để MoMo QR code hoạt động thật, cần:

1. **Backend proxy server** hoặc **Mobile app**
2. **Production MoMo credentials**
3. **Real webhook endpoints**
4. **Proper domain setup**

Current demo chỉ mô phỏng flow, không thể thanh toán thật được.
