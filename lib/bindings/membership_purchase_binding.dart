import 'package:get/get.dart';
import '../controllers/membership_purchase_controller.dart';

class MembershipPurchaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MembershipPurchaseController>(
      () => MembershipPurchaseController(),
    );
  }
}
