import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/profile/profile_view.dart';
import '../views/profile/edit_profile_view.dart';
import '../views/settings/privacy_policy_view.dart';
import '../views/settings/settings_view.dart';
import '../views/admin/member_management_view.dart';
import '../views/admin/exercise_management_view.dart';
import '../views/admin/membership_card_management_view.dart';
import '../views/membership/membership_purchase_view.dart';
import '../views/membership/checkout_view.dart' as MembershipCheckout;
import '../views/payment/payment_status_view.dart';
import '../views/payment/payment_result_view.dart';
import '../views/exercise/exercise_list_view.dart';

// Workout Schedule imports
import '../views/admin/schedule_management_view.dart';
import '../views/admin/create_schedule_view.dart';
import '../views/admin/edit_schedule_view.dart';
import '../views/user/user_schedule_selection_view.dart';
import '../views/user/user_schedule_detail_view.dart';
import '../views/user/user_schedule_history_view.dart';
import '../views/user/workout_schedule_detail_view.dart';
import '../views/checkout/direct_payment_confirmation_view.dart';
import '../views/admin/checkin_checkout_view.dart';
import '../views/user/my_membership_cards_view.dart';
import '../views/membership/membership_card_export_view.dart';

import '../views/test/cleanup_test_view.dart';
import '../views/test/test_checkout_view.dart';
import '../views/checkout/checkout_view.dart' as GeneralCheckout;
import '../controllers/auth_controller.dart';
import '../bindings/membership_purchase_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.initial, page: () => const InitialView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(name: AppRoutes.home, page: () => const HomeView()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileView()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileView()),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyView(),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
    GetPage(
      name: AppRoutes.memberManagement,
      page: () => const MemberManagementView(),
    ),
    GetPage(
      name: AppRoutes.exerciseManagement,
      page: () => const ExerciseManagementView(),
    ),
    GetPage(
      name: AppRoutes.membershipCardManagement,
      page: () => const MembershipCardManagementView(),
    ),
    GetPage(
      name: AppRoutes.membershipPurchase,
      page: () => const MembershipPurchaseView(),
      binding: MembershipPurchaseBinding(),
    ),
    GetPage(name: '/test-checkout', page: () => const TestCheckoutView()),
    GetPage(name: '/checkout', page: () => GeneralCheckout.CheckoutView()),
    GetPage(
      name: AppRoutes.directPaymentConfirmation,
      page: () => const DirectPaymentConfirmationView(),
    ),
    GetPage(
      name: AppRoutes.paymentStatus,
      page: () => PaymentStatusView(orderId: Get.arguments ?? ''),
    ),
    GetPage(
      name: AppRoutes.paymentResult,
      page: () => const PaymentResultView(),
    ),
    GetPage(name: AppRoutes.exercises, page: () => const ExerciseListView()),
    GetPage(name: '/cleanup-test', page: () => const CleanupTestView()),

    // Workout Schedule Routes
    GetPage(
      name: AppRoutes.scheduleManagement,
      page: () => const ScheduleManagementView(),
    ),
    GetPage(
      name: AppRoutes.createSchedule,
      page: () => const CreateScheduleView(),
    ),
    GetPage(
      name: AppRoutes.editSchedule,
      page: () => EditScheduleView(schedule: Get.arguments),
    ),
    GetPage(
      name: AppRoutes.userScheduleSelection,
      page: () => const UserScheduleSelectionView(),
    ),
    GetPage(
      name: AppRoutes.userScheduleDetail,
      page: () => const UserScheduleDetailView(),
    ),
    GetPage(
      name: AppRoutes.userScheduleHistory,
      page: () => const UserScheduleHistoryView(),
    ),
    GetPage(
      name: AppRoutes.workoutScheduleDetail,
      page: () => WorkoutScheduleDetailView(schedule: Get.arguments),
    ),
    GetPage(
      name: AppRoutes.checkinCheckout,
      page: () => const CheckinCheckoutView(),
    ),
    GetPage(
      name: AppRoutes.myMembershipCards,
      page: () => const MyMembershipCardsView(),
    ),
    GetPage(
      name: AppRoutes.membershipCardExport,
      page: () => const MembershipCardExportView(),
    ),
  ];
}

class InitialView extends StatelessWidget {
  const InitialView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        if (controller.isLoggedIn.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.home);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.login);
          });
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
