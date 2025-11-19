import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/models/delivery_address_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class DeliveryAddressesScreen extends ConsumerStatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  ConsumerState<DeliveryAddressesScreen> createState() => _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends ConsumerState<DeliveryAddressesScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Delivery Addresses'),
        body: Center(child: Text('Please login to view addresses')),
      );
    }

    final addressesAsync = ref.watch(deliveryAddressesProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Delivery Addresses'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deliveryAddressesProvider(currentUser.id));
        },
        child: addressesAsync.when(
          data: (addresses) {
            if (addresses.isEmpty) {
              return const EmptyState(
                icon: Icons.location_on_outlined,
                title: 'No Saved Addresses',
                message: 'Add delivery addresses for quick checkout.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length + 1, // +1 for "Add New" button
              itemBuilder: (context, index) {
                if (index == addresses.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomButton(
                      text: 'Add New Address',
                      onPressed: () => _showAddEditAddressDialog(context, null, currentUser.id),
                      variant: CustomButtonVariant.outlined,
                      fullWidth: true,
                    ),
                  );
                }
                final address = addresses[index];
                return _buildAddressCard(context, ref, address, currentUser.id);
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => ErrorView(
            error: error.toString(),
            onRetry: () => ref.invalidate(deliveryAddressesProvider(currentUser.id)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            _showAddEditAddressDialog(context, null, currentUser.id);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddressModel address,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showAddEditAddressDialog(context, address, userId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAddressIcon(address.label),
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          address.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Default',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditAddressDialog(context, address, userId);
                      } else if (value == 'set_default') {
                        _setDefaultAddress(context, ref, address.id, userId);
                      } else if (value == 'delete') {
                        _deleteAddress(context, ref, address.id, userId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (!address.isDefault)
                        const PopupMenuItem(
                          value: 'set_default',
                          child: Row(
                            children: [
                              Icon(Icons.star),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address.fullAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (address.phoneNumber != null && address.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      address.phoneNumber!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (address.notes != null && address.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  address.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home')) return Icons.home;
    if (lowerLabel.contains('work')) return Icons.work;
    if (lowerLabel.contains('restaurant') || lowerLabel.contains('business')) return Icons.business;
    return Icons.location_on;
  }

  void _showAddEditAddressDialog(
    BuildContext context,
    DeliveryAddressModel? address,
    String userId,
  ) {
    final isEditing = address != null;
    final labelController = TextEditingController(text: address?.label ?? '');
    final addressController = TextEditingController(text: address?.address ?? '');
    final apartmentController = TextEditingController(text: address?.apartment ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final stateController = TextEditingController(text: address?.state ?? '');
    final zipCodeController = TextEditingController(text: address?.zipCode ?? '');
    final countryController = TextEditingController(text: address?.country ?? '');
    final phoneController = TextEditingController(text: address?.phoneNumber ?? '');
    final notesController = TextEditingController(text: address?.notes ?? '');
    bool isDefault = address?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: labelController,
                  label: 'Label',
                  hint: 'e.g., Home, Work, Restaurant',
                  validator: (value) => Validators.validateRequired(value, 'label'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Street Address',
                  hint: '123 Main Street',
                  validator: (value) => Validators.validateRequired(value, 'address'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: apartmentController,
                  label: 'Apartment, Suite, etc. (Optional)',
                  hint: 'Apt 4B',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: cityController,
                        label: 'City',
                        hint: 'City',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: stateController,
                        label: 'State',
                        hint: 'State',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: zipCodeController,
                        label: 'Zip Code',
                        hint: '12345',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: countryController,
                        label: 'Country',
                        hint: 'Country',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: phoneController,
                  label: 'Phone Number (Optional)',
                  hint: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: notesController,
                  label: 'Notes (Optional)',
                  hint: 'Additional delivery instructions',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: isDefault,
                  onChanged: (value) {
                    setState(() => isDefault = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a label')),
                  );
                  return;
                }
                if (addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an address')),
                  );
                  return;
                }

                try {
                  final dataSource = ref.read(deliveryAddressesDataSourceProvider);
                  final newAddress = DeliveryAddressModel(
                    id: address?.id ?? const Uuid().v4(),
                    userId: userId,
                    label: labelController.text.trim(),
                    address: addressController.text.trim(),
                    apartment: apartmentController.text.trim().isEmpty
                        ? null
                        : apartmentController.text.trim(),
                    city: cityController.text.trim().isEmpty
                        ? null
                        : cityController.text.trim(),
                    state: stateController.text.trim().isEmpty
                        ? null
                        : stateController.text.trim(),
                    zipCode: zipCodeController.text.trim().isEmpty
                        ? null
                        : zipCodeController.text.trim(),
                    country: countryController.text.trim().isEmpty
                        ? null
                        : countryController.text.trim(),
                    phoneNumber: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    isDefault: isDefault,
                  );

                  await dataSource.saveAddress(newAddress);
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Address updated successfully'
                              : 'Address added successfully',
                        ),
                      ),
                    );
                    ref.invalidate(deliveryAddressesProvider(userId));
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save address: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _setDefaultAddress(
    BuildContext context,
    WidgetRef ref,
    String addressId,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(deliveryAddressesDataSourceProvider);
      await dataSource.setDefaultAddress(addressId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated')),
        );
        ref.invalidate(deliveryAddressesProvider(userId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default address: ${e.toString()}')),
        );
      }
    }
  }

  void _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    String addressId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final dataSource = ref.read(deliveryAddressesDataSourceProvider);
                await dataSource.deleteAddress(addressId, userId);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address deleted')),
                  );
                  ref.invalidate(deliveryAddressesProvider(userId));
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete address: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

