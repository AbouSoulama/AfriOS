import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/auth_screens.dart';
import '../features/clients/clients_screen.dart';
import '../features/invoices/invoices_screen.dart';
import '../features/products/products_screen.dart';
import '../features/ai/ai_screen.dart';
import '../features/settings/settings_screen.dart';
import 'router_refresh.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;

      final isAuth = auth.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/welcome' ||
          state.matchedLocation.startsWith('/onboarding');

      if (!isAuth && !isAuthRoute) return '/welcome';
      if (isAuth &&
          !auth.onboardingCompleted &&
          !state.matchedLocation.startsWith('/onboarding')) {
        return auth.businessName != null
            ? '/onboarding/tour'
            : '/onboarding/profile';
      }
      if (isAuth &&
          auth.onboardingCompleted &&
          (state.matchedLocation == '/welcome' ||
              state.matchedLocation.startsWith('/auth'))) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
              phone: extra['phone'] as String? ?? '',
              devCode: extra['devCode'] as String?);
        },
      ),
      GoRoute(
          path: '/onboarding/profile',
          builder: (_, __) => const CompanyProfileScreen()),
      GoRoute(
          path: '/onboarding/tour',
          builder: (_, __) => const OnboardingTourScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/invoices', builder: (_, __) => const InvoicesScreen()),
          GoRoute(path: '/clients', builder: (_, __) => const ClientsScreen()),
          GoRoute(path: '/stock', builder: (_, __) => const StockScreen()),
          GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
        ],
      ),
      GoRoute(
          path: '/clients/add', builder: (_, __) => const AddClientScreen()),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (_, state) =>
            AddClientScreen(clientId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (_, state) =>
            ClientDetailScreen(clientId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/stock/add', builder: (_, __) => const AddProductScreen()),
      GoRoute(
        path: '/stock/:id/edit',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddProductScreen(
            productId: state.pathParameters['id'],
            initial: extra,
          );
        },
      ),
      GoRoute(
        path: '/stock/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/invoices/create',
        builder: (_, state) {
          final clientId = state.uri.queryParameters['clientId'];
          return CreateInvoiceScreen(initialClientId: clientId);
        },
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (_, state) =>
            InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/business',
          builder: (_, __) => const BusinessSettingsScreen()),
      GoRoute(
          path: '/settings/payments',
          builder: (_, __) => const PaymentIntegrationsScreen()),
      GoRoute(
          path: '/settings/help',
          builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
