// lib/screens/merchant/merchant_dashboard.dart
import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/widgets/app_background.dart';

import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
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
  Timer? _refreshTimer;
  _StockFilter _filter = _StockFilter.all;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

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

  List<InventoryItem> _filteredItems(List<InventoryItem> items) {
    var list = items;

    // Apply filter
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

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                (i.sku?.toLowerCase().contains(q) ?? false) ||
                (i.category?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final filtered = _filteredItems(state.items);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
              child: const CustomScrollView(
                physics: ClampingScrollPhysics(),
                slivers: [
                  // // ── App Bar ──────────────────────────────────────
                  // _buildAppBar(context, state),
    
                  //       // ── Stats cards ──────────────────────────────────
                  //       SliverToBoxAdapter(
                  //         child: _StatsSection(
                  //           state: state,
                  //         ),
                  // // .animate().fadeIn(duration: 350.ms),
                  //       ),
    
                  //       // ── Stock flow chart ─────────────────────────────
                  //       SliverToBoxAdapter(
                  //         child: _StockFlowChart(
                  //           items: state.items,
                  //         ),
                  // // .animate().fadeIn(delay: 100.ms, duration: 350.ms),
                  //       ),
    
                  //       // ── Section header + filter chips ────────────────
                  //       SliverToBoxAdapter(
                  //         child: _InventorySectionHeader(
                  //           filter: _filter,
                  //           showSearch: _showSearch,
                  //           searchCtrl: _searchCtrl,
                  //           onFilterChanged: (f) => setState(() => _filter = f),
                  //           onSearchToggle: () => setState(() {
                  //             _showSearch = !_showSearch;
                  //             if (!_showSearch) {
                  //               _searchCtrl.clear();
                  //               _searchQuery = '';
                  //             }
                  //           }),
                  //           onSearchChanged: (q) =>
                  //               setState(() => _searchQuery = q),
                  //           outOfStockCount: state.items
                  //               .where((i) => i.stock == 0)
                  //               .length,
                  //           lowStockCount: state.lowStockItems.length,
                  //         ),
                  // // .animate().fadeIn(delay: 150.ms),
                  //       ),
    
                  //       // ── Inventory list ────────────────────────────────
                  //       filtered.isEmpty
                  //           ? SliverFillRemaining(
                  //               hasScrollBody: false,
                  //               child: _buildEmptyState(context),
                  //             )
                  //           : SliverPadding(
                  //               padding: const EdgeInsets.fromLTRB(
                  //                 16,
                  //                 0,
                  //                 16,
                  //                 100,
                  //               ),
                  //               sliver: SliverList(
                  //                 delegate: SliverChildBuilderDelegate((ctx, i) {
                  //                   final item = filtered[i];
                  //                   return _InventoryCard(
                  //                         item: item,
                  //                         onTap: () =>
                  //                             _showProductDetail(context, item),
                  //                         onIncrement: () => ref
                  //                             .read(inventoryProvider.notifier)
                  //                             .incrementStock(item.id),
                  //                         onDecrement: () => ref
                  //                             .read(inventoryProvider.notifier)
                  //                             .decrementStock(item.id),
                  //                         onDelete: () =>
                  //                             _confirmDelete(context, item),
                  //                       )
                  //                       .animate()
                  //                       .fadeIn(delay: (i * 40).ms)
                  //                       .slideY(begin: 0.04, end: 0);
                  //                 }, childCount: filtered.length),
                  //               ),
                  //             ),
                ],
              ),
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showAddItemSheet(context),
      //   backgroundColor: Theme.of(
      //     context,
      //   ).colorScheme.primary.withOpacity(.9),
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, InventoryState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Checkout button — visible when items exist
            if (state.items.isNotEmpty)
              _PillButton(
                label: 'Checkout',
                onTap: () => context.push('/merchant/checkout'),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final isFiltered = _filter != _StockFilter.all || _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered ? 'No items match' : 'No products yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Try a different filter or search term'
                : 'Tap + to add your first product',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
      // .animate().fadeIn(duration: 400.ms),
    );
  }

  // ── Product detail sheet ─────────────────────────────────────────────────────

  void _showProductDetail(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        item: item,
        onIncrement: () =>
            ref.read(inventoryProvider.notifier).incrementStock(item.id),
        onDecrement: () =>
            ref.read(inventoryProvider.notifier).decrementStock(item.id),
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, item);
        },
      ),
    );
  }

  // ── Add item sheet ────────────────────────────────────────────────────────────

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddItemSheet(
        onAdd: (name, price, stock, threshold, sku, category) async {
          Navigator.pop(context);
          try {
            await ref
                .read(inventoryProvider.notifier)
                .addItem(
                  name: name,
                  priceUsdc: price,
                  stock: stock,
                  threshold: threshold,
                  sku: sku.isEmpty ? null : sku,
                  category: category.isEmpty ? null : category,
                );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: $e'),
                  backgroundColor: DayFiColors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // ── Confirm delete ────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(inventoryProvider.notifier).deleteItem(item.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: DayFiColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill Button ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final InventoryState state;
  const _StatsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final outOfStock = state.items.where((i) => i.stock == 0).length;
    final lowStock = state.lowStockItems.length;
    final totalStock = state.items.fold<int>(0, (s, i) => s + i.stock);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Row 1 — wide card + small card
          Row(
            children: [
              // Total Stock Value — wide purple card
              Expanded(
                flex: 5,
                child: _StatsCard(
                  label: 'Total Stock Value',
                  value: '\$${state.totalInventoryValue.toStringAsFixed(2)}',
                  icon: Icons.upload_rounded,
                  accent: const Color(0xFF9B8EF8),
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              // Total Stock — white card
              Expanded(
                flex: 4,
                child: _StatsCard(
                  label: 'Total Stock',
                  value: '$totalStock',
                  icon: Icons.inventory_2_outlined,
                  accent: const Color(0xFF50C878),
                  filled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2 — two equal cards
          Row(
            children: [
              Expanded(
                child: _StatsCard(
                  label: 'Out of Stock',
                  value: outOfStock.toString().padLeft(2, '0'),
                  icon: Icons.remove_shopping_cart_outlined,
                  accent: DayFiColors.red,
                  filled: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsCard(
                  label: 'Low Stock',
                  value: lowStock.toString().padLeft(2, '0'),
                  icon: Icons.trending_down_rounded,
                  accent: const Color(0xFFFFB020),
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool filled;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? accent.withOpacity(0.85)
        : Theme.of(context).colorScheme.surface;
    final textColor = filled
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: filled
            ? null
            : Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.07),
                width: 0.5,
              ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white.withOpacity(0.2)
                  : accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: filled ? Colors.white : accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withOpacity(filled ? 0.75 : 0.5),
              fontSize: 12,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stock Flow Chart (pure Flutter, no fl_chart dep needed) ─────────────────

class _StockFlowChart extends StatelessWidget {
  final List<InventoryItem> items;
  const _StockFlowChart({required this.items});

  @override
  Widget build(BuildContext context) {
    // Derive weekly mock flow from real total stock (5 buckets)
    final total = items.fold<int>(0, (s, i) => s + i.stock);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    // Simulated growth curve based on current total
    final base = (total * 0.55).clamp(1, double.infinity);
    final values = [
      base * 0.45,
      base * 0.60,
      base * 0.75,
      base * 0.88,
      base * 1.0,
    ];
    final max = values.last;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Flow',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '+18%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Rise in Total Inventory Units',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final pct = max > 0 ? (values[i] / max) : 0.0;
                final isLast = i == days.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Percentage label
                        Text(
                          '${(pct * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        Container(
                          height: 80 * pct + 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isLast
                                ? const Color(0xFF9B8EF8)
                                : const Color(
                                    0xFF9B8EF8,
                                  ).withOpacity(0.25 + (0.15 * i)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Day label
                        Text(
                          days[i],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                        ),
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

// ─── Inventory Section Header + Filter Chips ──────────────────────────────────

class _InventorySectionHeader extends StatelessWidget {
  final _StockFilter filter;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final ValueChanged<_StockFilter> onFilterChanged;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final int outOfStockCount;
  final int lowStockCount;

  const _InventorySectionHeader({
    required this.filter,
    required this.showSearch,
    required this.searchCtrl,
    required this.onFilterChanged,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.outOfStockCount,
    required this.lowStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar (animated show/hide)
          if (showSearch) ...[
            TextField(
              controller: searchCtrl,
              autofocus: true,
              onChanged: onSearchChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search products, SKU...',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                suffixIcon: InkWell(
                  onTap: onSearchToggle,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            // .animate().fadeIn(duration: 200.ms),
            const SizedBox(height: 10),
          ],

          // Filter chips row
          Row(
            children: [
              // Search icon — toggles search bar
              if (!showSearch)
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: onSearchToggle,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),

              if (!showSearch) const SizedBox(width: 8),

              // Filter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Total Stock',
                        isActive: filter == _StockFilter.all,
                        onTap: () => onFilterChanged(_StockFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Out of Stock',
                        badge: outOfStockCount > 0 ? '$outOfStockCount' : null,
                        badgeColor: DayFiColors.red,
                        isActive: filter == _StockFilter.outOfStock,
                        onTap: () => onFilterChanged(_StockFilter.outOfStock),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Low Stock',
                        badge: lowStockCount > 0 ? '$lowStockCount' : null,
                        badgeColor: const Color(0xFFFFB020),
                        isActive: filter == _StockFilter.lowStock,
                        onTap: () => onFilterChanged(_StockFilter.lowStock),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF9B8EF8).withOpacity(0.15)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF9B8EF8).withOpacity(0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF9B8EF8)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: -0.1,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (badgeColor ?? DayFiColors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? DayFiColors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Inventory Card ───────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.item,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.stock == 0;
    final isLow = item.isLowStock && !isOut;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOut
                ? DayFiColors.red.withOpacity(0.3)
                : isLow
                ? const Color(0xFFFFB020).withOpacity(0.3)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 22,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.25),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sku != null
                        ? 'SKU: ${item.sku}'
                        : '\$${item.priceUsdc.toStringAsFixed(2)} USDC',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Stock row
                  Row(
                    children: [
                      Text(
                        '${item.stock} in Stock',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                      if (isOut || isLow) ...[
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: isOut ? 'Out of Stock' : 'Low Stock',
                          color: isOut
                              ? DayFiColors.red
                              : const Color(0xFFFFB020),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        const _StatusBadge(
                          label: 'In Stock',
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Quick stock stepper
            _MiniStepper(
              stock: item.stock,
              isLow: isLow || isOut,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int stock;
  final bool isLow;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MiniStepper({
    required this.stock,
    required this.isLow,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$stock',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isLow ? DayFiColors.red : null,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

// ─── Product Detail Sheet ─────────────────────────────────────────────────────

class _ProductDetailSheet extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _ProductDetailSheet({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.stock == 0;
    final isLow = item.isLowStock && !isOut;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Back button + title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Product Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Product image placeholder
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 20),

          // Name + status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                _StatusBadge(
                  label: isOut
                      ? 'Out of Stock'
                      : isLow
                      ? 'Low Stock'
                      : 'In Stock',
                  color: isOut
                      ? DayFiColors.red
                      : isLow
                      ? const Color(0xFFFFB020)
                      : Colors.green,
                ),
              ],
            ),
          ),

          if (item.sku != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4, right: 20),
              child: Row(
                children: [
                  Text(
                    'SKU: ${item.sku}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Details table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Quantity',
                    value: '${item.stock}',
                    isFirst: true,
                  ),
                  if (item.category != null)
                    _DetailRow(label: 'Category', value: item.category!),
                  _DetailRow(
                    label: 'Selling Price',
                    value: '\$${item.priceUsdc.toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Low Stock Threshold',
                    value: '${item.threshold}',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                // Add Stock
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      onIncrement();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Add Stock',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Remove Stock
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DayFiColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: item.stock > 0
                        ? () {
                            onDecrement();
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text(
                      'Remove Stock',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 4),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.07),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Item Sheet ───────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final Function(
    String name,
    double price,
    int stock,
    int threshold,
    String sku,
    String category,
  )
  onAdd;

  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '10');
  final _thresholdCtrl = TextEditingController(text: '5');
  final _skuCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _skuCtrl.dispose();
    _categoryCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Opacity(opacity: 0, child: SizedBox(width: 24)),
              Text(
                'Add Product',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Image upload area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 1,
                // Dashed effect via decoration
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B8EF8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 24,
                    color: Color(0xFF9B8EF8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload Product Image',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag & Drop or tap to browse',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9B8EF8),
                    side: const BorderSide(
                      color: Color(0xFF9B8EF8),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    backgroundColor: const Color(0xFF9B8EF8).withOpacity(0.1),
                  ),
                  onPressed: () {}, // TODO: image picker
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: const Text(
                    'Choose File',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Product Name
          _Field(
            controller: _nameCtrl,
            label: 'Product Name',
            hint: 'Product Name',
          ),
          const SizedBox(height: 12),

          // Category + SKU
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _categoryCtrl,
                  label: 'Category',
                  hint: 'Category',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _skuCtrl,
                  label: 'SKU',
                  hint: 'SKU-123',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quantity row with steppers
          Text(
            'Quantity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Qty display
              Container(
                width: 64,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _stockCtrl.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add Stock
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final v = int.tryParse(_stockCtrl.text) ?? 0;
                    setState(() => _stockCtrl.text = '${v + 1}');
                  },
                  child: const Text(
                    'Add Stock',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Remove Stock
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DayFiColors.red,
                    side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final v = int.tryParse(_stockCtrl.text) ?? 0;
                    if (v > 0) {
                      setState(() => _stockCtrl.text = '${v - 1}');
                    }
                  },
                  child: const Text(
                    'Remove Stock',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Supplier name
          _Field(
            controller: _supplierCtrl,
            label: 'Supplier Name',
            hint: 'Supplier Name',
          ),
          const SizedBox(height: 12),

          // Selling price
          _Field(
            controller: _priceCtrl,
            label: 'Selling Price',
            hint: '0.00',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // Alert threshold
          _Field(
            controller: _thresholdCtrl,
            label: 'Low Stock Alert Threshold',
            hint: '5',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B8EF8).withOpacity(0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    final threshold = int.tryParse(_thresholdCtrl.text.trim()) ?? 5;

    if (name.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, price, and stock are required')),
      );
      return;
    }

    setState(() => _saving = true);
    widget.onAdd(
      name,
      price,
      stock,
      threshold,
      _skuCtrl.text.trim(),
      _categoryCtrl.text.trim(),
    );
  }
}

// ─── Reusable Field ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
