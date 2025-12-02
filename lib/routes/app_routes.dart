abstract class AppRoutes {
  static const initial = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const privacyPolicy = '/privacy-policy';
  static const settings = '/settings';
  static const memberManagement = '/member-management';
  static const exerciseManagement = '/admin/exercise-management';
  static const membershipCardManagement = '/admin/membership-card-management';
  static const userMembershipManagement = '/admin/user-membership-management';
  static const membershipPurchase = '/membership-purchase';
  static const checkout = '/checkout';
  static const directPaymentConfirmation = '/direct-payment-confirmation';
  static const paymentStatus = '/payment/status';
  static const paymentResult = '/payment-result';
  static const exercises = '/exercises';
  static const cleanupTest = '/cleanup-test';

  // Workout Schedule Routes
  static const scheduleManagement = '/admin/schedule-management';
  static const createSchedule = '/admin/create-schedule';
  static const editSchedule = '/admin/edit-schedule';
  static const checkinCheckout = '/admin/checkin-checkout';
  static const adminStatistics = '/admin/statistics';
  static const userScheduleSelection = '/user/schedule-selection';
  static const userScheduleDetail = '/user/schedule-detail';
  static const userScheduleHistory = '/user/schedule-history';
  static const myMembershipCards = '/my-membership-cards';
  static const workoutScheduleDetail = '/user/workout-schedule-detail';
  static const membershipCardExport = '/membership-card-export';

  // News Management Routes
  static const newsManagement = '/admin/news-management';
  static const createNews = '/admin/news-management/create';
  static const editNews = '/admin/news-management/edit';
  static const newsDetail = '/admin/news-management/detail';
  static const newsPreview = '/admin/news-management/preview';

  // News User Routes
  static const newsFeed = '/news-feed';
  static const newsDetailUser = '/news-detail';

  // Trainer Management Routes
  static const trainerManagement = '/admin/trainer-management';

  // PT (Personal Trainer) Routes
  static const ptDashboard = '/pt/dashboard';

  // Trainer Rental Routes (Member)
  static const trainerRental = '/trainer-rental';
  static const myTrainerRentals = '/my-trainer-rentals';

  // Product Management Routes
  static const productManagement = '/admin/product-management';
  static const productDetail = '/admin/product-detail';

  // Shopping Routes (User)
  static const userProducts = '/user/products';
  static const userCart = '/user/cart';
  static const userCheckout = '/user/checkout';
  static const userOrders = '/user/orders';
  static const userOrderDetail = '/user/order-detail';

  // Order Management Routes (Admin)
  static const orderManagement = '/admin/order-management';

  // Admin Membership Purchases Routes
  static const adminMembershipPurchases = '/admin/membership-purchases';
}
