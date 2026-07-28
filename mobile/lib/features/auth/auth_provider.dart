import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.onboardingCompleted = false,
    this.businessName,
    this.devOtpCode,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final bool onboardingCompleted;
  final String? businessName;
  final String? devOtpCode;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? onboardingCompleted,
    String? businessName,
    String? devOtpCode,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      businessName: businessName ?? this.businessName,
      devOtpCode: devOtpCode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState()) {
    _init();
  }

  final ApiClient _api;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final onboarding = prefs.getBool('onboarding_completed') ?? false;
    final businessName = prefs.getString('business_name');

    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        onboardingCompleted: onboarding,
        businessName: businessName,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> sendOtp(String phone, {String? isoCountryCode}) async {
    try {
      if (isoCountryCode != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone_country_code', isoCountryCode);
      }
      final res = await _api.sendOtp(phone);
      return res['dev_code'] as String?;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    final res = await _api.verifyOtp(phone, code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', res['access_token'] as String);
    await prefs.setString('phone', phone);

    final onboarding = res['onboarding_completed'] as bool? ?? false;
    await prefs.setBool('onboarding_completed', onboarding);

    // Register FCM token if available
    try {
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm != null) await _api.registerFcmToken(fcm);
    } catch (_) {}

    state = state.copyWith(
      isAuthenticated: true,
      onboardingCompleted: onboarding,
      isLoading: false,
    );
  }

  Future<void> createBusiness({
    required String name,
    required String sector,
    String currency = 'XOF',
    String? countryCode,
    double taxRate = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedCountry =
        countryCode ?? prefs.getString('phone_country_code') ?? 'SN';
    final res = await _api.createBusiness({
      'name': name,
      'sector': sector,
      'currency': currency,
      'country_code': resolvedCountry,
      'tax_rate': taxRate,
    });
    await prefs.setString('business_name', res['name'].toString());
    await prefs.setString('business_id', res['id'].toString());
    state = state.copyWith(businessName: res['name'].toString());
  }

  Future<void> completeOnboarding() async {
    await _api.completeOnboarding();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> setBusinessName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', name);
    state = state.copyWith(businessName: name, devOtpCode: state.devOtpCode);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState(isLoading: false);
  }
}
