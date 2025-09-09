import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/production_momo_service.dart';

class MoMoPaymentWidget extends StatefulWidget {
  final String orderId;
  final int amount;
  final String orderInfo;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;
  final VoidCallback? onCancel;

  const MoMoPaymentWidget({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderInfo,
    this.onSuccess,
    this.onFailure,
    this.onCancel,
  });

  @override
  State<MoMoPaymentWidget> createState() => _MoMoPaymentWidgetState();
}

class _MoMoPaymentWidgetState extends State<MoMoPaymentWidget> {
  final ProductionMoMoService _momoService = ProductionMoMoService();

  PaymentResponse? _paymentResponse;
  PaymentStatus? _currentStatus;
  StreamSubscription<PaymentStatus>? _statusSubscription;
  bool _isLoading = true;
  String? _error;

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
      _error = null;
    });

    try {
      final response = await _momoService.createPayment(
        orderId: widget.orderId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
      );

      if (response.success) {
        setState(() {
          _paymentResponse = response;
          _isLoading = false;
        });

        // Start polling payment status
        _startStatusPolling();
      } else {
        setState(() {
          _error = response.error ?? 'Failed to create payment';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error creating payment: $e';
        _isLoading = false;
      });
    }
  }

  void _startStatusPolling() {
    _statusSubscription = _momoService
        .pollPaymentStatus(widget.orderId)
        .listen(
          (status) {
            setState(() {
              _currentStatus = status;
            });

            // Handle final states
            if (status.isSuccess) {
              widget.onSuccess?.call();
            } else if (status.isFailed || status.isExpired) {
              widget.onFailure?.call();
            }
          },
          onError: (error) {
            print('❌ Status polling error: $error');
          },
        );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB0006D), Color(0xFFD6336C)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MoMo',
                    style: TextStyle(
                      color: Color(0xFFB0006D),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_paymentResponse != null) {
      return _buildPaymentState();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFFB0006D)),
        const SizedBox(height: 16),
        Text(
          'Đang tạo mã thanh toán...',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          'Lỗi tạo thanh toán',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB0006D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Payment info
        _buildPaymentInfo(),
        const SizedBox(height: 20),

        // Status indicator
        _buildStatusIndicator(),
        const SizedBox(height: 20),

        // QR Code
        _buildQRCode(),
        const SizedBox(height: 20),

        // Instructions
        _buildInstructions(),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số tiền:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                _formatCurrency(widget.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB0006D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mã đơn hàng:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                widget.orderId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mô tả:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.orderInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_currentStatus == null) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Đang chờ thanh toán...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
        ],
      );
    }

    Color statusColor;
    IconData statusIcon;

    if (_currentStatus!.isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_currentStatus!.isFailed || _currentStatus!.isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _currentStatus!.message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    if (_paymentResponse?.qrCodeUrl == null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('QR Code không khả dụng')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: QrImageView(
        data: _paymentResponse!.payUrl!,
        version: QrVersions.auto,
        size: 250,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          '📱 Hướng dẫn thanh toán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInstructionStep('1', 'Mở ứng dụng MoMo'),
        _buildInstructionStep('2', 'Chọn "Quét mã QR"'),
        _buildInstructionStep('3', 'Quét mã QR ở trên'),
        _buildInstructionStep('4', 'Xác nhận thanh toán'),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFB0006D),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
