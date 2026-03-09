import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:gympro/controllers/shopping_cart_controller.dart';
import 'package:gympro/controllers/order_controller.dart';
import 'package:gympro/models/order.dart' as order_model;
import 'package:gympro/models/shipping_address.dart';
import 'order_history_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final cartController = Get.find<ShoppingCartController>();
  final orderController = Get.put(OrderController());

  final noteController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressTextController = TextEditingController();
  final wardController = TextEditingController();
  final districtController = TextEditingController();
  final cityController = TextEditingController();

  order_model.PaymentMethod selectedPayment = order_model.PaymentMethod.cod;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    noteController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressTextController.dispose();
    wardController.dispose();
    districtController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Đặt hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        return _buildCheckoutContent();
      }),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text('Giỏ hàng trống'),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent() {
    final cityText = cityController.text.trim();
    final shippingFee = cityText.isNotEmpty
        ? cartController.calculateShippingFee(cityText)
        : 0.0;
    final total = cartController.subtotal + shippingFee;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAddressSection(),
              const SizedBox(height: 12),
              _buildProductsSection(),
              const SizedBox(height: 12),
              _buildPaymentSection(),
              const SizedBox(height: 12),
              _buildNoteSection(),
            ],
          ),
        ),
        _buildBottomSummary(shippingFee, total),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ giao hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Address input fields
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên người nhận *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressTextController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ chi tiết *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: wardController,
                    decoration: const InputDecoration(
                      labelText: 'Phường/Xã *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: districtController,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'Thành phố *',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                hintText: 'VD: TP Hồ Chí Minh, Hà Nội, Đà Nẵng',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm đặt hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...cartController.cartItems.map((item) {
              if (item.product == null) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product!.name} x${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(item.totalPrice)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...order_model.PaymentMethod.values.map((method) {
              return RadioListTile<order_model.PaymentMethod>(
                title: Text(method.displayName),
                value: method,
                groupValue: selectedPayment,
                onChanged: (value) {
                  setState(() {
                    selectedPayment = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Thêm ghi chú cho đơn hàng...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(double shippingFee, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:'),
                Text(
                  '${NumberFormat('#,###', 'vi_VN').format(cartController.subtotal)}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phí vận chuyển:'),
                Text(
                  '${NumberFormat('#,###', 'vi_VN').format(shippingFee)}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${NumberFormat('#,###', 'vi_VN').format(total)}đ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đặt hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    // Validate form
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập tên người nhận');
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập số điện thoại');
      return;
    }
    if (addressTextController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập địa chỉ chi tiết');
      return;
    }
    if (wardController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập phường/xã');
      return;
    }
    if (districtController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập quận/huyện');
      return;
    }
    if (cityController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập thành phố');
      return;
    }

    // Create temporary address from form
    final tempAddress = ShippingAddress(
      id: '',
      userId: '',
      recipientName: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      address: addressTextController.text.trim(),
      ward: wardController.text.trim(),
      district: districtController.text.trim(),
      city: cityController.text.trim(),
      isDefault: false,
      createdAt: DateTime.now(),
    );

    final orderId = await orderController.createOrder(
      cartItems: cartController.cartItems,
      address: tempAddress,
      paymentMethod: selectedPayment,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (orderId != null) {
      Get.off(() => const OrderHistoryView());
    }
  }
}
