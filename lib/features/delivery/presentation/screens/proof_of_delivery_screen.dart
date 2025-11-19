import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/delivery/data/models/delivery_model.dart';
import 'package:localtrade/features/delivery/providers/delivery_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProofOfDeliveryScreen extends ConsumerStatefulWidget {
  const ProofOfDeliveryScreen({
    required this.deliveryId,
    super.key,
  });

  final String deliveryId;

  @override
  ConsumerState<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends ConsumerState<ProofOfDeliveryScreen> {
  File? _proofPhoto;
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _proofPhoto = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitProof() async {
    if (_proofPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo as proof of delivery')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deliveryAsync = await ref.read(deliveryByIdProvider(widget.deliveryId).future);
      if (deliveryAsync == null) {
        throw Exception('Delivery not found');
      }

      // Save photo to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'proof_${widget.deliveryId}_${const Uuid().v4()}.jpg';
      final savedFile = await _proofPhoto!.copy('${directory.path}/$fileName');

      // Update delivery with proof photo
      final dataSource = ref.read(deliveryDataSourceProvider);
      await dataSource.updateDelivery(
        deliveryAsync.copyWith(
          status: DeliveryStatus.delivered,
          proofOfDeliveryPhoto: savedFile.path,
          actualDeliveryTime: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof of delivery submitted successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit proof: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(widget.deliveryId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Proof of Delivery'),
      body: deliveryAsync.when(
        data: (delivery) {
          if (delivery == null) {
            return const ErrorView(error: 'Delivery not found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take a photo as proof of delivery',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This photo will be used to confirm that the order was delivered successfully.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_proofPhoto != null)
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _proofPhoto!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No photo taken',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  text: _proofPhoto != null ? 'Retake Photo' : 'Take Photo',
                  icon: Icons.camera_alt,
                  onPressed: _pickPhoto,
                  fullWidth: true,
                ),
                if (delivery.proofOfDeliveryPhoto != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Current Proof of Delivery:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: File(delivery.proofOfDeliveryPhoto!).existsSync()
                          ? Image.file(
                              File(delivery.proofOfDeliveryPhoto!),
                              fit: BoxFit.cover,
                            )
                          : const Center(child: Text('Photo not found')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(delivery.actualDeliveryTime ?? delivery.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 32),
                if (_proofPhoto != null)
                  CustomButton(
                    text: 'Submit Proof of Delivery',
                    onPressed: _isSubmitting ? null : _submitProof,
                    isLoading: _isSubmitting,
                    fullWidth: true,
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(deliveryByIdProvider(widget.deliveryId)),
        ),
      ),
    );
  }
}

