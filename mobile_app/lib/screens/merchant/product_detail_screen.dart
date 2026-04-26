// lib/screens/merchant/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/providers/inventory_provider.dart';
import 'package:mobile_app/providers/selected_product_provider.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/theme/app_theme.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const ProductDetailScreen({super.key, required this.insideShell});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete(BuildContext context, String itemId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete product?'),
        content: Text('Remove "$name" from inventory? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: DayFiColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(inventoryProvider.notifier).deleteItem(itemId);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: DayFiColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final item = ref.watch(selectedProductProvider);

    if (item == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('No product selected')),
      );
    }

    final isOut = item.stock == 0;
    final isLow = item.isLowStock && !isOut;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image ──────────────────────────────────────────────────
                  if (item.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 48,
                        color: cs.onSurface.withOpacity(0.15)),
                    ),
                  const SizedBox(height: 24),

                  // ── Name + status ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.4)),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(
                        label: isOut ? 'Out of Stock' : isLow ? 'Low Stock' : 'In Stock',
                        color: isOut ? DayFiColors.red : isLow ? const Color(0xFFFFB020) : Colors.green,
                      ),
                    ],
                  ),
                  if (item.sku != null) ...[
                    const SizedBox(height: 4),
                    Text('SKU: ${item.sku}',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
                  ],
                  const SizedBox(height: 24),

                  // ── Details card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Price', value: '\$${item.priceUsdc.toStringAsFixed(2)} USDC'),
                        _DetailRow(label: 'Stock', value: '${item.stock} units'),
                        _DetailRow(label: 'Low stock alert', value: '${item.threshold} units'),
                        if (item.category != null)
                          _DetailRow(label: 'Category', value: item.category!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stock controls ─────────────────────────────────────────
                  Text('Adjust Stock',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.55))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StockButton(
                          label: '− Remove',
                          color: DayFiColors.red,
                          onTap: item.stock > 0
                              ? () async {
                                  HapticFeedback.lightImpact();
                                  await ref.read(inventoryProvider.notifier)
                                      .decrementStock(item.id);
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StockButton(
                          label: '+ Add',
                          color: Colors.green,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await ref.read(inventoryProvider.notifier)
                                .incrementStock(item.id);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Bulk edit field ────────────────────────────────────────
                  _BulkStockField(itemId: item.id),
                  const SizedBox(height: 32),

                  // ── Edit button ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.onSurface.withOpacity(0.9), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => ref.read(shellNavProvider.notifier).goTo(ShellDest.editProduct),
                      child: const Text('Edit Product',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Delete button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DayFiColors.red,
                        side: BorderSide(color: DayFiColors.red.withOpacity(0.5), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _deleting
                          ? null
                          : () => _confirmDelete(context, item.id, item.name),
                      child: _deleting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: DayFiColors.red))
                          : const Text('Delete Product',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bulk stock set field ───────────────────────────────────────────────────────

class _BulkStockField extends ConsumerStatefulWidget {
  final String itemId;
  const _BulkStockField({required this.itemId});

  @override
  ConsumerState<_BulkStockField> createState() => _BulkStockFieldState();
}

class _BulkStockFieldState extends ConsumerState<_BulkStockField> {
  final _ctrl   = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _setStock() async {
    final v = int.tryParse(_ctrl.text.trim());
    if (v == null || v < 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(inventoryProvider.notifier).setAbsoluteStock(widget.itemId, v);
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Set exact stock quantity',
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 13),
              filled: true,
              fillColor: cs.onSurface.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.onSurface.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _loading ? null : _setStock,
            child: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Set'),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StockButton extends StatelessWidget {
  final String    label;
  final Color     color;
  final VoidCallback? onTap;
  const _StockButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 48),
    ),
    onPressed: onTap,
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}