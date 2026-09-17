import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_url_dialog.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/utils/url_open.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_empty_state.dart';
import '../../core/widgets/afri_logo.dart';
import '../../core/widgets/afri_motion.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text('Paramètres',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 12),
              AfriFadeSlide(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AfriColors.mistDeep),
                  ),
                  child: Row(
                    children: [
                      const AfriLogo(height: 72),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'L\'OS de ton business',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Entreprise',
                subtitle: 'Devise, TVA, informations',
                onTap: () => context.push('/settings/business'),
              ),
              _SettingsTile(
                icon: Icons.payment_outlined,
                title: 'Intégrations Mobile Money',
                subtitle: 'FedaPay — Wave, Moov, MTN…',
                onTap: () => context.push('/settings/payments'),
              ),
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Abonnement',
                subtitle: 'Gratuit · Pro · Entreprise',
                onTap: () => context.push('/settings/subscription'),
              ),
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Relances automatiques',
                subtitle: 'J+3, J+7, J+14',
                onTap: () => context.push('/reminders'),
              ),
              _SettingsTile(
                icon: Icons.dns_outlined,
                title: 'Serveur API',
                subtitle: ApiConfig.baseUrl,
                onTap: () => showApiUrlDialog(context),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Aide & Support',
                subtitle: 'Guides et contact',
                onTap: () => context.push('/settings/help'),
              ),
              const SizedBox(height: 28),
              AfriButton(
                label: 'Déconnexion',
                variant: AfriButtonVariant.soft,
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AfriColors.mistDeep),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AfriColors.tealSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AfriColors.tealDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AfriColors.slate)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AfriColors.slate.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

final businessProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).getBusiness();
});

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState
    extends ConsumerState<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tax = TextEditingController();
  String _sector = 'Boutique';
  String _country = 'SN';
  String _currency = 'XOF';
  bool _loading = false;
  bool _ready = false;

  static const _countries = [
    ('SN', 'Sénégal'),
    ('CI', "Côte d'Ivoire"),
    ('BF', 'Burkina Faso'),
    ('ML', 'Mali'),
    ('GN', 'Guinée'),
    ('TG', 'Togo'),
    ('BJ', 'Bénin'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await ref.read(apiClientProvider).getBusiness();
      _name.text = b['name'] as String? ?? '';
      _sector = (b['sector'] as String?) ?? 'Boutique';
      _country = (b['country_code'] as String?) ?? 'SN';
      _currency = (b['currency'] as String?) ?? 'XOF';
      _tax.text = '${b['tax_rate'] ?? 0}';
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: AfriColors.teal))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
                      Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                          Text('Entreprise',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nom *'),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Nom requis'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Secteur',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Boutique',
                          'Restaurant',
                          'Services',
                          'Artisanat',
                          'Autre'
                        ].map((s) {
                          final selected = _sector == s;
                          return ChoiceChip(
                            label: Text(s),
                            selected: selected,
                            onSelected: (_) => setState(() => _sector = s),
                            selectedColor: AfriColors.tealSoft,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _country,
                        decoration: const InputDecoration(labelText: 'Pays'),
                        items: _countries
                            .map((c) => DropdownMenuItem(
                                value: c.$1, child: Text(c.$2)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _country = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Devise'),
                        items: const [
                          DropdownMenuItem(
                              value: 'XOF', child: Text('FCFA (XOF)')),
                          DropdownMenuItem(value: 'GNF', child: Text('GNF')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tax,
                        decoration: const InputDecoration(labelText: 'TVA (%)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 28),
                      AfriButton(
                        label: 'Enregistrer',
                        isLoading: _loading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          try {
                            final res = await ref
                                .read(apiClientProvider)
                                .updateBusiness({
                              'name': _name.text.trim(),
                              'sector': _sector,
                              'country_code': _country,
                              'currency': _currency,
                              'tax_rate': double.tryParse(
                                      _tax.text.replaceAll(',', '.')) ??
                                  0,
                            });
                            await ref
                                .read(authStateProvider.notifier)
                                .setBusinessName(res['name'].toString());
                            ref.invalidate(businessProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Entreprise mise à jour')),
                              );
                              context.pop();
                            }
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

class PaymentIntegrationsScreen extends ConsumerStatefulWidget {
  const PaymentIntegrationsScreen({super.key});

  @override
  ConsumerState<PaymentIntegrationsScreen> createState() =>
      _PaymentIntegrationsScreenState();
}

class _PaymentIntegrationsScreenState
    extends ConsumerState<PaymentIntegrationsScreen> {
  final _publicKey = TextEditingController();
  final _secretKey = TextEditingController();
  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;
  bool _secretSet = false;
  bool _sandboxMode = true;
  bool _usingPlatformKeys = false;
  String _callbackUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getPaymentSettings();
      _publicKey.text =
          (data['public_key'] as String?) ?? (data['site_id'] as String?) ?? '';
      _enabled = data['enabled'] as bool? ?? false;
      _secretSet = (data['secret_key_set'] as bool?) ??
          (data['api_key_set'] as bool?) ??
          false;
      _sandboxMode = data['sandbox_mode'] as bool? ?? true;
      _usingPlatformKeys = data['using_platform_keys'] as bool? ?? false;
      _callbackUrl = (data['callback_url'] as String?) ??
          (data['notify_url'] as String?) ??
          '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _publicKey.dispose();
    _secretKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Text('FedaPay',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _sandboxMode
                          ? 'Mode sandbox : sans clés FedaPay, AfriOS ouvre une page de test qui confirme le paiement.'
                          : 'FedaPay connecté. Tes clients peuvent payer en Mobile Money.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AfriColors.slate, height: 1.4),
                    ),
                    if (_usingPlatformKeys) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Clés plateforme AfriOS utilisées (fallback serveur).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AfriColors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    if (_callbackUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Callback : $_callbackUrl',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AfriColors.slate),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activer Mobile Money'),
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _publicKey,
                      decoration: const InputDecoration(
                          labelText: 'Clé publique FedaPay'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _secretKey,
                      decoration: InputDecoration(
                        labelText: _secretSet
                            ? 'Nouvelle clé secrète (laisser vide pour garder)'
                            : 'Clé secrète FedaPay',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 28),
                    AfriButton(
                      label: 'Enregistrer sur le serveur',
                      isLoading: _saving,
                      onPressed: () async {
                        setState(() => _saving = true);
                        try {
                          final payload = <String, dynamic>{
                            'public_key': _publicKey.text.trim(),
                            'enabled': _enabled,
                          };
                          final key = _secretKey.text.trim();
                          if (key.isNotEmpty) {
                            payload['secret_key'] = key;
                          }
                          final data = await ref
                              .read(apiClientProvider)
                              .updatePaymentSettings(payload);
                          _secretKey.clear();
                          _secretSet = (data['secret_key_set'] as bool?) ??
                              (data['api_key_set'] as bool?) ??
                              _secretSet;
                          _sandboxMode =
                              data['sandbox_mode'] as bool? ?? _sandboxMode;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Configuration FedaPay synchronisée')),
                            );
                            context.pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur : $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final current = await api.getCurrentSubscription();
      final plansRes = await api.getBillingPlans();
      final plans = List<Map<String, dynamic>>.from(
          (plansRes['plans'] as List?) ?? []);
      if (mounted) {
        setState(() {
          _current = current;
          _plans = plans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _subscribe(String planId) async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.subscribePlan(planId);
      final link = res['payment_link'] as String?;
      final tx = res['transaction_id'] as String?;
      if (link != null && link.isNotEmpty && mounted) {
        await openExternalUrl(
          context,
          link,
          successMessage: 'Page de paiement ouverte — confirme puis reviens.',
        );
        if (tx != null && mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Paiement terminé ?'),
              content: const Text(
                  'Si tu as confirmé le paiement FedaPay / sandbox, valide ici.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Plus tard')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirmer')),
              ],
            ),
          );
          if (confirm == true) {
            await api.confirmSubscription(transactionId: tx, planId: planId);
            await _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abonnement mis à jour')),
              );
            }
          }
        }
      } else {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan Gratuit activé')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId =
        (_current?['plan_id'] as String?) ?? 'free';

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Text('Abonnement',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan actuel : ${(_current?['plan'] as Map?)?['name'] ?? currentId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AfriColors.teal),
                    ),
                    const SizedBox(height: 16),
                    ..._plans.map((plan) {
                      final id = plan['id'] as String? ?? '';
                      final price = plan['price_monthly'] ?? 0;
                      final features =
                          List<String>.from((plan['features'] as List?) ?? []);
                      final selected = id == currentId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AfriColors.teal
                                : AfriColors.mistDeep,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plan['name'] as String? ?? id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  ),
                                ),
                                Text(
                                  price == 0
                                      ? 'Gratuit'
                                      : '$price FCFA/mois',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              plan['tagline'] as String? ?? '',
                              style: const TextStyle(
                                  color: AfriColors.slate, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            ...features.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 16, color: AfriColors.teal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(f,
                                            style:
                                                const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AfriButton(
                              label: selected
                                  ? 'Plan actuel'
                                  : (price == 0
                                      ? 'Passer en Gratuit'
                                      : 'Choisir ce plan'),
                              isLoading: _busy,
                              onPressed: selected
                                  ? null
                                  : () => _subscribe(id),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text('Aide & Support',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              _HelpCard(
                title: 'Démarrer',
                body:
                    '1. Ajoute un client\n2. Crée une facture\n3. Envoie-la sur WhatsApp\n4. Encaisse en espèces ou Mobile Money',
              ),
              _HelpCard(
                title: 'Connexion',
                body:
                    'L\'app utilise https://afrios-api.onrender.com/v1 par défaut (4G / Wi‑Fi).\n'
                    'OTP SMS : Africa\'s Talking doit être configuré sur le serveur.\n'
                    'Paiements : FedaPay (clés dans Paramètres → FedaPay).',
              ),
              _HelpCard(
                title: 'Support beta',
                body:
                    'WhatsApp support : +221 77 000 00 00\nEmail : support@afrios.app',
              ),
              const SizedBox(height: 12),
              AfriButton(
                label: 'Écrire sur WhatsApp',
                icon: Icons.chat_outlined,
                onPressed: () => launchUrl(
                  Uri.parse('https://wa.me/221770000000'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 12),
              AfriButton(
                label: 'Copier l\'URL API actuelle',
                variant: AfriButtonVariant.secondary,
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: ApiConfig.baseUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL API copiée')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AfriColors.mistDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(color: AfriColors.slate, height: 1.45)),
        ],
      ),
    );
  }
}

final overdueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final list = await ref.watch(apiClientProvider).getOverdueReminders();
  return List<Map<String, dynamic>>.from(list);
});

final reminderRulesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).getReminderRules();
});

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(reminderRulesProvider);
    final overdue = ref.watch(overdueProvider);

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text('Relances',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 12),
              rules.when(
                loading: () =>
                    const LinearProgressIndicator(color: AfriColors.teal),
                error: (e, _) => Text('$e'),
                data: (r) {
                  final enabled = r['enabled'] as bool? ?? true;
                  final days = List<int>.from(
                      (r['days_after_due'] as List?) ?? [3, 7, 14]);
                  final template = r['message_template'] as String? ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Relances automatiques',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle:
                            const Text('Envoie des rappels après l\'échéance'),
                        value: enabled,
                        activeThumbColor: AfriColors.teal,
                        onChanged: (v) async {
                          setState(() => _saving = true);
                          try {
                            await ref
                                .read(apiClientProvider)
                                .updateReminderRules({'enabled': v});
                            ref.invalidate(reminderRulesProvider);
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Jours après échéance : ${days.join(', ')}',
                          style: const TextStyle(color: AfriColors.slate)),
                      const SizedBox(height: 8),
                      if (template.isNotEmpty)
                        Text('Modèle : $template',
                            style: const TextStyle(
                                color: AfriColors.slate, height: 1.35)),
                      if (_saving)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child:
                              LinearProgressIndicator(color: AfriColors.teal),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              AfriSectionHeader(
                  title: 'Factures en retard',
                  subtitle: 'Relance manuelle WhatsApp'),
              const SizedBox(height: 12),
              overdue.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AfriColors.teal)),
                error: (e, _) => Text('$e'),
                data: (list) {
                  if (list.isEmpty) {
                    return const AfriEmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Rien en retard',
                      subtitle: 'Aucune facture à relancer pour le moment.',
                    );
                  }
                  return Column(
                    children: list.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AfriColors.mistDeep),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['invoice_number']} — ${item['client_name']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${item['total']} FCFA',
                                    style: const TextStyle(
                                        color: AfriColors.slate, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final res = await ref
                                    .read(apiClientProvider)
                                    .sendReminder(item['invoice_id'] as String);
                                final url = res['whatsapp_url'] as String?;
                                if (url != null) {
                                  await launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Text('Relancer'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
