import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'offline_store.dart';

final offlineStoreProvider = FutureProvider<OfflineStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return OfflineStore(prefs);
});

/// Bumped after enqueue / successful push so UI rebuilds pending count.
final pendingOpsTickProvider = StateProvider<int>((ref) => 0);

final pendingCountProvider = FutureProvider<int>((ref) async {
  ref.watch(pendingOpsTickProvider);
  final store = await ref.watch(offlineStoreProvider.future);
  return store.pendingCount();
});

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);
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
      final res = await _api.syncPush(pending);
      final results = List<Map<String, dynamic>>.from(res['results'] as List? ?? []);
      final done = <String>[];
      for (final r in results) {
        final status = r['status'] as String? ?? '';
        final opId = r['client_op_id'] as String?;
        if (opId != null && (status == 'processed' || status == 'duplicate')) {
          done.add(opId);
        }
      }
      await _store.removePendingOperations(done);
      await pullAndCache();
      return done.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> syncIfOnline(bool isOnline) async {
    if (!isOnline) return 0;
    final pushed = await pushPending();
    await pullAndCache();
    return pushed;
  }
}

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final api = ref.watch(apiClientProvider);
  final store = await ref.watch(offlineStoreProvider.future);
  return SyncService(api, store);
});
