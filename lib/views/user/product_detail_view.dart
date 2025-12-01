import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../controllers/shopping_cart_controller.dart';

class ProductDetailView extends StatefulWidget {
  final Product product;

  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final ShoppingCartController _cartController;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize or get existing ShoppingCartController
    _cartController = Get.put(ShoppingCartController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final itemCount = _cartController.totalItems;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: () => Get.toNamed('/user/cart'),
                ),
                if (itemCount > 0)
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
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
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
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  _buildImageCarousel(),

                  // Product info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Manufacturer
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.manufacturer,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price section
                        _buildPriceSection(),
                        const SizedBox(height: 16),

                        // Stock status
                        _buildStockStatus(),
                        const SizedBox(height: 24),

                        // Divider
                        const Divider(),
                        const SizedBox(height: 16),

                        // Description
                        const Text(
                          'Mô tả sản phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category
                        _buildInfoRow('Danh mục', widget.product.category),
                        const SizedBox(height: 8),

                        // Status
                        _buildInfoRow('Trạng thái', _getStatusText()),

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom bar with quantity and add to cart
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.product.images;

    if (images.isEmpty) {
      return Container(
        height: 400,
        color: Colors.grey[100],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                color: Colors.grey[50],
                child: images[index].startsWith('data:image')
                    ? Image.memory(
                        base64Decode(images[index].split(',')[1]),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? const Color(0xFFE91E63)
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.product.discount > 0) ...[
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(widget.product.price)}đ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(widget.product.finalPrice)}đ',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                    if (widget.product.discount > 0) ...[
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
                          '-${widget.product.discount.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatus() {
    final isInStock = widget.product.stockQuantity > 0;
    final isLowStock =
        widget.product.stockQuantity > 0 && widget.product.stockQuantity <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isInStock
            ? (isLowStock ? Colors.orange[50] : Colors.green[50])
            : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInStock
              ? (isLowStock ? Colors.orange[300]! : Colors.green[300]!)
              : Colors.red[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInStock ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: isInStock
                ? (isLowStock ? Colors.orange : Colors.green)
                : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isInStock
                ? (isLowStock
                      ? 'Sắp hết hàng: ${widget.product.stockQuantity} sản phẩm'
                      : 'Còn hàng: ${widget.product.stockQuantity} sản phẩm')
                : 'Hết hàng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isInStock
                  ? (isLowStock ? Colors.orange[800] : Colors.green[800])
                  : Colors.red[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isInStock = widget.product.stockQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Quantity selector
              if (isInStock) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        color: Colors.black87,
                        iconSize: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _quantity.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _quantity < widget.product.stockQuantity
                            ? () {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add),
                        color: Colors.black87,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Add to cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isInStock
                      ? () async {
                          await _cartController.addToCart(
                            widget.product,
                            quantity: _quantity,
                          );

                          if (mounted) {
                            Get.snackbar(
                              'Thành công',
                              'Đã thêm $_quantity sản phẩm vào giỏ hàng',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                              margin: const EdgeInsets.all(16),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    isInStock ? 'Thêm vào giỏ hàng' : 'Hết hàng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (widget.product.status) {
      case ProductStatus.inStock:
        return 'Còn hàng';
      case ProductStatus.lowStock:
        return 'Sắp hết';
      case ProductStatus.outOfStock:
        return 'Hết hàng';
    }
  }
}
