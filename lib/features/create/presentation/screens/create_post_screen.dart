import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/utils/image_helper.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/create/data/models/draft_post_model.dart';
import 'package:localtrade/features/create/providers/drafts_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  List<File> _selectedImages = [];
  String? _selectedCategory;
  String? _location;
  Position? _position;
  bool _isSubmitting = false;
  String? _currentDraftId;
  bool _hasUnsavedChanges = false;
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  bool _hasExpiration = false;
  DateTime? _expirationDateTime;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _setupAutoSave();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final draftsNotifier = ref.read(draftsProvider(currentUser.id).notifier);
    final currentDraft = await draftsNotifier.getCurrentDraft();
    
    if (currentDraft != null && mounted) {
      setState(() {
        _currentDraftId = currentDraft.id;
        _titleController.text = currentDraft.title;
        _descriptionController.text = currentDraft.description;
        _priceController.text = currentDraft.price?.toString() ?? '';
        _quantityController.text = currentDraft.quantity ?? '';
        _selectedCategory = currentDraft.category;
        _location = currentDraft.location;
        if (currentDraft.latitude != null && currentDraft.longitude != null) {
          _position = Position(
            latitude: currentDraft.latitude!,
            longitude: currentDraft.longitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        // Load images from draft paths (if files still exist)
        if (currentDraft.imagePaths.isNotEmpty) {
          final existingImages = <File>[];
          for (final path in currentDraft.imagePaths) {
            final file = File(path);
            if (await file.exists()) {
              existingImages.add(file);
            }
          }
          if (existingImages.isNotEmpty) {
            _selectedImages = existingImages;
          }
        }
      });
    }
  }

  void _setupAutoSave() {
    // Listen to text field changes for auto-save
    _titleController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _priceController.addListener(_markAsChanged);
    _quantityController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
      _autoSave();
    }
  }

  Future<void> _autoSave() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Debounce auto-save - wait 2 seconds after last change
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await _saveDraft(isAutoSave: true);
  }

  Future<void> _saveDraft({bool isAutoSave = false}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final draftId = _currentDraftId ?? const Uuid().v4();
    
    final draft = DraftPostModel(
      id: draftId,
      userId: currentUser.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text)
          : null,
      quantity: _quantityController.text.trim().isNotEmpty
          ? _quantityController.text.trim()
          : null,
      category: _selectedCategory,
      imagePaths: _selectedImages.map((img) => img.path).toList(),
      location: _location,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final draftsNotifier = ref.read(draftsProvider(currentUser.id).notifier);
    
    if (isAutoSave) {
      // For auto-save, only save to current draft (temporary)
      await draftsNotifier.saveCurrentDraft(draft);
    } else {
      // For manual save, save to drafts list
      await draftsNotifier.saveDraft(draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _currentDraftId = draftId;
        _hasUnsavedChanges = false;
      });
    }
  }

  Future<void> _editImage(BuildContext context, int index) async {
    final imagePath = Uri.encodeComponent(_selectedImages[index].path);
    final result = await context.push<String>('/image-editor?path=$imagePath');
    if (result != null && mounted) {
      setState(() {
        _selectedImages[index] = File(result);
        _markAsChanged();
      });
    }
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
                    _selectedImages = images;
                    _markAsChanged();
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
                    _selectedImages = [image];
                    _markAsChanged();
                  });
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
      setState(() {
        _position = position;
        _location = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lon: ${position.longitude.toStringAsFixed(4)}';
        _markAsChanged();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured successfully')),
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
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a post')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
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
      // In a real app, we would upload images to a server
      // For now, we'll use placeholder URLs
      final imageUrls = _selectedImages
          .map((img) => 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch + _selectedImages.indexOf(img)}')
          .toList();

      final postType = currentUser.isSeller ? PostType.product : PostType.request;

      final post = PostModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        userName: currentUser.name,
        userProfileImage: currentUser.profileImageUrl,
        userRole: currentUser.role,
        postType: postType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        category: _selectedCategory!,
        price: postType == PostType.product && _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        quantity: _quantityController.text.trim().isNotEmpty
            ? _quantityController.text.trim()
            : null,
        location: currentUser.address ?? 'Location not specified',
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        isScheduled: _isScheduled,
        scheduledAt: _isScheduled ? _scheduledDateTime : null,
        expiresAt: _hasExpiration ? _expirationDateTime : null,
      );

      await ref.read(postsProvider.notifier).createPost(post);

      // Clear draft after successful post creation
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final draftsNotifier = ref.read(draftsProvider(currentUser.id).notifier);
        if (_currentDraftId != null) {
          await draftsNotifier.deleteDraft(_currentDraftId!);
        }
        await draftsNotifier.clearCurrentDraft();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isScheduled
                  ? 'Post scheduled successfully!'
                  : 'Post created successfully!',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}')),
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
    final isSeller = currentUser?.isSeller ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Post',
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _saveDraft(),
            child: const Text('Save Draft'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
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
              _buildSchedulingSection(),
              const SizedBox(height: 16),
              _buildExpirationSection(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/create/drafts'),
                      icon: const Icon(Icons.drafts),
                      label: const Text('Drafts'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/create/scheduled'),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Scheduled'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => _saveDraft(),
                      child: const Text('Save Draft'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Create Post',
                onPressed: _isSubmitting ? null : _submit,
                isLoading: _isSubmitting,
                fullWidth: true,
              ),
              if (_hasUnsavedChanges)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.save,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-saving...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
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
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                if (_selectedImages.length >= 5) {
                  return const SizedBox.shrink();
                }
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

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () => _editImage(context, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: InkWell(
                        onTap: () => _editImage(context, index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                            _markAsChanged();
                          });
                        },
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
        if (_selectedImages.isEmpty)
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
          _markAsChanged();
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

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Schedule Post'),
          subtitle: Text(
            _isScheduled && _scheduledDateTime != null
                ? 'Scheduled for ${_formatDateTime(_scheduledDateTime!)}'
                : 'Publish this post at a specific time',
          ),
          value: _isScheduled,
          onChanged: (value) {
            setState(() {
              _isScheduled = value;
              if (value && _scheduledDateTime == null) {
                // Default to 1 hour from now
                _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
              } else if (!value) {
                _scheduledDateTime = null;
              }
              _markAsChanged();
            });
          },
        ),
        if (_isScheduled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _selectScheduleDateTime(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _scheduledDateTime != null
                  ? 'Change Schedule: ${_formatDateTime(_scheduledDateTime!)}'
                  : 'Select Date & Time',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (_scheduledDateTime != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Post will be published on ${_formatDateTime(_scheduledDateTime!)}',
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

  Future<void> _selectScheduleDateTime(BuildContext context) async {
    // Select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    // Select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _scheduledDateTime != null
          ? TimeOfDay.fromDateTime(_scheduledDateTime!)
          : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );

    if (pickedTime == null) return;

    // Combine date and time
    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Ensure scheduled time is in the future
    if (scheduled.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled time must be in the future'),
          ),
        );
      }
      return;
    }

    setState(() {
      _scheduledDateTime = scheduled;
      _markAsChanged();
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      // Today
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      // Tomorrow
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      // This week
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} at ${_formatTime(dateTime)}';
    } else {
      // Future date
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
                // Default to 7 days from now
                _expirationDateTime = DateTime.now().add(const Duration(days: 7));
              } else if (!value) {
                _expirationDateTime = null;
              }
              _markAsChanged();
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
    // Select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDateTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    // Select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _expirationDateTime != null
          ? TimeOfDay.fromDateTime(_expirationDateTime!)
          : const TimeOfDay(hour: 23, minute: 59),
    );

    if (pickedTime == null) return;

    // Combine date and time
    final expiration = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Ensure expiration time is in the future
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
      _markAsChanged();
    });
  }

  String _formatExpirationDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      // Today
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      // Tomorrow
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      // This week
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} at ${_formatTime(dateTime)}';
    } else {
      // Future date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }
}
