import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'offline_store.dart';

final offlineStoreProvider = FutureProvider<OfflineStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return OfflineStore(prefs);
});

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  await for (final result in connectivity.onConnectivityChanged) {
    yield result.any((r) => r != ConnectivityResult.none);
  }
});

class SyncService {
  SyncService(this._api, this._store);
  final ApiClient _api;
  final OfflineStore _store;

  Future<void> pullAndCache() async {
    try {
      final data = await _api.syncPull();
      await _store.saveClients(
          List<Map<String, dynamic>>.from(data['clients'] as List? ?? []));
      await _store.saveProducts(
          List<Map<String, dynamic>>.from(data['products'] as List? ?? []));
      await _store.saveInvoices(
          List<Map<String, dynamic>>.from(data['invoices'] as List? ?? []));
    } catch (_) {
      // Use cached data when offline
    }
  }

  Future<int> pushPending() async {
    final pending = _store.getPendingOperations();
    if (pending.isEmpty) return 0;

    try {
      await _api.syncPush(pending);
      await _store.clearPendingOperations();
      await pullAndCache();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> syncIfOnline(bool isOnline) async {
    if (!isOnline) return;
    await pushPending();
    await pullAndCache();
  }
}

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final api = ref.watch(apiClientProvider);
  final store = await ref.watch(offlineStoreProvider.future);
  return SyncService(api, store);
});
