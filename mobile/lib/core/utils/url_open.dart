import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a payment / external URL robustly on Android.
Future<bool> openExternalUrl(
  BuildContext context,
  String url, {
  String? successMessage,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lien de paiement invalide : $url')),
      );
    }
    return false;
  }

  // Prefer external browser, then platform default.
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
  }

  if (!context.mounted) return opened;

  if (opened) {
    if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
    return true;
  }

  await Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Impossible d\'ouvrir le navigateur. Lien copié — colle-le dans Chrome.',
      ),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
      duration: const Duration(seconds: 8),
    ),
  );
  return false;
}
