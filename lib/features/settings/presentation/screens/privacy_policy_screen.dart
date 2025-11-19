import 'package:flutter/material.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              '1. Introduction',
              'Welcome to LocalTrade. We are committed to protecting your privacy and ensuring you have a positive experience on our platform. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
              '• Account Information: Name, email address, phone number, business name, and profile information\n'
              '• Location Data: Your address and geographic coordinates for proximity-based features\n'
              '• Content: Posts, messages, orders, reviews, and other content you create\n'
              '• Preferences: Notification settings, privacy settings, and app preferences\n'
              '• Device Information: Device type, operating system, and app version\n'
              '• Usage Data: How you interact with our app, features used, and time spent',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide and maintain our services\n'
              '• Process transactions and manage orders\n'
              '• Enable communication between users\n'
              '• Personalize your experience\n'
              '• Send you notifications and updates\n'
              '• Improve our services and develop new features\n'
              '• Ensure platform safety and prevent fraud\n'
              '• Comply with legal obligations',
            ),
            _buildSection(
              context,
              '4. Information Sharing',
              'We do not sell your personal information. We may share your information only in the following circumstances:\n\n'
              '• With other users: Your profile information, posts, and public content are visible to other users as intended by the platform\n'
              '• Service Providers: We may share data with third-party service providers who assist us in operating our platform\n'
              '• Legal Requirements: We may disclose information if required by law or to protect our rights and safety\n'
              '• Business Transfers: In the event of a merger, acquisition, or sale of assets, your information may be transferred',
            ),
            _buildSection(
              context,
              '5. Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.',
            ),
            _buildSection(
              context,
              '6. Your Rights and Choices',
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Export your data in JSON or CSV format\n'
              '• Control privacy settings and visibility preferences\n'
              '• Opt-out of certain communications\n'
              '• Request data portability',
            ),
            _buildSection(
              context,
              '7. Location Data',
              'We collect location information to enable proximity-based features such as distance calculations and location-based search. You can control location sharing in your privacy settings. Location data is used only for platform functionality and is not shared with third parties except as necessary to provide our services.',
            ),
            _buildSection(
              context,
              '8. Cookies and Tracking',
              'We may use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.',
            ),
            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Our services are not intended for users under the age of 18. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            ),
            _buildSection(
              context,
              '10. Data Retention',
              'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy. When you delete your account, we will delete or anonymize your personal information, except where we are required to retain it for legal or regulatory purposes.',
            ),
            _buildSection(
              context,
              '11. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws that differ from those in your country. By using our services, you consent to the transfer of your information to these countries.',
            ),
            _buildSection(
              context,
              '12. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              context,
              '13. Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\n'
              'Email: privacy@localtrade.app\n'
              'Address: LocalTrade Privacy Team\n'
              'We will respond to your inquiry within a reasonable timeframe.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using LocalTrade, you agree to the collection and use of information in accordance with this Privacy Policy.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

