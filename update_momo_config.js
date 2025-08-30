// Script tự động chạy ngrok, lấy domain và update vào config momo

const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");
const http = require("http");

const NGROK_PATH = path.resolve(__dirname, "ngrok.exe");
const MOMO_CONFIG_PATH = path.resolve(__dirname, "lib/config/momo_config.dart");
const LOCAL_PORT = 8080; // chỉnh lại nếu backend chạy port khác

function runNgrokBackground() {
  return new Promise((resolve, reject) => {
    const ngrok = spawn(NGROK_PATH, ["http", LOCAL_PORT], {
      detached: true,
      stdio: "ignore",
    });
    ngrok.unref();
    // Đợi ngrok khởi động xong
    setTimeout(resolve, 2000); // chờ 2s
  });
}

function getNgrokDomain() {
  return new Promise((resolve, reject) => {
    http
      .get("http://127.0.0.1:4040/api/tunnels", (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            const obj = JSON.parse(data);
            const tunnel = obj.tunnels.find((t) => t.proto === "https");
            if (tunnel && tunnel.public_url) {
              resolve(tunnel.public_url);
            } else {
              reject("Không tìm thấy domain ngrok");
            }
          } catch (e) {
            reject("Lỗi parse ngrok api: " + e);
          }
        });
      })
      .on("error", reject);
  });
}

function updateMomoConfig(domain) {
  let content = fs.readFileSync(MOMO_CONFIG_PATH, "utf8");
  // Giả sử có dòng: const String momoDomain = '...';
  content = content.replace(
    /const String momoDomain = '.*';/,
    `const String momoDomain = '${domain}';`
  );
  fs.writeFileSync(MOMO_CONFIG_PATH, content, "utf8");
  console.log("Đã cập nhật domain vào momo_config.dart:", domain);
}

(async () => {
  try {
    console.log("Đang chạy ngrok...");
    await runNgrokBackground();
    // Đợi ngrok khởi động và có domain
    let domain = null;
    for (let i = 0; i < 10; i++) {
      try {
        domain = await getNgrokDomain();
        break;
      } catch (e) {
        await new Promise((r) => setTimeout(r, 1000));
      }
    }
    if (!domain) throw "Không lấy được domain ngrok";
    console.log("Domain ngrok:", domain);
    updateMomoConfig(domain);
  } catch (err) {
    console.error("Lỗi:", err);
  }
})();
