import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_config.dart';
import '../theme/afri_colors.dart';

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    return AppReleaseInfo(
      versionName: (json['version_name'] ?? '').toString(),
      versionCode: int.tryParse('${json['version_code']}') ?? 0,
      apkUrl: (json['apk_url'] ?? '').toString(),
      releaseNotes: (json['release_notes'] ?? '').toString(),
      forceUpdate: json['force_update'] == true,
    );
  }
}

class AppUpdateService {
  AppUpdateService._();

  static bool _promptShown = false;

  static Future<AppReleaseInfo?> fetchLatest() async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final res = await dio.get<Map<String, dynamic>>('/app/latest');
      final data = res.data;
      if (data == null) return null;
      return AppReleaseInfo.fromJson(data);
    } catch (e) {
      debugPrint('AppUpdateService: $e');
      return null;
    }
  }

  /// Vérifie s'il y a une APK plus récente. Les données locales sont
  /// conservées : Android remplace juste le même package (même signature).
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (kIsWeb || _promptShown) return;
    if (!context.mounted) return;

    final latest = await fetchLatest();
    if (latest == null || latest.apkUrl.isEmpty || latest.versionCode <= 0) {
      return;
    }

    final info = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(info.buildNumber) ?? 0;
    if (latest.versionCode <= currentCode) return;
    if (!context.mounted) return;

    _promptShown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: !latest.forceUpdate,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Mise à jour disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AfriOS ${latest.versionName} est prête.\n'
                'Tu n’as pas besoin de désinstaller : Android remplace '
                'l’ancienne version et conserve tes données.',
                style: const TextStyle(height: 1.4),
              ),
              if (latest.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  latest.releaseNotes,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ],
          ),
          actions: [
            if (!latest.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Plus tard'),
              ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AfriColors.teal),
              onPressed: () async {
                final uri = Uri.parse(latest.apkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Télécharger'),
            ),
          ],
        );
      },
    );
  }
}
