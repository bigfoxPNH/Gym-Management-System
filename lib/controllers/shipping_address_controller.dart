import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:gympro/models/shipping_address.dart';

class ShippingAddressController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final addresses = <ShippingAddress>[].obs;
  final isLoading = false.obs;
  final defaultAddress = Rx<ShippingAddress?>(null);

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  // Load all addresses
  Future<void> loadAddresses() async {
    if (currentUserId == null) return;

    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('shipping_addresses')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      addresses.value = snapshot.docs
          .map((doc) => ShippingAddress.fromMap(doc.data(), doc.id))
          .toList();

      // Find default address
      final defaultAddr = addresses.firstWhereOrNull((addr) => addr.isDefault);
      defaultAddress.value = defaultAddr;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách địa chỉ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Add new address
  Future<void> addAddress(ShippingAddress address) async {
    if (currentUserId == null) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập');
      return;
    }

    try {
      isLoading.value = true;

      // If this is the first address or marked as default, update others
      if (address.isDefault || addresses.isEmpty) {
        await _clearDefaultAddresses();
      }

      await _firestore
          .collection('shipping_addresses')
          .add(
            address
                .copyWith(userId: currentUserId!, createdAt: DateTime.now())
                .toMap(),
          );

      Get.snackbar('Thành công', 'Đã thêm địa chỉ mới');
      await loadAddresses();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm địa chỉ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update address
  Future<void> updateAddress(ShippingAddress address) async {
    try {
      isLoading.value = true;

      // If marking as default, clear other defaults
      if (address.isDefault) {
        await _clearDefaultAddresses();
      }

      await _firestore
          .collection('shipping_addresses')
          .doc(address.id)
          .update(address.toMap());

      Get.snackbar('Thành công', 'Đã cập nhật địa chỉ');
      await loadAddresses();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật địa chỉ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('shipping_addresses').doc(addressId).delete();

      Get.snackbar('Thành công', 'Đã xóa địa chỉ');
      await loadAddresses();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa địa chỉ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Set address as default
  Future<void> setDefaultAddress(String addressId) async {
    try {
      isLoading.value = true;

      await _clearDefaultAddresses();

      await _firestore.collection('shipping_addresses').doc(addressId).update({
        'isDefault': true,
      });

      await loadAddresses();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể đặt địa chỉ mặc định: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear all default flags
  Future<void> _clearDefaultAddresses() async {
    if (currentUserId == null) return;

    final snapshot = await _firestore
        .collection('shipping_addresses')
        .where('userId', isEqualTo: currentUserId)
        .where('isDefault', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  // Get address by ID
  ShippingAddress? getAddressById(String id) {
    return addresses.firstWhereOrNull((addr) => addr.id == id);
  }
}
