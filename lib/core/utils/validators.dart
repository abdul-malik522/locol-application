import 'package:intl/intl.dart';

class Validators {
  const Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&' + "'" + r'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  static final _phoneRegex = RegExp(r'^[0-9+() -]{7,}$');
  static final _urlRegex = RegExp(
    r'^(https?:\/\/)?([\w\-])+\.{1}([a-zA-Z]{2,63})([\/\w\-]*)*\/?$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter your email address.');
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return Intl.message('Please enter a valid email address.');
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return Intl.message('Please enter your password.');
    }
    if (value.length < 8) {
      return Intl.message('Password must be at least 8 characters long.');
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return Intl.message('Password needs at least one uppercase letter.');
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return Intl.message('Password needs at least one lowercase letter.');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return Intl.message('Password needs at least one number.');
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter your phone number.');
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return Intl.message('Please enter a valid phone number.');
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter your $fieldName.');
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter your $fieldName.');
    }
    if (value.trim().length < minLength) {
      return Intl.message(
        '$fieldName must be at least $minLength characters long.',
      );
    }
    return null;
  }

  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value != null && value.trim().length > maxLength) {
      return Intl.message(
        '$fieldName must be less than $maxLength characters.',
      );
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter a price.');
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return Intl.message('Please enter a valid positive price.');
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Intl.message('Please enter a quantity.');
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return Intl.message('Please enter a valid quantity.');
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_urlRegex.hasMatch(value.trim())) {
      return Intl.message('Please enter a valid URL.');
    }
    return null;
  }
}

