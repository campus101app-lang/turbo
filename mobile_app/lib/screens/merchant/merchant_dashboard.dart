// lib/screens/merchant/merchant_dashboard.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/selected_product_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../screens/merchant/checkout_screen.dart'; // cartProvider
import '../../theme/app_theme.dart';

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum _StockFilter { all, outOfStock, lowStock }

// ─── MerchantDashboard ────────────────────────────────────────────────────────

class MerchantDashboard extends ConsumerStatefulWidget {
  const MerchantDashboard({super.key});

  @override
  ConsumerState<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends ConsumerState<MerchantDashboard> {
  Timer?        _refreshTimer;
  _StockFilter  _filter      = _StockFilter.all;
  final         _searchCtrl  = TextEditingController();
  String        _searchQuery = '';
  bool          _showSearch  = false;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.read(inventoryProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _openAddProduct() {
    HapticFeedback.lightImpact();
    ref.read(shellNavProvider.notifier).goTo(ShellDest.addProduct);
  }

  void _openProductDetail(InventoryItem item) {
    HapticFeedback.lightImpact();
    ref.read(selectedProductProvider.notifier).state = item;
    ref.read(shellNavProvider.notifier).goTo(ShellDest.productDetail);
  }

  void _openCheckout() {
    HapticFeedback.lightImpact();
    ref.read(shellNavProvider.notifier).goTo(ShellDest.checkout);
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<InventoryItem> _filtered(List<InventoryItem> items) {
    var list = items;
    switch (_filter) {
      case _StockFilter.outOfStock:
        list = list.where((i) => i.stock == 0).toList();
        break;
      case _StockFilter.lowStock:
        list = list.where((i) => i.isLowStock && i.stock > 0).toList();
        break;
      case _StockFilter.all:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) =>
        i.name.toLowerCase().contains(q) ||
        (i.sku?.toLowerCase().contains(q) ?? false) ||
        (i.category?.toLowerCase().contains(q) ?? false),
      ).toList();
    }
    return list;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(inventoryProvider);
    final filtered = _filtered(state.items);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: double.infinity,
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                        child: _isWide(context)
                            ? _buildWideLayout(state, filtered)
                            : _buildNarrowLayout(state, filtered),
                      ),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 768;

  Widget _buildFab() => Container(
    height: 56,
    width: 56,
    decoration: BoxDecoration(
      color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
      borderRadius: BorderRadius.circular(40),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
    ),
    child: InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: _openAddProduct,
      child: Center(
        child: FaIcon(FontAwesomeIcons.add, size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      ),
    ),
  ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);

  Widget _buildWideLayout(InventoryState state, List<InventoryItem> filtered) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InsightsPanel(
            state:      state,
            onCheckout: state.items.isNotEmpty ? _openCheckout : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ProductListPanel(
            state:          state,
            filtered:       filtered,
            filter:         _filter,
            showSearch:     _showSearch,
            searchCtrl:     _searchCtrl,
            searchQuery:    _searchQuery,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchCtrl.clear(); _searchQuery = ''; }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onShowDetail:   _openProductDetail,
            onAddProduct:   _openAddProduct,
            onIncrement:    (id) => ref.read(inventoryProvider.notifier).incrementStock(id),
            onDecrement:    (id) => ref.read(inventoryProvider.notifier).decrementStock(id),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(InventoryState state, List<InventoryItem> filtered) {
    return Column(
      children: [
        _InsightsPanel(
          state:      state,
          onCheckout: state.items.isNotEmpty ? _openCheckout : null,
        ),
        const SizedBox(height: 24),
        _ProductListPanel(
          state:          state,
          filtered:       filtered,
          filter:         _filter,
          showSearch:     _showSearch,
          searchCtrl:     _searchCtrl,
          searchQuery:    _searchQuery,
          onFilterChanged: (f) => setState(() => _filter = f),
          onSearchToggle: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { _searchCtrl.clear(); _searchQuery = ''; }
          }),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onShowDetail:   _openProductDetail,
          onAddProduct:   _openAddProduct,
          onIncrement:    (id) => ref.read(inventoryProvider.notifier).incrementStock(id),
          onDecrement:    (id) => ref.read(inventoryProvider.notifier).decrementStock(id),
        ),
      ],
    );
  }
}

// ─── Insights Panel ───────────────────────────────────────────────────────────

class _InsightsPanel extends StatelessWidget {
  final InventoryState state;
  final VoidCallback?  onCheckout;
  const _InsightsPanel({required this.state, this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final outOfStock = state.items.where((i) => i.stock == 0).length;
    final lowStock   = state.lowStockItems.length;
    final totalStock = state.items.fold<int>(0, (s, i) => s + i.stock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Inventory', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5)),
            const Spacer(),
            if (onCheckout != null)
              _ActionChip(label: 'Checkout', icon: Icons.qr_code_rounded, onTap: onCheckout!),
          ],
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _MetricCard(label: 'Stock Value',
            value: '\$${state.totalInventoryValue.toStringAsFixed(2)}',
            icon: Icons.attach_money_rounded, color: const Color(0xFF9B8EF8))),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(label: 'Total Units',
            value: '$totalStock',
            icon: Icons.inventory_2_outlined, color: const Color(0xFF50C878))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricCard(label: 'Out of Stock',
            value: outOfStock.toString().padLeft(2, '0'),
            icon: Icons.remove_shopping_cart_outlined, color: DayFiColors.red)),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(label: 'Low Stock',
            value: lowStock.toString().padLeft(2, '0'),
            icon: Icons.trending_down_rounded, color: const Color(0xFFFFB020))),
        ]),
        const SizedBox(height: 20),
        _StockFlowChart(items: state.items),
        const SizedBox(height: 20),
        _CategoryCard(items: state.items),
      ],
    );
  }
}

// ─── Product List Panel ───────────────────────────────────────────────────────

class _ProductListPanel extends StatelessWidget {
  final InventoryState    state;
  final List<InventoryItem> filtered;
  final _StockFilter      filter;
  final bool              showSearch;
  final TextEditingController searchCtrl;
  final String            searchQuery;
  final ValueChanged<_StockFilter> onFilterChanged;
  final VoidCallback      onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InventoryItem> onShowDetail;
  final VoidCallback      onAddProduct;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  const _ProductListPanel({
    required this.state, required this.filtered, required this.filter,
    required this.showSearch, required this.searchCtrl, required this.searchQuery,
    required this.onFilterChanged, required this.onSearchToggle,
    required this.onSearchChanged, required this.onShowDetail,
    required this.onAddProduct, required this.onIncrement, required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStockCount = state.items.where((i) => i.stock == 0).length;
    final lowStockCount   = state.lowStockItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Products', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5)),
            const Spacer(),
            _ActionChip(label: 'Add Product', icon: Icons.add_rounded, onTap: onAddProduct),
          ],
        ),
        const SizedBox(height: 16),

        // Search bar
        if (showSearch) ...[
          TextField(
            controller: searchCtrl,
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search products, SKU...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              prefixIcon: Icon(Icons.search_rounded, size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              suffixIcon: InkWell(onTap: onSearchToggle,
                child: Icon(Icons.close_rounded, size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
              filled: true,
              fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Filter chips
        Row(
          children: [
            if (!showSearch)
              _IconBtn(icon: Icons.search_rounded, onTap: onSearchToggle),
            if (!showSearch) const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: 'All', isActive: filter == _StockFilter.all,
                    onTap: () => onFilterChanged(_StockFilter.all)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Out of Stock',
                    badge: outOfStockCount > 0 ? '$outOfStockCount' : null,
                    badgeColor: DayFiColors.red,
                    isActive: filter == _StockFilter.outOfStock,
                    onTap: () => onFilterChanged(_StockFilter.outOfStock)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Low Stock',
                    badge: lowStockCount > 0 ? '$lowStockCount' : null,
                    badgeColor: const Color(0xFFFFB020),
                    isActive: filter == _StockFilter.lowStock,
                    onTap: () => onFilterChanged(_StockFilter.lowStock)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Product list
        if (filtered.isEmpty)
          _EmptyState(onAdd: onAddProduct)
        else
          ...List.generate(filtered.length, (i) {
            final item = filtered[i];
            return _ProductCard(
              item:        item,
              onTap:       () => onShowDetail(item),
              onIncrement: () => onIncrement(item.id),
              onDecrement: () => onDecrement(item.id),
            ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.04, end: 0);
          }),
      ],
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback  onTap;
  final VoidCallback  onIncrement;
  final VoidCallback  onDecrement;
  const _ProductCard({required this.item, required this.onTap,
    required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isOut = item.stock == 0;
    final isLow = item.isLowStock && !isOut;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOut  ? DayFiColors.red.withOpacity(0.3)
                : isLow  ? const Color(0xFFFFB020).withOpacity(0.3)
                : cs.onSurface.withOpacity(0.07),
            width: 0.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Image or placeholder
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item.imageUrl!, fit: BoxFit.cover))
                  : Icon(Icons.inventory_2_outlined, size: 22,
                      color: cs.onSurface.withOpacity(0.25)),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, letterSpacing: -0.2, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.sku != null ? 'SKU: ${item.sku}'
                      : '\$${item.priceUsdc.toStringAsFixed(2)} USDC',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text('${item.stock} in stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
                    const SizedBox(width: 8),
                    _Badge(
                      label: isOut ? 'Out' : isLow ? 'Low' : 'OK',
                      color: isOut ? DayFiColors.red
                          : isLow ? const Color(0xFFFFB020) : Colors.green),
                  ]),
                ],
              ),
            ),

            // Stepper
            _MiniStepper(
              stock:       item.stock,
              isLow:       isLow || isOut,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;
  const _MetricCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Stock Flow Chart ─────────────────────────────────────────────────────────

class _StockFlowChart extends StatelessWidget {
  final List<InventoryItem> items;
  const _StockFlowChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final total = items.fold<int>(0, (s, i) => s + i.stock);
    final days  = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final base  = (total * 0.55).clamp(1, double.infinity);
    final vals  = [base * 0.45, base * 0.60, base * 0.75, base * 0.88, base * 1.0];
    final max   = vals.last;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Stock Flow', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('7 days', style: TextStyle(
                  fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final pct    = max > 0 ? vals[i] / max : 0.0;
                final isLast = i == days.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 70 * pct + 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isLast
                                ? const Color(0xFF9B8EF8)
                                : const Color(0xFF9B8EF8).withOpacity(0.2 + 0.15 * i),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i], style: TextStyle(
                          fontSize: 10, color: cs.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final List<InventoryItem> items;
  const _CategoryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final map = <String, int>{};
    for (final i in items) {
      final c = i.category ?? 'other';
      map[c] = (map[c] ?? 0) + i.stock;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total  = map.values.fold(0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          if (total == 0)
            Text('No items yet', style: TextStyle(color: cs.onSurface.withOpacity(0.4)))
          else
            ...sorted.take(5).map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _catColor(e.key),
                        borderRadius: BorderRadius.circular(5))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      e.key[0].toUpperCase() + e.key.substring(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    Text('${e.value}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _catColor(String c) {
    switch (c.toLowerCase()) {
      case 'electronics': return const Color(0xFF9B8EF8);
      case 'clothing':    return const Color(0xFFFFA726);
      case 'food':        return const Color(0xFF50C878);
      case 'books':       return const Color(0xFF42A5F5);
      default:            return const Color(0xFF78909C);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 44,
            color: cs.onSurface.withOpacity(0.18)),
          const SizedBox(height: 14),
          Text('No products found', style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 6),
          Text('Add your first product to get started.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.3)),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Product'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.onSurface.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.5)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;
  final String?  badge;
  final Color?   badgeColor;
  const _FilterChip({required this.label, required this.isActive,
    required this.onTap, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF9B8EF8).withOpacity(0.15)
              : cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF9B8EF8).withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? const Color(0xFF9B8EF8) : cs.onSurface.withOpacity(0.6))),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (badgeColor ?? DayFiColors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: badgeColor ?? DayFiColors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int          stock;
  final bool         isLow;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _MiniStepper({required this.stock, required this.isLow,
    required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$stock', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13,
              color: isLow ? DayFiColors.red : cs.onSurface)),
          ),
          _StepBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Icon(icon, size: 14,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(
      fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}