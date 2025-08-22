import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataSettingsView extends StatelessWidget {
  const DataSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data Settings'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Collection Section
            _buildSection(
              title: 'Data Collection',
              description: 'Control what data we collect from your usage',
              children: [
                _buildSwitchTile(
                  title: 'Analytics Data',
                  subtitle: 'Help improve the app with anonymous usage data',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Performance Data',
                  subtitle: 'Share performance metrics to help us optimize',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Crash Reports',
                  subtitle: 'Send crash reports to help fix bugs',
                  value: true.obs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Usage Section
            _buildSection(
              title: 'Data Usage',
              description: 'Manage how your data is used for personalization',
              children: [
                _buildSwitchTile(
                  title: 'Personalized Recommendations',
                  subtitle:
                      'Use your data to provide better workout suggestions',
                  value: true.obs,
                ),
                _buildSwitchTile(
                  title: 'Marketing Communications',
                  subtitle: 'Receive personalized fitness tips and offers',
                  value: false.obs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Export & Deletion
            _buildSection(
              title: 'Your Data Rights',
              description: 'Download or delete your personal data',
              children: [
                _buildActionTile(
                  title: 'Download My Data',
                  subtitle: 'Export all your personal data',
                  icon: Icons.download_outlined,
                  onTap: () => _showDataExportDialog(context),
                ),
                _buildActionTile(
                  title: 'Delete My Data',
                  subtitle: 'Permanently remove all your data',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                  onTap: () => _showDataDeletionDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacy Policy Link
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.policy_outlined,
                  color: Color(0xFF2196F3),
                ),
                title: const Text('View Full Privacy Policy'),
                subtitle: const Text('Read our complete privacy policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Get.toNamed('/privacy-policy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required RxBool value,
  }) {
    return Obx(
      () => SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        value: value.value,
        onChanged: (bool newValue) {
          value.value = newValue;
          _savePreference(title, newValue);
        },
        activeColor: const Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF2196F3),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _savePreference(String key, bool value) {
    // Here you would typically save to SharedPreferences or similar
    Get.snackbar(
      'Settings Updated',
      '$key has been ${value ? 'enabled' : 'disabled'}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showDataExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Your Data'),
        content: const Text(
          'We will prepare a file containing all your personal data and send it to your registered email address. This may take up to 24 hours.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Export Requested',
                'Your data export has been requested. You will receive an email shortly.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your personal data from our servers. This action cannot be undone. Your account will also be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDataDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }

  void _confirmDataDeletion() {
    Get.dialog(
      AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Are you absolutely sure? This will delete your account and all associated data permanently.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Here you would call the actual deletion logic
              Get.snackbar(
                'Data Deletion Requested',
                'Your data deletion request has been submitted. This will be processed within 7 days.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );
  }
}
