import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:localtrade/core/theme/app_colors.dart';

enum CustomButtonVariant { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final child = _buildContent(context);
    final button = switch (variant) {
      CustomButtonVariant.primary => ElevatedButton(
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            minimumSize: fullWidth ? const Size.fromHeight(50) : null,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          ),
          child: child,
        ),
      CustomButtonVariant.secondary => ElevatedButton(
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            minimumSize: fullWidth ? const Size.fromHeight(50) : null,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.secondary.withOpacity(0.4),
          ),
          child: child,
        ),
      CustomButtonVariant.outlined => OutlinedButton(
          onPressed: _handlePress,
          style: OutlinedButton.styleFrom(
            minimumSize: fullWidth ? const Size.fromHeight(50) : null,
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.primary.withOpacity(0.4),
          ),
          child: child,
        ),
      CustomButtonVariant.text => TextButton(
          onPressed: _handlePress,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.primary.withOpacity(0.4),
          ),
          child: child,
        ),
    };

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildContent(BuildContext context) {
    final textWidget = Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: variant == CustomButtonVariant.primary ||
                    variant == CustomButtonVariant.secondary
                ? Colors.white
                : AppColors.primary,
          ),
    );

    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        textWidget,
      ],
    );
  }

  void _handlePress() {
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    onPressed?.call();
  }
}

