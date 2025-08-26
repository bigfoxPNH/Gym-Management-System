# 🚀 Hướng dẫn triển khai MoMo QR thật

## **📋 Tổng quan**

Để sử dụng MoMo QR thật (không phải demo), bạn cần chạy backend proxy server vì web browser không thể gọi MoMo API trực tiếp do CORS policy.

## **🏗️ Kiến trúc hệ thống**

```
Flutter Web App ←→ Backend Proxy Server ←→ MoMo API
```

## **⚡ Bước 1: Cài đặt và chạy backend**

### 1.1. Cài đặt Node.js dependencies

```bash
cd backend
npm install
```

### 1.2. Khởi động server

```bash
# Development mode (auto-restart khi có thay đổi)
npm run dev

# Production mode
npm start
```

Server sẽ chạy tại: `http://localhost:3000`

### 1.3. Kiểm tra server health

Truy cập: `http://localhost:3000/health`
Kết quả mong đợi:

```json
{
  "status": "OK",
  "message": "MoMo Proxy Server is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## **🔧 Bước 2: Cấu hình Flutter app**

### 2.1. Cập nhật endpoint trong `momo_service_v3.dart`

```dart
class MoMoConfig {
  // Development
  static const String endpoint = 'http://localhost:3000/api/momo/create-payment';

  // Production - thay your-domain.com bằng domain thật
  // static const String endpoint = 'https://your-domain.com/api/momo/create-payment';
}
```

### 2.2. Sử dụng PaymentServiceV2 trong UI

```dart
import '../services/payment_service_v2.dart';

final paymentService = PaymentServiceV2();

// Tạo thanh toán MoMo
final result = await paymentService.createPayment(
  userId: userId,
  membershipCard: card,
  method: PaymentMethod.momo,
);
```

## **📱 Bước 3: Test thanh toán**

### 3.1. Quy trình test

1. ✅ Chạy backend server: `cd backend && npm start`
2. ✅ Chạy Flutter app: `flutter run -d chrome --web-port 5000`
3. ✅ Thực hiện mua membership card
4. ✅ Chọn phương thức "MoMo"
5. ✅ Kiểm tra QR code có hiển thị
6. ✅ **Quan trọng**: Dùng app MoMo thật để quét QR

### 3.2. Kết quả mong đợi

- ✅ QR code được tạo thành công
- ✅ App MoMo có thể quét và thanh toán được
- ✅ Callback từ MoMo được xử lý tự động
- ✅ Membership purchase được tạo khi thanh toán thành công

## **🔒 Bước 4: Cấu hình MoMo credentials**

### 4.1. Cập nhật sandbox credentials trong `backend/momo-proxy-server.js`

```javascript
const MOMO_CONFIG = {
  partnerCode: "MOMO",
  accessKey: "F8BBA842ECF85", // Sandbox key
  secretKey: "K951B6PE1waDMi640xX08PD3vg6EkVlz", // Sandbox secret
  endpoint: "https://test-payment.momo.vn/v2/gateway/api/create",

  // Production (uncomment khi có credentials thật)
  // partnerCode: 'YOUR_PARTNER_CODE',
  // accessKey: 'YOUR_ACCESS_KEY',
  // secretKey: 'YOUR_SECRET_KEY',
  // endpoint: 'https://payment.momo.vn/v2/gateway/api/create',
};
```

### 4.2. Cấu hình callback URLs

```javascript
const baseUrl = "http://localhost:3000"; // Development
// const baseUrl = 'https://your-domain.com'; // Production

const returnUrl = `${baseUrl}/payment/momo/return`;
const notifyUrl = `${baseUrl}/payment/momo/callback`;
```

## **🌐 Bước 5: Deploy production**

### 5.1. Deploy backend lên cloud

**Heroku:**

```bash
# Tạo Heroku app
heroku create your-app-name

# Deploy
git subtree push --prefix=backend heroku main
```

**Railway:**

```bash
# Connect Railway
railway login
railway init
railway up
```

**Vercel:**

```bash
# Deploy
vercel --prod
```

### 5.2. Cập nhật Flutter config cho production

```dart
class MoMoConfig {
  static const String endpoint = 'https://your-deployed-backend.com/api/momo/create-payment';
}
```

### 5.3. Cập nhật MoMo callback URLs

Trong MoMo partner portal, cập nhật:

- Return URL: `https://your-backend.com/payment/momo/return`
- IPN URL: `https://your-backend.com/payment/momo/callback`

## **🐛 Troubleshooting**

### ❌ "Không thể kết nối tới server backend"

**Nguyên nhân**: Backend chưa chạy hoặc URL không đúng
**Giải pháp**:

1. Kiểm tra backend: `http://localhost:3000/health`
2. Khởi động backend: `cd backend && npm start`
3. Kiểm tra URL trong MoMoConfig

### ❌ "MoMo app báo mã không hỗ trợ thanh toán"

**Nguyên nhân**: Đang dùng demo QR hoặc credentials không đúng
**Giải pháp**:

1. Đảm bảo backend đang chạy và tạo QR thật
2. Kiểm tra MoMo credentials trong backend
3. Kiểm tra message hiển thị có ghi "QR này được tạo qua MoMo API thật"

### ❌ CORS errors

**Nguyên nhân**: Flutter web gọi MoMo API trực tiếp
**Giải pháp**: Luôn sử dụng backend proxy, không gọi MoMo API trực tiếp từ Flutter web

### ❌ Backend deployment issues

**Giải pháp**:

1. Đảm bảo `package.json` có đủ dependencies
2. Cấu hình environment variables cho production
3. Kiểm tra port configuration

## **✅ Checklist hoàn thiện**

- [ ] Backend server chạy thành công
- [ ] Flutter app connect được tới backend
- [ ] QR code MoMo được tạo (không phải demo)
- [ ] App MoMo có thể quét và thanh toán
- [ ] Callback được xử lý tự động
- [ ] Membership purchase được tạo khi thanh toán thành công
- [ ] Deploy production và cập nhật callback URLs

## **💡 Tips**

1. **Development**: Luôn chạy backend trước khi test Flutter app
2. **Testing**: Dùng MoMo app thật để verify QR code hoạt động
3. **Production**: Đăng ký MoMo merchant account để có credentials thật
4. **Security**: Không bao giờ commit credentials vào git
5. **Monitoring**: Setup logging để track payment status

---

🎉 **Sau khi hoàn thành**: Bạn sẽ có hệ thống thanh toán MoMo thật hoàn chỉnh, không còn demo!
