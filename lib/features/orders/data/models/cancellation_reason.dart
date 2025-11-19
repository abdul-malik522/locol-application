import 'package:flutter/material.dart';

enum CancellationReason {
  changedMind('Changed my mind', Icons.undo),
  foundBetterPrice('Found a better price', Icons.attach_money),
  noLongerNeeded('No longer needed', Icons.remove_circle_outline),
  deliveryTooSlow('Delivery too slow', Icons.schedule),
  productUnavailable('Product unavailable', Icons.inventory_2_outlined),
  sellerUnresponsive('Seller unresponsive', Icons.person_off_outlined),
  wrongProduct('Wrong product ordered', Icons.error_outline),
  duplicateOrder('Duplicate order', Icons.content_copy),
  paymentIssue('Payment issue', Icons.payment),
  other('Other', Icons.more_horiz);

  const CancellationReason(this.label, this.icon);
  final String label;
  final IconData icon;
}

