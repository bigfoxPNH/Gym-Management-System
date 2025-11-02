import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/qr_checkin_service.dart';
import '../../widgets/qr_scanner_widget.dart';
import '../../widgets/loading_overlay.dart';

class CheckinCheckoutController extends GetxController {
  final isLoading = false.obs;
  final checkinRecords = <Map<String, dynamic>>[].obs;
  final searchQuery = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    loadCheckinRecords();
  }

  Future<void> loadCheckinRecords() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('check_ins')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      checkinRecords.value = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error loading checkin records: $e');
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu checkin');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkinUser(String userId, String userName) async {
    try {
      await _firestore.collection('check_ins').add({
        'userId': userId,
        'userName': userName,
        'type': 'checkin',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Thành công', '$userName đã checkin thành công');
      loadCheckinRecords();
    } catch (e) {
      print('Error checkin: $e');
      Get.snackbar('Lỗi', 'Checkin thất bại');
    }
  }

  Future<void> checkoutUser(String userId, String userName) async {
    try {
      await _firestore.collection('check_ins').add({
        'userId': userId,
        'userName': userName,
        'type': 'checkout',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Thành công', '$userName đã checkout thành công');
      loadCheckinRecords();
    } catch (e) {
      print('Error checkout: $e');
      Get.snackbar('Lỗi', 'Checkout thất bại');
    }
  }

  /// Process QR code for checkin/checkout
  Future<void> processQRCheckin(String qrData, String type) async {
    try {
      // Validate QR and get user info
      final result = await QRCheckinService.validateQRForCheckin(qrData);

      if (!result['isValid']) {
        Get.snackbar(
          'Lỗi',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final userId = result['userId'];
      final userName = result['userName'];
      final membership = result['membership'];

      // Record the checkin/checkout
      final success = await QRCheckinService.recordCheckinCheckout(
        userId: userId,
        userName: userName,
        type: type,
        membership: membership,
      );

      if (success) {
        Get.snackbar(
          'Thành công',
          '$userName đã ${type == 'checkin' ? 'check-in' : 'check-out'} thành công',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        loadCheckinRecords();
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể ghi nhận ${type == 'checkin' ? 'check-in' : 'check-out'}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error processing QR checkin: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi khi xử lý QR code: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<Map<String, dynamic>> get filteredRecords {
    if (searchQuery.value.isEmpty) return checkinRecords;

    return checkinRecords.where((record) {
      final userName = record['userName']?.toString().toLowerCase() ?? '';
      return userName.contains(searchQuery.value.toLowerCase());
    }).toList();
  }
}

class CheckinCheckoutView extends StatelessWidget {
  const CheckinCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CheckinCheckoutController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkin/Checkout'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: controller.loadCheckinRecords,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành viên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCheckinDialog(context, controller),
                    icon: const Icon(Icons.login),
                    label: const Text('Checkin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCheckoutDialog(context, controller),
                    icon: const Icon(Icons.logout),
                    label: const Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // QR Scanner buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openQRScanner(context, controller, 'checkin'),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QR Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openQRScanner(context, controller, 'checkout'),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QR Check-out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Records list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => Text(
                    '${controller.filteredRecords.length} bản ghi',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Records list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.checkinRecords.isEmpty) {
                  return const CenterLoading(
                    message: 'Đang tải lịch sử check-in...',
                  );
                }

                final records = controller.filteredRecords;

                if (records.isEmpty) {
                  return const Center(
                    child: Text('Chưa có dữ liệu checkin/checkout'),
                  );
                }

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _buildRecordCard(record);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final isCheckin = record['type'] == 'checkin';
    final timestamp = record['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Không xác định';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCheckin ? Colors.green : Colors.orange,
          child: Icon(
            isCheckin ? Icons.login : Icons.logout,
            color: Colors.white,
          ),
        ),
        title: Text(
          record['userName'] ?? 'Không xác định',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(timeStr),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCheckin ? Colors.green[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isCheckin ? 'Checkin' : 'Checkout',
            style: TextStyle(
              color: isCheckin ? Colors.green[800] : Colors.orange[800],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (recordDate == today) {
      return 'Hôm nay ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showCheckinDialog(
    BuildContext context,
    CheckinCheckoutController controller,
  ) {
    final userIdController = TextEditingController();
    final userNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: Colors.green),
            SizedBox(width: 8),
            Text('Checkin thành viên'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'ID thành viên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userNameController,
              decoration: const InputDecoration(
                labelText: 'Tên thành viên',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (userIdController.text.isNotEmpty &&
                  userNameController.text.isNotEmpty) {
                controller.checkinUser(
                  userIdController.text,
                  userNameController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Checkin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    CheckinCheckoutController controller,
  ) {
    final userIdController = TextEditingController();
    final userNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Checkout thành viên'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'ID thành viên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userNameController,
              decoration: const InputDecoration(
                labelText: 'Tên thành viên',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (userIdController.text.isNotEmpty &&
                  userNameController.text.isNotEmpty) {
                controller.checkoutUser(
                  userIdController.text,
                  userNameController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Checkout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openQRScanner(
    BuildContext context,
    CheckinCheckoutController controller,
    String type,
  ) {
    Get.to(
      () => QRScannerWidget(
        title: type == 'checkin' ? 'QR Check-in' : 'QR Check-out',
        onQRScanned: (qrData) {
          // Close scanner
          Get.back();

          // Process the QR code
          controller.processQRCheckin(qrData, type);
        },
      ),
    );
  }
}
