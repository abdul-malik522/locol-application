import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:localtrade/core/widgets/loading_indicator.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => placeholder ??
            const ShimmerLoading(
              child: SizedBox.expand(),
            ),
        errorWidget: (_, __, ___) =>
            errorWidget ??
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Icon(Icons.broken_image),
            ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: placeholder ??
          const Icon(
            Icons.image,
            color: Colors.white54,
          ),
    );
  }
}

