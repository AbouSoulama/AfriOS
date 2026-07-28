import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/network/api_config.dart';
import 'core/theme/afri_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();

  // Edge-to-edge lets hero images bleed under the status bar; each screen then
  // declares its own icon contrast via AnnotatedRegion.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  try {
    await Firebase.initializeApp();
    await _setupFcm();
  } catch (_) {
    // Firebase optional in dev
  }

  runApp(const ProviderScope(child: AfriOSApp()));
}

Future<void> _setupFcm() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  final token = await messaging.getToken();
  if (token != null) {
    // Token registered after login via auth flow
  }
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('FCM: ${message.notification?.title}');
  });
}

class AfriOSApp extends ConsumerWidget {
  const AfriOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AfriOS',
      debugShowCheckedModeBanner: false,
      theme: AfriTheme.light,
      locale: const Locale('fr'),
      routerConfig: router,
    );
  }
}
