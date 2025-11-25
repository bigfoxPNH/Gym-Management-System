import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';

class ProductManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final products = <Product>[].obs;
  final filteredProducts = <Product>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'Tất cả'.obs;
  final selectedStatus = Rx<ProductStatus?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      products.value = snapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      filterProducts();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách sản phẩm: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterProducts() {
    var result = products.toList();

    // Filter by category
    if (selectedCategory.value != 'Tất cả') {
      result = result
          .where((product) => product.category == selectedCategory.value)
          .toList();
    }

    // Filter by status
    if (selectedStatus.value != null) {
      result = result
          .where((product) => product.status == selectedStatus.value)
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.manufacturer.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }).toList();
    }

    filteredProducts.value = result;
  }

  Future<void> addProduct(Product product) async {
    try {
      isLoading.value = true;
      print('ProductController: Bắt đầu thêm sản phẩm...');
      print('ProductController: Tên sản phẩm: ${product.name}');
      print('ProductController: Số ảnh: ${product.images.length}');

      final productJson = product.toJson();
      productJson['createdAt'] = FieldValue.serverTimestamp();
      productJson['updatedAt'] = FieldValue.serverTimestamp();
      print('ProductController: JSON: $productJson');

      final docRef = await _firestore.collection('products').add(productJson);
      print('ProductController: Đã tạo document với ID: ${docRef.id}');

      final newProduct = product.copyWith(id: docRef.id);
      products.insert(0, newProduct);
      filterProducts();

      print('ProductController: Thành công! Tổng sản phẩm: ${products.length}');
      Get.back();
      Get.snackbar(
        'Thành công',
        'Đã thêm sản phẩm mới',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      print('ProductController: LỖI khi thêm sản phẩm: $e');
      print('ProductController: Stack trace: $stackTrace');
      Get.snackbar(
        'Lỗi',
        'Không thể thêm sản phẩm: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      isLoading.value = true;

      final productJson = product.toJson();
      productJson['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(productJson);

      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product;
        filterProducts();
      }

      Get.back();
      Get.snackbar('Thành công', 'Đã cập nhật sản phẩm');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật sản phẩm: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('products').doc(productId).delete();

      products.removeWhere((p) => p.id == productId);
      filterProducts();

      Get.snackbar('Thành công', 'Đã xóa sản phẩm');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa sản phẩm: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProductStatus(
    String productId,
    ProductStatus status,
  ) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': status.value,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        filterProducts();
      }

      Get.snackbar('Thành công', 'Đã cập nhật trạng thái sản phẩm');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái: $e');
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    filterProducts();
  }

  void setSelectedCategory(String category) {
    selectedCategory.value = category;
    selectedStatus.value = null; // Reset status filter
    filterProducts();
  }

  void setSelectedStatus(ProductStatus? status) {
    selectedStatus.value = status;
    selectedCategory.value = 'Tất cả'; // Reset category filter
    filterProducts();
  }

  List<String> get categories => ['Tất cả', ...ProductCategory.all];

  int getTotalStockValue() {
    return products.fold(
      0,
      (sum, product) =>
          sum + (product.sellingPrice * product.stockQuantity).toInt(),
    );
  }

  int getInStockCount() {
    return products
        .where((product) => product.status == ProductStatus.inStock)
        .length;
  }

  int getLowStockCount() {
    return products
        .where((product) => product.status == ProductStatus.lowStock)
        .length;
  }

  int getOutOfStockCount() {
    return products
        .where((product) => product.status == ProductStatus.outOfStock)
        .length;
  }
}
