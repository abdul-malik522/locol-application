import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/data/models/message_model.dart';
import 'package:localtrade/features/messages/presentation/widgets/voice_message_player.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.isSentByMe,
    this.searchQuery,
    super.key,
  });

  final MessageModel message;
  final bool isSentByMe;
  final String? searchQuery; // For highlighting search results

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showReactionPicker(context, ref),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSentByMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
              bottomRight: Radius.circular(isSentByMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (message.isImageMessage && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: message.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else if (message.isVoiceMessage && message.audioUrl != null && message.durationSeconds != null)
              VoiceMessagePlayer(
                audioUrl: message.audioUrl!,
                durationSeconds: message.durationSeconds!,
                isSentByMe: isSentByMe,
              )
            else if (message.isLocationMessage && message.latitude != null && message.longitude != null)
              _buildLocationMessage(context, message)
            else if (message.isTextMessage && message.text != null)
              _buildHighlightedText(
                message.text!,
                isSentByMe,
              )
            else if (message.isOrderMessage)
              _buildOrderMessage(context)
            else if (message.isPriceOfferMessage && message.priceOfferData != null)
              _buildPriceOfferMessage(context, ref),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.createdAt),
                  style: TextStyle(
                    color: isSentByMe
                        ? Colors.white70
                        : Theme.of(context).colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
                if (isSentByMe) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: message.isRead
                        ? (message.readAt != null
                            ? 'Read ${timeago.format(message.readAt!)}'
                            : 'Read')
                        : 'Sent',
                    child: Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? Colors.blue : Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMessage(BuildContext context) {
    if (message.orderData == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Order information unavailable',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final orderId = message.orderData!['id'] as String? ?? message.orderData!['orderId'] as String?;
    final orderNumber = message.orderData!['orderNumber'] as String? ?? 'N/A';
    final productName = message.orderData!['productName'] as String? ?? 'Unknown Product';
    final quantity = message.orderData!['quantity'] as String? ?? '1';
    final price = (message.orderData!['price'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (message.orderData!['totalAmount'] as num?)?.toDouble() ?? price;
    final statusString = message.orderData!['status'] as String? ?? 'pending';
    final productImage = message.orderData!['productImage'] as String?;
    final status = _parseOrderStatus(statusString);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order #$orderNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildStatusChip(context, status),
            ],
          ),
          const SizedBox(height: 12),
          if (productImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImage(
                imageUrl: productImage,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildOrderDetailRow(
            context,
            Icons.inventory_2,
            'Product',
            productName,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOrderDetailRow(
                  context,
                  Icons.scale,
                  'Quantity',
                  quantity,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOrderDetailRow(
                  context,
                  Icons.attach_money,
                  'Price',
                  '\$${price.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildOrderDetailRow(
            context,
            Icons.payments,
            'Total',
            '\$${totalAmount.toStringAsFixed(2)}',
            isBold: true,
          ),
          const SizedBox(height: 12),
          if (orderId != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/order/$orderId');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Order Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status) {
    Color statusColor;
    switch (status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.accepted:
        statusColor = Colors.blue;
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildOrderDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  OrderStatus _parseOrderStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  Widget _buildPriceOfferMessage(BuildContext context, WidgetRef ref) {
    final offerData = PriceOfferData.fromJson(message.priceOfferData!);
    final discount = ((offerData.originalPrice - offerData.offeredPrice) /
            offerData.originalPrice *
            100)
        .toStringAsFixed(1);
    final isPending = offerData.status == PriceOfferStatus.pending;
    final isAccepted = offerData.status == PriceOfferStatus.accepted;
    final isRejected = offerData.status == PriceOfferStatus.rejected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccepted
              ? Colors.green
              : isRejected
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Price Offer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
              else if (isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Accepted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
              else if (isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rejected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          if (offerData.postTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              offerData.postTitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Price',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${offerData.originalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Offered Price',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${offerData.offeredPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_down,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$discount% discount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          if (offerData.message != null && offerData.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              offerData.message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (isPending && !isSentByMe) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectOffer(context, ref),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOffer(context, ref),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => _showCounterOfferDialog(context, ref, offerData),
                child: const Text('Make Counter Offer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _acceptOffer(BuildContext context, WidgetRef ref) {
    final chatId = message.chatId;
    ref.read(chatMessagesProvider(chatId).notifier).respondToPriceOffer(
          message.id,
          PriceOfferStatus.accepted,
          null,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price offer accepted')),
    );
  }

  void _rejectOffer(BuildContext context, WidgetRef ref) {
    final chatId = message.chatId;
    ref.read(chatMessagesProvider(chatId).notifier).respondToPriceOffer(
          message.id,
          PriceOfferStatus.rejected,
          null,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price offer rejected')),
    );
  }

  void _showCounterOfferDialog(
    BuildContext context,
    WidgetRef ref,
    PriceOfferData originalOffer,
  ) {
    final counterPriceController = TextEditingController(
      text: originalOffer.offeredPrice.toStringAsFixed(2),
    );
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Counter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: counterPriceController,
              decoration: const InputDecoration(
                labelText: 'Your Price',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'Add a note to your offer...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final counterPrice = double.tryParse(counterPriceController.text);
              if (counterPrice != null && counterPrice > 0) {
                final counterOffer = PriceOfferData(
                  originalPrice: originalOffer.originalPrice,
                  offeredPrice: counterPrice,
                  postId: originalOffer.postId,
                  postTitle: originalOffer.postTitle,
                  quantity: originalOffer.quantity,
                  message: messageController.text.trim().isEmpty
                      ? null
                      : messageController.text.trim(),
                );

                final chatId = message.chatId;
                final currentUser = ref.read(currentUserProvider);
                if (currentUser == null) {
                  Navigator.pop(context);
                  return;
                }

                final chatMessagesNotifier = ref.read(chatMessagesProvider(chatId).notifier);
                
                // Update original offer status
                await chatMessagesNotifier.respondToPriceOffer(
                  message.id,
                  PriceOfferStatus.counterOffered,
                  null,
                );

                // Send counter offer as new message
                await chatMessagesNotifier.sendPriceOffer(
                  counterOffer,
                  currentUser.id,
                  currentUser.name,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Counter offer sent')),
                );
              }
            },
            child: const Text('Send Counter Offer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context, MessageModel message) {
    final lat = message.latitude!;
    final lng = message.longitude!;
    final locationName = message.locationName ?? 'Shared Location';
    
    // Generate static map URL using OpenStreetMap (free, no API key required)
    // In a real app, you might use Google Maps Static API, Mapbox, etc.
    final mapImageUrl = 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=300x200&markers=$lat,$lng,red-pushpin';

    return InkWell(
      onTap: () async {
        // Open location in maps app
        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open maps')),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSentByMe
                ? Colors.white.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                mapImageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: isSentByMe
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          style: TextStyle(
                            color: isSentByMe ? Colors.white : null,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: isSentByMe ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: isSentByMe ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            // Reactions display
            if (message.reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildReactions(context, ref),
            ],
          ],
        ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Reaction',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: quickReactions.map((emoji) {
                final hasReacted = message.reactions[emoji]?.contains(currentUser.id) ?? false;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(chatMessagesProvider(message.chatId).notifier).toggleReaction(
                      message.id,
                      emoji,
                      currentUser.id,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasReacted
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: hasReacted
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final hasReacted = users.contains(currentUser.id);
        
        return GestureDetector(
          onTap: () {
            ref.read(chatMessagesProvider(message.chatId).notifier).toggleReaction(
              message.id,
              emoji,
              currentUser.id,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: hasReacted
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                if (users.length > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasReacted
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightedText(String text, bool isSentByMe) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isSentByMe ? Colors.white : null,
          fontSize: 15,
        ),
      );
    }

    final query = searchQuery!.toLowerCase();
    final textLower = text.toLowerCase();
    final matches = <_TextMatch>[];

    int startIndex = 0;
    while (startIndex < textLower.length) {
      final index = textLower.indexOf(query, startIndex);
      if (index == -1) break;
      matches.add(_TextMatch(index, index + query.length));
      startIndex = index + 1;
    }

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isSentByMe ? Colors.white : null,
          fontSize: 15,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: isSentByMe ? Colors.white : null,
            fontSize: 15,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          color: isSentByMe ? Colors.white : null,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: isSentByMe ? Colors.white : null,
          fontSize: 15,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class _TextMatch {
  final int start;
  final int end;

  _TextMatch(this.start, this.end);
}
