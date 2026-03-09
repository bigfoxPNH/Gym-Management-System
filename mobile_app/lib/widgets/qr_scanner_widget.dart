import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRScanned;
  final String title;

  const QRScannerWidget({
    super.key,
    required this.onQRScanned,
    this.title = 'Quét QR Code',
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController controller;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
          ),
          IconButton(icon: const Icon(Icons.flash_on), onPressed: _toggleFlash),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hướng camera vào mã QR để quét',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đảm bảo mã QR nằm trong khung hình',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
          // QR Scanner
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (isScanning && capture.barcodes.isNotEmpty) {
                      final String? code = capture.barcodes.first.rawValue;
                      if (code != null) {
                        _handleScannedData(code);
                      }
                    }
                  },
                ),
                // Overlay with scanning frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
                if (!isScanning)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pause_circle_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quét đã tạm dừng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: isScanning ? Icons.pause : Icons.play_arrow,
                      label: isScanning ? 'Tạm dừng' : 'Tiếp tục',
                      onPressed: _toggleScanning,
                    ),
                    _buildActionButton(
                      icon: Icons.flash_on,
                      label: 'Đèn flash',
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isScanning ? 'Đang quét...' : 'Đã tạm dừng',
                  style: TextStyle(
                    color: isScanning ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _handleScannedData(String data) {
    // Pause scanning to prevent multiple scans
    setState(() {
      isScanning = false;
    });

    // Call the callback
    widget.onQRScanned(data);
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
    });
  }

  void _toggleFlash() {
    controller.toggleTorch();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
