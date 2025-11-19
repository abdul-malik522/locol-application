import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    required this.imagePath,
    super.key,
  });

  final String imagePath;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  File? _editedImage;
  double _rotation = 0;
  double _brightness = 0;
  double _contrast = 1.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _editedImage = File(widget.imagePath);
  }

  Future<void> _rotateImage() async {
    setState(() {
      _isProcessing = true;
      _rotation = (_rotation + 90) % 360;
    });

    try {
      final imageBytes = await _editedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      final rotated = img.copyRotate(image, angle: 90);
      final rotatedBytes = img.encodePng(rotated);

      final tempDir = await getTemporaryDirectory();
      final rotatedFile = File('${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.png');
      await rotatedFile.writeAsBytes(rotatedBytes);

      setState(() {
        _editedImage = rotatedFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rotate image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _adjustBrightness(double value) async {
    setState(() {
      _brightness = value;
      _isProcessing = true;
    });

    try {
      final imageBytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      final adjusted = img.adjustColor(
        image,
        brightness: value,
        contrast: _contrast,
      );
      final adjustedBytes = img.encodePng(adjusted);

      final tempDir = await getTemporaryDirectory();
      final adjustedFile = File('${tempDir.path}/adjusted_${DateTime.now().millisecondsSinceEpoch}.png');
      await adjustedFile.writeAsBytes(adjustedBytes);

      setState(() {
        _editedImage = adjustedFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _adjustContrast(double value) async {
    setState(() {
      _contrast = value;
      _isProcessing = true;
    });

    try {
      final imageBytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      final adjusted = img.adjustColor(
        image,
        brightness: _brightness,
        contrast: value,
      );
      final adjustedBytes = img.encodePng(adjusted);

      final tempDir = await getTemporaryDirectory();
      final adjustedFile = File('${tempDir.path}/adjusted_${DateTime.now().millisecondsSinceEpoch}.png');
      await adjustedFile.writeAsBytes(adjustedBytes);

      setState(() {
        _editedImage = adjustedFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _resetImage() async {
    setState(() {
      _editedImage = File(widget.imagePath);
      _rotation = 0;
      _brightness = 0;
      _contrast = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Image',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetImage,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : _editedImage != null && _editedImage!.existsSync()
                      ? Image.file(
                          _editedImage!,
                          fit: BoxFit.contain,
                        )
                      : const Text('Image not found'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.rotate_right),
                      onPressed: _rotateImage,
                      tooltip: 'Rotate',
                    ),
                    IconButton(
                      icon: const Icon(Icons.crop),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Crop feature coming soon')),
                        );
                      },
                      tooltip: 'Crop',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _brightness,
                  min: -100,
                  max: 100,
                  divisions: 40,
                  label: _brightness.toStringAsFixed(0),
                  onChanged: _adjustBrightness,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contrast',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _contrast,
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  label: _contrast.toStringAsFixed(2),
                  onChanged: _adjustContrast,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Save',
                  onPressed: () {
                    if (_editedImage != null) {
                      context.pop(_editedImage!.path);
                    }
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

