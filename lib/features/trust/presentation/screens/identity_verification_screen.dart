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
import 'package:localtrade/features/trust/data/models/identity_verification_model.dart';
import 'package:localtrade/features/trust/providers/trust_provider.dart';
import 'package:uuid/uuid.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _documentCountryController = TextEditingController();
  
  DateTime? _dateOfBirth;
  IdentityDocumentType? _selectedDocumentType;
  File? _documentFront;
  File? _documentBack;
  File? _selfie;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _documentNumberController.dispose();
    _documentCountryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingVerification() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final verificationAsync = await ref.read(identityVerificationProvider(currentUser.id).future);
    if (verificationAsync != null) {
      setState(() {
        _fullNameController.text = verificationAsync.fullName;
        _documentNumberController.text = verificationAsync.documentNumber;
        _documentCountryController.text = verificationAsync.documentIssuingCountry;
        _dateOfBirth = verificationAsync.dateOfBirth;
        _selectedDocumentType = verificationAsync.documentType;
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _pickDocumentFront() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _documentFront = File(image.path);
      });
    }
  }

  Future<void> _pickDocumentBack() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _documentBack = File(image.path);
      });
    }
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selfie = File(image.path);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    if (_selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select document type')),
      );
      return;
    }
    if (_documentFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload document front image')),
      );
      return;
    }
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie for verification')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // In a real app, upload documents to server and get URLs
      final verification = IdentityVerificationModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        documentType: _selectedDocumentType!,
        documentNumber: _documentNumberController.text.trim(),
        documentIssuingCountry: _documentCountryController.text.trim(),
        documentFrontUrl: _documentFront?.path,
        documentBackUrl: _documentBack?.path,
        selfieUrl: _selfie?.path,
        status: IdentityVerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      final dataSource = ref.read(identityVerificationDataSourceProvider);
      await dataSource.submitVerification(verification);

      // Refresh provider
      ref.invalidate(identityVerificationProvider(currentUser.id));

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
        appBar: CustomAppBar(title: 'Identity Verification'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final verificationAsync = ref.watch(identityVerificationProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Identity Verification (KYC)'),
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
          onRetry: () => ref.invalidate(identityVerificationProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildApprovedView(BuildContext context, IdentityVerificationModel verification) {
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
                Icon(Icons.verified_user, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Identity Verified!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your identity has been verified. This enables you to participate in high-value transactions.',
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

  Widget _buildPendingView(BuildContext context, IdentityVerificationModel verification) {
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
                  'Your identity verification is being reviewed. You will be notified once the review is complete.',
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

  Widget _buildRejectedView(BuildContext context, IdentityVerificationModel verification) {
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
                    ref.invalidate(identityVerificationProvider(verification.userId));
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
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your identity information for KYC verification. This is required for high-value transactions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full legal name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateOfBirth,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select date of birth',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Identity Document',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IdentityDocumentType>(
              value: _selectedDocumentType,
              decoration: InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: IdentityDocumentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDocumentType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select document type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _documentNumberController,
              label: 'Document Number',
              hint: 'Enter your document number',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Document number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _documentCountryController,
              label: 'Issuing Country',
              hint: 'Enter country where document was issued',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Issuing country is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Document Front',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_documentFront == null ? 'Upload Document Front' : 'Document Selected'),
              onPressed: _pickDocumentFront,
            ),
            if (_documentFront != null) ...[
              const SizedBox(height: 8),
              Text(
                _documentFront!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Document Back (if applicable)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_documentBack == null ? 'Upload Document Back' : 'Document Selected'),
              onPressed: _pickDocumentBack,
            ),
            if (_documentBack != null) ...[
              const SizedBox(height: 8),
              Text(
                _documentBack!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Selfie Verification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please take a selfie holding your identity document next to your face.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_selfie == null ? 'Take Selfie' : 'Selfie Taken'),
              onPressed: _pickSelfie,
            ),
            if (_selfie != null) ...[
              const SizedBox(height: 8),
              Image.file(_selfie!, height: 200, fit: BoxFit.cover),
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

