#!/usr/bin/env node

// Quick test script for iPhone MoMo UAT deep link compatibility
const fetch = require("node-fetch").default || require("node-fetch");

async function testIPhoneMoMoFormats() {
  console.log("🧪 Testing iPhone MoMo UAT QR Code Formats...\n");

  const formats = ["iphone_deeplink", "basic_deeplink", "payment_code", "web"];

  for (let format of formats) {
    console.log(`📱 Testing format: ${format}`);

    try {
      const orderId = `TEST_${format}_${Date.now()}`;

      // Set environment variable for this test
      process.env.MOMO_QR_FORMAT = format;

      const response = await fetch(
        "http://localhost:3003/api/momo/create-payment",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            orderId: orderId,
            amount: 10000,
            orderInfo: `Test iPhone Format: ${format}`,
          }),
        }
      );

      if (response.ok) {
        const data = await response.json();
        console.log(`   ✅ Success: ${format}`);
        console.log(`   📄 QR Data: ${data.deepLink?.substring(0, 80)}...`);
        console.log(`   💰 Amount: ${data.amount} VND`);

        // Analyze format compatibility
        if (data.deepLink?.startsWith("momo://")) {
          console.log(`   📱 iPhone Compatible: YES (Deep Link)`);
        } else if (data.deepLink?.startsWith("https://")) {
          console.log(`   📱 iPhone Compatible: MAYBE (Requires network)`);
        } else {
          console.log(`   📱 iPhone Compatible: UNKNOWN`);
        }
      } else {
        console.log(`   ❌ Failed: ${format} - ${response.status}`);
      }
    } catch (error) {
      console.log(`   ❌ Error: ${format} - ${error.message}`);
    }

    console.log("   ─────────────────────────────");
  }

  console.log("\n🎯 Recommendation for iPhone MoMo UAT:");
  console.log('   1️⃣ Use "iphone_deeplink" format (momo://transfer)');
  console.log('   2️⃣ Fallback to "basic_deeplink" (momo://app)');
  console.log('   3️⃣ Avoid "web" format (causes network errors)');
  console.log('\n💡 To switch format: $env:MOMO_QR_FORMAT="iphone_deeplink"');
}

// Only run if called directly
if (require.main === module) {
  testIPhoneMoMoFormats().catch(console.error);
}

module.exports = { testIPhoneMoMoFormats };
