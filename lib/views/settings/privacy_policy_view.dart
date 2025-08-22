import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF21CBF3).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gym Pro Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: August 22, 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              title: '1. Introduction',
              content: '''Welcome to Gym Pro, your comprehensive fitness management application. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, protect, and share your information when you use our mobile application and related services.

By using Gym Pro, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree with our policies and practices, please do not use our services.''',
            ),

            // Information We Collect
            _buildSection(
              title: '2. Information We Collect',
              content: '''We collect several types of information to provide and improve our services:

**2.1 Personal Information**
- Account Information: Full name, username, email address
- Contact Details: Phone number, address
- Personal Details: Date of birth, gender
- Profile Information: Profile pictures, fitness goals, preferences

**2.2 Automatically Collected Information**
- Device Information: Device type, operating system, unique device identifiers
- Usage Data: App interactions, feature usage, session duration
- Technical Data: IP address, browser type, app version
- Location Data: General location information (with your permission)

**2.3 Information from Third Parties**
- Social Media: If you connect your social media accounts
- Fitness Devices: Data from connected fitness trackers or wearables
- Analytics: Anonymous usage statistics and crash reports''',
            ),

            // How We Use Information
            _buildSection(
              title: '3. How We Use Your Information',
              content: '''We use your information for the following purposes:

**3.1 Service Provision**
- Create and manage your user account
- Provide personalized fitness recommendations
- Track your workout progress and achievements
- Enable social features and community interactions

**3.2 Communication**
- Send important service notifications
- Provide customer support and assistance
- Share fitness tips and educational content
- Notify you about app updates and new features

**3.3 Improvement and Analytics**
- Analyze app usage to improve user experience
- Develop new features and services
- Conduct research and analytics
- Fix bugs and technical issues

**3.4 Safety and Security**
- Prevent fraud and abuse
- Protect against security threats
- Comply with legal requirements
- Ensure platform integrity''',
            ),

            // Data Sharing
            _buildSection(
              title: '4. Information Sharing and Disclosure',
              content: '''We do not sell, trade, or rent your personal information to third parties. We may share your information in the following limited circumstances:

**4.1 Service Providers**
We work with trusted third-party service providers who assist us in operating our app:
- Cloud storage providers (Google Firebase)
- Analytics services (crash reporting, usage analytics)
- Communication services (email, push notifications)

**4.2 Legal Requirements**
We may disclose your information if required by law or in good faith belief that such disclosure is necessary to:
- Comply with legal processes or government requests
- Protect our rights, property, or safety
- Prevent fraud or illegal activities
- Enforce our Terms of Service

**4.3 Business Transfers**
In the event of a merger, acquisition, or asset sale, your information may be transferred as part of the business transaction.''',
            ),

            // Data Security
            _buildSection(
              title: '5. Data Security and Protection',
              content: '''We implement appropriate technical and organizational measures to protect your personal information:

**5.1 Technical Safeguards**
- Encryption of data in transit and at rest
- Secure authentication systems
- Regular security assessments and updates
- Access controls and monitoring

**5.2 Organizational Measures**
- Employee training on data protection
- Strict access controls based on job requirements
- Regular security audits and compliance checks
- Incident response procedures

**5.3 Data Retention**
We retain your personal information only as long as necessary to:
- Provide our services to you
- Comply with legal obligations
- Resolve disputes and enforce agreements
- Maintain business records as required

When information is no longer needed, we securely delete or anonymize it.''',
            ),

            // User Rights
            _buildSection(
              title: '6. Your Rights and Choices',
              content: '''You have several rights regarding your personal information:

**6.1 Access and Portability**
- View and download your personal data
- Request a copy of your information in a portable format
- Access your data processing history

**6.2 Correction and Updates**
- Update your profile information at any time
- Correct inaccurate or incomplete data
- Request verification of data accuracy

**6.3 Deletion and Restriction**
- Delete your account and associated data
- Request restriction of data processing
- Opt-out of certain data uses

**6.4 Communication Preferences**
- Manage notification settings
- Unsubscribe from marketing communications
- Control data sharing preferences

To exercise these rights, please contact us through the app settings or our support channels.''',
            ),

            // International Transfers
            _buildSection(
              title: '7. International Data Transfers',
              content: '''Our services are provided globally, and your information may be processed in countries other than your residence. We ensure adequate protection through:

- Standard contractual clauses approved by regulatory authorities
- Adequacy decisions for certain countries
- Certification schemes and binding corporate rules
- Your explicit consent where required

We maintain the same level of protection regardless of where your data is processed.''',
            ),

            // Children's Privacy
            _buildSection(
              title: '8. Children\'s Privacy',
              content: '''Gym Pro is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.

For users aged 13-18, we recommend parental supervision and guidance when using our services. We take extra care to protect the privacy of younger users.''',
            ),

            // Changes to Policy
            _buildSection(
              title: '9. Changes to This Privacy Policy',
              content: '''We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. When we make changes:

- We will notify you through the app or via email
- The "Last updated" date will be revised
- Material changes will be prominently displayed
- Continued use constitutes acceptance of the updated policy

We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.''',
            ),

            // Contact Information
            _buildSection(
              title: '10. Contact Us',
              content: '''If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:

**Email:** privacy@gympro.app
**Address:** Gym Pro Privacy Team, 123 Fitness Street, Health City, HC 12345
**Phone:** +1 (555) 123-4567

For immediate assistance with privacy matters, you can also reach us through the in-app support feature.

We are committed to addressing your privacy concerns promptly and effectively.''',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Thank you for trusting Gym Pro with your fitness journey.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is our priority.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF2196F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
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
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
