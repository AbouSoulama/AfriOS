import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const prefKey = 'api_base_url';
  static String? _baseUrl;
  static bool _isPhysicalDevice = false;

  static String get baseUrl => _baseUrl ?? _compileTimeUrl;

  static bool get isPhysicalDevice => _isPhysicalDevice;

  /// True when the app likely needs a manual LAN IP (physical device → localhost).
  static bool get likelyNeedsLanUrl {
    if (kIsWeb) return false;
    final url = baseUrl;
    return _isPhysicalDevice &&
        (url.contains('127.0.0.1') || url.contains('localhost'));
  }

  static String get _compileTimeUrl {
    const full = String.fromEnvironment('API_BASE_URL');
    if (full.isNotEmpty) return full;

    const host = String.fromEnvironment('API_HOST');
    if (host.isNotEmpty) return 'http://$host:8000/v1';

    return 'http://10.0.2.2:8000/v1';
  }

  static Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isPhysicalDevice = await _detectPhysicalDevice();
    }

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      _baseUrl = fromEnv;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = _normalize(saved);
      return;
    }

    const host = String.fromEnvironment('API_HOST');
    if (host.isNotEmpty) {
      _baseUrl = 'http://$host:8000/v1';
      return;
    }

    if (!kIsWeb &&
        (Platform.isAndroid || Platform.isIOS) &&
        _isPhysicalDevice) {
      // USB + adb reverse, ou Wi-Fi via Paramètres (IP du PC).
      _baseUrl = 'http://127.0.0.1:8000/v1';
      return;
    }

    if (!kIsWeb && Platform.isAndroid) {
      _baseUrl = 'http://10.0.2.2:8000/v1';
      return;
    }

    _baseUrl = 'http://127.0.0.1:8000/v1';
  }

  static Future<bool> _detectPhysicalDevice() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await plugin.androidInfo).isPhysicalDevice;
    }
    if (Platform.isIOS) {
      return (await plugin.iosInfo).isPhysicalDevice;
    }
    return false;
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = _normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, _baseUrl!);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKey);
    _baseUrl = null;
    await initialize();
  }

  static String _normalize(String url) {
    var value = url.trim();
    if (!value.startsWith('http')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (!value.endsWith('/v1')) {
      value = '$value/v1';
    }
    return value;
  }

  /// Returns the /health URL for a given API base (.../v1).
  static String healthUrl([String? apiBase]) {
    final base = apiBase != null ? _normalize(apiBase) : baseUrl;
    return base.replaceFirst(RegExp(r'/v1/?$'), '/health');
  }

  /// Pings GET /health. Returns null on success, or an error message.
  static Future<String?> testConnection([String? url]) async {
    final target = url != null ? _normalize(url) : baseUrl;
    final health = healthUrl(target);
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final res = await dio.get(health);
      if (res.statusCode == 200) return null;
      return 'Réponse inattendue (${res.statusCode}) depuis $health';
    } on DioException catch (e) {
      return friendlyError(e);
    } catch (e) {
      return 'Impossible de joindre $health';
    }
  }

  static String friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail.map(_formatValidationItem).join('\n');
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Délai dépassé. Vérifie que ton téléphone et ton PC sont sur le même Wi-Fi, '
            'et que l\'API tourne (port 8000).';
      }
      if (error.type == DioExceptionType.connectionError) {
        return _connectionHelp;
      }
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('connection error') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable')) {
      return _connectionHelp;
    }
    if (msg.contains('timeout')) {
      return 'Délai dépassé. Vérifie que ton téléphone et ton PC sont sur le même réseau.';
    }
    return 'Erreur : $error';
  }

  static String get _connectionHelp => "Serveur inaccessible.\n"
      "1. Lance l'API sur le PC (port 8000)\n"
      "2. Icône ⚙️ → URL serveur\n"
      "   • Émulateur : http://10.0.2.2:8000/v1\n"
      "   • Téléphone Wi-Fi : http://IP_DU_PC:8000/v1\n"
      "   • USB : adb reverse tcp:8000 tcp:8000 puis http://127.0.0.1:8000/v1";

  static String _formatValidationItem(dynamic e) {
    if (e is! Map) return e.toString();
    final loc = (e['loc'] is List)
        ? (e['loc'] as List).where((x) => x != 'body').join('.')
        : '';
    final raw = (e['msg'] ?? e.toString()).toString();
    final msg = _translateValidation(raw);
    if (loc.isEmpty) return msg;
    return '${_fieldLabel(loc)} : $msg';
  }

  static String _fieldLabel(String loc) {
    const labels = {
      'phone': 'Téléphone',
      'code': 'Code OTP',
      'name': 'Nom',
      'sector': 'Secteur',
      'currency': 'Devise',
      'country_code': 'Pays',
    };
    return labels[loc] ?? loc;
  }

  static String _translateValidation(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('at least 2')) return 'au moins 2 caractères requis';
    if (lower.contains('at least 8'))
      return 'numéro trop court (min. 8 caractères)';
    if (lower.contains('at least 4')) return 'code trop court';
    if (lower.contains('at most')) return 'valeur trop longue';
    if (lower.contains('field required')) return 'champ obligatoire';
    return msg;
  }
}
