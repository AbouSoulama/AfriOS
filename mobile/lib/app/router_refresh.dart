import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_provider.dart';

/// Notifie GoRouter sans recréer l'instance (évite de perdre la navigation).
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});
