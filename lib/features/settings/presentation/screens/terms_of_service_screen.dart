import 'package:flutter/material.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Terms of Service'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using LocalTrade, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            _buildSection(
              context,
              '2. Description of Service',
              'LocalTrade is a marketplace platform that connects local sellers and farmers with restaurants. The platform enables users to:\n\n'
              '• Create and manage product listings\n'
              '• Post product requests\n'
              '• Communicate with other users\n'
              '• Place and manage orders\n'
              '• Rate and review transactions\n'
              '• Discover local products and suppliers',
            ),
            _buildSection(
              context,
              '3. User Accounts',
              'To use certain features of LocalTrade, you must register for an account. You agree to:\n\n'
              '• Provide accurate, current, and complete information\n'
              '• Maintain and update your account information\n'
              '• Maintain the security of your password\n'
              '• Accept responsibility for all activities under your account\n'
              '• Notify us immediately of any unauthorized use\n'
              '• Be at least 18 years old to use the service',
            ),
            _buildSection(
              context,
              '4. User Roles and Responsibilities',
              'LocalTrade supports two user roles:\n\n'
              '• Sellers/Farmers: Can create product listings, receive orders, and manage inventory\n'
              '• Restaurants: Can browse products, post requests, and place orders\n\n'
              'You are responsible for:\n'
              '• The accuracy of information you provide\n'
              '• Compliance with all applicable laws and regulations\n'
              '• The quality and safety of products you sell\n'
              '• Fulfilling orders you accept',
            ),
            _buildSection(
              context,
              '5. Content and Posting Guidelines',
              'You agree not to post, upload, or transmit content that:\n\n'
              '• Is illegal, harmful, or violates any laws\n'
              '• Infringes on intellectual property rights\n'
              '• Contains false or misleading information\n'
              '• Is spam, unsolicited, or promotional\n'
              '• Contains viruses or malicious code\n'
              '• Harasses, abuses, or threatens others\n'
              '• Violates privacy rights of others\n'
              '• Is inappropriate, offensive, or discriminatory',
            ),
            _buildSection(
              context,
              '6. Transactions and Orders',
              'LocalTrade facilitates transactions between users. You agree that:\n\n'
              '• All transactions are between you and other users\n'
              '• LocalTrade is not a party to any transaction\n'
              '• You are responsible for fulfilling accepted orders\n'
              '• Prices and terms are negotiated between users\n'
              '• LocalTrade does not guarantee product quality or delivery\n'
              '• Disputes should be resolved directly between parties\n'
              '• LocalTrade may assist with dispute resolution but is not obligated',
            ),
            _buildSection(
              context,
              '7. Payment and Fees',
              'Currently, LocalTrade does not process payments. All payments are handled directly between users. LocalTrade reserves the right to:\n\n'
              '• Introduce payment processing services in the future\n'
              '• Charge fees for premium features\n'
              '• Modify fee structures with notice\n'
              '• Process refunds in accordance with our policies',
            ),
            _buildSection(
              context,
              '8. Intellectual Property',
              'The LocalTrade platform, including its design, features, and content, is protected by intellectual property laws. You agree that:\n\n'
              '• LocalTrade owns all rights to the platform\n'
              '• You retain ownership of content you create\n'
              '• You grant LocalTrade a license to use your content on the platform\n'
              '• You will not copy, modify, or distribute platform content without permission',
            ),
            _buildSection(
              context,
              '9. Prohibited Activities',
              'You agree not to:\n\n'
              '• Use the platform for illegal purposes\n'
              '• Impersonate others or provide false information\n'
              '• Interfere with platform operations\n'
              '• Attempt to gain unauthorized access\n'
              '• Use automated systems to access the platform\n'
              '• Reverse engineer or decompile the platform\n'
              '• Collect user information without consent\n'
              '• Engage in fraudulent or deceptive practices',
            ),
            _buildSection(
              context,
              '10. Account Termination',
              'We reserve the right to:\n\n'
              '• Suspend or terminate accounts that violate these terms\n'
              '• Remove content that violates our policies\n'
              '• Take legal action against violators\n'
              '• Refuse service to anyone at any time\n\n'
              'You may delete your account at any time through Settings. Upon termination:\n'
              '• Your access to the platform will be revoked\n'
              '• Your content may be removed\n'
              '• Outstanding obligations remain your responsibility',
            ),
            _buildSection(
              context,
              '11. Disclaimers and Limitations of Liability',
              'LocalTrade is provided "as is" without warranties of any kind. We disclaim:\n\n'
              '• All warranties, express or implied\n'
              '• Guarantees of platform availability or performance\n'
              '• Responsibility for user content or transactions\n'
              '• Liability for damages arising from platform use\n'
              '• Responsibility for third-party services or content\n\n'
              'To the maximum extent permitted by law, LocalTrade shall not be liable for any indirect, incidental, special, or consequential damages.',
            ),
            _buildSection(
              context,
              '12. Indemnification',
              'You agree to indemnify and hold LocalTrade harmless from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:\n\n'
              '• Your use of the platform\n'
              '• Your violation of these terms\n'
              '• Your violation of any rights of others\n'
              '• Content you post or transmit',
            ),
            _buildSection(
              context,
              '13. Dispute Resolution',
              'In the event of disputes:\n\n'
              '• Users should attempt to resolve disputes directly\n'
              '• LocalTrade may provide dispute resolution assistance\n'
              '• Disputes between users and LocalTrade will be resolved through binding arbitration\n'
              '• These terms are governed by applicable laws\n'
              '• Jurisdiction for legal proceedings will be determined by applicable law',
            ),
            _buildSection(
              context,
              '14. Modifications to Terms',
              'We reserve the right to modify these terms at any time. We will:\n\n'
              '• Notify users of significant changes\n'
              '• Update the "Last Updated" date\n'
              '• Post updated terms on the platform\n\n'
              'Continued use of the platform after changes constitutes acceptance of the modified terms.',
            ),
            _buildSection(
              context,
              '15. Privacy',
              'Your use of LocalTrade is also governed by our Privacy Policy. By using the platform, you consent to the collection and use of information as described in the Privacy Policy.',
            ),
            _buildSection(
              context,
              '16. Contact Information',
              'If you have questions about these Terms of Service, please contact us at:\n\n'
              'Email: legal@localtrade.app\n'
              'Address: LocalTrade Legal Team\n'
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
                      'By using LocalTrade, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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

