import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Offline cache + sync queue (MVP without Drift code generation).
class OfflineStore {
  OfflineStore(this._prefs);
  final SharedPreferences _prefs;
  static const _clientsKey = 'cache_clients';
  static const _productsKey = 'cache_products';
  static const _invoicesKey = 'cache_invoices';
  static const _pendingKey = 'pending_operations';

  List<Map<String, dynamic>> getClients() {
    final raw = _prefs.getString(_clientsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> saveClients(List<Map<String, dynamic>> clients) async {
    await _prefs.setString(_clientsKey, jsonEncode(clients));
  }

  List<Map<String, dynamic>> getProducts() {
    final raw = _prefs.getString(_productsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    await _prefs.setString(_productsKey, jsonEncode(products));
  }

  List<Map<String, dynamic>> getInvoices() {
    final raw = _prefs.getString(_invoicesKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> saveInvoices(List<Map<String, dynamic>> invoices) async {
    await _prefs.setString(_invoicesKey, jsonEncode(invoices));
  }

  List<Map<String, dynamic>> getPendingOperations() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> enqueueOperation({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final pending = getPendingOperations();
    pending.add({
      'client_op_id': const Uuid().v4(),
      'entity_type': entityType,
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<void> clearPendingOperations() async {
    await _prefs.remove(_pendingKey);
  }

  int pendingCount() => getPendingOperations().length;
}
