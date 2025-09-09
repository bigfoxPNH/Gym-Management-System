# MoMo Payment Production Server

Production-ready Node.js/Express server cho xử lý thanh toán MoMo UAT API.

## 🚀 Tính năng

- ✅ **Không phụ thuộc ngrok** - Server production hoàn toàn độc lập
- ✅ **Chuẩn MoMo API** - Body JSON đúng format captureWallet
- ✅ **HMAC-SHA256 Signature** - Bảo mật theo chuẩn MoMo
- ✅ **Environment Variables** - Cấu hình qua file .env
- ✅ **Full Logging** - In log body request/response để debug
- ✅ **Error Handling** - Xử lý lỗi toàn diện
- ✅ **CORS Support** - Hỗ trợ Flutter web/mobile

## 📦 Cài đặt

```bash
cd backend
npm install
```

## ⚙️ Cấu hình

Tạo file `.env` trong thư mục `backend`:

```env
# MoMo Configuration
MOMO_PARTNER_CODE=MOMO0HGO20220721
MOMO_ACCESS_KEY=klm05TvNBzhg7h7j
MOMO_SECRET_KEY=at67qH6mk8w5Y1nAyMoYKMWACiEi2bsa
MOMO_REDIRECT_URL=https://yourproductiondomain.com/payment-success
MOMO_IPN_URL=https://yourproductiondomain.com/momo/callback

# Server Configuration
PORT=3000
NODE_ENV=production

# MoMo API URLs
MOMO_API_URL=https://test-payment.momo.vn/v2/gateway/api/create
MOMO_QUERY_URL=https://test-payment.momo.vn/v2/gateway/api/query
```

## 🏃‍♂️ Chạy Server

```bash
# Production
npm start

# Development với nodemon
npm run dev
```

## 📡 API Endpoints

### POST /createPayment

Tạo thanh toán mới

**Request Body:**

```json
{
  "orderId": "ORDER_123456",
  "amount": 50000,
  "orderInfo": "Thanh toán thành viên GymPro"
}
```

**Response Success:**

```json
{
  "success": true,
  "orderId": "ORDER_123456",
  "requestId": "1694123456789abc",
  "payUrl": "https://test-payment.momo.vn/gw_payment/...",
  "qrCodeUrl": "https://test-payment.momo.vn/gw_payment/...",
  "resultCode": 0,
  "message": "Successful"
}
```

### GET /paymentStatus/:orderId

Kiểm tra trạng thái thanh toán

**Response:**

```json
{
  "orderId": "ORDER_123456",
  "status": "success",
  "message": "Thanh toán thành công",
  "isSuccess": true,
  "isFailed": false,
  "isExpired": false,
  "isPending": false,
  "resultCode": 0,
  "transId": "12345678",
  "amount": 50000
}
```

### POST /momo/callback

Webhook nhận callback từ MoMo (tự động)

### GET /health

Health check server

## 🔧 Flutter Integration

Cập nhật `lib/config/momo_config.dart`:

```dart
class MoMoConfig {
  static const String productionBackendUrl = 'http://localhost:3000';
  // Hoặc domain production của bạn
  // static const String productionBackendUrl = 'https://yourproductiondomain.com';
}
```

## 📝 Logging

Server tự động log:

- 🚀 Request body khi tạo thanh toán
- 📤 Body gửi tới MoMo API
- 📥 Response từ MoMo API
- 🔐 Raw data và signature generation
- 📨 MoMo callback data

## 🛡️ Security Features

- HMAC-SHA256 signature verification
- Input validation
- Environment variable protection
- Error message sanitization
- Request timeout handling

## 🚨 Production Deployment

1. **Update .env file** với thông tin production:

   ```env
   MOMO_REDIRECT_URL=https://yourproductiondomain.com/payment-success
   MOMO_IPN_URL=https://yourproductiondomain.com/momo/callback
   NODE_ENV=production
   ```

2. **Deploy to server** và đảm bảo:

   - SSL certificate cho HTTPS
   - Port 3000 accessible
   - Process manager (PM2)

3. **Update Flutter config** với production domain

## 📞 Support

- MoMo UAT Environment
- Test Partner Code: MOMO0HGO20220721
- API Documentation: [MoMo Developer](https://developers.momo.vn)

---

**Made for GymPro** 💪
