import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionTitle('Theme', Icons.palette),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionTitle('Notifications', Icons.notifications),
          _buildNotificationSettings(),
          const SizedBox(height: 24),

          // App Updates Section
          _buildSectionTitle('Update App', Icons.system_update),
          _buildUpdateSettings(),
          const SizedBox(height: 24),

          // Contact Support Section
          _buildSectionTitle('Contact Support', Icons.contact_support),
          _buildContactSupport(),
          const SizedBox(height: 24),

          // Account Actions
          _buildSectionTitle('Account Settings', Icons.account_circle),
          _buildAccountActions(authController),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.light_mode, color: Colors.orange),
            title: const Text('Light Mode'),
            trailing: Radio<String>(
              value: 'light',
              groupValue: 'light', // You can implement theme controller
              onChanged: (value) => _showComingSoonSnackBar(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.grey),
            title: const Text('Dark Mode'),
            trailing: Radio<String>(
              value: 'dark',
              groupValue: 'light',
              onChanged: (value) => _showComingSoonSnackBar(),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_system_daydream,
              color: Colors.blue,
            ),
            title: const Text('System'),
            trailing: Radio<String>(
              value: 'system',
              groupValue: 'light',
              onChanged: (value) => _showComingSoonSnackBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive workout reminders and updates'),
            value: true, // You can implement notification controller
            onChanged: (value) => _showComingSoonSnackBar(),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive weekly progress reports'),
            value: false,
            onChanged: (value) => _showComingSoonSnackBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSettings() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.update, color: Colors.green),
        title: const Text('Check for Updates'),
        subtitle: const Text('Version 1.0.0 - Latest'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showComingSoonSnackBar(),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.facebook, color: Colors.white, size: 16),
            ),
            title: const Text('Facebook'),
            subtitle: const Text('Follow us on Facebook'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl(
              'https://www.facebook.com/people/Gym-Pro/61576247638943/',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0068FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'Z',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: const Text('Zalo'),
            subtitle: const Text('Chat with us on Zalo'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('https://zalo.me/0326658276'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('Address'),
            subtitle: const Text('Gym Pro - Click to view location on map'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () =>
                _launchUrl('https://maps.app.goo.gl/JavEQA2nVqxE6mry5'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(AuthController authController) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF2196F3)),
            title: const Text('Profile'),
            subtitle: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(AppRoutes.profile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text('Privacy Policy'),
            subtitle: const Text('View our complete privacy policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSignOutDialog(authController),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar() {
    Get.snackbar(
      'Coming Soon',
      'This feature will be available in a future update.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2196F3),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      Get.snackbar(
        'Error',
        'Could not open link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
