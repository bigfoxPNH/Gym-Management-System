import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/product_management_controller.dart';
import '../../models/product.dart';
import '../../routes/app_routes.dart';

class ProductManagementView extends StatelessWidget {
  ProductManagementView({Key? key}) : super(key: key);

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductManagementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Sản Phẩm'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Obx(() {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Còn hàng',
                      controller.getInStockCount().toString(),
                      Icons.check_circle,
                      Colors.green,
                      onTap: () =>
                          controller.setSelectedStatus(ProductStatus.inStock),
                      isSelected:
                          controller.selectedStatus.value ==
                          ProductStatus.inStock,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sắp hết',
                      controller.getLowStockCount().toString(),
                      Icons.warning_amber,
                      Colors.orange,
                      onTap: () =>
                          controller.setSelectedStatus(ProductStatus.lowStock),
                      isSelected:
                          controller.selectedStatus.value ==
                          ProductStatus.lowStock,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Hết hàng',
                      controller.getOutOfStockCount().toString(),
                      Icons.remove_shopping_cart,
                      Colors.red,
                      onTap: () => controller.setSelectedStatus(
                        ProductStatus.outOfStock,
                      ),
                      isSelected:
                          controller.selectedStatus.value ==
                          ProductStatus.outOfStock,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Tất cả',
                      controller.products.length.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                      onTap: () => controller.setSelectedStatus(null),
                      isSelected: controller.selectedStatus.value == null,
                    ),
                  ),
                ],
              );
            }),
          ),

          // Search and Filter
          Container(
            padding: const EdgeInsets.all(12.8),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(fontSize: 12.8),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    hintStyle: const TextStyle(fontSize: 12.8),
                    prefixIcon: const Icon(Icons.search, size: 19.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.8,
                      vertical: 12.8,
                    ),
                  ),
                  onChanged: (value) => controller.setSearchQuery(value),
                ),
                const SizedBox(height: 9.6),
                Obx(() {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller.categories.map((category) {
                        final isSelected =
                            controller.selectedCategory.value == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.4),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              controller.setSelectedCategory(category);
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Colors.deepPurple.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9.6,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: TextStyle(
                              fontSize: 11.2,
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredProducts.isEmpty) {
                return Center(
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
                        'Chưa có sản phẩm nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProducts[index];
                  return _buildProductCard(product, controller, currencyFormat);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.productDetail, arguments: {'isEdit': false});
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Thêm sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25.6),
            const SizedBox(height: 6.4),
            Text(
              value,
              style: TextStyle(
                fontSize: 19.2,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9.6, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    ProductManagementController controller,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.productDetail,
            arguments: {'isEdit': true, 'product': product},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? _buildProductImage(product.images.first)
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.manufacturer,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currencyFormat.format(product.sellingPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: product.isLowStock
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Còn ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.isLowStock
                                ? Colors.orange
                                : Colors.grey[600],
                            fontWeight: product.isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              product.status,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(product.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Get.toNamed(
                      AppRoutes.productDetail,
                      arguments: {'isEdit': true, 'product': product},
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(product, controller);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.inStock:
        return Colors.green;
      case ProductStatus.outOfStock:
        return Colors.red;
      case ProductStatus.lowStock:
        return Colors.orange;
    }
  }

  Widget _buildProductImage(String imageUrl) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 40),
        );
      }
    } else {
      // Network image
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 40),
          );
        },
      );
    }
  }

  void _showDeleteDialog(
    Product product,
    ProductManagementController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
