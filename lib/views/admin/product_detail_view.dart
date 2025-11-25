import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/product_management_controller.dart';
import '../../models/product.dart';
import '../../utils/initialize_products_collection.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({Key? key}) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProductManagementController>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _originalPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  String _selectedCategory = ProductCategory.wheyProtein;
  ProductStatus _selectedStatus = ProductStatus.inStock;
  List<String> _imageUrls = [];
  List<XFile> _newImages = []; // Changed from File to XFile
  bool _isUploading = false;

  bool isEdit = false;
  Product? existingProduct;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    isEdit = args['isEdit'] ?? false;
    existingProduct = args['product'];

    _nameController = TextEditingController(text: existingProduct?.name ?? '');
    _manufacturerController = TextEditingController(
      text: existingProduct?.manufacturer ?? '',
    );
    _originalPriceController = TextEditingController(
      text: existingProduct?.originalPrice.toStringAsFixed(0) ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: existingProduct?.sellingPrice.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: existingProduct?.stockQuantity.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: existingProduct?.description ?? '',
    );

    if (existingProduct != null) {
      _selectedCategory = existingProduct!.category;
      _selectedStatus = existingProduct!.status;
      _imageUrls = List.from(existingProduct!.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        // Check total file size (limit each image to 500KB for Firestore)
        for (var image in images) {
          final bytes = await image.readAsBytes();
          final sizeInKB = bytes.length / 1024;

          if (sizeInKB > 500) {
            Get.snackbar(
              'Cảnh báo',
              'Ảnh "${image.name}" quá lớn (${sizeInKB.toStringAsFixed(0)}KB). Vui lòng chọn ảnh nhỏ hơn 500KB.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            continue;
          }
        }

        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chọn ảnh: $e');
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];

    try {
      for (var imageFile in _newImages) {
        print('📸 Đang chuyển đổi ảnh: ${imageFile.name}');

        // Read image bytes
        final bytes = await imageFile.readAsBytes();

        // Convert to base64
        final base64String = base64Encode(bytes);
        final base64Image = 'data:image/jpeg;base64,$base64String';

        base64Images.add(base64Image);
        print('✅ Đã chuyển đổi: ${(bytes.length / 1024).toStringAsFixed(0)}KB');
      }
    } catch (e) {
      print('❌ Lỗi chuyển đổi ảnh: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xử lý ảnh: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    return base64Images;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      print('🔄 Bắt đầu lưu sản phẩm...');

      // Initialize products collection if it doesn't exist
      await initializeProductsCollection();

      // Convert new images to base64
      print('📸 Đang xử lý ${_newImages.length} ảnh mới...');
      final newBase64Images = await _convertImagesToBase64();
      final allImages = [..._imageUrls, ...newBase64Images];
      print('✅ Tổng số ảnh: ${allImages.length}');

      final product = Product(
        id: existingProduct?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        manufacturer: _manufacturerController.text.trim(),
        originalPrice: double.parse(_originalPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stockQuantity: int.parse(_stockController.text),
        description: _descriptionController.text.trim(),
        images: allImages,
        status: _selectedStatus,
        createdAt: existingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📦 Sản phẩm: ${product.name}');

      if (isEdit) {
        print('🔄 Đang cập nhật sản phẩm...');
        await controller.updateProduct(product);
      } else {
        print('➕ Đang thêm sản phẩm mới...');
        await controller.addProduct(product);
      }

      print('Lưu sản phẩm thành công!');
    } catch (e, stackTrace) {
      print('Lỗi khi lưu sản phẩm: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Lỗi',
        'Không thể lưu sản phẩm: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang lưu sản phẩm...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Images Section
                  const Text(
                    'Ảnh sản phẩm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildImageGrid(),
                  const SizedBox(height: 24),

                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Nhóm sản phẩm *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ProductCategory.all.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Manufacturer
                  TextFormField(
                    controller: _manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Hãng sản xuất *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập hãng sản xuất';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prices
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Giá gốc *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                            suffixText: '₫',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập giá gốc';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Giá không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Giá bán *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.sell),
                            suffixText: '₫',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập giá bán';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Giá không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock and Status
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng tồn kho *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập số lượng';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Số lượng không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ProductStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Trạng thái *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: ProductStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả sản phẩm',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả sản phẩm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      height: 120,
      child: Row(
        children: [
          // Add Image Button
          InkWell(
            onTap: _pickImages,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Thêm ảnh', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Image List
          Expanded(
            child: (_imageUrls.isEmpty && _newImages.isEmpty)
                ? const Center(
                    child: Text(
                      'Chưa có ảnh nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Display existing URLs
                      ..._imageUrls.map(
                        (url) => _buildImagePreview(
                          url: url,
                          onRemove: () {
                            setState(() {
                              _imageUrls.remove(url);
                            });
                          },
                        ),
                      ),
                      // Display new picked images
                      ..._newImages.map(
                        (xFile) => _buildImagePreview(
                          xFile: xFile,
                          onRemove: () {
                            setState(() {
                              _newImages.remove(xFile);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({
    String? url,
    XFile? xFile,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url != null
                ? _buildBase64OrNetworkImage(url)
                : FutureBuilder<Uint8List>(
                    future: xFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
          ),
        ),
        Positioned(
          top: 0,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Widget _buildBase64OrNetworkImage(String imageUrl) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }
    } else {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
      );
    }
  }
}
