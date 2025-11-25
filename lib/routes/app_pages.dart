import 'package:get/get.dart';
import '../views/splash/splash_view.dart';
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
import '../views/admin/user_membership_management_view.dart';
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
import '../views/admin/admin_statistics_view.dart';
import '../views/user/my_membership_cards_view.dart';
import '../views/membership/membership_card_export_view.dart';

// News Management imports
import '../screens/admin/news_management_screen.dart';
import '../screens/admin/news_form_screen.dart';
import '../screens/admin/news_detail_screen.dart';

// News User imports
import '../screens/user/news_feed_screen.dart';
import '../screens/user/news_detail_user_screen.dart';
import '../controllers/news_user_controller.dart';

// Trainer Management imports
import '../views/admin/trainer_management_view.dart';

// PT (Personal Trainer) imports
import '../views/pt/pt_dashboard_tabs_view.dart';
import '../views/pt/pt_schedule_view.dart';

// Trainer Rental imports
import '../views/trainer_rental/trainer_rental_view.dart';
import '../views/trainer_rental/my_trainer_rentals_view.dart';

// Product Management imports
import '../views/admin/product_management_view.dart';
import '../views/admin/product_detail_view.dart';

// Shopping imports
import '../views/user/user_product_list_view.dart';
import '../views/user/shopping_cart_view.dart';
import '../views/user/checkout_view.dart' as UserCheckout;
import '../views/user/order_history_view.dart';
import '../views/admin/order_management_view.dart';
import '../controllers/shopping_cart_controller.dart';
import '../controllers/order_controller.dart';

import '../views/test/cleanup_test_view.dart';
import '../views/test/test_checkout_view.dart';
import '../views/checkout/checkout_view.dart' as GeneralCheckout;
import '../bindings/membership_purchase_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.initial, page: () => const SplashView()),
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
      name: AppRoutes.userMembershipManagement,
      page: () => const UserMembershipManagementView(),
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
      name: AppRoutes.adminStatistics,
      page: () => const AdminStatisticsView(),
    ),
    GetPage(
      name: AppRoutes.myMembershipCards,
      page: () => const MyMembershipCardsView(),
    ),
    GetPage(
      name: AppRoutes.membershipCardExport,
      page: () => const MembershipCardExportView(),
    ),

    // Trainer Management Routes
    GetPage(
      name: AppRoutes.trainerManagement,
      page: () => const TrainerManagementView(),
    ),

    // Trainer Rental Routes
    GetPage(
      name: AppRoutes.trainerRental,
      page: () => const TrainerRentalView(),
    ),
    GetPage(
      name: AppRoutes.myTrainerRentals,
      page: () => const MyTrainerRentalsView(),
    ),

    // Product Management Routes
    GetPage(
      name: AppRoutes.productManagement,
      page: () => ProductManagementView(),
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailView(),
    ),

    // News Management Routes
    GetPage(
      name: AppRoutes.newsManagement,
      page: () => const NewsManagementScreen(),
    ),
    GetPage(name: AppRoutes.createNews, page: () => const NewsFormScreen()),
    GetPage(
      name: '${AppRoutes.editNews}/:newsId',
      page: () => NewsFormScreen(newsId: Get.parameters['newsId']),
    ),
    GetPage(
      name: '${AppRoutes.newsDetail}/:newsId',
      page: () => NewsDetailScreen(newsId: Get.parameters['newsId']!),
    ),
    GetPage(
      name: AppRoutes.newsPreview,
      page: () =>
          NewsDetailScreen(newsId: 'preview', previewNews: Get.arguments),
    ),

    // News User Routes
    GetPage(
      name: AppRoutes.newsFeed,
      page: () => const NewsFeedScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NewsUserController>(() => NewsUserController());
      }),
    ),
    GetPage(
      name: '${AppRoutes.newsDetailUser}/:newsId',
      page: () => NewsDetailUserScreen(newsId: Get.parameters['newsId']!),
      binding: BindingsBuilder(() {
        Get.lazyPut<NewsUserController>(() => NewsUserController());
      }),
    ),

    // PT Dashboard
    GetPage(
      name: AppRoutes.ptDashboard,
      page: () => const PTDashboardTabsView(),
    ),

    // PT Schedule
    GetPage(name: '/pt/schedule', page: () => const PTScheduleView()),

    // Shopping Routes (User)
    GetPage(
      name: AppRoutes.userProducts,
      page: () => const UserProductListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ShoppingCartController>(() => ShoppingCartController());
      }),
    ),
    GetPage(
      name: AppRoutes.userCart,
      page: () => const ShoppingCartView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ShoppingCartController>(() => ShoppingCartController());
      }),
    ),
    GetPage(
      name: AppRoutes.userCheckout,
      page: () => const UserCheckout.CheckoutView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ShoppingCartController>(() => ShoppingCartController());
        Get.lazyPut<OrderController>(() => OrderController());
      }),
    ),
    GetPage(
      name: AppRoutes.userOrders,
      page: () => const OrderHistoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<OrderController>(() => OrderController());
      }),
    ),
    GetPage(
      name: AppRoutes.orderManagement,
      page: () => const OrderManagementView(),
    ),
  ];
}
