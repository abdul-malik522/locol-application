import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'About'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.store,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'LocalTrade',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // App Tagline
            Text(
              'Connecting local sellers with restaurants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Version Info
            _buildInfoCard(
              context,
              'Version',
              '1.0.0',
              Icons.info_outline,
            ),
            const SizedBox(height: 16),
            // Build Number
            _buildInfoCard(
              context,
              'Build',
              '1',
              Icons.build_outlined,
            ),
            const SizedBox(height: 32),
            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About LocalTrade',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LocalTrade is a modern marketplace platform that connects local sellers and farmers with restaurants. '
                      'Our mission is to facilitate local commerce, support sustainable food systems, and help local businesses thrive.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Built with Flutter and designed with Material Design 3, LocalTrade provides an intuitive, '
                      'social-first experience for discovering and trading local products.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Credits Section
            Text(
              'Credits & Acknowledgments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildCreditItem(
                    context,
                    'Framework',
                    'Flutter',
                    'https://flutter.dev',
                  ),
                  const Divider(),
                  _buildCreditItem(
                    context,
                    'State Management',
                    'Riverpod',
                    'https://riverpod.dev',
                  ),
                  const Divider(),
                  _buildCreditItem(
                    context,
                    'Navigation',
                    'go_router',
                    'https://pub.dev/packages/go_router',
                  ),
                  const Divider(),
                  _buildCreditItem(
                    context,
                    'UI Design',
                    'Material Design 3',
                    'https://m3.material.io',
                  ),
                  const Divider(),
                  _buildCreditItem(
                    context,
                    'Fonts',
                    'Google Fonts',
                    'https://fonts.google.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Links Section
            Text(
              'Links',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Website'),
                    subtitle: const Text('www.localtrade.app'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _launchURL('https://www.localtrade.app'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Contact Us'),
                    subtitle: const Text('info@localtrade.app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchURL('mailto:info@localtrade.app'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report a Bug'),
                    subtitle: const Text('Help us improve'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchURL('mailto:support@localtrade.app?subject=Bug Report'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Copyright
            Text(
              '© ${DateTime.now().year} LocalTrade',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              'All rights reserved',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem(
    BuildContext context,
    String category,
    String name,
    String url,
  ) {
    return ListTile(
      title: Text(category),
      subtitle: Text(name),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _launchURL(url),
    );
  }
}

