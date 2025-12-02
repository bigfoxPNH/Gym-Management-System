import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:gympro/controllers/shopping_cart_controller.dart';
import 'package:gympro/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'product_detail_view.dart';

class UserProductListView extends StatefulWidget {
  const UserProductListView({super.key});

  @override
  State<UserProductListView> createState() => _UserProductListViewState();
}

class _UserProductListViewState extends State<UserProductListView> {
  final ShoppingCartController cartController = Get.put(
    ShoppingCartController(),
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedCategory = 'Tất cả';
  String searchQuery = '';
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => isLoading = true);

      final snapshot = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'in_stock')
          .get();

      products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();

      _filterProducts();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải sản phẩm: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        final matchesCategory =
            selectedCategory == 'Tất cả' ||
            product.category == selectedCategory;
        final matchesSearch =
            searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.manufacturer.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mua Sản Phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Cart Icon with badge
          Obx(
            () => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Get.toNamed('/user/cart'),
                ),
                if (cartController.totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartController.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Order History Icon
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Get.toNamed('/user/orders'),
            tooltip: 'Đơn hàng của tôi',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                searchQuery = value;
                _filterProducts();
              },
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Tất cả', ...Product.productCategories].map((
                category,
              ) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        _filterProducts();
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Product Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có sản phẩm',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                SizedBox(
                  height: constraints.maxHeight * 0.55,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product.images.isNotEmpty
                        ? _buildProductImage(product.images.first)
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),

                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.manufacturer,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (product.discount > 0) ...[
                          Text(
                            '${NumberFormat('#,###', 'vi_VN').format(product.originalPrice)}đ',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                        ],
                        Text(
                          '${NumberFormat('#,###', 'vi_VN').format(product.sellingPrice)}đ',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageData) {
    if (imageData.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = imageData.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      }
    } else if (imageData.startsWith('http')) {
      // Network image
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }
  }

  void _showProductDetail(Product product) {
    // Navigate to product detail page
    Get.to(
      () => ProductDetailView(product: product),
      transition: Transition.rightToLeft,
    );
  }

  void _showProductDetailOld(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Product Images Carousel
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildProductImage(product.images[index]),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Manufacturer
                    Row(
                      children: [
                        Icon(Icons.factory, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          product.manufacturer,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Price
                    Row(
                      children: [
                        if (product.discount > 0) ...[
                          Text(
                            '${product.originalPrice.toStringAsFixed(0)}đ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${product.discount.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${product.sellingPrice.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stock
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: product.stockQuantity > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.stockQuantity > 0
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: product.stockQuantity > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.stockQuantity > 0
                                ? 'Còn hàng: ${product.stockQuantity} sản phẩm'
                                : 'Hết hàng',
                            style: TextStyle(
                              color: product.stockQuantity > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Mô tả sản phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 80), // Space for button
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Reset any state if needed
    });

    // Show Add to Cart button
    _showAddToCartButton(product);
  }

  void _showAddToCartButton(Product product) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      builder: (context) => Container(
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
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: product.stockQuantity > 0
                      ? () async {
                          await cartController.addToCart(product);
                          if (context.mounted) {
                            Navigator.pop(context); // Close button sheet
                            Navigator.pop(context); // Close detail sheet
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Thêm vào giỏ hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
