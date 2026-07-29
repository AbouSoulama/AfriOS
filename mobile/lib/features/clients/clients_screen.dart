import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/shell.dart';
import '../../core/database/sync_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/utils/parsing.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_components.dart';
import '../../core/widgets/afri_empty_state.dart';
import '../../core/widgets/afri_motion.dart';
import '../../core/widgets/afri_offline_banner.dart';
import '../../core/widgets/afri_premium.dart';
import '../auth/auth_provider.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getDashboard();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final dashboard = ref.watch(dashboardProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    final bottomPad = shellBottomClearance(context);

    return Scaffold(
      body: AfriMeshBackground(
        overlayStyle: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            if (!isOnline)
              const SafeArea(bottom: false, child: AfriOfflineBanner()),
            Expanded(
              child: dashboard.when(
                loading: () => const _HomeSkeleton(),
                error: (e, _) => AfriEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Tableau de bord indisponible',
                  subtitle: ApiConfig.friendlyError(e),
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(dashboardProvider),
                ),
                data: (data) => RefreshIndicator(
                  color: AfriColors.teal,
                  onRefresh: () async {
                    ref.invalidate(dashboardProvider);
                    final sync = await ref.read(syncServiceProvider.future);
                    await sync.syncIfOnline(isOnline);
                  },
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _HomeHero(
                          scroll: _scroll,
                          businessName: auth.businessName ?? 'AfriOS',
                          revenueToday: asDouble(data['revenue_today']),
                          pendingCount: asInt(data['pending_invoices_count']),
                          overdueCount: asInt(data['overdue_count']),
                          onSettings: () => context.push('/settings'),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            20, AfriSpace.md, 20, bottomPad),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            AfriKPICard(
                              label: 'Chiffre d\'affaires ce mois',
                              value: '${data['revenue_month']}',
                              isAmount: true,
                              trend: asDoubleOrNull(
                                  data['revenue_change_percent']),
                              icon: Icons.trending_up_rounded,
                              featured: true,
                            ),
                            const SizedBox(height: AfriSpace.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: AfriKPICard(
                                    label: 'En attente',
                                    value: '${data['pending_invoices_count']}',
                                    subtitle:
                                        '${data['pending_invoices_total']} FCFA',
                                    icon: Icons.schedule_rounded,
                                    accent: AfriColors.navy,
                                    onTap: () => context.go('/invoices'),
                                  ),
                                ),
                                const SizedBox(width: AfriSpace.sm),
                                Expanded(
                                  child: AfriKPICard(
                                    label: 'Stock faible',
                                    value: '${data['low_stock_count']}',
                                    subtitle: 'produits à réapprovisionner',
                                    icon: Icons.warning_amber_rounded,
                                    accent: AfriColors.orange,
                                    onTap: () => context.go('/stock'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AfriSpace.xl),
                            const AfriSectionHeader(
                              title: 'Actions rapides',
                              subtitle: 'Les gestes du quotidien',
                            ),
                            const SizedBox(height: AfriSpace.sm),
                            AfriQuickAction(
                              label: 'Créer une facture',
                              subtitle: 'Encaisse en moins d\'une minute',
                              icon: Icons.receipt_long_rounded,
                              color: AfriColors.teal,
                              onTap: () => context.push('/invoices/create'),
                            ),
                            const SizedBox(height: AfriSpace.xs),
                            AfriQuickAction(
                              label: 'Relancer les impayés',
                              subtitle:
                                  '${data['overdue_count']} facture(s) en retard',
                              icon: Icons.notifications_active_rounded,
                              color: AfriColors.orange,
                              onTap: () => context.push('/reminders'),
                            ),
                            const SizedBox(height: AfriSpace.xs),
                            AfriQuickAction(
                              label: 'Ajouter un client',
                              subtitle: 'Enrichis ton carnet commercial',
                              icon: Icons.person_add_alt_1_rounded,
                              color: AfriColors.navy,
                              onTap: () => context.push('/clients/add'),
                            ),
                            const SizedBox(height: AfriSpace.xs),
                            AfriQuickAction(
                              label: 'Assistant IA',
                              subtitle: 'Pose une question sur ton business',
                              icon: Icons.auto_awesome_rounded,
                              color: AfriColors.gold,
                              onTap: () => context.go('/ai'),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.scroll,
    required this.businessName,
    required this.revenueToday,
    required this.pendingCount,
    required this.overdueCount,
    required this.onSettings,
  });

  final ScrollController scroll;
  final String businessName;
  final double revenueToday;
  final int pendingCount;
  final int overdueCount;
  final VoidCallback onSettings;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    const imageHeight = 268.0;

    return SizedBox(
      height: imageHeight + 44,
      child: Stack(
        children: [
          // Image drifts slower than the content, which gives the header depth
          // as the dashboard scrolls over it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: scroll,
              builder: (context, child) {
                double offset = 0;
                try {
                  if (scroll.hasClients) {
                    offset = scroll.offset.clamp(0.0, 300.0);
                  }
                } catch (_) {
                  // Controller may already be disposed during route teardown.
                }
                return Transform.translate(
                  offset: Offset(0, offset * 0.32),
                  child: Transform.scale(
                    scale: 1 + offset * 0.0006,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AfriRadius.xxl),
                ),
                child: const SizedBox(
                  height: imageHeight,
                  child: AfriHeroImage(asset: 'assets/images/home_hero.png'),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 14, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AfriBrandMark(light: true)
                            .animate()
                            .fadeIn(duration: 450.ms)
                            .slideX(begin: -0.08, end: 0),
                        const Spacer(),
                        _GlassIconButton(
                          icon: Icons.settings_outlined,
                          onTap: onSettings,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _greeting,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 3),
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.9,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 120.ms)
                        .slideY(begin: 0.12, end: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: _PulseStrip(
              revenueToday: revenueToday,
              pendingCount: pendingCount,
              overdueCount: overdueCount,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted stat strip that straddles the hero and the content below it.
class _PulseStrip extends StatelessWidget {
  const _PulseStrip({
    required this.revenueToday,
    required this.pendingCount,
    required this.overdueCount,
  });

  final double revenueToday;
  final int pendingCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: AfriSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AfriRadius.rLg,
        border: Border.all(color: AfriColors.line),
        boxShadow: AfriShadow.lifted,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Encaissé aujourd'hui",
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    color: AfriColors.slateLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AfriAnimatedAmount(
                    amount: revenueToday,
                    style: GoogleFonts.sora(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AfriColors.ink,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 34, color: AfriColors.line),
          Expanded(
            flex: 2,
            child: _MiniStat(
              value: '$pendingCount',
              label: 'en attente',
              color: AfriColors.navy,
            ),
          ),
          Container(width: 1, height: 34, color: AfriColors.line),
          Expanded(
            flex: 2,
            child: _MiniStat(
              value: '$overdueCount',
              label: 'en retard',
              color: overdueCount > 0 ? AfriColors.orange : AfriColors.success,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AfriColors.slateLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AfriPressable(
      onTap: onTap,
      child: AfriGlass(
        dark: true,
        blur: 8,
        radius: AfriRadius.sm,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Dashboard placeholder that mirrors the real layout while data loads.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        const SizedBox(height: 60),
        const AfriShimmer(width: 120, height: 22),
        const SizedBox(height: AfriSpace.sm),
        const AfriShimmer(width: 210, height: 30),
        const SizedBox(height: AfriSpace.xl),
        const AfriShimmer(height: 76, radius: AfriRadius.lg),
        const SizedBox(height: AfriSpace.md),
        const AfriShimmer(height: 120, radius: AfriRadius.lg),
        const SizedBox(height: AfriSpace.sm),
        const Row(
          children: [
            Expanded(child: AfriShimmer(height: 104, radius: AfriRadius.lg)),
            SizedBox(width: AfriSpace.sm),
            Expanded(child: AfriShimmer(height: 104, radius: AfriRadius.lg)),
          ],
        ),
        const SizedBox(height: AfriSpace.xl),
        for (var i = 0; i < 3; i++) ...[
          const AfriShimmer(height: 78, radius: AfriRadius.lg),
          const SizedBox(height: AfriSpace.xs),
        ],
      ],
    );
  }
}

final clientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  if (!isOnline) {
    final store = await ref.watch(offlineStoreProvider.future);
    return store.getClients();
  }
  final clients = await api.getClients();
  final store = await ref.watch(offlineStoreProvider.future);
  await store.saveClients(List<Map<String, dynamic>>.from(clients));
  return List<Map<String, dynamic>>.from(clients);
});

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    final bottomPad = shellBottomClearance(context);

    return Scaffold(
      body: AfriMeshBackground(
        child: Column(
          children: [
            if (!isOnline)
              const SafeArea(bottom: false, child: AfriOfflineBanner()),
            AfriListHeader(
              title: 'Clients',
              subtitle: 'Ton carnet commercial',
              count: clients.value?.length,
            ),
            Expanded(
              child: clients.when(
                loading: () => const AfriSkeletonList(),
                error: (e, _) => AfriEmptyState(
                  icon: Icons.people_outline,
                  title: 'Erreur de chargement',
                  subtitle: ApiConfig.friendlyError(e),
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(clientsProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return AfriEmptyState(
                      icon: Icons.people_outline,
                      title: 'Aucun client',
                      subtitle:
                          'Ajoute ton premier client pour commencer à facturer.',
                      actionLabel: 'Ajouter un client',
                      onAction: () => context.push('/clients/add'),
                    );
                  }
                  return RefreshIndicator(
                    color: AfriColors.teal,
                    onRefresh: () async => ref.invalidate(clientsProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return AfriFadeSlide(
                          delay: (i < 12 ? 40 * i : 0).ms,
                          child: AfriClientTile(
                            name: c['name'] as String,
                            phone: c['phone'] as String?,
                            amountDue: asDoubleOrNull(c['amount_due']),
                            onTap: () => context.push('/clients/${c['id']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AfriFab(
        label: 'Client',
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => context.push('/clients/add'),
      ),
    );
  }
}

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key, this.clientId});

  final String? clientId;

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = false;
  bool _loadingInitial = false;

  bool get _isEdit => widget.clientId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() => _loadingInitial = true);
    try {
      final c = await ref.read(apiClientProvider).getClient(widget.clientId!);
      _name.text = c['name'] as String? ?? '';
      _phone.text = c['phone'] as String? ?? '';
      _email.text = c['email'] as String? ?? '';
      _address.text = c['address'] as String? ?? '';
      _notes.text = c['notes'] as String? ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    String? emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();
    return {
      'name': _name.text.trim(),
      'phone': emptyToNull(_phone.text),
      'email': emptyToNull(_email.text),
      'address': emptyToNull(_address.text),
      'notes': emptyToNull(_notes.text),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: _loadingInitial
              ? const Center(
                  child: CircularProgressIndicator(color: AfriColors.teal))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      IconButton(
                        alignment: Alignment.centerLeft,
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        _isEdit ? 'Modifier le client' : 'Nouveau client',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coordonnées complètes pour facturer et relancer.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AfriColors.slate),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Nom complet / raison sociale *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone (WhatsApp)',
                          hintText: '+221 77 000 00 00',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final email = v?.trim() ?? '';
                          if (email.isEmpty) return null;
                          if (!email.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _address,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          hintText: 'Quartier, ville',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notes,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Notes internes',
                          hintText: 'Préférences, conditions de paiement…',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      AfriButton(
                        label: _isEdit
                            ? 'Enregistrer les modifications'
                            : 'Enregistrer le client',
                        isLoading: _loading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final isOnline =
                              ref.read(connectivityProvider).value ?? true;
                          try {
                            final payload = _payload();
                            if (_isEdit) {
                              await ref
                                  .read(apiClientProvider)
                                  .updateClient(widget.clientId!, payload);
                              ref.invalidate(
                                  clientDetailProvider(widget.clientId!));
                              ref.invalidate(
                                  clientInvoicesProvider(widget.clientId!));
                            } else if (isOnline) {
                              await ref
                                  .read(apiClientProvider)
                                  .createClient(payload);
                            } else {
                              final store =
                                  await ref.read(offlineStoreProvider.future);
                              final opId = await store.enqueueOperation(
                                entityType: 'client',
                                operation: 'create',
                                payload: payload,
                              );
                              final cached = store.getClients();
                              cached.insert(0, {
                                'id': 'local-$opId',
                                'client_op_id': opId,
                                ...payload,
                                'amount_due': 0,
                                'pending_sync': true,
                              });
                              await store.saveClients(cached);
                              ref
                                  .read(pendingOpsTickProvider.notifier)
                                  .state++;
                            }
                            ref.invalidate(clientsProvider);
                            if (context.mounted) context.pop();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('$e')));
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

final clientDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  if (!isOnline) {
    final store = await ref.watch(offlineStoreProvider.future);
    final local = store.getClients().cast<Map<String, dynamic>?>().firstWhere(
          (c) => c!['id'] == id,
          orElse: () => null,
        );
    if (local == null) throw Exception('Client introuvable hors ligne');
    return local;
  }
  return api.getClient(id);
});

final clientInvoicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clientId) async {
  final api = ref.watch(apiClientProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  if (!isOnline) {
    final store = await ref.watch(offlineStoreProvider.future);
    return store
        .getInvoices()
        .where((i) => i['client_id'] == clientId)
        .toList();
  }
  final list = await api.getInvoices();
  return List<Map<String, dynamic>>.from(list)
      .where((i) => i['client_id'] == clientId)
      .toList();
});

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientDetailProvider(clientId));
    final invoices = ref.watch(clientInvoicesProvider(clientId));

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: client.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AfriColors.teal)),
            error: (e, _) => AfriEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Client introuvable',
              subtitle: '$e',
              actionLabel: 'Retour',
              onAction: () => context.pop(),
            ),
            data: (c) {
              final name = c['name'] as String? ?? 'Client';
              final phone = c['phone'] as String?;
              final email = c['email'] as String?;
              final address = c['address'] as String?;
              final notes = c['notes'] as String?;
              final due = asDouble(c['amount_due']);
              final invoiced = asDouble(c['total_invoiced']);
              final clientInvoices =
                  invoices.valueOrNull ?? <Map<String, dynamic>>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () async {
                            await context.push('/clients/${clientId}/edit');
                            ref.invalidate(clientDetailProvider(clientId));
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        TextButton.icon(
                          onPressed: () => context
                              .push('/invoices/create?clientId=$clientId'),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Facturer'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        AfriFadeSlide(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AfriColors.tealSoft,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.sora(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AfriColors.tealDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                    if (phone != null && phone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(phone,
                                          style: const TextStyle(
                                              color: AfriColors.slate)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((email != null && email.isNotEmpty) ||
                            (address != null && address.isNotEmpty) ||
                            (notes != null && notes.isNotEmpty)) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AfriColors.mistDeep),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (email != null && email.isNotEmpty)
                                  _InfoRow(
                                      icon: Icons.email_outlined, label: email),
                                if (address != null && address.isNotEmpty)
                                  _InfoRow(
                                      icon: Icons.place_outlined,
                                      label: address),
                                if (notes != null && notes.isNotEmpty)
                                  _InfoRow(
                                      icon: Icons.notes_outlined, label: notes),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AfriKPICard(
                                label: 'À encaisser',
                                value: '$due',
                                isAmount: true,
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AfriKPICard(
                                label: 'Facturé',
                                value: '$invoiced',
                                isAmount: true,
                                icon: Icons.receipt_long_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        AfriSectionHeader(
                          title: 'Factures',
                          subtitle: clientInvoices.isEmpty
                              ? 'Aucune facture pour ce client'
                              : '${clientInvoices.length} facture(s)',
                        ),
                        const SizedBox(height: 12),
                        if (invoices.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AfriColors.teal)),
                          )
                        else if (clientInvoices.isEmpty)
                          AfriEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Pas encore de facture',
                            subtitle: 'Crée la première facture pour $name.',
                            actionLabel: 'Nouvelle facture',
                            onAction: () => context
                                .push('/invoices/create?clientId=$clientId'),
                          )
                        else
                          ...clientInvoices.map(
                            (inv) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AfriInvoiceTile(
                                number: inv['number'] as String,
                                clientName: name,
                                total: asDouble(inv['total']),
                                status: inv['status'] as String,
                                onTap: () =>
                                    context.push('/invoices/${inv['id']}'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        AfriButton(
                          label: 'Nouvelle facture',
                          icon: Icons.add,
                          onPressed: () => context
                              .push('/invoices/create?clientId=$clientId'),
                        ),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AfriButton(
                            label: 'Contacter sur WhatsApp',
                            variant: AfriButtonVariant.secondary,
                            icon: Icons.chat_outlined,
                            onPressed: () async {
                              final digits =
                                  phone.replaceAll(RegExp(r'[^\d+]'), '');
                              final uri = Uri.parse(
                                'https://wa.me/${digits.replaceFirst('+', '')}',
                              );
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AfriColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
