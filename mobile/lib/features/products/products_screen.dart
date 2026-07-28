import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/afri_colors.dart';
import '../../core/utils/parsing.dart';
import '../../core/widgets/afri_amount.dart';
import '../../core/widgets/afri_button.dart';
import '../../core/widgets/afri_empty_state.dart';
import '../../core/widgets/afri_motion.dart';
import '../../core/widgets/afri_premium.dart';

final productsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.getProducts();
  return List<Map<String, dynamic>>.from(list);
});

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final bottomPad = shellBottomClearance(context);

    return Scaffold(
      body: AfriMeshBackground(
        child: Column(
          children: [
            AfriListHeader(
              title: 'Stock',
              subtitle: 'Produits & alertes',
              count: products.value?.length,
            ),
            Expanded(
              child: products.when(
                loading: () => const AfriSkeletonList(),
                error: (e, _) => AfriEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Erreur de chargement',
                  subtitle: ApiConfig.friendlyError(e),
                  actionLabel: 'Réessayer',
                  onAction: () => ref.invalidate(productsProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return AfriEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucun produit',
                      subtitle: 'Ajoute tes produits pour gérer ton stock.',
                      actionLabel: 'Ajouter un produit',
                      onAction: () => context.push('/stock/add'),
                    );
                  }
                  return RefreshIndicator(
                    color: AfriColors.teal,
                    onRefresh: () async => ref.invalidate(productsProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => AfriFadeSlide(
                        delay: (i < 12 ? 35 * i : 0).ms,
                        child: _ProductTile(
                          product: list[i],
                          onTap: () => context.push('/stock/${list[i]['id']}'),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AfriFab(
        label: 'Produit',
        icon: Icons.add_rounded,
        onPressed: () => context.push('/stock/add'),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLow = product['is_low_stock'] as bool? ?? false;
    final quantity = asDouble(product['quantity']);
    final threshold = asDouble(product['low_stock_threshold'], 5);
    final accent = isLow ? AfriColors.orange : AfriColors.teal;

    // Full ring at 3x the alert threshold keeps the gauge readable for both
    // fast movers and slow stock.
    final ratio =
        threshold <= 0 ? 1.0 : (quantity / (threshold * 3)).clamp(0.04, 1.0);

    return AfriPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AfriRadius.rLg,
          border: Border.all(color: AfriColors.line),
          boxShadow: AfriShadow.subtle,
        ),
        child: Row(
          children: [
            AfriProgressRing(
              value: ratio,
              size: 48,
              stroke: 5,
              color: accent,
              label: Text(
                '${quantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: AfriSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AfriColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AfriAmount(
                        amount: asDouble(product['price']),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        color: AfriColors.slate,
                      ),
                      if (product['category'] != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                              color: AfriColors.slateLight, fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            '${product['category']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AfriColors.slateLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AfriSpace.xs),
            if (isLow)
              const AfriPill(
                label: 'Faible',
                color: AfriColors.orange,
                icon: Icons.warning_amber_rounded,
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AfriColors.slateLight,
              ),
          ],
        ),
      ),
    );
  }
}

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.productId, this.initial});

  final String? productId;
  final Map<String, dynamic>? initial;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '5');
  final _category = TextEditingController();
  bool _loading = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _name.text = p['name'] as String? ?? '';
      _price.text = '${p['price'] ?? ''}';
      _qty.text = '${p['quantity'] ?? 0}';
      _threshold.text = '${p['low_stock_threshold'] ?? 5}';
      _category.text = p['category'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    _threshold.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: Form(
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
                  _isEdit ? 'Modifier le produit' : 'Nouveau produit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Prix, stock et seuil d\'alerte pour ton inventaire.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AfriColors.slate),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(labelText: 'Nom du produit *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nom obligatoire'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    hintText: 'Ex. Boissons, Épicerie, Services',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                      labelText: 'Prix unitaire (FCFA) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Prix obligatoire';
                    if (double.tryParse(v.replaceAll(',', '.')) == null)
                      return 'Nombre invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qty,
                  decoration:
                      const InputDecoration(labelText: 'Quantité en stock *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (int.tryParse(v ?? '') == null) return 'Entier requis';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _threshold,
                  decoration: const InputDecoration(
                    labelText: 'Seuil stock faible *',
                    helperText:
                        'Alerte quand la quantité atteint ou passe sous ce seuil',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (int.tryParse(v ?? '') == null) return 'Entier requis';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AfriButton(
                  label: _isEdit ? 'Enregistrer' : 'Créer le produit',
                  isLoading: _loading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _loading = true);
                    try {
                      final payload = {
                        'name': _name.text.trim(),
                        'price':
                            double.tryParse(_price.text.replaceAll(',', '.')) ??
                                0,
                        'quantity': int.tryParse(_qty.text) ?? 0,
                        'low_stock_threshold':
                            int.tryParse(_threshold.text) ?? 5,
                        'category': _category.text.trim().isEmpty
                            ? null
                            : _category.text.trim(),
                      };
                      if (_isEdit) {
                        await ref
                            .read(apiClientProvider)
                            .updateProduct(widget.productId!, payload);
                      } else {
                        await ref
                            .read(apiClientProvider)
                            .createProduct(payload);
                      }
                      ref.invalidate(productsProvider);
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

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _busy = false;

  Map<String, dynamic>? _findProduct(List<Map<String, dynamic>> list) {
    for (final p in list) {
      if (p['id'] == widget.productId) return p;
    }
    return null;
  }

  Future<void> _adjustStock(Map<String, dynamic> product,
      {required String type}) async {
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'in' ? 'Entrée stock' : 'Sortie stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Valider')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).addStockMovement(widget.productId, {
        'type': type,
        'quantity': int.tryParse(qtyCtrl.text) ?? 1,
        'reason':
            reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      });
      ref.invalidate(productsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      body: AfriMeshBackground(
        child: SafeArea(
          child: products.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AfriColors.teal)),
            error: (e, _) => AfriEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Erreur',
              subtitle: '$e',
              actionLabel: 'Retour',
              onAction: () => context.pop(),
            ),
            data: (list) {
              final p = _findProduct(list);
              if (p == null) {
                return AfriEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Produit introuvable',
                  subtitle: 'Ce produit n\'existe plus ou a été supprimé.',
                  actionLabel: 'Retour',
                  onAction: () => context.pop(),
                );
              }
              final isLow = p['is_low_stock'] as bool? ?? false;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await context.push('/stock/${widget.productId}/edit',
                              extra: p);
                          ref.invalidate(productsProvider);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  Text(p['name'] as String,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (p['category'] != null)
                    Text('${p['category']}',
                        style: const TextStyle(color: AfriColors.slate)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Stock',
                          value: '${p['quantity']}',
                          highlight: isLow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Prix',
                          value: '${p['price']} F',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Seuil',
                          value: '${p['low_stock_threshold']}',
                        ),
                      ),
                    ],
                  ),
                  if (isLow) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AfriColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Stock faible — pense à réapprovisionner.',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AfriColors.orange),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AfriButton(
                    label: 'Entrée de stock',
                    icon: Icons.add,
                    isLoading: _busy,
                    onPressed: () => _adjustStock(p, type: 'in'),
                  ),
                  const SizedBox(height: 12),
                  AfriButton(
                    label: 'Sortie de stock',
                    variant: AfriButtonVariant.secondary,
                    icon: Icons.remove,
                    isLoading: _busy,
                    onPressed: () => _adjustStock(p, type: 'out'),
                  ),
                  const SizedBox(height: 12),
                  AfriButton(
                    label: 'Supprimer le produit',
                    variant: AfriButtonVariant.ghost,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer ?'),
                          content:
                              Text('Supprimer « ${p['name']} » du stock ?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Supprimer')),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      await ref
                          .read(apiClientProvider)
                          .deleteProduct(widget.productId);
                      ref.invalidate(productsProvider);
                      if (context.mounted) context.pop();
                    },
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

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfriColors.mistDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AfriColors.slate)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: highlight ? AfriColors.orange : AfriColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
