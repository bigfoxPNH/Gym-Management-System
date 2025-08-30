const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const QRCode = require("qrcode");
const { v4: uuidv4 } = require("uuid");

const app = express();
const port = 3003;

// Store payment status in memory (for demo)
const paymentStore = new Map();

// Store QR expiration timers
const qrTimers = new Map();

// Store WebSocket connections for real-time updates
const activeConnections = new Map();

app.use(cors());
app.use(express.json());
app.use(express.static("public"));

// MoMo configuration (read from environment variables when available)
const MOMO_CONFIG = {
  partnerCode: process.env.MOMO_PARTNER_CODE || "MOMO0HGO20220721",
  accessKey: process.env.MOMO_ACCESS_KEY || "mTCKt9W3eU1m39TW",
  secretKey: process.env.MOMO_SECRET_KEY || "SuqieLSjmfxOEFhKdPJrQOvjaglzrNzP",
  endpoint:
    process.env.MOMO_ENDPOINT ||
    "https://test-payment.momo.vn/v2/gateway/api/create",
};

// Get local IP address for LAN access
function getLocalIP() {
  const { networkInterfaces } = require("os");
  const nets = networkInterfaces();

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Skip over non-IPv4 and internal (i.e. 127.0.0.1) addresses
      if (net.family === "IPv4" && !net.internal) {
        // Prefer 192.168.x.x range
        if (net.address.startsWith("192.168.")) {
          return net.address;
        }
      }
    }
  }
  return "192.168.1.14"; // fallback
}

// Backend configuration - use local IP but need public access for MoMo callback
// For UAT: Configure port forwarding or use ngrok
const BACKEND_DOMAIN = process.env.BACKEND_DOMAIN || `https://${getLocalIP()}.ngrok.io`; // Ensure ngrok domain is used
const FRONTEND_URL = process.env.FRONTEND_URL || `https://${getLocalIP()}.ngrok.io`; // Ensure ngrok domain is used

console.log(`🚨 IMPORTANT: MoMo UAT needs public access to callback URL`);
console.log(`📞 IPN URL: ${BACKEND_DOMAIN}/payment/ipn`);
console.log(`🔄 Redirect URL: ${FRONTEND_URL}/#/payment-callback`);
console.log(`💡 For UAT testing, consider using ngrok: 'ngrok http 3003'`);

console.log(`🌐 Backend domain: ${BACKEND_DOMAIN}`);
console.log(`🌐 Frontend URL: ${FRONTEND_URL}`);

// Demo mode but create MoMo UAT compatible QR codes
let DEMO_MODE = true;
console.log("🎭 DEMO_MODE: Creating UAT-compatible QR codes for testing");
console.log("📝 Note: For real MoMo UAT, set these environment variables:");
console.log(`📋 MOMO_PARTNER_CODE=<your_partner_code>`);
console.log(`📋 MOMO_ACCESS_KEY=<your_access_key>`);
console.log(`📋 MOMO_SECRET_KEY=<your_secret_key>`);
console.log(`📋 Then set DEMO_MODE=false`);

console.log(`ℹ️ DEMO_MODE=${DEMO_MODE}`);
console.log(`ℹ️ BACKEND_DOMAIN=${BACKEND_DOMAIN}`);
console.log(`ℹ️ FRONTEND_URL=${FRONTEND_URL}`);

// Generate MoMo signature
function generateSignature(rawSignature) {
  return crypto
    .createHmac("sha256", MOMO_CONFIG.secretKey)
    .update(rawSignature)
    .digest("hex");
}

// Create MoMo payment
app.post("/api/momo/create-payment", async (req, res) => {
  try {
    const { orderId, amount, orderInfo } = req.body;

    console.log("🔄 Creating MoMo payment:", { orderId, amount, orderInfo });

    const requestId = uuidv4();
    const extraData = "";
    const requestType = "captureWallet";

    // Use ngrok domain for callback URLs
    const redirectUrl = `${BACKEND_DOMAIN}/momo/callback`;
    const ipnUrl = `${BACKEND_DOMAIN}/momo/callback`;

    // Generate raw signature
    const rawSignature = [
      `accessKey=${MOMO_CONFIG.accessKey}`,
      `amount=${amount}`,
      `extraData=${extraData}`,
      `ipnUrl=${ipnUrl}`,
      `orderId=${orderId}`,
      `orderInfo=${orderInfo}`,
      `partnerCode=${MOMO_CONFIG.partnerCode}`,
      `redirectUrl=${redirectUrl}`,
      `requestId=${requestId}`,
      `requestType=${requestType}`,
    ].join("&");

    const signature = generateSignature(rawSignature);

    const requestBody = {
      partnerCode: MOMO_CONFIG.partnerCode,
      accessKey: MOMO_CONFIG.accessKey,
      requestId,
      amount: amount.toString(),
      orderId,
      orderInfo,
      redirectUrl,
      ipnUrl,
      requestType,
      extraData,
      signature,
    };

    console.log("📨 MoMo request body:", requestBody);

    const response = await fetch(MOMO_CONFIG.endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
    });

    const responseData = await response.json();
    console.log("📥 MoMo response:", responseData);

    if (responseData.resultCode !== 0) {
      console.error("❌ MoMo API error:", responseData);
      return res.status(400).json({ error: responseData.message });
    }

    res.status(200).json(responseData);
  } catch (error) {
    console.error("❌ Error creating MoMo payment:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Add route to create MoMo payment
app.post("/momo/pay", async (req, res) => {
  try {
    const { orderId, amount, orderInfo } = req.body;

    const requestId = uuidv4();
    const extraData = "";
    const requestType = "captureWallet";

    const redirectUrl = `${BACKEND_DOMAIN}/momo/callback`;
    const ipnUrl = `${BACKEND_DOMAIN}/momo/callback`;

    const rawSignature = [
      `accessKey=${MOMO_CONFIG.accessKey}`,
      `amount=${amount}`,
      `extraData=${extraData}`,
      `ipnUrl=${ipnUrl}`,
      `orderId=${orderId}`,
      `orderInfo=${orderInfo}`,
      `partnerCode=${MOMO_CONFIG.partnerCode}`,
      `redirectUrl=${redirectUrl}`,
      `requestId=${requestId}`,
      `requestType=${requestType}`,
    ].join("&");

    const signature = generateSignature(rawSignature);

    const requestBody = {
      partnerCode: MOMO_CONFIG.partnerCode,
      accessKey: MOMO_CONFIG.accessKey,
      requestId,
      amount: amount.toString(),
      orderId,
      orderInfo,
      redirectUrl,
      ipnUrl,
      requestType,
      extraData,
      signature,
    };

    const response = await fetch(MOMO_CONFIG.endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();
    res.status(200).json(data);
  } catch (error) {
    console.error("Error creating MoMo payment:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Add route to handle MoMo callback
app.post("/momo/callback", (req, res) => {
  try {
    const {
      partnerCode,
      orderId,
      requestId,
      amount,
      orderInfo,
      orderType,
      transId,
      resultCode,
      message,
      payType,
      responseTime,
      extraData,
      signature,
    } = req.body;

    const rawSignature = [
      `accessKey=${MOMO_CONFIG.accessKey}`,
      `amount=${amount}`,
      `extraData=${extraData}`,
      `message=${message}`,
      `orderId=${orderId}`,
      `orderInfo=${orderInfo}`,
      `orderType=${orderType}`,
      `partnerCode=${partnerCode}`,
      `payType=${payType}`,
      `requestId=${requestId}`,
      `responseTime=${responseTime}`,
      `resultCode=${resultCode}`,
      `transId=${transId}`,
    ].join("&");

    const expectedSignature = generateSignature(rawSignature);

    if (signature !== expectedSignature) {
      console.error("Invalid signature:", { signature, expectedSignature });
      return res.status(400).json({ error: "Invalid signature" });
    }

    console.log("Payment callback received:", req.body);
    paymentStore.set(orderId, {
      status: resultCode === 0 ? "success" : "failure",
      transId,
    });

    res.status(200).send("OK");
  } catch (error) {
    console.error("Error handling MoMo callback:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Check payment status
app.get("/api/momo/payment-status/:orderId", (req, res) => {
  const { orderId } = req.params;

  const payment = paymentStore.get(orderId);

  if (payment) {
    console.log(`📋 Payment status for ${orderId}:`, payment.status);

    // Check if payment is expired
    const isExpired =
      payment.isExpired ||
      (payment.expiresAt && new Date() > new Date(payment.expiresAt));

    res.json({
      success: true,
      orderId: orderId,
      status: isExpired ? "expired" : payment.status,
      amount: payment.amount,
      orderInfo: payment.orderInfo,
      createdAt: payment.createdAt,
      completedAt: payment.completedAt,
      expiresAt: payment.expiresAt,
      isExpired: isExpired,
      timeRemaining: isExpired
        ? 0
        : Math.max(0, new Date(payment.expiresAt).getTime() - Date.now()),
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Payment not found",
    });
  }
});

// Generate QR code (base64)
app.get("/api/momo/qr-code", async (req, res) => {
  try {
    const { payUrl } = req.query;

    if (!payUrl) {
      return res.status(400).json({ error: "payUrl is required" });
    }

    // Generate QR code as base64
    const qrCodeBuffer = await QRCode.toBuffer(payUrl, {
      type: "png",
      quality: 0.92,
      margin: 1,
      color: {
        dark: "#000000",
        light: "#FFFFFF",
      },
      width: 220,
    });

    const base64QR = qrCodeBuffer.toString("base64");

    res.json({
      success: true,
      qrCodeBase64: base64QR,
    });
  } catch (error) {
    console.error("❌ Error generating QR code:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Payment callback (for web redirect)
app.get("/payment/callback", (req, res) => {
  const { orderId, resultCode } = req.query;

  console.log("🔄 Payment callback:", { orderId, resultCode });

  if (paymentStore.has(orderId)) {
    const status = resultCode === "0" ? "success" : "failed";
    paymentStore.set(orderId, {
      ...paymentStore.get(orderId),
      status: status,
      completedAt: new Date(),
    });
  }

  // Redirect to frontend payment result page
  const redirectUrl = `${FRONTEND_URL}/#/payment-result?orderId=${orderId}&status=${
    resultCode === "0" ? "success" : "failed"
  }`;
  console.log("🔗 Redirecting user to:", redirectUrl);
  res.redirect(redirectUrl);
});

// Payment IPN (webhook from MoMo)
app.post("/payment/ipn", (req, res) => {
  console.log("📨 MoMo IPN received:", JSON.stringify(req.body));

  const { orderId, resultCode } = req.body;

  if (paymentStore.has(orderId)) {
    const status = resultCode === 0 ? "success" : "failed";
    paymentStore.set(orderId, {
      ...paymentStore.get(orderId),
      status: status,
      completedAt: new Date(),
    });

    console.log(`✅ Payment ${orderId} updated to ${status}`);
  }

  res.status(200).json({ success: true });
});

// Manual success for testing (simulate QR code scan)
app.post("/api/momo/manual-success/:orderId", (req, res) => {
  const { orderId } = req.params;

  if (paymentStore.has(orderId)) {
    const payment = paymentStore.get(orderId);

    // Check if payment is still valid (not expired)
    if (payment.isExpired || new Date() > new Date(payment.expiresAt)) {
      return res.status(400).json({
        success: false,
        message: "Mã QR đã hết hạn. Không thể thanh toán.",
        status: "expired",
      });
    }

    // Clear expiration timer
    if (qrTimers.has(orderId)) {
      clearTimeout(qrTimers.get(orderId));
      qrTimers.delete(orderId);
    }

    // Update payment status
    paymentStore.set(orderId, {
      ...payment,
      status: "success",
      completedAt: new Date(),
    });

    console.log(`✅ Payment completed via QR scan: ${orderId}`);

    // Broadcast real-time update to connected clients
    broadcastPaymentUpdate(orderId, {
      status: "success",
      message: "Thanh toán thành công!",
      completedAt: new Date().toISOString(),
    });

    res.json({
      success: true,
      message: "Payment completed successfully",
      status: "success",
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Payment not found",
    });
  }
});

// Broadcast payment updates to all connected clients
function broadcastPaymentUpdate(orderId, updateData) {
  // In a real app, this would use WebSocket or Server-Sent Events
  // For now, we'll just log the update
  console.log(`📡 Broadcasting payment update for ${orderId}:`, updateData);
}

// Serve MoMo payment page
app.get("/payment", (req, res) => {
  res.sendFile(__dirname + "/public/momo-payment.html");
});

// Get all payments (for debugging)
app.get("/api/momo/payments", (req, res) => {
  const payments = Array.from(paymentStore.entries()).map(
    ([orderId, payment]) => ({
      orderId,
      ...payment,
    })
  );

  res.json({ payments });
});

// Special endpoint for iPhone MoMo UAT - accepts payment completion without network callback
app.post("/api/momo/complete-offline/:orderId", (req, res) => {
  const { orderId } = req.params;
  const { transactionId, amount } = req.body;

  const payment = paymentStore.get(orderId);

  if (payment) {
    // Update payment status as completed
    paymentStore.set(orderId, {
      ...payment,
      status: "success",
      completedAt: new Date(),
      transactionId: transactionId || `OFFLINE_${Date.now()}`,
      completedVia: "iPhone_UAT_Offline",
    });

    console.log(`✅ iPhone UAT Payment completed offline: ${orderId}`);

    // Broadcast update
    broadcastPaymentUpdate(orderId, {
      status: "success",
      message: "Thanh toán thành công (iPhone UAT)!",
      completedAt: new Date().toISOString(),
      method: "iPhone_UAT_Offline",
    });

    res.json({
      success: true,
      message: "Payment completed via iPhone UAT",
      orderId: orderId,
      status: "success",
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Payment not found",
    });
  }
});

app.listen(port, () => {
  console.log(`🚀 MoMo Proxy Server running on http://localhost:${port}`);
  console.log(`📱 Ready to process MoMo payments`);
  // Log presence of credentials (masked) to help debugging
  const hasCreds = !!(
    process.env.MOMO_PARTNER_CODE &&
    process.env.MOMO_ACCESS_KEY &&
    process.env.MOMO_SECRET_KEY
  );
  console.log(`🔐 MoMo credentials provided via env: ${hasCreds}`);
  if (!hasCreds) {
    console.log(
      "👉 To test with real MoMo sandbox, set the following env vars before starting server:"
    );
    console.log("   - MOMO_PARTNER_CODE, MOMO_ACCESS_KEY, MOMO_SECRET_KEY");
    console.log(
      '   Example (powershell): $env:MOMO_PARTNER_CODE="PARTNER"; $env:MOMO_ACCESS_KEY="KEY"; $env:MOMO_SECRET_KEY="SECRET"; node momo-proxy-server.js'
    );
  }
});
