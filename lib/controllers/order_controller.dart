import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:gympro/models/order.dart' as order_model;
import 'package:gympro/models/shipping_address.dart';
import 'package:gympro/models/cart_item.dart';
import 'package:gympro/controllers/shopping_cart_controller.dart';
import 'dart:math';

class OrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final orders = <order_model.Order>[].obs;
  final isLoading = false.obs;
  final selectedAddress = Rx<ShippingAddress?>(null);

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  // Generate unique order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'ORD${timestamp.toString().substring(7)}$random';
  }

  // Create order from cart
  Future<String?> createOrder({
    required List<CartItem> cartItems,
    required ShippingAddress address,
    required order_model.PaymentMethod paymentMethod,
    String? note,
  }) async {
    if (currentUserId == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập');
      return null;
    }

    if (cartItems.isEmpty) {
      Get.snackbar('Lỗi', 'Giỏ hàng trống');
      return null;
    }

    try {
      isLoading.value = true;

      // Calculate totals
      double subtotal = 0;
      final orderItems = <order_model.OrderItem>[];

      for (var cartItem in cartItems) {
        if (cartItem.product != null) {
          final orderItem = order_model.OrderItem.fromProduct(
            cartItem.product!,
            cartItem.quantity,
          );
          orderItems.add(orderItem);
          subtotal += orderItem.total;
        }
      }

      final shippingController = Get.find<ShoppingCartController>();
      final shippingFee = shippingController.calculateShippingFee(address.city);
      final total = subtotal + shippingFee;

      // Create order
      final orderNumber = _generateOrderNumber();
      final orderData = {
        'userId': currentUserId,
        'orderNumber': orderNumber,
        'items': orderItems.map((item) => item.toMap()).toList(),
        'status': order_model.OrderStatus.pending.value,
        'paymentMethod': paymentMethod.value,
        'isPaid': false,
        'recipientName': address.recipientName,
        'phoneNumber': address.phoneNumber,
        'address': address.address,
        'ward': address.ward,
        'district': address.district,
        'city': address.city,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discount': 0,
        'total': total,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);

      // Update product stock quantities
      for (var item in orderItems) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        await _firestore.runTransaction((transaction) async {
          final productDoc = await transaction.get(productRef);
          if (productDoc.exists) {
            final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
            final newStock = currentStock - item.quantity;
            transaction.update(productRef, {'stockQuantity': newStock});
          }
        });
      }

      // Clear cart
      await shippingController.clearCart();

      Get.snackbar('Thành công', 'Đặt hàng thành công! Mã đơn: $orderNumber');
      await loadOrders();

      return docRef.id;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo đơn hàng: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Load user's orders
  // Firebase Free tier friendly: Get all orders, filter and sort in memory
  Future<void> loadOrders() async {
    if (currentUserId == null) return;

    try {
      isLoading.value = true;

      // Get all orders
      final snapshot = await _firestore.collection('orders').get();

      // Filter by userId and sort in memory
      final userOrders = snapshot.docs
          .where((doc) => doc.data()['userId'] == currentUserId)
          .map((doc) => order_model.Order.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending
      userOrders.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      orders.value = userOrders;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải đơn hàng: $e');
      print('Error loading orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      isLoading.value = true;

      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        Get.snackbar('Lỗi', 'Không tìm thấy đơn hàng');
        return;
      }

      final order = order_model.Order.fromMap(orderDoc.data()!, orderDoc.id);

      // Only allow cancel if order is pending or confirmed
      if (order.status != order_model.OrderStatus.pending &&
          order.status != order_model.OrderStatus.confirmed) {
        Get.snackbar(
          'Lỗi',
          'Không thể hủy đơn hàng ở trạng thái ${order.status.displayName}',
        );
        return;
      }

      // Restore product stock quantities
      for (var item in order.items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        await _firestore.runTransaction((transaction) async {
          final productDoc = await transaction.get(productRef);
          if (productDoc.exists) {
            final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
            final newStock = currentStock + item.quantity;
            transaction.update(productRef, {'stockQuantity': newStock});
          }
        });
      }

      await orderRef.update({
        'status': order_model.OrderStatus.cancelled.value,
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Thành công', 'Đã hủy đơn hàng');
      await loadOrders();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể hủy đơn hàng: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get order by ID
  Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return order_model.Order.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải thông tin đơn hàng: $e');
      return null;
    }
  }

  // Filter orders by status
  List<order_model.Order> getOrdersByStatus(order_model.OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }

  // Get statistics
  int get totalOrders => orders.length;

  int get pendingOrdersCount =>
      orders.where((o) => o.status == order_model.OrderStatus.pending).length;

  int get completedOrdersCount =>
      orders.where((o) => o.status == order_model.OrderStatus.delivered).length;

  double get totalSpent => orders
      .where((o) => o.status == order_model.OrderStatus.delivered)
      .fold(0.0, (sum, order) => sum + order.total);
}
