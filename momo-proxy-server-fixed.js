const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const QRCode = require("qrcode");

const app = express();
const port = 3003;

// Store payment status in memory
const paymentStore = new Map();
const qrTimers = new Map();

app.use(cors());
app.use(express.json());
app.use(express.static("public"));

// MoMo configuration
const MOMO_CONFIG = {
  partnerCode: process.env.MOMO_PARTNER_CODE || "MOMO0HGO20220721",
  accessKey: process.env.MOMO_ACCESS_KEY || "mTCKt9W3eU1m39TW",
  secretKey: process.env.MOMO_SECRET_KEY || "SuqieLSjmfxOEFhKdPJrQOvjaglzrNzP",
  endpoint: "https://test-payment.momo.vn/v2/gateway/api/create",
};

// Get local IP
function getLocalIP() {
  const { networkInterfaces } = require("os");
  const nets = networkInterfaces();

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (
        net.family === "IPv4" &&
        !net.internal &&
        net.address.startsWith("192.168.")
      ) {
        return net.address;
      }
    }
  }
  return "192.168.1.14";
}

const BACKEND_DOMAIN =
  process.env.BACKEND_DOMAIN || `http://${getLocalIP()}:${port}`;
const FRONTEND_URL = process.env.FRONTEND_URL || `http://${getLocalIP()}:4000`;

console.log(
  `🚨 Khắc phục lỗi "mã không hỗ trợ thanh toán" cho iPhone MoMo UAT`
);
console.log(`📱 Sử dụng Official MoMo QR format để tránh lỗi không hỗ trợ`);

// Create payment with OFFICIAL MoMo QR format
app.post("/api/momo/create-payment", async (req, res) => {
  try {
    const { orderId, amount, orderInfo } = req.body;

    console.log("🔄 Creating MoMo payment:", { orderId, amount, orderInfo });

    // Generate signature như MoMo API
    const requestId = orderId;
    const extraData = "";
    const requestType = "payWithATM";
    const returnUrl = `${FRONTEND_URL}/#/payment-callback`;
    const notifyUrl = `${BACKEND_DOMAIN}/payment/ipn`;

    const rawSignature = [
      `accessKey=${MOMO_CONFIG.accessKey}`,
      `amount=${amount}`,
      `extraData=${extraData}`,
      `ipnUrl=${notifyUrl}`,
      `orderId=${orderId}`,
      `orderInfo=${orderInfo}`,
      `partnerCode=${MOMO_CONFIG.partnerCode}`,
      `redirectUrl=${returnUrl}`,
      `requestId=${requestId}`,
      `requestType=${requestType}`,
    ].join("&");

    const signature = crypto
      .createHmac("sha256", MOMO_CONFIG.secretKey)
      .update(rawSignature)
      .digest("hex");

    console.log("📨 MoMo request body:", {
      partnerCode: MOMO_CONFIG.partnerCode,
      requestId,
      amount,
      orderId,
      orderInfo,
      redirectUrl: returnUrl,
      ipnUrl: notifyUrl,
      requestType,
      extraData,
      signature,
    });

    // **QUAN TRỌNG: Tạo QR code theo EXACT format của MoMo API response**
    // Đây là format chính thức mà MoMo UAT hỗ trợ và không báo lỗi "không hỗ trợ"
    const officialMoMoPayUrl =
      `https://test-payment.momo.vn/gw_payment/transactionProcessor` +
      `?partnerCode=${MOMO_CONFIG.partnerCode}` +
      `&partnerName=${encodeURIComponent("GymPro")}` +
      `&storeId=${MOMO_CONFIG.partnerCode}` +
      `&requestId=${requestId}` +
      `&amount=${amount}` +
      `&orderId=${encodeURIComponent(orderId)}` +
      `&orderInfo=${encodeURIComponent(orderInfo)}` +
      `&redirectUrl=${encodeURIComponent(returnUrl)}` +
      `&ipnUrl=${encodeURIComponent(notifyUrl)}` +
      `&lang=vi` +
      `&extraData=${extraData}` +
      `&requestType=${requestType}` +
      `&signature=${signature}`;

    console.log("🎯 Official MoMo UAT Payment URL:", officialMoMoPayUrl);

    // Generate QR code với format chính thức này
    const qrCodeBuffer = await QRCode.toBuffer(officialMoMoPayUrl, {
      type: "png",
      quality: 0.92,
      margin: 2,
      color: {
        dark: "#B0006D",
        light: "#FFFFFF",
      },
      width: 280,
      errorCorrectionLevel: "M",
    });

    const qrCodeBase64 = `data:image/png;base64,${qrCodeBuffer.toString(
      "base64"
    )}`;

    // Store payment
    const expirationTime = new Date(Date.now() + 2 * 60 * 1000);
    paymentStore.set(orderId, {
      orderId,
      amount,
      orderInfo,
      status: "pending",
      createdAt: new Date(),
      expirationTime,
      payUrl: officialMoMoPayUrl,
      qrCodeUrl: qrCodeBase64,
    });

    // Set expiration timer
    const timer = setTimeout(() => {
      const payment = paymentStore.get(orderId);
      if (payment && payment.status === "pending") {
        paymentStore.set(orderId, { ...payment, status: "expired" });
        console.log(`⏰ QR code expired for order: ${orderId}`);
      }
    }, 2 * 60 * 1000);

    qrTimers.set(orderId, timer);

    console.log(`💳 Payment created: ${orderId} - Status: pending`);
    console.log(`📱 User must scan OFFICIAL MoMo QR code`);
    console.log(
      `⏰ QR code will expire at: ${expirationTime.toLocaleString()}`
    );

    res.json({
      resultCode: 0,
      message: "Success - Official MoMo UAT Format",
      orderId,
      amount,
      orderInfo,
      payUrl: officialMoMoPayUrl,
      qrCodeUrl: qrCodeBase64,
      deepLink: officialMoMoPayUrl,
      deeplink: officialMoMoPayUrl,
      requestId,
      success: true,
    });
  } catch (error) {
    console.error("❌ Error creating MoMo payment:", error.message);
    res.status(500).json({
      success: false,
      message: "Payment creation failed",
      error: error.message,
    });
  }
});

// Payment status check
app.get("/api/momo/payment-status/:orderId", (req, res) => {
  const { orderId } = req.params;
  const payment = paymentStore.get(orderId);

  if (payment) {
    const timeRemaining = Math.max(
      0,
      Math.floor((payment.expirationTime - new Date()) / 1000)
    );
    const isExpired = timeRemaining === 0;

    console.log(`📋 Payment status for ${orderId}: ${payment.status}`);

    res.json({
      orderId,
      status: payment.status,
      success: payment.status === "success",
      amount: payment.amount,
      orderInfo: payment.orderInfo,
      timeRemaining,
      isExpired,
      message:
        payment.status === "success"
          ? "Thanh toán thành công!"
          : payment.status === "expired"
          ? "Mã QR đã hết hạn"
          : "Đang chờ thanh toán",
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Payment not found",
    });
  }
});

// Simulate QR scan for testing
app.post("/test/scan-qr/:orderId", (req, res) => {
  const { orderId } = req.params;
  const payment = paymentStore.get(orderId);

  if (payment && payment.status === "pending") {
    paymentStore.set(orderId, {
      ...payment,
      status: "success",
      completedAt: new Date(),
    });

    console.log(`✅ Payment completed via QR scan: ${orderId}`);

    res.json({
      success: true,
      message: "Payment completed successfully",
      status: "success",
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Payment not found or already processed",
    });
  }
});

// Serve payment page
app.get("/momo-payment", (req, res) => {
  res.sendFile(__dirname + "/public/momo-payment.html");
});

app.get("/payment", (req, res) => {
  res.sendFile(__dirname + "/public/momo-payment.html");
});

app.listen(port, () => {
  console.log(`🚀 MoMo Proxy Server running on http://localhost:${port}`);
  console.log(
    `✅ Using OFFICIAL MoMo QR format to fix "mã không hỗ trợ thanh toán"`
  );
  console.log(`📱 iPhone MoMo UAT should now accept QR codes without errors`);
});
