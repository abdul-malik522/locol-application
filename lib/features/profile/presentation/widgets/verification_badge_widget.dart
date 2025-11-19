import 'package:flutter/material.dart';
import 'package:localtrade/features/profile/data/models/verification_badge_model.dart';

/// Widget to display a single verification badge
class VerificationBadgeWidget extends StatelessWidget {
  const VerificationBadgeWidget({
    required this.badge,
    this.size = 16,
    this.showLabel = false,
    super.key,
  });

  final VerificationBadgeModel badge;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badge.type.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badge.type.color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.type.icon,
              size: size,
              color: badge.type.color,
            ),
            const SizedBox(width: 4),
            Text(
              badge.type.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: badge.type.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: badge.type.label,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: badge.type.color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: badge.type.color, width: 1.5),
        ),
        child: Icon(
          badge.type.icon,
          size: size,
          color: badge.type.color,
        ),
      ),
    );
  }
}

/// Widget to display multiple verification badges
class VerificationBadgesWidget extends StatelessWidget {
  const VerificationBadgesWidget({
    required this.badges,
    this.size = 16,
    this.spacing = 4,
    this.showLabel = false,
    super.key,
  });

  final List<VerificationBadgeModel> badges;
  final double size;
  final double spacing;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .map((badge) => Padding(
                padding: EdgeInsets.only(right: spacing),
                child: VerificationBadgeWidget(
                  badge: badge,
                  size: size,
                  showLabel: showLabel,
                ),
              ))
          .toList(),
    );
  }
}

