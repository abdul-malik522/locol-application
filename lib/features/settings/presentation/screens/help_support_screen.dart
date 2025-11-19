import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final Map<String, bool> _expandedSections = {};

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'LocalTrade Support Request',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Help & Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactSection(context),
            const SizedBox(height: 32),
            _buildFAQSection(context),
            const SizedBox(height: 32),
            _buildReportIssueSection(context),
            const SizedBox(height: 32),
            _buildResourcesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Support',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@localtrade.app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchEmail('support@localtrade.app'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone Support'),
                  subtitle: const Text('+1 (555) 123-4567'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchPhone('+15551234567'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.access_time_outlined),
                  title: const Text('Support Hours'),
                  subtitle: const Text('Monday - Friday, 9 AM - 6 PM EST'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          context,
          'How do I create a post?',
          'To create a post, tap the "Create" tab in the bottom navigation. Fill in the required information including title, description, category, images, and pricing. You can also schedule posts for future publication or set expiration dates.',
        ),
        _buildFAQItem(
          context,
          'How do I place an order?',
          'Browse the feed or use search to find products you need. Tap on a post to view details, then tap "Order" or "Contact Seller" to initiate the order. You can negotiate prices through messaging before placing the order.',
        ),
        _buildFAQItem(
          context,
          'How do I manage my orders?',
          'Go to the "Orders" tab to view all your orders. You can filter by status (Pending, Accepted, Completed, Cancelled). Tap on an order to view details, track delivery, download receipts, or file disputes.',
        ),
        _buildFAQItem(
          context,
          'How do I message other users?',
          'You can start a conversation by tapping "Contact" on a post or user profile. Go to the "Messages" tab to view all your conversations. You can send text messages, images, voice messages, and share your location.',
        ),
        _buildFAQItem(
          context,
          'How do I change my profile information?',
          'Go to Settings > Edit Profile to update your business name, description, phone number, address, and profile images. Changes are saved immediately.',
        ),
        _buildFAQItem(
          context,
          'How do I delete my account?',
          'Go to Settings > Danger Zone > Delete Account. You will be asked to confirm as this action is permanent and cannot be undone. All your data will be deleted.',
        ),
        _buildFAQItem(
          context,
          'How do I export my data?',
          'Go to Settings > Data > Export Data. You can export all your data in JSON or CSV format. The file will be saved to your device and you can share it securely.',
        ),
        _buildFAQItem(
          context,
          'How do I report inappropriate content?',
          'You can report posts or users by tapping the "Report" option in the menu. Select a reason and provide additional details. Our team will review the report and take appropriate action.',
        ),
        _buildFAQItem(
          context,
          'How do I block a user?',
          'Go to a user\'s profile and tap "Block User". Blocked users cannot contact you or see your posts. You can manage blocked users in Settings > Account Management > Blocked Users.',
        ),
        _buildFAQItem(
          context,
          'How do I enable two-factor authentication?',
          'Go to Settings > Account > Two-Factor Authentication. Follow the setup instructions to scan a QR code with your authenticator app. Save your backup codes in a safe place.',
        ),
        _buildFAQItem(
          context,
          'How do I change my password?',
          'Go to Settings > Account > Change Password. Enter your current password and your new password. Make sure your new password is at least 8 characters long.',
        ),
        _buildFAQItem(
          context,
          'How do I save a post to favorites?',
          'Tap the bookmark icon on any post to save it to your favorites. You can view all your favorite posts by going to your profile or using the favorites screen.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isExpanded = _expandedSections[question] ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) => _toggleSection(question),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportIssueSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report an Issue',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Found a bug or experiencing a problem? Let us know and we\'ll help you resolve it.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Report Issue',
          icon: Icons.bug_report_outlined,
          onPressed: () => _showReportIssueDialog(context),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildResourcesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/privacy-policy'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/terms-of-service'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Video Tutorials'),
                subtitle: const Text('Learn how to use LocalTrade'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launchURL('https://localtrade.app/tutorials'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Help Center'),
                subtitle: const Text('Browse our knowledge base'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _launchURL('https://localtrade.app/help'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    final issueTypeController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report an Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Issue Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bug',
                      child: Text('Bug / Technical Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'feature',
                      child: Text('Feature Request'),
                    ),
                    DropdownMenuItem(
                      value: 'account',
                      child: Text('Account Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'payment',
                      child: Text('Payment Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: issueTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Issue Title',
                    hintText: 'Brief description of the issue',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description',
                    hintText: 'Please provide as much detail as possible',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategory == null ||
                    issueTypeController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                // In a real app, this would send the report to a backend
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Issue reported successfully. We\'ll get back to you soon.'),
                  ),
                );

                // Optionally, send via email
                _launchEmail('support@localtrade.app');
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

