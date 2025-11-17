import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  const ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromGallery() async {
    final granted = await _requestPermission(Permission.photos);
    if (!granted) return null;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  static Future<File?> pickImageFromCamera() async {
    final granted = await _requestPermission(Permission.camera);
    if (!granted) return null;
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  static Future<List<File>> pickMultipleImages(int maxCount) async {
    final granted = await _requestPermission(Permission.photos);
    if (!granted) return [];
    final files = await _picker.pickMultiImage(
      limit: maxCount,
      imageQuality: 85,
    );
    return files.map((xFile) => File(xFile.path)).toList();
  }

  static Future<bool> validateImageSize(File image, int maxSizeBytes) async {
    final length = await image.length();
    return length <= maxSizeBytes;
  }

  static bool validateImageFormat(File image, List<String> allowedFormats) {
    final extension = image.path.split('.').last.toLowerCase();
    return allowedFormats.contains(extension);
  }

  static Future<Map<String, int>> getImageDimensions(File image) async {
    final bytes = await image.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (image) => completer.complete(image));
    final decoded = await completer.future;
    return {'width': decoded.width, 'height': decoded.height};
  }

  static Future<File?> compressImage(File image, {int quality = 80}) async {
    // Placeholder: actual compression would use image libraries (e.g., flutter_image_compress)
    // Returned file is unchanged to keep dependencies minimal for now.
    return image;
  }

  static Future<File?> cropImage(File image) async {
    // Placeholder hook for integration with image cropper packages.
    return image;
  }

  static Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }
}

