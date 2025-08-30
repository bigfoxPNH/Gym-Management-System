const express = require("express");
const axios = require("axios");
const crypto = require("crypto");
const cors = require("cors");
const QRCode = require("qrcode");
const os = require("os");
const path = require("path");

const app = express();

// Enable CORS cho Flutter web
app.use(cors());
app.use(express.json());

// Serve static files từ thư mục public
app.use("/public", express.static(path.join(__dirname, "public")));

// Lấy IP thực của máy
function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Tìm IPv4 không phải loopback và không internal
      if (iface.family === "IPv4" && !iface.internal) {
        return iface.address;
      }
    }
  }
  return "localhost"; // fallback
}

// MoMo configuration theo tài liệu chính thức
const MOMO_CONFIG = {
  partnerCode: "MOMO",
  accessKey: "F8BBA842ECF85",
  secretKey: "K951B6PE1waDMi640xX08PD3vg6EkVlz",
  endpoint: "https://test-payment.momo.vn/v2/gateway/api/create",
  redirectUrl: "https://6b601b1cc795.ngrok-free.app/payment-success", // Redirect về trang success của chúng ta
  ipnUrl: "https://6b601b1cc795.ngrok-free.app/api/momo/callback", // Callback endpoint
};

// Generate HMAC SHA256 signature
function generateSignature(rawData) {
  return crypto
    .createHmac("sha256", MOMO_CONFIG.secretKey)
    .update(rawData)
    .digest("hex");
}

// Proxy endpoint để tạo MoMo payment với deep linking support
app.post("/api/momo/create-payment", async (req, res) => {
  try {
    const { orderId, amount, orderInfo } = req.body;
    const requestId = `MM${Date.now()}${Math.floor(Math.random() * 999999)}`;

    // Tạo raw signature data theo MoMo spec cho One-Time Payment
    const rawSignature = `accessKey=${MOMO_CONFIG.accessKey}&amount=${amount}&extraData=&ipnUrl=${MOMO_CONFIG.ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${MOMO_CONFIG.partnerCode}&redirectUrl=${MOMO_CONFIG.redirectUrl}&requestId=${requestId}&requestType=captureWallet`;

    const signature = generateSignature(rawSignature);

    const requestBody = {
      partnerCode: MOMO_CONFIG.partnerCode,
      requestId: requestId,
      amount: parseInt(amount),
      orderId: orderId,
      orderInfo: orderInfo,
      redirectUrl: MOMO_CONFIG.redirectUrl, // Deep link để quay về app
      ipnUrl: MOMO_CONFIG.ipnUrl,
      requestType: "captureWallet",
      extraData: "",
      lang: "vi",
      signature: signature,
    };

    console.log("🚀 Calling MoMo API with deep link:", requestBody);

    // Gọi MoMo API
    const response = await axios.post(MOMO_CONFIG.endpoint, requestBody, {
      headers: {
        "Content-Type": "application/json",
      },
      timeout: 30000,
    });

    console.log("💰 MoMo API Response:", response.data);

    // Tạo QR code từ payUrl (chính xác theo tài liệu MoMo)
    let qrCodeDataUrl = null;
    if (response.data.payUrl) {
      try {
        qrCodeDataUrl = await QRCode.toDataURL(response.data.payUrl, {
          width: 300,
          margin: 2,
          color: {
            dark: "#000000",
            light: "#FFFFFF",
          },
        });
        console.log("✅ QR Code generated successfully from payUrl");
      } catch (qrError) {
        console.error("❌ QR Code generation error:", qrError);
        throw new Error("Failed to generate QR Code from payUrl");
      }
    } else {
      throw new Error("MoMo API did not return a valid payUrl");
    }

    // Trả về response với QR code và deep linking info
    const responseData = {
      ...response.data,
      qrCodeUrl: qrCodeDataUrl, // QR code image data URL để hiển thị
      originalPayUrl: response.data.payUrl, // payUrl gốc từ MoMo
      originalQrCodeUrl: response.data.qrCodeUrl, // qrCodeUrl gốc (deeplink)
      originalDeeplink: response.data.deeplink, // deeplink gốc
      // Thêm thông tin cho Flutter app
      appDeeplink: MOMO_CONFIG.redirectUrl, // Deep link để quay về app
      paymentInfo: {
        orderId: orderId,
        requestId: requestId,
        amount: amount,
        orderInfo: orderInfo,
      },
    };

    res.json(responseData);
  } catch (error) {
    console.error("❌ MoMo API Error:", error.response?.data || error.message);
    res.status(500).json({
      error: error.message,
      details: error.response?.data,
    });
  }
});

// Webhook endpoint nhận callback từ MoMo - Support deep linking
app.post("/api/momo/callback", async (req, res) => {
  try {
    const callbackData = req.body;
    console.log("🔔 MoMo Callback received:", callbackData);

    // Verify signature để đảm bảo tính xác thực
    const rawSignature = `accessKey=${MOMO_CONFIG.accessKey}&amount=${callbackData.amount}&extraData=${callbackData.extraData}&message=${callbackData.message}&orderId=${callbackData.orderId}&orderInfo=${callbackData.orderInfo}&orderType=${callbackData.orderType}&partnerCode=${callbackData.partnerCode}&payType=${callbackData.payType}&requestId=${callbackData.requestId}&responseTime=${callbackData.responseTime}&resultCode=${callbackData.resultCode}&transId=${callbackData.transId}`;

    const expectedSignature = generateSignature(rawSignature);

    if (expectedSignature === callbackData.signature) {
      // Lưu kết quả vào payment status store
      if (callbackData.resultCode == 0) {
        console.log("✅ Payment successful:", {
          orderId: callbackData.orderId,
          transId: callbackData.transId,
          amount: callbackData.amount,
        });

        // Update payment status
        paymentStatusStore[callbackData.orderId] = {
          status: "success",
          message: "Payment completed successfully",
          transId: callbackData.transId,
          amount: callbackData.amount,
          completedAt: new Date().toISOString(),
        };
      } else {
        console.log("❌ Payment failed:", {
          orderId: callbackData.orderId,
          resultCode: callbackData.resultCode,
          message: callbackData.message,
        });

        // Update payment status
        paymentStatusStore[callbackData.orderId] = {
          status: "failed",
          message: callbackData.message || "Payment failed",
          resultCode: callbackData.resultCode,
          failedAt: new Date().toISOString(),
        };
      }

      // Trả về xác nhận đã nhận callback thành công
      res.json({ RspCode: "00", Message: "Confirm Success" });
    } else {
      console.error("❌ Invalid signature in callback");
      res.json({ RspCode: "01", Message: "Invalid signature" });
    }
  } catch (error) {
    console.error("❌ Callback processing error:", error);
    res.json({ RspCode: "99", Message: "Internal error" });
  }
});

// Endpoint để Flutter app check trạng thái payment
app.get("/api/momo/payment-status/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    console.log(`📋 Checking payment status for order: ${orderId}`);

    // Trong real app sẽ query từ database
    // Tạm thời check nếu order tồn tại trong recent payments
    const paymentStatus = paymentStatusStore[orderId] || {
      status: "pending",
      message: "Waiting for payment confirmation",
    };

    res.json({
      orderId: orderId,
      ...paymentStatus,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("❌ Payment status check error:", error);
    res.status(500).json({
      error: error.message,
    });
  }
});

// QR Code generation endpoint
app.get("/api/momo/qr-code", async (req, res) => {
  try {
    const { payUrl, orderId } = req.query;

    if (!payUrl || !orderId) {
      return res.status(400).json({ error: "payUrl and orderId are required" });
    }

    console.log(`🔍 Generating QR code for payUrl: ${payUrl}`);

    // Generate QR code from payUrl
    const qrCodeDataUrl = await QRCode.toDataURL(payUrl, {
      width: 300,
      margin: 2,
      color: {
        dark: "#000000",
        light: "#FFFFFF",
      },
    });

    // Set QR code expiration timer
    setTimeout(() => {
      paymentStatusStore[orderId] = {
        status: "expired",
        message: "QR code expired",
      };
      console.log(`⏰ QR code expired for order: ${orderId}`);
    }, 2 * 60 * 1000); // Expire after 2 minutes

    res.json({
      success: true,
      qrCodeUrl: qrCodeDataUrl,
      payUrl: payUrl,
    });
  } catch (error) {
    console.error("❌ QR Code generation error:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Endpoint to validate QR scan
app.post("/api/momo/validate-scan", async (req, res) => {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return res.status(400).json({ error: "orderId is required" });
    }

    const paymentStatus = paymentStatusStore[orderId];

    if (!paymentStatus || paymentStatus.status === "expired") {
      return res.status(400).json({ error: "QR code is expired or invalid" });
    }

    // Ensure payment is marked as successful only after user scans QR
    paymentStatusStore[orderId] = {
      status: "success",
      message: "Payment completed successfully",
      transId: `VALID_${Date.now()}`,
      completedAt: new Date().toISOString(),
    };

    console.log(`🎉 Payment validated for order: ${orderId}`);

    res.json({
      success: true,
      message: "Payment validated successfully",
    });
  } catch (error) {
    console.error("❌ Payment validation error:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Simple in-memory store for payment status (replace with real database)
const paymentStatusStore = {};

// Mock success callback endpoint cho test local
app.post("/api/momo/mock-success/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    console.log(`🎉 Mock success callback for order: ${orderId}`);

    // Update payment status to success immediately
    paymentStatusStore[orderId] = {
      status: "success",
      message: "Payment completed successfully (mock)",
      transId: `MOCK_${Date.now()}`,
      amount: parseInt(req.body.amount) || 10000, // Use actual amount
      completedAt: new Date().toISOString(),
    };

    res.json({
      success: true,
      message: `Payment ${orderId} marked as successful`,
      data: paymentStatusStore[orderId],
    });
  } catch (error) {
    console.error("❌ Mock success error:", error);
    res.status(500).json({
      error: error.message,
    });
  }
});

// Alias to be compatible with Flutter app calling /manual-success
app.post("/api/momo/manual-success/:orderId", (req, res) => {
  // Reuse the same logic as mock-success
  const { orderId } = req.params;
  paymentStatusStore[orderId] = {
    status: "success",
    message: "Payment completed successfully (manual)",
    transId: `MANUAL_${Date.now()}`,
    amount: parseInt(req.body?.amount) || 10000,
    completedAt: new Date().toISOString(),
  };
  res.json({
    success: true,
    message: `Payment ${orderId} marked as successful (manual)`,
    data: paymentStatusStore[orderId],
  });
});

// Mark success endpoint called by payment-success page (idempotent)
app.post("/api/momo/mark-success/:orderId", (req, res) => {
  const { orderId } = req.params;
  const amount = parseInt(req.body?.amount) || undefined;
  if (
    !paymentStatusStore[orderId] ||
    paymentStatusStore[orderId].status !== "success"
  ) {
    paymentStatusStore[orderId] = {
      status: "success",
      message: "Payment completed successfully (mark)",
      transId: paymentStatusStore[orderId]?.transId || `MARK_${Date.now()}`,
      amount: amount || paymentStatusStore[orderId]?.amount,
      completedAt: new Date().toISOString(),
    };
  }
  res.json({ success: true, data: paymentStatusStore[orderId] });
});

// Mock success endpoint for testing
app.post("/api/momo/mock-success/:orderId", (req, res) => {
  try {
    const { orderId } = req.params;

    // Mark payment as successful in our store
    paymentStatusStore[orderId] = {
      status: "success",
      timestamp: Date.now(),
      data: {
        partnerCode: "MOMO",
        orderId: orderId,
        requestId: `MM${Date.now()}`,
        amount: 10000,
        resultCode: 0,
        message: "Thành công.",
        responseTime: Date.now(),
        transId: Math.floor(Math.random() * 9999999999).toString(),
      },
    };

    console.log("Mock callback data:", paymentStatusStore[orderId]);
    res.json({
      success: true,
      message: "Payment marked as successful",
      data: paymentStatusStore[orderId],
    });
  } catch (error) {
    console.error("Mock callback error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Payment success page
app.get("/payment-success", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "payment-success.html"));
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", service: "MoMo Proxy Server" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 MoMo Proxy Server running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
