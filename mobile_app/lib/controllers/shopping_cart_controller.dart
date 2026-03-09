import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:gympro/models/cart_item.dart';
import 'package:gympro/models/product.dart';

class ShoppingCartController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final cartItems = <CartItem>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // Load cart from Firestore
  // Use simple query to get all cart items for current user
  Future<void> loadCart() async {
    if (currentUserId == null) return;

    try {
      isLoading.value = true;

      // Get ALL carts and filter in memory (Firebase free tier friendly)
      final snapshot = await _firestore.collection('carts').get();

      final items = <CartItem>[];

      for (var doc in snapshot.docs) {
        // Check if document ID starts with current userId
        if (doc.id.startsWith('${currentUserId}_')) {
          final cartItem = CartItem.fromMap(doc.data(), doc.id);

          // Load product details
          final productDoc = await _firestore
              .collection('products')
              .doc(cartItem.productId)
              .get();

          if (productDoc.exists) {
            final product = Product.fromMap(productDoc.data()!, productDoc.id);
            items.add(cartItem.copyWith(product: product));
          }
        }
      }

      cartItems.value = items;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải giỏ hàng: $e');
      print('Error loading cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Add item to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (currentUserId == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập để thêm vào giỏ hàng');
      return;
    }

    try {
      isLoading.value = true;

      // Simple approach: Just add to cart, let Firestore handle duplicates
      // We'll use a composite key format for document ID
      final cartDocId = '${currentUserId}_${product.id}';
      final cartRef = _firestore.collection('carts').doc(cartDocId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Update quantity
        final currentQuantity = cartDoc.data()?['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQuantity + quantity});
        Get.snackbar('Thành công', 'Đã cập nhật số lượng trong giỏ hàng');
      } else {
        // Add new item
        await cartRef.set({
          'userId': currentUserId,
          'productId': product.id,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
        Get.snackbar('Thành công', 'Đã thêm sản phẩm vào giỏ hàng');
      }

      await loadCart();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm vào giỏ hàng: $e');
      print('Error adding to cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      await _firestore.collection('carts').doc(cartItemId).update({
        'quantity': quantity,
      });

      await loadCart();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật số lượng: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _firestore.collection('carts').doc(cartItemId).delete();
      await loadCart();
      Get.snackbar('Thành công', 'Đã xóa sản phẩm khỏi giỏ hàng');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa sản phẩm: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    if (currentUserId == null) return;

    try {
      // Get ALL carts and filter by document ID pattern
      final snapshot = await _firestore.collection('carts').get();

      for (var doc in snapshot.docs) {
        // Only delete items belonging to current user
        if (doc.id.startsWith('${currentUserId}_')) {
          await doc.reference.delete();
        }
      }

      cartItems.clear();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa giỏ hàng: $e');
    }
  }

  // Calculate totals
  double get subtotal {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Calculate shipping fee based on city
  double calculateShippingFee(String city) {
    // Simple shipping fee calculation
    final normalizedCity = city.toLowerCase().trim();

    if (normalizedCity.contains('hà nội') ||
        normalizedCity.contains('tp hồ chí minh') ||
        normalizedCity.contains('hồ chí minh') ||
        normalizedCity.contains('đà nẵng')) {
      return 30000; // 30k for major cities
    } else {
      return 50000; // 50k for other provinces
    }
  }
}
