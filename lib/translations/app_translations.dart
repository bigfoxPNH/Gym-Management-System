import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // App General
      'app_name': 'Gym Pro',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'close': 'Close',

      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
      'full_name': 'Full Name',
      'username': 'Username',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'sign_in_to_continue': 'Sign in to continue',
      'create_your_account': 'Create your account',

      // Profile
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'personal_information': 'Personal Information',
      'account_information': 'Account Information',
      'phone_number': 'Phone Number',
      'address': 'Address',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'select_gender': 'Select Gender',
      'date_of_birth': 'Date of Birth',
      'select_date_of_birth': 'Select Date of Birth',
      'member_since': 'Member Since',
      'last_updated': 'Last Updated',
      'save_changes': 'Save Changes',

      // Account Settings
      'account_settings': 'Account Settings',
      'change_password': 'Change Password',
      'update_your_password': 'Update your password',
      'notifications': 'Notifications',
      'manage_notification_settings': 'Manage notification settings',
      'privacy_policy': 'Privacy Policy',
      'view_complete_privacy_policy': 'View our complete privacy policy',
      'data_settings': 'Data Settings',
      'manage_data_privacy_preferences':
          'Manage your data and privacy preferences',

      // Actions
      'actions': 'Actions',
      'update_your_information': 'Update your information',
      'sign_out_of_your_account': 'Sign out of your account',
      'permanently_delete_your_account': 'Permanently delete your account',
      'delete_account': 'Delete Account',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system': 'System',
      'update_app': 'Update App',
      'contact_support': 'Contact Support',
      'coming_soon': 'Coming Soon',

      // Contact
      'facebook': 'Facebook',
      'zalo': 'Zalo',
      'address_location': 'Address',

      // Messages
      'profile_updated_successfully': 'Profile updated successfully',
      'password_changed_successfully': 'Password changed successfully',
      'account_deleted_successfully':
          'Your account has been successfully deleted',
      'uploading_image': 'Uploading...',
      'please_wait_uploading':
          'Please wait while we update your profile picture',
      'image_updated_successfully': 'Profile picture updated successfully',

      // Validation
      'please_enter_full_name': 'Please enter your full name',
      'name_min_2_chars': 'Name must be at least 2 characters',
      'please_enter_username': 'Please enter a username',
      'username_min_3_chars': 'Username must be at least 3 characters',
      'phone_min_10_digits': 'Phone number must be at least 10 digits',
      'address_min_5_chars': 'Address must be at least 5 characters',

      // Privacy
      'privacy_data_protection': 'Privacy & Data Protection',
      'data_collection': 'Data Collection',
      'analytics_data': 'Analytics Data',
      'performance_data': 'Performance Data',
      'crash_reports': 'Crash Reports',
      'your_data_rights': 'Your Data Rights',
      'download_my_data': 'Download My Data',
      'delete_my_data': 'Delete My Data',
    },

    'vi_VN': {
      // App General
      'app_name': 'Gym Pro',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'confirm': 'Xác nhận',
      'close': 'Đóng',

      // Authentication
      'sign_in': 'Đăng Nhập',
      'sign_up': 'Đăng Ký',
      'sign_out': 'Đăng Xuất',
      'email': 'Email',
      'password': 'Mật khẩu',
      'full_name': 'Họ và tên',
      'username': 'Tên đăng nhập',
      'forgot_password': 'Quên mật khẩu?',
      'dont_have_account': 'Chưa có tài khoản?',
      'already_have_account': 'Đã có tài khoản?',
      'sign_in_to_continue': 'Đăng nhập để tiếp tục',
      'create_your_account': 'Tạo tài khoản của bạn',

      // Profile
      'profile': 'Hồ Sơ',
      'edit_profile': 'Chỉnh Sửa Hồ Sơ',
      'personal_information': 'Thông Tin Cá Nhân',
      'account_information': 'Thông Tin Tài Khoản',
      'phone_number': 'Số điện thoại',
      'address': 'Địa chỉ',
      'gender': 'Giới tính',
      'male': 'Nam',
      'female': 'Nữ',
      'other': 'Khác',
      'select_gender': 'Chọn giới tính',
      'date_of_birth': 'Ngày sinh',
      'select_date_of_birth': 'Chọn ngày sinh',
      'member_since': 'Thành viên từ',
      'last_updated': 'Cập nhật lần cuối',
      'save_changes': 'Lưu Thay Đổi',

      // Account Settings
      'account_settings': 'Cài Đặt Tài Khoản',
      'change_password': 'Đổi Mật Khẩu',
      'update_your_password': 'Cập nhật mật khẩu của bạn',
      'notifications': 'Thông Báo',
      'manage_notification_settings': 'Quản lý cài đặt thông báo',
      'privacy_policy': 'Chính Sách Bảo Mật',
      'view_complete_privacy_policy': 'Xem chính sách bảo mật đầy đủ',
      'data_settings': 'Cài Đặt Dữ Liệu',
      'manage_data_privacy_preferences':
          'Quản lý tùy chọn dữ liệu và quyền riêng tư',

      // Actions
      'actions': 'Hành Động',
      'update_your_information': 'Cập nhật thông tin của bạn',
      'sign_out_of_your_account': 'Đăng xuất khỏi tài khoản',
      'permanently_delete_your_account': 'Xóa vĩnh viễn tài khoản của bạn',
      'delete_account': 'Xóa Tài Khoản',

      // Settings
      'settings': 'Cài Đặt',
      'language': 'Ngôn Ngữ',
      'theme': 'Giao Diện',
      'dark_mode': 'Chế độ tối',
      'light_mode': 'Chế độ sáng',
      'system': 'Hệ thống',
      'update_app': 'Cập Nhật Ứng Dụng',
      'contact_support': 'Liên Hệ Hỗ Trợ',
      'coming_soon': 'Sắp ra mắt',

      // Contact
      'facebook': 'Facebook',
      'zalo': 'Zalo',
      'address_location': 'Địa chỉ',

      // Messages
      'profile_updated_successfully': 'Cập nhật hồ sơ thành công',
      'password_changed_successfully': 'Đổi mật khẩu thành công',
      'account_deleted_successfully':
          'Tài khoản của bạn đã được xóa thành công',
      'uploading_image': 'Đang tải lên...',
      'please_wait_uploading':
          'Vui lòng đợi trong khi chúng tôi cập nhật ảnh đại diện',
      'image_updated_successfully': 'Cập nhật ảnh đại diện thành công',

      // Validation
      'please_enter_full_name': 'Vui lòng nhập họ và tên',
      'name_min_2_chars': 'Tên phải có ít nhất 2 ký tự',
      'please_enter_username': 'Vui lòng nhập tên đăng nhập',
      'username_min_3_chars': 'Tên đăng nhập phải có ít nhất 3 ký tự',
      'phone_min_10_digits': 'Số điện thoại phải có ít nhất 10 số',
      'address_min_5_chars': 'Địa chỉ phải có ít nhất 5 ký tự',

      // Privacy
      'privacy_data_protection': 'Bảo Mật & Bảo Vệ Dữ Liệu',
      'data_collection': 'Thu Thập Dữ Liệu',
      'analytics_data': 'Dữ Liệu Phân Tích',
      'performance_data': 'Dữ Liệu Hiệu Suất',
      'crash_reports': 'Báo Cáo Lỗi',
      'your_data_rights': 'Quyền Dữ Liệu Của Bạn',
      'download_my_data': 'Tải Xuống Dữ Liệu',
      'delete_my_data': 'Xóa Dữ Liệu Của Tôi',
    },
  };
}
