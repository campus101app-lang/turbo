// lib/screens/merchant/merchant_dashboard.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/merchant/checkout_modal.dart'; // For CheckoutModal
import '../../screens/merchant/checkout_screen.dart'; // For cartProvider

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
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 118, 0, 100),
                child: state.isLoading && state.items.isEmpty
                    ? const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            _buildBody(context, ref, state, filtered),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, ref, state),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref, InventoryState state) {
    return Container(
      height: 60,
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        ),
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => _showAddItemModal(context, ref),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.add,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    InventoryState state,
    List<InventoryItem> filtered,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Inventory Insights ────────────────────────────────────────
        Expanded(
          child: _InventoryInsightsPanel(
            state: state,
            filtered: filtered,
            onCheckout: state.items.isNotEmpty
                ? () => _showCheckoutModal(context, ref)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        // ── Right: Inventory List ───────────────────────────────────────────
        Expanded(
          child: _InventoryListPanel(
            state: state,
            filtered: filtered,
            filter: _filter,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            searchQuery: _searchQuery,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSearchToggle: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _searchQuery = '';
              }
            }),
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onShowDetail: (item) => _showProductDetailModal(context, ref, item),
          ),
        ),
      ],
    );
  }

  // ── Modal Methods ─────────────────────────────────────────────────────────────

  void _showAddItemModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GlassModal(
        child: _AddItemFlow(
          onAdd: (name, price, stock, threshold, sku, category) async {
            try {
              await ref.read(inventoryProvider.notifier).addItem(
                name: name,
                priceUsdc: price,
                stock: stock,
                threshold: threshold,
                sku: sku.isEmpty ? null : sku,
                category: category.isEmpty ? null : category,
              );
              Navigator.of(context).pop();
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
      ),
    );
  }

  void _showProductDetailModal(BuildContext context, WidgetRef ref, InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GlassModal(
        child: _ProductDetailContent(
          item: item,
          onIncrement: () => ref.read(inventoryProvider.notifier).incrementStock(item.id),
          onDecrement: () => ref.read(inventoryProvider.notifier).decrementStock(item.id),
          onDelete: () {
            Navigator.of(context).pop();
            _confirmDelete(context, item);
          },
        ),
      ),
    );
  }

  void _showCheckoutModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GlassModal(
        child: CheckoutModal(),
      ),
    );
  }

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
  }}

// ─── Glass Modal ────────────────────────────────────────────────────────────────

class _GlassModal extends StatelessWidget {
  final Widget child;
  const _GlassModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 520,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Inventory Insights Panel ───────────────────────────────────────────────────

class _InventoryInsightsPanel extends StatelessWidget {
  final InventoryState state;
  final List<InventoryItem> filtered;
  final VoidCallback? onCheckout;

  const _InventoryInsightsPanel({
    required this.state,
    required this.filtered,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = state.items.where((i) => i.stock == 0).length;
    final lowStock = state.lowStockItems.length;
    final totalStock = state.items.fold<int>(0, (s, i) => s + i.stock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Inventory Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (onCheckout != null)
              _CreateButton(onTap: onCheckout!, label: 'Checkout'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Stats Cards Row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Stock Value',
                value: '\$${state.totalInventoryValue.toStringAsFixed(2)}',
                icon: Icons.upload_rounded,
                color: const Color(0xFF9B8EF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Total Stock',
                value: '$totalStock',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF50C878),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Out of Stock',
                value: outOfStock.toString().padLeft(2, '0'),
                icon: Icons.remove_shopping_cart_outlined,
                color: DayFiColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Low Stock',
                value: lowStock.toString().padLeft(2, '0'),
                icon: Icons.trending_down_rounded,
                color: const Color(0xFFFFB020),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Stock Flow Chart
        _StockFlowChart(items: state.items),
        const SizedBox(height: 24),
        
        // Category Distribution
        _CategoryDistributionCard(items: state.items),
      ],
    );
  }
}

// ─── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Create Button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _CreateButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Distribution Card ───────────────────────────────────────────────────

class _CategoryDistributionCard extends StatelessWidget {
  final List<InventoryItem> items;
  const _CategoryDistributionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, int>{};
    
    for (final item in items) {
      final category = item.category ?? 'other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + item.stock;
    }
    
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = categoryTotals.values.fold(0, (sum, val) => sum + val);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Text(
              'No items in inventory',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          else ...[
            ...sortedCategories.take(5).map((entry) {
              final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key[0].toUpperCase() + entry.key.substring(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} units',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return const Color(0xFF9B8EF8);
      case 'clothing':
        return const Color(0xFFFFA726);
      case 'food':
        return const Color(0xFF50C878);
      case 'books':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// ─── Inventory List Panel ───────────────────────────────────────────────────────

class _InventoryListPanel extends StatelessWidget {
  final InventoryState state;
  final List<InventoryItem> filtered;
  final _StockFilter filter;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<_StockFilter> onFilterChanged;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InventoryItem> onShowDetail;

  const _InventoryListPanel({
    required this.state,
    required this.filtered,
    required this.filter,
    required this.showSearch,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStockCount = state.items.where((i) => i.stock == 0).length;
    final lowStockCount = state.lowStockItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (state.items.isNotEmpty)
              _CreateButton(onTap: () {}, label: 'Add Product'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Search and Filters
        _InventorySectionHeader(
          filter: filter,
          showSearch: showSearch,
          searchCtrl: searchCtrl,
          onFilterChanged: onFilterChanged,
          onSearchToggle: onSearchToggle,
          onSearchChanged: onSearchChanged,
          outOfStockCount: outOfStockCount,
          lowStockCount: lowStockCount,
        ),
        const SizedBox(height: 16),
        
        // Inventory List
        if (filtered.isEmpty)
          _EmptyInventoryCard()
        else
          Column(
            children: List.generate(filtered.length, (i) {
              final item = filtered[i];
              return _InventoryCard(
                item: item,
                onTap: () => onShowDetail(item),
                onIncrement: () {}, // Handle in parent
                onDecrement: () {}, // Handle in parent
                onDelete: () {}, // Handle in parent
              ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.04, end: 0);
            }),
          ),
      ],
    );
  }
}

// ─── Empty Inventory Card ───────────────────────────────────────────────────────

class _EmptyInventoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add your first product.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Modal Components ───────────────────────────────────────────────────────────

class _AddItemFlow extends ConsumerStatefulWidget {
  final Function(String name, double price, int stock, int threshold, String sku, String category) onAdd;
  const _AddItemFlow({required this.onAdd});

  @override
  ConsumerState<_AddItemFlow> createState() => _AddItemFlowState();
}

class _AddItemFlowState extends ConsumerState<_AddItemFlow>
    with TickerProviderStateMixin {
  int _step = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _skuCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() => _step--);
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Add Product',
          step: _step,
          totalSteps: 3,
          onBack: _step > 1 ? _prevStep : null,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Product Details'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameCtrl,
          decoration: _modalField(context, 'Product name'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          decoration: _modalField(context, 'Price in USDC'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _stockCtrl,
          keyboardType: TextInputType.number,
          decoration: _modalField(context, 'Initial stock'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Stock Settings'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _thresholdCtrl,
          keyboardType: TextInputType.number,
          decoration: _modalField(context, 'Low stock threshold'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _skuCtrl,
          decoration: _modalField(context, 'SKU (optional)'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _categoryCtrl,
          decoration: _modalField(context, 'Category (optional)'),
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  Widget _buildStep3() {
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    final threshold = int.tryParse(_thresholdCtrl.text) ?? 5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Review & Add'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameCtrl.text.trim(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${price.toStringAsFixed(2)} · $stock units in stock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (_categoryCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Category: ${_categoryCtrl.text.trim()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Low stock alert at:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$threshold units',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(
          label: 'Add Product',
          onTap: _submitProduct,
        ),
      ],
    );
  }

  Future<void> _submitProduct() async {
    try {
      final name = _nameCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text);
      final stock = int.tryParse(_stockCtrl.text);
      final threshold = int.tryParse(_thresholdCtrl.text) ?? 5;
      
      if (name.isEmpty || price == null || stock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      await widget.onAdd(
        name,
        price,
        stock,
        threshold,
        _skuCtrl.text.trim(),
        _categoryCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    }
  }
}

// ─── Product Detail Content ────────────────────────────────────────────────────

class _ProductDetailContent extends ConsumerWidget {
  final InventoryItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _ProductDetailContent({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Product Details',
          step: 0,
          totalSteps: 0,
          onBack: null,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${item.priceUsdc.toStringAsFixed(2)} per unit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (item.sku != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${item.sku}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                      if (item.category != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${item.category}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stock Info
                _DetailRow(label: 'Current Stock', value: '${item.stock} units'),
                _DetailRow(
                  label: 'Low Stock Threshold',
                  value: '${item.threshold} units',
                ),
                _DetailRow(
                  label: 'Status',
                  value: item.stock == 0
                      ? 'Out of Stock'
                      : item.isLowStock
                          ? 'Low Stock'
                          : 'In Stock',
                ),
                
                const SizedBox(height: 32),
                
                // Stock Controls
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecrement,
                        child: const Text('Decrease Stock'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onIncrement,
                        child: const Text('Increase Stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DayFiColors.red,
                      side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                    ),
                    onPressed: onDelete,
                    child: const Text('Delete Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Checkout Modal Content ───────────────────────────────────────────────────

class _CheckoutModalContent extends ConsumerWidget {
  final VoidCallback onClose;
  const _CheckoutModalContent({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inventory = ref.watch(inventoryProvider).items;
    
    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Checkout',
          step: 0,
          totalSteps: 0,
          onBack: null,
          onClose: onClose,
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cart.isEmpty) ...[
                  const Center(
                    child: Text('No items in cart'),
                  ),
                ] else ...[
                  _CartSection(
                    cart: cart,
                    inventory: inventory,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 20),
                  // Generate QR button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Generate checkout URI logic here
                      },
                      child: const Text('Generate Payment QR'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Modal Helper Components ───────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.title,
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          _SmallIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack!,
          )
        else
          const SizedBox(width: 36),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        _SmallIconButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => Container(
          width: 32,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: i < current
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _ModalPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _ModalPrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
      ),
    );
  }
}

InputDecoration _modalField(BuildContext context, String hint) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurface.withOpacity(.35), fontSize: 14),
    filled: true,
    fillColor: cs.onSurface.withOpacity(.07),
    hoverColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
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
                    // isFirst: true,
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
                    // isLast: true,
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

// ─── Cart Section ─────────────────────────────────────────────────────────────

class _CartSection extends ConsumerWidget {
  final Map<String, int> cart;
  final List<InventoryItem> inventory;
  final ValueChanged<Map<String, int>> onChanged;

  const _CartSection({
    required this.cart,
    required this.inventory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Items',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...inventory.map((item) {
          final qty = cart[item.id] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: qty > 0
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: qty > 0
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        '\$${item.priceUsdc.toStringAsFixed(2)} · ${item.stock} in stock',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Qty stepper
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (qty > 0) ...[
                      _CartBtn(
                        icon: Icons.remove,
                        onTap: () {
                          final newCart = Map<String, int>.from(cart);
                          if (qty <= 1) {
                            newCart.remove(item.id);
                          } else {
                            newCart[item.id] = qty - 1;
                          }
                          ref.read(cartProvider.notifier).state = newCart;
                          onChanged(newCart);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$qty',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                      ),
                    ],
                    _CartBtn(
                      icon: Icons.add,
                      onTap: item.stock <= qty
                          ? null
                          : () {
                              final newCart = Map<String, int>.from(cart);
                              newCart[item.id] = qty + 1;
                              ref.read(cartProvider.notifier).state = newCart;
                              onChanged(newCart);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CartBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CartBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(onTap == null ? 0.04 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(onTap == null ? 0.2 : 0.7),
        ),
      ),
    );
  }
}

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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image upload is coming soon.'),
                      ),
                    );
                  },
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
