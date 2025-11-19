import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/custom_button.dart';

class SocialLoginRoleDialog extends ConsumerWidget {
  const SocialLoginRoleDialog({
    super.key,
    required this.onRoleSelected,
  });

  final void Function(UserRole role) onRoleSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Select Your Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please select your role to continue. You can change this later in your profile settings.',
          ),
          const SizedBox(height: 20),
          _buildRoleOption(
            context,
            UserRole.seller,
            Icons.store,
            'Seller / Farmer',
            'I want to sell products',
            () {
              Navigator.pop(context);
              onRoleSelected(UserRole.seller);
            },
          ),
          const SizedBox(height: 12),
          _buildRoleOption(
            context,
            UserRole.restaurant,
            Icons.restaurant,
            'Restaurant',
            'I want to buy products',
            () {
              Navigator.pop(context);
              onRoleSelected(UserRole.restaurant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    UserRole role,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

