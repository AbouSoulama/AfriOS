import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const prefKey = 'api_base_url';
  static const productionUrl = 'https://afrios-api.onrender.com/v1';
  static String? _baseUrl;
  static bool _isPhysicalDevice = false;

  static String get baseUrl => _baseUrl ?? _compileTimeUrl;

  static bool get isPhysicalDevice => _isPhysicalDevice;

  /// True when the app is still pointing at a local/LAN server.
  static bool get likelyNeedsLanUrl {
    if (kIsWeb) return false;
    return _isLocalUrl(baseUrl);
  }

  static String get _compileTimeUrl {
    const full = String.fromEnvironment('API_BASE_URL');
    if (full.isNotEmpty) return full;

    const host = String.fromEnvironment('API_HOST');
    if (host.isNotEmpty) return 'http://$host:8000/v1';

    return productionUrl;
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

    const host = String.fromEnvironment('API_HOST');
    if (host.isNotEmpty) {
      _baseUrl = 'http://$host:8000/v1';
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKey);
    if (saved != null && saved.isNotEmpty) {
      final normalized = _normalize(saved);
      // Old installs saved localhost / LAN IP — those break on 4G.
      if (_isLocalUrl(normalized)) {
        await prefs.remove(prefKey);
        _baseUrl = productionUrl;
        return;
      }
      _baseUrl = normalized;
      return;
    }

    _baseUrl = productionUrl;
  }

  static bool _isLocalUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? url.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }
    if (host.startsWith('192.168.')) return true;
    if (host.startsWith('10.')) return true;
    final match = RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').firstMatch(host);
    return match != null;
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
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
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
        return 'Le serveur met trop de temps à répondre. '
            'Sur le plan gratuit Render, le premier appel peut prendre 30 à 60 s — réessaie.';
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
      return 'Délai dépassé. Réessaie : le serveur peut être en réveil (30–60 s).';
    }
    return 'Erreur : $error';
  }

  static String get _connectionHelp =>
      "Serveur inaccessible. Vérifie ta connexion internet (4G / Wi-Fi).\n"
      "L'app utilise déjà https://afrios-api.onrender.com/v1.\n"
      "Si le serveur est en veille, attends une minute puis réessaie.";

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
