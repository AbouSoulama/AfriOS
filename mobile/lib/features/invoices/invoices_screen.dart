import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/shell.dart';
import '../../core/database/sync_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/utils/parsing.dart';
import '../../core/utils/url_open.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_amount.dart';
import '../../core/widgets/afri_components.dart';
import '../../core/widgets/afri_motion.dart';
import '../../core/widgets/afri_offline_banner.dart';
import '../../core/widgets/afri_premium.dart';
import '../../core/widgets/afri_status_badge.dart';
import '../../core/widgets/afri_empty_state.dart';
import '../clients/clients_screen.dart';
import '../products/products_screen.dart';

final invoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? true;
  if (!isOnline) {
    final store = await ref.watch(offlineStoreProvider.future);
    return store.getInvoices();
  }
  try {
    final list = await api.getInvoices();
    final mapped = List<Map<String, dynamic>>.from(list);
    final store = await ref.watch(offlineStoreProvider.future);
    // Keep pending local drafts visible until sync completes.
    final localPending = store
        .getInvoices()
        .where((i) => i['pending_sync'] == true)
        .toList();
    final merged = [...localPending, ...mapped];
    await store.saveInvoices(merged);
    return merged;
  } catch (_) {
    final store = await ref.watch(offlineStoreProvider.future);
    return store.getInvoices();
  }
});

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  static const _filters = ['Toutes', 'En attente', 'En retard', 'Payées'];
  static const _statuses = [null, 'sent', 'overdue', 'paid'];

  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);
    final bottomPad = shellBottomClearance(context);

    return Scaffold(
      body: AfriMeshBackground(
        child: Column(
          children: [
            const SafeArea(bottom: false, child: AfriOfflineBanner()),
            AfriListHeader(
              title: 'Factures',
              subtitle: 'Suivi & encaissement',
              count: invoices.value?.length,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, AfriSpace.sm),
              child: AfriPillTabs(
                labels: _filters,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
            Expanded(
              child: invoices.when(
                loading: () => const AfriSkeletonList(showAvatar: false),
                error: (e, _) => AfriEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Erreur de chargement',
                  subtitle: ApiConfig.friendlyError(e),
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(invoicesProvider),
                ),
                data: (all) {
                  final wanted = _statuses[_filter];
                  final list = wanted == null
                      ? all
                      : all.where((i) => i['status'] == wanted).toList();

                  if (all.isEmpty) {
                    return AfriEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucune facture',
                      subtitle:
                          'Crée ta première facture et envoie-la par WhatsApp.',
                      actionLabel: 'Nouvelle facture',
                      onAction: () => context.push('/invoices/create'),
                    );
                  }
                  if (list.isEmpty) {
                    return AfriEmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Rien dans « ${_filters[_filter]} »',
                      subtitle:
                          'Change de filtre pour voir tes autres factures.',
                      actionLabel: 'Voir toutes',
                      onAction: () => setState(() => _filter = 0),
                    );
                  }
                  return RefreshIndicator(
                    color: AfriColors.teal,
                    onRefresh: () async {
                      final online =
                          ref.read(connectivityProvider).value ?? true;
                      final sync = await ref.read(syncServiceProvider.future);
                      await sync.syncIfOnline(online);
                      ref.read(pendingOpsTickProvider.notifier).state++;
                      ref.invalidate(invoicesProvider);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final inv = list[i];
                        return AfriFadeSlide(
                          delay: (i < 12 ? 35 * i : 0).ms,
                          child: AfriInvoiceTile(
                            number: inv['number'] as String,
                            clientName: inv['client_name'] as String? ?? '',
                            total: asDouble(inv['total']),
                            status: inv['status'] as String,
                            subtitle: _dueLabel(inv),
                            leadingIcon: Icons.description_outlined,
                            onTap: () {
                              final id = inv['id'] as String;
                              if (inv['pending_sync'] == true ||
                                  id.startsWith('local-')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Facture locale — sera disponible après synchronisation'),
                                  ),
                                );
                                return;
                              }
                              context.push('/invoices/$id');
                            },
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
        label: 'Facture',
        icon: Icons.add_rounded,
        onPressed: () => context.push('/invoices/create'),
      ),
    );
  }

  String? _dueLabel(Map<String, dynamic> invoice) {
    final raw = invoice['due_date'] as String?;
    if (raw == null) return null;
    final due = DateTime.tryParse(raw);
    if (due == null) return null;

    final days = due.difference(DateTime.now()).inDays;
    if (invoice['status'] == 'paid') return 'réglée';
    if (days < 0) return 'échue depuis ${-days} j';
    if (days == 0) return 'échéance aujourd\'hui';
    return 'échéance dans $days j';
  }
}

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key, this.initialClientId});

  final String? initialClientId;

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  String? _clientId;
  final List<_LineItem> _items = [];
  final _notes = TextEditingController();
  DateTime? _dueDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _clientId = widget.initialClientId;
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final products = ref.watch(productsProvider);

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Nouvelle facture',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    clients.when(
                      loading: () =>
                          const LinearProgressIndicator(color: AfriColors.teal),
                      error: (e, _) => Text('Erreur clients: $e'),
                      data: (list) => DropdownButtonFormField<String>(
                        initialValue: _clientId != null &&
                                list.any((c) => c['id'] == _clientId)
                            ? _clientId
                            : null,
                        decoration: const InputDecoration(labelText: 'Client'),
                        items: list
                            .map((c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Produits',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextButton.icon(
                          onPressed: () => _showAddItem(products),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    ..._items.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.description),
                          subtitle: Text(
                              '${item.quantity} × ${item.unitPrice} FCFA'),
                          trailing:
                              Text('${item.lineTotal.toStringAsFixed(0)} FCFA'),
                          onTap: () => _editItemQuantity(item),
                          onLongPress: () =>
                              setState(() => _items.remove(item)),
                        )),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Ajoute un produit et choisis la quantité. '
                          'Appui court : modifier la quantité. Appui long : retirer.',
                          style:
                              TextStyle(color: AfriColors.slate, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date d\'échéance'),
                      subtitle: Text(
                        _dueDate == null
                            ? 'Non définie'
                            : '${_dueDate!.day.toString().padLeft(2, '0')}/'
                                '${_dueDate!.month.toString().padLeft(2, '0')}/'
                                '${_dueDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ??
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                    TextField(
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes / conditions',
                        hintText: 'Délai de paiement, mention légale…',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total : ${_items.fold<double>(0, (s, i) => s + i.lineTotal).toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    AfriButton(
                      label: 'Enregistrer comme brouillon',
                      variant: AfriButtonVariant.secondary,
                      isLoading: _loading,
                      onPressed: () => _save(send: false),
                    ),
                    const SizedBox(height: 12),
                    AfriButton(
                      label: 'Envoyer par WhatsApp',
                      icon: Icons.send,
                      isLoading: _loading,
                      onPressed: () => _save(send: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItem(AsyncValue<List<Map<String, dynamic>>> products) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(ApiConfig.friendlyError(e)),
        ),
        data: (list) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Ajouter un produit',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Ligne personnalisée'),
              subtitle: const Text('Sans produit du stock'),
              onTap: () {
                Navigator.pop(ctx);
                _addCustomItem();
              },
            ),
            const Divider(height: 1),
            ...list.map((p) {
              final stock = asInt(p['quantity']);
              return ListTile(
                title: Text(p['name'] as String),
                subtitle: Text(
                  '${p['price']} FCFA'
                  '${stock > 0 ? ' · Stock : $stock' : ''}',
                ),
                trailing: const Icon(Icons.add_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _addProductItem(p);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Demande la quantité avant d'ajouter un produit du stock à la facture.
  Future<void> _addProductItem(Map<String, dynamic> product) async {
    final qtyCtrl = TextEditingController(text: '1');
    final stock = asInt(product['quantity']);
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product['name'] as String? ?? 'Produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prix unitaire : ${product['price']} FCFA'
              '${stock > 0 ? '\nStock disponible : $stock' : ''}',
              style: const TextStyle(color: AfriColors.slate, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité demandée *',
                hintText: 'Ex. 2, 5, 10…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (qty < 1) return;
              Navigator.pop(ctx, qty);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    qtyCtrl.dispose();
    if (confirmed == null || !mounted) return;
    setState(() {
      _items.add(_LineItem(
        description: product['name'] as String,
        quantity: confirmed,
        unitPrice: asDouble(product['price']),
        productId: product['id'] as String,
      ));
    });
  }

  Future<void> _editItemQuantity(_LineItem item) async {
    final qtyCtrl = TextEditingController(text: '${item.quantity}');
    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.description),
        content: TextField(
          controller: qtyCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantité demandée *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (qty < 1) return;
              Navigator.pop(ctx, qty);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    qtyCtrl.dispose();
    if (confirmed == null || !mounted) return;
    setState(() {
      final index = _items.indexOf(item);
      if (index < 0) return;
      _items[index] = _LineItem(
        description: item.description,
        quantity: confirmed,
        unitPrice: item.unitPrice,
        discount: item.discount,
        productId: item.productId,
      );
    });
  }

  void _addCustomItem() {
    final desc = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController();
    final discount = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une ligne'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: desc,
                  decoration:
                      const InputDecoration(labelText: 'Description *')),
              TextField(
                  controller: qty,
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: price,
                  decoration: const InputDecoration(labelText: 'Prix unitaire'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: discount,
                  decoration: const InputDecoration(labelText: 'Remise (FCFA)'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              setState(() {
                _items.add(_LineItem(
                  description: desc.text,
                  quantity: int.tryParse(qty.text) ?? 1,
                  unitPrice: double.tryParse(price.text) ?? 0,
                  discount: double.tryParse(discount.text) ?? 0,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({required bool send}) async {
    if (_clientId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Client et au moins un produit requis')));
      return;
    }
    setState(() => _loading = true);
    final isOnline = ref.read(connectivityProvider).value ?? true;
    try {
      final payload = <String, dynamic>{
        'notes': _notes.text.isEmpty ? null : _notes.text,
        if (_dueDate != null) 'due_date': _dueDate!.toUtc().toIso8601String(),
        'items': _items
            .map((i) => {
                  'description': i.description,
                  'quantity': i.quantity,
                  'unit_price': i.unitPrice,
                  'discount': i.discount,
                  if (i.productId != null &&
                      !i.productId!.startsWith('local-'))
                    'product_id': i.productId,
                })
            .toList(),
      };

      final clientId = _clientId!;
      if (clientId.startsWith('local-')) {
        payload['client_op_id'] = clientId.substring('local-'.length);
      } else {
        payload['client_id'] = clientId;
      }

      if (!isOnline) {
        if (send) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Hors ligne : la facture sera enregistrée, l\'envoi WhatsApp se fera après sync.'),
          ));
        }
        final store = await ref.read(offlineStoreProvider.future);
        final opId = await store.enqueueOperation(
          entityType: 'invoice',
          operation: 'create',
          payload: payload,
        );
        final clients = store.getClients();
        final clientName = clients
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (c) => c!['id'] == clientId,
              orElse: () => null,
            )?['name'] as String? ??
            'Client';
        final subtotal = _items.fold<double>(0, (s, i) => s + i.lineTotal);
        final local = {
          'id': 'local-$opId',
          'number': 'BROUILLON',
          'status': 'draft',
          'client_id': clientId,
          'client_name': clientName,
          'subtotal': subtotal,
          'tax': 0,
          'total': subtotal,
          'notes': payload['notes'],
          'due_date': payload['due_date'],
          'payment_link': null,
          'created_at': DateTime.now().toIso8601String(),
          'items': payload['items'],
          'pending_sync': true,
        };
        final cached = store.getInvoices();
        cached.insert(0, local);
        await store.saveInvoices(cached);
        ref.read(pendingOpsTickProvider.notifier).state++;
        ref.invalidate(invoicesProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Facture enregistrée hors ligne'),
        ));
        context.pop();
        return;
      }

      final api = ref.read(apiClientProvider);
      final invoice = await api.createInvoice(payload);

      if (send) {
        final result = await api.sendInvoice(invoice['id'] as String);
        final waMessage = result['whatsapp_message'] as String;
        await Share.share(waMessage, subject: 'Facture AfriOS');
      }

      ref.invalidate(invoicesProvider);
      if (!mounted) return;
      if (send) {
        context.go('/invoices/${invoice['id']}');
      } else {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiConfig.friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _LineItem {
  _LineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.discount = 0,
  });

  final String description;
  final int quantity;
  final double unitPrice;
  final String? productId;
  final double discount;
  double get lineTotal => (quantity * unitPrice) - discount;
}

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _busy = false;

  /// Crée le lien Mobile Money et propose de l'ENVOYER AU CLIENT.
  /// C'est le client qui paie : le commerçant n'ouvre pas ce lien pour lui-même.
  Future<void> _createPaymentLink(Map<String, dynamic> inv) async {
    setState(() => _busy = true);
    try {
      final res =
          await ref.read(apiClientProvider).initiatePayment(widget.invoiceId);
      final link = res['payment_link'] as String?;
      final sandbox = res['sandbox_mock'] as bool? ?? false;
      if (link == null || link.isEmpty) {
        throw Exception('Aucun lien de paiement reçu du serveur');
      }
      if (!mounted) return;
      await _showPaymentLinkSheet(inv, link, sandbox);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiConfig.friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPaymentLinkSheet(
      Map<String, dynamic> inv, String link, bool sandbox) {
    final clientName = inv['client_name'] as String? ?? 'Client';
    final number = inv['number'] as String? ?? '';
    final total = asDouble(inv['total']).toStringAsFixed(0);
    final message =
        'Bonjour $clientName, voici le lien pour régler la facture $number '
        '($total FCFA) par Mobile Money : $link';

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lien de paiement pour $clientName',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Envoie ce lien à ton client : c’est lui qui paie, et l’argent '
                'arrive sur ton compte Mobile Money. Ensuite, reviens ici et '
                'appuie sur « Vérifier l’encaissement ».',
                style: TextStyle(color: AfriColors.slate, height: 1.4),
              ),
              const SizedBox(height: 18),
              AfriButton(
                label: 'Envoyer au client',
                icon: Icons.send_rounded,
                onPressed: () =>
                    Share.share(message, subject: 'Facture $number'),
              ),
              const SizedBox(height: 10),
              AfriButton(
                label: 'Copier le lien',
                icon: Icons.copy_rounded,
                variant: AfriButtonVariant.secondary,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Lien copié')),
                    );
                  }
                },
              ),
              if (sandbox) ...[
                const SizedBox(height: 10),
                AfriButton(
                  label: 'Mode test : simuler le paiement du client',
                  icon: Icons.science_outlined,
                  variant: AfriButtonVariant.ghost,
                  onPressed: () => openExternalUrl(
                    sheetContext,
                    link,
                    successMessage:
                        'Page de test ouverte : tu joues le rôle du client. Confirme, puis reviens vérifier l’encaissement.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: invoiceAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AfriColors.teal)),
            error: (e, _) => AfriEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Facture introuvable',
              subtitle: '$e',
              actionLabel: 'Retour',
              onAction: () => context.pop(),
            ),
            data: (inv) {
              final items = List<Map<String, dynamic>>.from(
                  (inv['items'] as List?) ?? []);
              final status = inv['status'] as String;
              final isPaid = status == 'paid';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            inv['number'] as String? ?? 'Facture',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        AfriStatusBadge(status: status),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Text(
                          inv['client_name'] as String? ?? 'Client',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        AfriAmount(
                          amount: asDouble(inv['total']),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (inv['notes'] != null &&
                            (inv['notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            inv['notes'] as String,
                            style: const TextStyle(color: AfriColors.slate),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AfriSectionHeader(
                            title: 'Lignes',
                            subtitle: '${items.length} article(s)'),
                        const SizedBox(height: 10),
                        ...items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['description'] as String? ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        '${item['quantity']} × ${item['unit_price']} FCFA',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AfriColors.slate),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${asDouble(item['line_total']).toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isPaid) ...[
                          const AfriSectionHeader(
                            title: 'Encaissement',
                            subtitle:
                                'C’est ton client qui paie. Toi, tu suis ou tu confirmes l’encaissement.',
                          ),
                          const SizedBox(height: 12),
                          AfriButton(
                            label: 'Envoyer le lien de paiement au client',
                            icon: Icons.send_rounded,
                            isLoading: _busy,
                            onPressed: () => _createPaymentLink(inv),
                          ),
                          const SizedBox(height: 12),
                          AfriButton(
                            label: 'Vérifier l’encaissement',
                            variant: AfriButtonVariant.secondary,
                            icon: Icons.refresh_rounded,
                            isLoading: _busy,
                            onPressed: () async {
                              setState(() => _busy = true);
                              try {
                                final res = await ref
                                    .read(apiClientProvider)
                                    .verifyPayment(invoiceId: widget.invoiceId);
                                final status = res['status'] as String? ?? '';
                                ref.invalidate(
                                    invoiceDetailProvider(widget.invoiceId));
                                ref.invalidate(invoicesProvider);
                                if (context.mounted) {
                                  final msg = switch (status) {
                                    'paid' || 'already_paid' =>
                                      'Encaissement confirmé — facture payée',
                                    'pending' =>
                                      'Le client n’a pas encore payé',
                                    _ => 'Statut : $status',
                                  };
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ApiConfig.friendlyError(e))),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          AfriButton(
                            label: 'Client a payé en espèces',
                            variant: AfriButtonVariant.ghost,
                            icon: Icons.payments_outlined,
                            isLoading: _busy,
                            onPressed: () async {
                              setState(() => _busy = true);
                              try {
                                await ref
                                    .read(apiClientProvider)
                                    .markPaid(widget.invoiceId);
                                ref.invalidate(
                                    invoiceDetailProvider(widget.invoiceId));
                                ref.invalidate(invoicesProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Facture marquée comme payée')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ApiConfig.friendlyError(e))),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          AfriButton(
                            label: 'Relancer le client',
                            variant: AfriButtonVariant.ghost,
                            icon: Icons.chat_outlined,
                            isLoading: _busy,
                            onPressed: () async {
                              setState(() => _busy = true);
                              try {
                                final res = await ref
                                    .read(apiClientProvider)
                                    .sendReminder(widget.invoiceId);
                                final url = res['whatsapp_url'] as String?;
                                if (url != null) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(ApiConfig.friendlyError(e))),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AfriColors.tealSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: AfriColors.teal),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Encaissée — ton client a payé cette facture',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

final invoiceDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(apiClientProvider).getInvoice(id);
});
