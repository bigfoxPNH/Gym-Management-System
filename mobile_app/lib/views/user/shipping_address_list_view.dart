import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/shipping_address_controller.dart';
import 'package:gympro/models/shipping_address.dart';

class ShippingAddressListView extends StatelessWidget {
  const ShippingAddressListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShippingAddressController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Địa chỉ giao hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _AddressFormDialog.show(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.addresses.isEmpty) {
          return _buildEmptyState(context, controller);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.addresses.length,
          itemBuilder: (context, index) {
            final address = controller.addresses[index];
            return _AddressCard(address: address, controller: controller);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ShippingAddressController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có địa chỉ giao hàng',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _AddressFormDialog.show(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Thêm địa chỉ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final ShippingAddressController controller;

  const _AddressCard({required this.address, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.phoneNumber,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              address.fullAddress,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: () => controller.setDefaultAddress(address.id),
                    child: const Text('Đặt mặc định'),
                  ),
                TextButton.icon(
                  onPressed: () => _AddressFormDialog.show(
                    context,
                    controller,
                    address: address,
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                ),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa địa chỉ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAddress(address.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddressFormDialog {
  static void show(
    BuildContext context,
    ShippingAddressController controller, {
    ShippingAddress? address,
  }) {
    final nameController = TextEditingController(text: address?.recipientName);
    final phoneController = TextEditingController(text: address?.phoneNumber);
    final addressController = TextEditingController(text: address?.address);
    final wardController = TextEditingController(text: address?.ward);
    final districtController = TextEditingController(text: address?.district);
    final cityController = TextEditingController(text: address?.city);
    bool isDefault = address?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            address == null ? 'Thêm địa chỉ mới' : 'Chỉnh sửa địa chỉ',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên người nhận *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ chi tiết *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wardController,
                  decoration: const InputDecoration(
                    labelText: 'Phường/Xã *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtController,
                  decoration: const InputDecoration(
                    labelText: 'Quận/Huyện *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Tỉnh/Thành phố *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: isDefault,
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (_validateForm(
                  nameController,
                  phoneController,
                  addressController,
                  wardController,
                  districtController,
                  cityController,
                )) {
                  final newAddress = ShippingAddress(
                    id: address?.id ?? '',
                    userId: '',
                    recipientName: nameController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    ward: wardController.text.trim(),
                    district: districtController.text.trim(),
                    city: cityController.text.trim(),
                    isDefault: isDefault,
                    createdAt: address?.createdAt ?? DateTime.now(),
                  );

                  if (address == null) {
                    controller.addAddress(newAddress);
                  } else {
                    controller.updateAddress(
                      newAddress.copyWith(id: address.id),
                    );
                  }

                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  static bool _validateForm(
    TextEditingController name,
    TextEditingController phone,
    TextEditingController address,
    TextEditingController ward,
    TextEditingController district,
    TextEditingController city,
  ) {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        ward.text.trim().isEmpty ||
        district.text.trim().isEmpty ||
        city.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ thông tin');
      return false;
    }
    return true;
  }
}
