import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_url_dialog.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_empty_state.dart';
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
                    gradient: AfriColors.tealGlow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AfriOS',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'L\'OS de ton business',
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.85)),
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
                subtitle: 'CinetPay — Wave, Orange Money',
                onTap: () => context.push('/settings/payments'),
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

class PaymentIntegrationsScreen extends StatefulWidget {
  const PaymentIntegrationsScreen({super.key});

  @override
  State<PaymentIntegrationsScreen> createState() =>
      _PaymentIntegrationsScreenState();
}

class _PaymentIntegrationsScreenState extends State<PaymentIntegrationsScreen> {
  final _siteId = TextEditingController();
  final _apiKey = TextEditingController();
  final _notifyUrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _siteId.text = prefs.getString('cinetpay_site_id') ?? '';
    _apiKey.text = prefs.getString('cinetpay_api_key') ?? '';
    _notifyUrl.text = prefs.getString('cinetpay_notify_url') ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _siteId.dispose();
    _apiKey.dispose();
    _notifyUrl.dispose();
    super.dispose();
  }

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
                  Text('Mobile Money',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Configure CinetPay pour accepter Wave, Orange Money et Moov. '
                'Les clés serveur restent dans l\'API ; ici tu notes tes identifiants marchand.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AfriColors.slate, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _siteId,
                decoration:
                    const InputDecoration(labelText: 'CinetPay Site ID'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKey,
                decoration: const InputDecoration(
                    labelText: 'Clé API (référence locale)'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notifyUrl,
                decoration: const InputDecoration(
                  labelText: 'URL de notification (webhook)',
                  hintText: 'https://api.afrios.app/v1/payments/webhook',
                ),
              ),
              const SizedBox(height: 28),
              AfriButton(
                label: 'Enregistrer',
                isLoading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                      'cinetpay_site_id', _siteId.text.trim());
                  await prefs.setString(
                      'cinetpay_api_key', _apiKey.text.trim());
                  await prefs.setString(
                      'cinetpay_notify_url', _notifyUrl.text.trim());
                  if (mounted) {
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Préférences Mobile Money enregistrées')),
                    );
                    context.pop();
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
                title: 'Connexion téléphone ↔ API',
                body:
                    'USB : adb reverse tcp:8000 tcp:8000 puis URL http://127.0.0.1:8000/v1\n'
                    'Wi‑Fi : http://IP_DU_PC:8000/v1 (même réseau)',
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
