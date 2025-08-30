import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../widgets/app_button.dart';

class PaymentTestPage extends GetView<PaymentController> {
  const PaymentTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test MoMo Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Payment Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production MoMo Integration',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextFormField(
                      controller: TextEditingController(text: '10000'),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (VND)',
                        hintText: 'Nhập số tiền cần thanh toán',
                        border: OutlineInputBorder(),
                        prefixText: '₫ ',
                      ),
                      onChanged: (value) {
                        controller.updateAmount(int.tryParse(value) ?? 10000);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Order Info Input
                    TextFormField(
                      controller: TextEditingController(
                        text: 'Test Payment GymPro',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nội dung thanh toán',
                        hintText: 'Mô tả nội dung thanh toán',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        controller.updateOrderInfo(value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Payment Button
                    Obx(
                      () => AppButton(
                        text: controller.isProcessing.value
                            ? 'Đang xử lý...'
                            : 'Thanh toán MoMo',
                        onPressed: controller.isProcessing.value
                            ? null
                            : () => controller.processPayment(),
                        backgroundColor: Colors.purple[600],
                        textColor: Colors.white,
                        icon: controller.isProcessing.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.payment, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái thanh toán',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusItem(
                            'Trạng thái:',
                            controller.paymentStatus.value.isEmpty
                                ? 'Chưa thanh toán'
                                : controller.paymentStatus.value,
                            _getStatusColor(controller.paymentStatus.value),
                          ),
                          if (controller.currentOrderId.value.isNotEmpty)
                            _buildStatusItem(
                              'Mã đơn hàng:',
                              controller.currentOrderId.value,
                              Colors.blue[700]!,
                            ),
                          if (controller.currentTransactionId.value.isNotEmpty)
                            _buildStatusItem(
                              'Mã giao dịch:',
                              controller.currentTransactionId.value,
                              Colors.green[700]!,
                            ),
                          if (controller.paymentMessage.value.isNotEmpty)
                            _buildStatusItem(
                              'Thông báo:',
                              controller.paymentMessage.value,
                              Colors.orange[700]!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hướng dẫn sử dụng',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInstructionItem(
                      '1.',
                      'Nhập số tiền và nội dung thanh toán',
                      Icons.edit,
                    ),
                    _buildInstructionItem(
                      '2.',
                      'Nhấn nút "Thanh toán MoMo" để tạo đơn hàng',
                      Icons.payment,
                    ),
                    _buildInstructionItem(
                      '3.',
                      'Quét QR code hoặc mở link trong ứng dụng MoMo',
                      Icons.qr_code,
                    ),
                    _buildInstructionItem(
                      '4.',
                      'Thực hiện thanh toán trong ứng dụng MoMo',
                      Icons.mobile_friendly,
                    ),
                    _buildInstructionItem(
                      '5.',
                      'Ứng dụng sẽ tự động quay về và hiển thị kết quả',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
    String number,
    String instruction,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'thành công':
        return Colors.green[700]!;
      case 'failed':
      case 'thất bại':
        return Colors.red[700]!;
      case 'pending':
      case 'đang xử lý':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
