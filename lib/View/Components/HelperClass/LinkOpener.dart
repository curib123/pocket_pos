import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkOpener {
  /// Opens a given link in Chrome if available, else falls back to external browser.
  static Future<void> openLink(BuildContext context, String link) async {
    final Uri url = Uri.parse(link);
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  /// Your default Facebook Page URL (for reuse in app).
  static const String facebookPageUrl = 'https://www.facebook.com/profile.php?id=61577201312987';
}
