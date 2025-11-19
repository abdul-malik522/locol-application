import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/trust/data/models/business_verification_model.dart';
import 'package:localtrade/features/trust/providers/trust_provider.dart';
import 'package:uuid/uuid.dart';

class BusinessVerificationScreen extends ConsumerStatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  ConsumerState<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends ConsumerState<BusinessVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseAuthorityController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  File? _licenseDocument;
  File? _taxDocument;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _licenseNumberController.dispose();
    _licenseAuthorityController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingVerification() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final verificationAsync = await ref.read(businessVerificationProvider(currentUser.id).future);
    if (verificationAsync != null) {
      setState(() {
        _businessNameController.text = verificationAsync.businessName;
        _businessTypeController.text = verificationAsync.businessType;
        _licenseNumberController.text = verificationAsync.licenseNumber;
        _licenseAuthorityController.text = verificationAsync.licenseIssuingAuthority;
        _taxIdController.text = verificationAsync.taxIdNumber ?? '';
      });
    }
  }

  Future<void> _pickLicenseDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _licenseDocument = File(image.path);
      });
    }
  }

  Future<void> _pickTaxDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _taxDocument = File(image.path);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a license document')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // In a real app, upload documents to server and get URLs
      // For mock, we'll use local file paths
      final verification = BusinessVerificationModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        businessName: _businessNameController.text.trim(),
        businessType: _businessTypeController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        licenseIssuingAuthority: _licenseAuthorityController.text.trim(),
        licenseDocumentUrl: _licenseDocument?.path,
        taxIdNumber: _taxIdController.text.trim().isNotEmpty ? _taxIdController.text.trim() : null,
        taxDocumentUrl: _taxDocument?.path,
        status: BusinessVerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      final dataSource = ref.read(businessVerificationDataSourceProvider);
      await dataSource.submitVerification(verification);

      // Refresh provider
      ref.invalidate(businessVerificationProvider(currentUser.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted! Our team will review it shortly.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit verification: ${e.toString()}')),
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
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Business Verification'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final verificationAsync = ref.watch(businessVerificationProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Business Verification'),
      body: verificationAsync.when(
        data: (verification) {
          if (verification != null && verification.isApproved) {
            return _buildApprovedView(context, verification);
          }
          if (verification != null && verification.isPending) {
            return _buildPendingView(context, verification);
          }
          if (verification != null && verification.isRejected) {
            return _buildRejectedView(context, verification);
          }
          return _buildForm(context);
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(businessVerificationProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildApprovedView(BuildContext context, BusinessVerificationModel verification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Business Verified!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your business has been verified and you now have a verification badge on your profile.',
                  textAlign: TextAlign.center,
                ),
                if (verification.reviewedAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Verified on: ${verification.reviewedAt!.toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView(BuildContext context, BusinessVerificationModel verification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Verification Under Review',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your verification request is being reviewed by our team. You will be notified once the review is complete.',
                  textAlign: TextAlign.center,
                ),
                if (verification.submittedAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Submitted on: ${verification.submittedAt!.toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedView(BuildContext context, BusinessVerificationModel verification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.cancel, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Verification Rejected',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (verification.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reason:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verification.rejectionReason!,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Resubmit Verification',
                  onPressed: () {
                    ref.invalidate(businessVerificationProvider(verification.userId));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your business details and upload required documents for verification.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _businessNameController,
              label: 'Business Name',
              hint: 'Enter your business name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _businessTypeController,
              label: 'Business Type',
              hint: 'e.g., Farm, Restaurant, Producer',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business type is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'License Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _licenseNumberController,
              label: 'License Number',
              hint: 'Enter your business license number',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'License number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _licenseAuthorityController,
              label: 'Issuing Authority',
              hint: 'e.g., State Department of Agriculture',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Issuing authority is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'License Document',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_licenseDocument == null ? 'Upload License Document' : 'Document Selected'),
              onPressed: _pickLicenseDocument,
            ),
            if (_licenseDocument != null) ...[
              const SizedBox(height: 8),
              Text(
                _licenseDocument!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Tax Information (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _taxIdController,
              label: 'Tax ID Number',
              hint: 'Enter your tax ID (optional)',
            ),
            const SizedBox(height: 16),
            Text(
              'Tax Document (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_taxDocument == null ? 'Upload Tax Document' : 'Document Selected'),
              onPressed: _pickTaxDocument,
            ),
            if (_taxDocument != null) ...[
              const SizedBox(height: 8),
              Text(
                _taxDocument!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit for Verification',
              onPressed: _isSubmitting ? null : _submitVerification,
              isLoading: _isSubmitting,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

