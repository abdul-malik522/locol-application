import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/image_helper.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  const EditPostScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  String? _selectedCategory;
  String? _location;
  Position? _position;
  bool _isSubmitting = false;
  PostModel? _originalPost;
  bool _hasExpiration = false;
  DateTime? _expirationDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _loadPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final postAsync = ref.read(postByIdProvider(widget.postId));
    postAsync.whenData((post) {
      if (post != null && mounted) {
        setState(() {
          _originalPost = post;
          _titleController.text = post.title;
          _descriptionController.text = post.description;
          _priceController.text = post.price?.toString() ?? '';
          _quantityController.text = post.quantity ?? '';
          _selectedCategory = post.category;
          _existingImageUrls = List.from(post.imageUrls);
          _location = post.location;
          _position = Position(
            latitude: post.latitude,
            longitude: post.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _hasExpiration = post.expiresAt != null;
          _expirationDateTime = post.expiresAt;
        });
      }
    });
  }

  Future<void> _pickImages() async {
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
                final images = await ImageHelper.pickMultipleImages(5);
                if (images != null && images.isNotEmpty) {
                  setState(() {
                    _newImages = images;
                  });
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
                  setState(() {
                    _newImages = [image];
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _pickLocation() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position != null) {
      setState(() {
        _position = position;
        _location = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lon: ${position.longitude.toStringAsFixed(4)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch location')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _originalPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update post')),
      );
      return;
    }

    // Check if user owns the post
    if (currentUser.id != _originalPost.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only edit your own posts')),
      );
      return;
    }

    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep at least one image')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // In a real app, we would upload new images to a server
      // For now, we'll use placeholder URLs for new images
      final newImageUrls = _newImages
          .map((img) => 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + _newImages.indexOf(img)}')
          .toList();

      // Combine existing and new image URLs
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final updatedPost = _originalPost!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: allImageUrls,
        category: _selectedCategory!,
        price: _originalPost!.postType == PostType.product && _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        quantity: _quantityController.text.trim().isNotEmpty
            ? _quantityController.text.trim()
            : null,
        location: _location ?? _originalPost!.location,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        expiresAt: _hasExpiration ? _expirationDateTime : null,
      );

      await ref.read(postsProvider.notifier).updatePost(updatedPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post: ${e.toString()}')),
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
    final postAsync = ref.watch(postByIdProvider(widget.postId));

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return const Scaffold(
            appBar: CustomAppBar(title: 'Edit Post'),
            body: Center(child: Text('Post not found')),
          );
        }

        // Check if user owns the post
        if (currentUser?.id != post.userId) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Edit Post'),
            body: const Center(
              child: Text('You can only edit your own posts'),
            ),
          );
        }

        final isSeller = post.postType == PostType.product;

        return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Post',
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
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
              _buildImagePicker(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter post title',
                validator: (value) => Validators.validateRequired(value, 'title'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your product or request...',
                validator: (value) => Validators.validateRequired(
                  value,
                  'description',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              if (isSeller) ...[
                CustomTextField(
                  controller: _priceController,
                  label: 'Price',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required for products';
                    }
                    return Validators.validatePrice(value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _quantityController,
                label: isSeller ? 'Quantity Available' : 'Quantity Needed',
                hint: isSeller ? 'e.g., 10 kg, 5 pieces' : 'e.g., 20 kg',
                validator: (value) => Validators.validateRequired(
                  value,
                  'quantity',
                ),
              ),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildExpirationSection(),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Update Post',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final totalImages = _existingImageUrls.length + _newImages.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalImages + (totalImages < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              // Add new image button
              if (index == totalImages) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Image',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Existing images (from network)
              if (index < _existingImageUrls.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _existingImageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeExistingImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // New images (from file)
              final newImageIndex = index - _existingImageUrls.length;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _newImages[newImageIndex],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeNewImage(newImageIndex),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (totalImages == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Add at least one image (max 5)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.category),
      ),
      items: AppConstants.categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (_location != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _location!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickLocation,
                  child: const Text('Update'),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
      ],
    );
  }

  Widget _buildExpirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Set Expiration Date'),
          subtitle: Text(
            _hasExpiration && _expirationDateTime != null
                ? 'Expires on ${_formatExpirationDate(_expirationDateTime!)}'
                : 'Automatically remove this post after a specific date',
          ),
          value: _hasExpiration,
          onChanged: (value) {
            setState(() {
              _hasExpiration = value;
              if (value && _expirationDateTime == null) {
                _expirationDateTime = DateTime.now().add(const Duration(days: 7));
              } else if (!value) {
                _expirationDateTime = null;
              }
            });
          },
        ),
        if (_hasExpiration) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _selectExpirationDate(context),
            icon: const Icon(Icons.event_busy),
            label: Text(
              _expirationDateTime != null
                  ? 'Change Expiration: ${_formatExpirationDate(_expirationDateTime!)}'
                  : 'Select Expiration Date',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (_expirationDateTime != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _expirationDateTime!.isBefore(DateTime.now().add(const Duration(days: 3)))
                    ? Colors.orange.withOpacity(0.1)
                    : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _expirationDateTime!.isBefore(DateTime.now().add(const Duration(days: 3)))
                      ? Colors.orange
                      : Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: _expirationDateTime!.isBefore(DateTime.now().add(const Duration(days: 3)))
                        ? Colors.orange
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _expirationDateTime!.isBefore(DateTime.now().add(const Duration(days: 3)))
                          ? 'Post will expire soon (less than 3 days)'
                          : 'Post will expire on ${_formatExpirationDate(_expirationDateTime!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDateTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _expirationDateTime != null
          ? TimeOfDay.fromDateTime(_expirationDateTime!)
          : const TimeOfDay(hour: 23, minute: 59),
    );

    if (pickedTime == null) return;

    final expiration = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (expiration.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiration date must be in the future'),
          ),
        );
      }
      return;
    }

    setState(() {
      _expirationDateTime = expiration;
    });
  }

  String _formatExpirationDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
      },
      loading: () => const Scaffold(
        appBar: CustomAppBar(title: 'Edit Post'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: const CustomAppBar(title: 'Edit Post'),
        body: Center(child: Text('Error loading post: $error')),
      ),
    );
  }

