import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../services/production_momo_service.dart';
import '../../widgets/loading_overlay.dart';

class MoMoPaymentView extends StatefulWidget {
  final String orderId;
  final int amount;
  final String orderInfo;

  const MoMoPaymentView({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderInfo,
  });

  @override
  State<MoMoPaymentView> createState() => _MoMoPaymentViewState();
}

class _MoMoPaymentViewState extends State<MoMoPaymentView> {
  final ProductionMoMoService _momoService = ProductionMoMoService();

  PaymentResponse? _paymentResult;
  PaymentStatus? _currentStatus;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<PaymentStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _momoService.stopPolling();
    super.dispose();
  }

  Future<void> _createPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _momoService.createPayment(
        orderId: widget.orderId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
      );

      setState(() {
        _paymentResult = result;
        _isLoading = false;
        if (!result.success) {
          _errorMessage = result.error;
        }
      });

      if (result.success) {
        _startStatusPolling();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tạo thanh toán: $e';
      });
    }
  }

  void _startStatusPolling() {
    _statusSubscription = _momoService.pollPaymentStatus(widget.orderId).listen(
      (status) {
        setState(() {
          _currentStatus = status;
        });

        if (status.isSuccess || status.isFailed || status.isExpired) {
          _showPaymentResult(status);
        }
      },
    );
  }

  void _showPaymentResult(PaymentStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          status.isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.isSuccess ? Icons.check_circle : Icons.error,
              color: status.isSuccess ? Colors.green : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              status.isSuccess
                  ? 'Giao dịch đã được xử lý thành công!'
                  : status.message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.back(result: status);
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán MoMo'),
        backgroundColor: const Color(0xFFD82D8B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin thanh toán',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mã đơn hàng:'),
                        Text(
                          widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số tiền:'),
                        Text(
                          _formatCurrency(widget.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD82D8B),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mô tả:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.orderInfo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QR Code or Loading
            Expanded(child: _buildPaymentContent()),

            // Status indicator
            if (_currentStatus != null) _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentContent() {
    if (_isLoading) {
      return const CenterLoading(message: 'Đang tạo mã QR thanh toán...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createPayment,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_paymentResult?.payUrl != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: QrImageView(
                data: _paymentResult!.payUrl!,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sử dụng app MoMo để quét mã QR',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('Không thể tạo mã QR'));
  }

  Widget _buildStatusIndicator() {
    final status = _currentStatus!;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (status.isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Thanh toán thành công';
    } else if (status.isFailed || status.isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = status.message;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = 'Đang chờ thanh toán...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ),
          if (status.isPending) const InlineLoading(color: Color(0xFFD82D8B)),
        ],
      ),
    );
  }
}
