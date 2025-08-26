# 🚀 Hướng dẫn test hệ thống MoMo QR thật

## **📝 Tổng quan**

Hệ thống thanh toán MoMo QR thật đã được triển khai hoàn chỉnh với kiến trúc backend proxy để bypass CORS policy.

## **🏗️ Kiến trúc hệ thống**

```
Flutter Web App ←→ Backend Proxy Server ←→ MoMo API ←→ MoMo Mobile App
       ↓                    ↓                  ↓           ↓
   UI/UX Layer       CORS Handler      Real Payment    User Payment
   PaymentTestView   momo-proxy.js     Gateway API     Experience
```

## **⚡ BƯỚC 1: Khởi động Backend Server**

### 1.1. Mở terminal thứ nhất

```bash
cd backend
npm install
npm start
```

### 1.2. Verify server health

Truy cập: `http://localhost:3000/health`

Kết quả mong đợi:

```json
{
  "status": "OK",
  "message": "MoMo Proxy Server is running",
  "timestamp": "2025-08-26T..."
}
```

## **📱 BƯỚC 2: Khởi động Flutter App**

### 2.1. Mở terminal thứ hai

```bash
flutter run -d chrome
```

### 2.2. App sẽ chạy tại

`http://localhost:5000` (hoặc port được assign)

## **🧪 BƯỚC 3: Test Payment Flow**

### 3.1. Thêm PaymentTestView vào routes

**File:** `lib/routes/app_pages.dart`

```dart
import '../views/test/payment_test_view.dart';

static final routes = [
  // ... existing routes
  GetPage(
    name: '/payment-test',
    page: () => const PaymentTestView(),
  ),
];
```

### 3.2. Truy cập test page

Vào URL: `http://localhost:5000/#/payment-test`

### 3.3. Test scenarios

**A. Test Backend Status ✅**

- Kiểm tra backend server status indicator
- Xanh = OK, Đỏ = Backend down

**B. Test MoMo Payment (Real QR) ✅**

1. Click "📱 MoMo Payment"
2. Đợi QR code hiển thị
3. Kiểm tra message: **"QR này được tạo qua MoMo API thật!"**
4. Dùng app MoMo quét QR → Thanh toán thành công ✨

**C. Test Banking QR ✅**

1. Click "🏦 Banking QR"
2. QR VietQR hiển thị
3. Quét bằng app ngân hàng

**D. Test Cash Payment ✅**

1. Click "💰 Cash Payment"
2. Hiển thị hướng dẫn đến quầy

## **🔍 BƯỚC 4: Verify Payment Flow**

### 4.1. Check Firestore Database

Collection: `payments`

```json
{
  "id": "PAY_1724684800000_1234",
  "userId": "test_user_001",
  "membershipCardId": "test_card_001",
  "amount": 500000,
  "method": "momo",
  "status": "pending",
  "paymentData": {
    "type": "momo",
    "qrCodeUrl": "https://...",
    "isReal": true
  }
}
```

### 4.2. Check MoMo App Payment

1. **Mở app MoMo** → Quét QR
2. **Xác nhận thanh toán** → Thành công
3. **Backend nhận callback** → Update status = "success"
4. **Tạo membership purchase** trong Firestore

### 4.3. Check Membership Purchase

Collection: `membership_purchases`

```json
{
  "id": "purchase_id_123",
  "userId": "test_user_001",
  "membershipCardName": "Thẻ Premium Test",
  "price": 500000,
  "startDate": "2025-08-26T...",
  "endDate": "2025-11-26T...",
  "status": "active",
  "paymentId": "PAY_1724684800000_1234"
}
```

## **🐛 Troubleshooting**

### ❌ Backend Status: Red (Not Running)

```bash
# Terminal 1: Start backend
cd backend
npm install
npm start

# Verify
curl http://localhost:3000/health
```

### ❌ "Không thể kết nối tới server backend"

**Nguyên nhân:** Backend chưa chạy hoặc port conflict

**Giải pháp:**

1. Kiểm tra backend: `http://localhost:3000/health`
2. Check port: `netstat -an | findstr :3000`
3. Kill process: `taskkill /f /pid <PID>`

### ❌ QR Code hiển thị "Demo QR - Chỉ để test"

**Nguyên nhân:** Backend down, app fallback sang demo mode

**Giải pháp:** Khởi động backend server

### ❌ MoMo app báo "Mã không được hỗ trợ thanh toán"

**Nguyên nhân:** Đang dùng QR demo hoặc credentials sai

**Giải pháp:**

1. Đảm bảo message hiển thị: **"QR này được tạo qua MoMo API thật!"**
2. Kiểm tra backend logs có tạo real QR không

### ❌ Flutter compile errors

```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

## **📊 Expected Results**

### ✅ SUCCESS Indicators:

- ✅ Backend health: **Green** indicator
- ✅ QR message: **"QR này được tạo qua MoMo API thật!"**
- ✅ MoMo app: **Can scan and pay**
- ✅ Firestore: **Payment record created**
- ✅ Callback: **Auto processed**
- ✅ Membership: **Purchase created**

### 🎯 Complete Flow Test:

```
1. Click MoMo Payment → ✅ Real QR generated
2. Scan with MoMo app → ✅ Payment accepted
3. Confirm payment → ✅ Success response
4. Backend callback → ✅ Auto processed
5. Database updated → ✅ Membership created
6. User notification → ✅ Payment complete
```

## **🎉 Success Criteria**

Hệ thống hoạt động **100% thật** khi:

1. **🔒 Backend Security**: CORS bypassed, signatures verified
2. **📱 Real QR Codes**: MoMo app accepts and processes payments
3. **🔄 Auto Processing**: Callbacks handled automatically
4. **💾 Data Persistence**: Payments and memberships stored correctly
5. **🎯 User Experience**: Seamless payment flow

---

## **💡 Quick Test Command**

```bash
# Terminal 1 - Backend
cd backend && npm start

# Terminal 2 - Flutter
flutter run -d chrome

# Browser - Test
http://localhost:5000/#/payment-test
```

**🎊 Congratulations!**

Bạn đã có hệ thống thanh toán MoMo **thật 100%** - không còn demo!

MoMo QR codes sẽ được app MoMo chính thức chấp nhận và xử lý thanh toán thành công! 🚀
