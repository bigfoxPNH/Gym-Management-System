const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const axios = require("axios");
const path = require("path");

// Load .env file from current directory (backend folder)
require("dotenv").config({ path: path.join(__dirname, ".env") });

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(
  cors({
    origin: [
      "http://localhost:4000",
      "http://localhost:3000",
      "http://127.0.0.1:4000",
    ],
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

/**
 * Tạo chữ ký HMAC-SHA256 theo chuẩn MoMo
 * @param {string} rawData - Chuỗi dữ liệu cần ký
 * @param {string} secretKey - Secret key để ký
 * @returns {string} Chữ ký hex
 */
function generateSignature(rawData, secretKey) {
  const signature = crypto
    .createHmac("sha256", secretKey)
    .update(rawData, "utf8")
    .digest("hex");

  console.log("🔐 Signature Generation:");
  console.log("Raw Data:", rawData);
  console.log("Signature:", signature);

  return signature;
}

/**
 * Tạo requestId unique
 * @returns {string} Request ID
 */
function generateRequestId() {
  return Date.now().toString() + Math.random().toString(36).substring(2);
}

/**
 * Endpoint tạo thanh toán MoMo
 */
app.post("/createPayment", async (req, res) => {
  try {
    console.log("\n🚀 Creating MoMo Payment...");
    console.log("Request body:", JSON.stringify(req.body, null, 2));

    const { orderId, amount, orderInfo } = req.body;

    // Validate input
    if (!orderId || !amount || !orderInfo) {
      return res.status(400).json({
        success: false,
        error: "Thiếu thông tin: orderId, amount, orderInfo",
      });
    }

    // Validate environment variables
    const requiredEnvVars = [
      "MOMO_PARTNER_CODE",
      "MOMO_ACCESS_KEY",
      "MOMO_SECRET_KEY",
      "MOMO_REDIRECT_URL",
      "MOMO_IPN_URL",
    ];
    for (const envVar of requiredEnvVars) {
      if (!process.env[envVar]) {
        console.error(`❌ Missing environment variable: ${envVar}`);
        return res.status(500).json({
          success: false,
          error: `Server configuration error: Missing ${envVar}`,
        });
      }
    }

    const requestId = generateRequestId();
    const partnerCode = process.env.MOMO_PARTNER_CODE;
    const accessKey = process.env.MOMO_ACCESS_KEY;
    const secretKey = process.env.MOMO_SECRET_KEY;
    const redirectUrl = process.env.MOMO_REDIRECT_URL;
    const ipnUrl = process.env.MOMO_IPN_URL;
    const requestType = "captureWallet";
    const extraData = "";

    // Tạo raw signature data theo thứ tự MoMo quy định
    const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;

    // Tạo signature
    const signature = generateSignature(rawSignature, secretKey);

    // Tạo body request gửi cho MoMo
    const requestBody = {
      partnerCode: partnerCode,
      partnerName: "Test",
      storeId: "MomoTestStore",
      requestId: requestId,
      amount: amount.toString(),
      orderId: orderId,
      orderInfo: orderInfo,
      redirectUrl: redirectUrl,
      ipnUrl: ipnUrl,
      requestType: requestType,
      signature: signature,
      extraData: extraData,
      lang: "vi",
    };

    console.log("\n📤 Request Body to MoMo:");
    console.log(JSON.stringify(requestBody, null, 2));

    // Gửi request tới MoMo API
    const momoApiUrl =
      process.env.MOMO_API_URL ||
      "https://test-payment.momo.vn/v2/gateway/api/create";

    console.log(`\n🌐 Sending request to: ${momoApiUrl}`);

    const response = await axios.post(momoApiUrl, requestBody, {
      headers: {
        "Content-Type": "application/json",
      },
      timeout: 10000, // 10 seconds timeout
    });

    console.log("\n📥 Response from MoMo:");
    console.log("Status:", response.status);
    console.log("Data:", JSON.stringify(response.data, null, 2));

    // Trả về full response từ MoMo cho Flutter
    const momoResponse = response.data;

    // Kiểm tra kết quả
    if (momoResponse.resultCode === 0) {
      console.log("✅ Payment created successfully");
      res.json({
        success: true,
        orderId: orderId,
        requestId: requestId,
        payUrl: momoResponse.payUrl,
        qrCodeUrl: momoResponse.qrCodeUrl,
        deeplink: momoResponse.deeplink,
        deeplinkMiniApp: momoResponse.deeplinkMiniApp,
        ...momoResponse,
      });
    } else {
      console.log("❌ Payment creation failed:", momoResponse.message);
      res.json({
        success: false,
        error: momoResponse.message || "Tạo thanh toán thất bại",
        resultCode: momoResponse.resultCode,
        ...momoResponse,
      });
    }
  } catch (error) {
    console.error("❌ Error creating payment:", error.message);

    if (error.code === "ECONNABORTED") {
      return res.status(408).json({
        success: false,
        error: "Timeout khi kết nối tới MoMo API",
      });
    }

    if (error.response) {
      console.error("MoMo API Error Response:", error.response.data);
      return res.status(500).json({
        success: false,
        error:
          "MoMo API Error: " + (error.response.data?.message || error.message),
      });
    }

    res.status(500).json({
      success: false,
      error: "Internal server error: " + error.message,
    });
  }
});

/**
 * Endpoint kiểm tra trạng thái thanh toán
 */
app.get("/paymentStatus/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    console.log(`\n🔍 Checking payment status for orderId: ${orderId}`);

    const requestId = generateRequestId();
    const partnerCode = process.env.MOMO_PARTNER_CODE;
    const accessKey = process.env.MOMO_ACCESS_KEY;
    const secretKey = process.env.MOMO_SECRET_KEY;

    // Tạo signature cho query
    const rawSignature = `accessKey=${accessKey}&orderId=${orderId}&partnerCode=${partnerCode}&requestId=${requestId}`;
    const signature = generateSignature(rawSignature, secretKey);

    const queryBody = {
      partnerCode: partnerCode,
      requestId: requestId,
      orderId: orderId,
      signature: signature,
      lang: "vi",
    };

    console.log("\n📤 Query Body to MoMo:");
    console.log(JSON.stringify(queryBody, null, 2));

    const momoQueryUrl =
      process.env.MOMO_QUERY_URL ||
      "https://test-payment.momo.vn/v2/gateway/api/query";

    const response = await axios.post(momoQueryUrl, queryBody, {
      headers: {
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });

    console.log("\n📥 Query Response from MoMo:");
    console.log("Status:", response.status);
    console.log("Data:", JSON.stringify(response.data, null, 2));

    const momoResponse = response.data;

    // Xử lý trạng thái thanh toán
    let status = "pending";
    let message = "Đang chờ thanh toán";

    if (momoResponse.resultCode === 0) {
      status = "success";
      message = "Thanh toán thành công";
    } else if (momoResponse.resultCode === 1006) {
      status = "pending";
      message = "Giao dịch đang được xử lý";
    } else if (momoResponse.resultCode === 49) {
      status = "expired";
      message = "Giao dịch đã hết hạn";
    } else {
      status = "failed";
      message = momoResponse.message || "Giao dịch thất bại";
    }

    res.json({
      orderId: orderId,
      status: status,
      message: message,
      isSuccess: status === "success",
      isFailed: status === "failed",
      isExpired: status === "expired",
      isPending: status === "pending",
      resultCode: momoResponse.resultCode,
      transId: momoResponse.transId,
      amount: momoResponse.amount,
      ...momoResponse,
    });
  } catch (error) {
    console.error("❌ Error checking payment status:", error.message);

    res.status(500).json({
      orderId: req.params.orderId,
      status: "error",
      message: "Không thể kiểm tra trạng thái thanh toán",
      isSuccess: false,
      isFailed: true,
      isExpired: false,
      isPending: false,
      error: error.message,
    });
  }
});

/**
 * Endpoint nhận callback từ MoMo
 */
app.post("/momo/callback", (req, res) => {
  try {
    console.log("\n📨 MoMo Callback Received:");
    console.log("Headers:", JSON.stringify(req.headers, null, 2));
    console.log("Body:", JSON.stringify(req.body, null, 2));

    const callback = req.body;

    // Xác thực signature callback
    const secretKey = process.env.MOMO_SECRET_KEY;
    const rawSignature = `accessKey=${callback.accessKey}&amount=${callback.amount}&extraData=${callback.extraData}&message=${callback.message}&orderId=${callback.orderId}&orderInfo=${callback.orderInfo}&orderType=${callback.orderType}&partnerCode=${callback.partnerCode}&payType=${callback.payType}&requestId=${callback.requestId}&responseTime=${callback.responseTime}&resultCode=${callback.resultCode}&transId=${callback.transId}`;

    const expectedSignature = generateSignature(rawSignature, secretKey);

    if (callback.signature !== expectedSignature) {
      console.log("❌ Invalid callback signature");
      return res.status(400).json({ message: "Invalid signature" });
    }

    console.log("✅ Callback signature verified");

    // Xử lý callback logic tại đây
    if (callback.resultCode === 0) {
      console.log(`✅ Payment success for orderId: ${callback.orderId}`);
    } else {
      console.log(
        `❌ Payment failed for orderId: ${callback.orderId}, reason: ${callback.message}`
      );
    }

    // Trả về status code 204 cho MoMo
    res.status(204).send();
  } catch (error) {
    console.error("❌ Error processing callback:", error.message);
    res.status(500).json({ message: "Internal server error" });
  }
});

/**
 * Health check endpoint
 */
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || "development",
  });
});

/**
 * Endpoint hiển thị thông tin server
 */
app.get("/", (req, res) => {
  res.json({
    name: "MoMo Payment Production Server",
    version: "1.0.0",
    status: "running",
    endpoints: {
      createPayment: "POST /createPayment",
      paymentStatus: "GET /paymentStatus/:orderId",
      momoCallback: "POST /momo/callback",
      health: "GET /health",
    },
    environment: process.env.NODE_ENV || "development",
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("❌ Unhandled error:", err);
  res.status(500).json({
    success: false,
    error: "Internal server error",
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: "Endpoint not found",
  });
});

// Start server
app.listen(PORT, () => {
  console.log("\n🚀 Production MoMo Server Started Successfully!");
  console.log("=====================================");
  console.log(`📡 Server: http://localhost:${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`🔑 Partner Code: ${process.env.MOMO_PARTNER_CODE || "NOT_SET"}`);
  console.log("=====================================");
  console.log("📱 Endpoints:");
  console.log(`   POST /createPayment - Tạo thanh toán`);
  console.log(`   GET  /paymentStatus/:orderId - Kiểm tra trạng thái`);
  console.log(`   POST /momo/callback - Nhận callback từ MoMo`);
  console.log(`   GET  /health - Health check`);
  console.log("=====================================\n");
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("🔄 SIGTERM received, shutting down gracefully...");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("🔄 SIGINT received, shutting down gracefully...");
  process.exit(0);
});

module.exports = app;
