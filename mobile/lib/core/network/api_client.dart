import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      options.baseUrl = ApiConfig.baseUrl;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _dio.post('/auth/otp/send', data: {'phone': phone});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await _dio
        .post('/auth/otp/verify', data: {'phone': phone, 'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBusiness(Map<String, dynamic> data) async {
    final res = await _dio.post('/business', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBusiness() async {
    final res = await _dio.get('/business');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBusiness(Map<String, dynamic> data) async {
    final res = await _dio.put('/business', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> completeOnboarding() async {
    await _dio.post('/business/onboarding/complete');
  }

  Future<List<dynamic>> getClients({String? q}) async {
    final res = await _dio.get('/clients',
        queryParameters: q != null ? {'q': q} : null);
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    final res = await _dio.post('/clients', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getClient(String id) async {
    final res = await _dio.get('/clients/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateClient(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/clients/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteClient(String id) async {
    await _dio.delete('/clients/$id');
  }

  Future<List<dynamic>> getProducts() async {
    final res = await _dio.get('/products');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  Future<Map<String, dynamic>> addStockMovement(
      String productId, Map<String, dynamic> data) async {
    final res = await _dio.post('/products/$productId/movements', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getInvoices({String? status}) async {
    final res = await _dio.get('/invoices',
        queryParameters: status != null ? {'status': status} : null);
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final res = await _dio.post('/invoices', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    final res = await _dio.get('/invoices/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendInvoice(String id) async {
    final res = await _dio.post('/invoices/$id/send');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markPaid(String id,
      {String method = 'cash'}) async {
    final res =
        await _dio.post('/invoices/$id/mark-paid', data: {'method': method});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/dashboard/summary');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> aiChat(String message,
      {String? conversationId}) async {
    final res = await _dio.post('/ai/chat', data: {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<String>> aiSuggestions() async {
    final res = await _dio.get('/ai/suggestions');
    return List<String>.from((res.data as Map)['suggestions'] as List);
  }

  Future<List<dynamic>> getOverdueReminders() async {
    final res = await _dio.get('/reminders/overdue');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendReminder(String invoiceId) async {
    final res = await _dio.post('/reminders/$invoiceId/send');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReminderRules() async {
    final res = await _dio.get('/reminders/rules');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateReminderRules(
      Map<String, dynamic> data) async {
    final res = await _dio.put('/reminders/rules', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncPush(
      List<Map<String, dynamic>> operations) async {
    final res = await _dio.post('/sync/push', data: {'operations': operations});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncPull({String? since}) async {
    final res = await _dio.get('/sync/pull',
        queryParameters: since != null ? {'since': since} : null);
    return res.data as Map<String, dynamic>;
  }

  Future<void> registerFcmToken(String token) async {
    await _dio.post('/devices/fcm-token',
        data: {'token': token, 'platform': 'android'});
  }

  Future<Map<String, dynamic>> initiatePayment(String invoiceId) async {
    final res =
        await _dio.post('/payments/initiate', data: {'invoice_id': invoiceId});
    return res.data as Map<String, dynamic>;
  }
}
