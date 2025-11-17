import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/utils/image_helper.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  File? _coverImage;
  Position? _position;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _businessNameController.text = currentUser.businessName ?? '';
      _businessDescriptionController.text =
          currentUser.businessDescription ?? '';
      _phoneController.text = currentUser.phoneNumber ?? '';
      _addressController.text = currentUser.address ?? '';
      _isActive = currentUser.isActive;
      if (currentUser.latitude != null && currentUser.longitude != null) {
        _position = Position(
          latitude: currentUser.latitude!,
          longitude: currentUser.longitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromGallery();
                if (image != null) {
                  setState(() => _profileImage = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromCamera();
                if (image != null) {
                  setState(() => _profileImage = image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromGallery();
                if (image != null) {
                  setState(() => _coverImage = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromCamera();
                if (image != null) {
                  setState(() => _coverImage = image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position != null) {
      setState(() => _position = position);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch location')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'businessDescription': _businessDescriptionController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'isActive': _isActive,
        if (_position != null) 'latitude': _position!.latitude,
        if (_position != null) 'longitude': _position!.longitude,
        // In a real app, upload images and get URLs
        if (_profileImage != null)
          'profileImageUrl':
              'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch}',
        if (_coverImage != null)
          'coverImageUrl':
              'https://picsum.photos/400/200?random=${DateTime.now().millisecondsSinceEpoch}',
      };

      await ref.read(authProvider.notifier).updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isSeller = currentUser?.isSeller ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Profile',
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImageSection(context),
              const SizedBox(height: 16),
              _buildProfileImageSection(context),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'Your Name',
                validator: (value) => Validators.validateRequired(value, 'name'),
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _businessNameController,
                label: isSeller ? 'Farm / Business Name' : 'Restaurant Name',
                validator: (value) =>
                    Validators.validateRequired(value, 'business name'),
                prefixIcon: Icons.business_center_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _businessDescriptionController,
                label: 'Business Description',
                hint: 'Tell us about your specialties',
                maxLines: 5,
                validator: (value) => Validators.validateMinLength(
                  value,
                  10,
                  'description',
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                validator: (value) =>
                    Validators.validateRequired(value, 'address'),
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Update Location'),
              ),
              if (_position != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_position!.latitude.toStringAsFixed(4)}, '
                  'Lon: ${_position!.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (isSeller) ...[
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: const Text('Show your products in the feed'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Changes',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: _coverImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _coverImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : currentUser?.coverImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedImage(
                        imageUrl: currentUser!.coverImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image_outlined, size: 48),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: FloatingActionButton.small(
            onPressed: _pickCoverImage,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : currentUser?.profileImageUrl != null
                    ? NetworkImage(currentUser!.profileImageUrl!)
                    : null,
            child: _profileImage == null &&
                    (currentUser?.profileImageUrl == null)
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: _pickProfileImage,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
