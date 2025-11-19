import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localtrade/features/home/data/models/post_model.dart';

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

class PostShareService {
  PostShareService._();
  static final PostShareService instance = PostShareService._();

  /// Generate share text for a post
  String _generateShareText(PostModel post) {
    final buffer = StringBuffer();
    buffer.writeln('Check out this ${post.postType.name} on LocalTrade!');
    buffer.writeln('');
    buffer.writeln(post.title);
    buffer.writeln('');
    buffer.writeln(post.description);
    if (post.price != null) {
      buffer.writeln('');
      buffer.writeln('Price: \$${post.price!.toStringAsFixed(2)}');
    }
    if (post.quantity != null) {
      buffer.writeln('Quantity: ${post.quantity}');
    }
    buffer.writeln('');
    buffer.writeln('Location: ${post.location}');
    buffer.writeln('');
    buffer.writeln('View on LocalTrade: https://localtrade.app/post/${post.id}');
    return buffer.toString();
  }

  /// Generate share URL for a post
  String _generateShareUrl(PostModel post) {
    return 'https://localtrade.app/post/${post.id}';
  }

  /// Share post via native share sheet
  Future<void> shareViaNative(PostModel post) async {
    final text = _generateShareText(post);
    await Share.share(
      text,
      subject: 'Check out this ${post.postType.name} on LocalTrade',
    );
  }

  /// Share post via WhatsApp
  Future<void> shareViaWhatsApp(PostModel post) async {
    final text = Uri.encodeComponent(_generateShareText(post));
    final url = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Share post via Facebook
  Future<void> shareViaFacebook(PostModel post) async {
    final url = Uri.parse(_generateShareUrl(post));
    final encodedUrl = Uri.encodeComponent(url.toString());
    final facebookUrl = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl');
    if (await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share post via Twitter
  Future<void> shareViaTwitter(PostModel post) async {
    final text = Uri.encodeComponent('${post.title} - Check it out on LocalTrade!');
    final url = Uri.parse(_generateShareUrl(post));
    final encodedUrl = Uri.encodeComponent(url.toString());
    final twitterUrl = Uri.parse('https://twitter.com/intent/tweet?text=$text&url=$encodedUrl');
    if (await canLaunchUrl(twitterUrl)) {
      await launchUrl(twitterUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share post via Email
  Future<void> shareViaEmail(PostModel post) async {
    final subject = Uri.encodeComponent('Check out this ${post.postType.name} on LocalTrade');
    final body = Uri.encodeComponent(_generateShareText(post));
    final emailUrl = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    }
  }

  /// Share post via SMS
  Future<void> shareViaSMS(PostModel post) async {
    final text = Uri.encodeComponent(_generateShareText(post));
    final smsUrl = Uri.parse('sms:?body=$text');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
    }
  }

  /// Copy post link to clipboard
  Future<void> copyLink(PostModel post) async {
    final url = _generateShareUrl(post);
    await Clipboard.setData(ClipboardData(text: url));
  }

  /// Share post to specific platform
  Future<void> shareToPlatform(PostModel post, SharePlatform platform) async {
    switch (platform) {
      case SharePlatform.native:
        await shareViaNative(post);
        break;
      case SharePlatform.whatsapp:
        await shareViaWhatsApp(post);
        break;
      case SharePlatform.facebook:
        await shareViaFacebook(post);
        break;
      case SharePlatform.twitter:
        await shareViaTwitter(post);
        break;
      case SharePlatform.email:
        await shareViaEmail(post);
        break;
      case SharePlatform.sms:
        await shareViaSMS(post);
        break;
      case SharePlatform.copyLink:
        await copyLink(post);
        break;
    }
  }
}

