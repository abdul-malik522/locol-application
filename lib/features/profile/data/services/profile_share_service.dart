import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';

enum SharePlatform {
  native('Share via...', 'native'),
  whatsapp('WhatsApp', 'whatsapp'),
  facebook('Facebook', 'facebook'),
  twitter('Twitter', 'twitter'),
  email('Email', 'email'),
  sms('SMS', 'sms'),
  copyLink('Copy Link', 'copy');

  const SharePlatform(this.label, this.value);
  final String label;
  final String value;
}

class ProfileShareService {
  ProfileShareService._();
  static final ProfileShareService instance = ProfileShareService._();

  /// Generate share text for a profile
  String _generateShareText(UserModel user) {
    final buffer = StringBuffer();
    buffer.writeln('Check out ${user.businessName ?? user.name} on LocalTrade!');
    buffer.writeln('');
    if (user.businessDescription != null) {
      buffer.writeln(user.businessDescription!);
      buffer.writeln('');
    }
    buffer.writeln('Role: ${user.role.label}');
    if (user.rating > 0) {
      buffer.writeln('Rating: ${user.rating.toStringAsFixed(1)} ⭐ (${user.reviewCount} reviews)');
    }
    if (user.address != null) {
      buffer.writeln('Location: ${user.address}');
    }
    buffer.writeln('');
    buffer.writeln('View profile on LocalTrade: https://localtrade.app/user/${user.id}');
    return buffer.toString();
  }

  /// Generate share URL for a profile
  String _generateShareUrl(UserModel user) {
    return 'https://localtrade.app/user/${user.id}';
  }

  /// Share profile via native share sheet
  Future<void> shareViaNative(UserModel user) async {
    final text = _generateShareText(user);
    await Share.share(
      text,
      subject: 'Check out ${user.businessName ?? user.name} on LocalTrade',
    );
  }

  /// Share profile via WhatsApp
  Future<void> shareViaWhatsApp(UserModel user) async {
    final text = Uri.encodeComponent(_generateShareText(user));
    final url = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Share profile via Facebook
  Future<void> shareViaFacebook(UserModel user) async {
    final url = Uri.parse(_generateShareUrl(user));
    final encodedUrl = Uri.encodeComponent(url.toString());
    final facebookUrl = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl');
    if (await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share profile via Twitter
  Future<void> shareViaTwitter(UserModel user) async {
    final text = Uri.encodeComponent('${user.businessName ?? user.name} - Check them out on LocalTrade!');
    final url = Uri.parse(_generateShareUrl(user));
    final encodedUrl = Uri.encodeComponent(url.toString());
    final twitterUrl = Uri.parse('https://twitter.com/intent/tweet?text=$text&url=$encodedUrl');
    if (await canLaunchUrl(twitterUrl)) {
      await launchUrl(twitterUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share profile via Email
  Future<void> shareViaEmail(UserModel user) async {
    final subject = Uri.encodeComponent('Check out ${user.businessName ?? user.name} on LocalTrade');
    final body = Uri.encodeComponent(_generateShareText(user));
    final emailUrl = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    }
  }

  /// Share profile via SMS
  Future<void> shareViaSMS(UserModel user) async {
    final text = Uri.encodeComponent(_generateShareText(user));
    final smsUrl = Uri.parse('sms:?body=$text');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
    }
  }

  /// Copy profile link to clipboard
  Future<void> copyLink(UserModel user) async {
    final url = _generateShareUrl(user);
    await Clipboard.setData(ClipboardData(text: url));
  }

  /// Share profile to specific platform
  Future<void> shareToPlatform(UserModel user, SharePlatform platform) async {
    switch (platform) {
      case SharePlatform.native:
        await shareViaNative(user);
        break;
      case SharePlatform.whatsapp:
        await shareViaWhatsApp(user);
        break;
      case SharePlatform.facebook:
        await shareViaFacebook(user);
        break;
      case SharePlatform.twitter:
        await shareViaTwitter(user);
        break;
      case SharePlatform.email:
        await shareViaEmail(user);
        break;
      case SharePlatform.sms:
        await shareViaSMS(user);
        break;
      case SharePlatform.copyLink:
        await copyLink(user);
        break;
    }
  }
}

