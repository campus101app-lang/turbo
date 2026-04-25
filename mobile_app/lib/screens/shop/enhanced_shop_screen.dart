// lib/screens/shop/enhanced_shop_screen.dart
//
// Enhanced Shop Screen with Enterprise Features
// Professional e-commerce management, inventory tracking, and analytics
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';
import 'package:mobile_app/widgets/enterprise/activity_feed.dart';

class EnhancedShopScreen extends StatefulWidget {
  const EnhancedShopScreen({super.key});

  @override
  State<EnhancedShopScreen> createState() => _EnhancedShopScreenState();
}

class _EnhancedShopScreenState extends State<EnhancedShopScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedTab = 'products';
  final List<String> _tabs = ['products', 'orders', 'inventory', 'customers', 'analytics'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      backgroundColor: themeExtension.surfaceBackground,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: themeExtension.accentBlue,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(themeExtension),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildTabSelector(themeExtension),
                      _buildTabContent(themeExtension),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(themeExtension),
    );
  }

  Widget _buildSliverAppBar(AppThemeExtension themeExtension) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: themeExtension.surfaceBackground,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Shop',
          style: TextStyle(
            color: themeExtension.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeExtension.surfaceBackground,
                themeExtension.surfaceBackground.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _openSearch,
          icon: Icon(
            Icons.search,
            color: themeExtension.primaryText,
          ),
        ),
        IconButton(
          onPressed: _openFilter,
          icon: Icon(
            Icons.filter_list,
            color: themeExtension.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectTab(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? themeExtension.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTabTitle(tab),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? Colors.white 
                        : themeExtension.secondaryText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(AppThemeExtension themeExtension) {
    switch (_selectedTab) {
      case 'products':
        return _buildProductsTab(themeExtension);
      case 'orders':
        return _buildOrdersTab(themeExtension);
      case 'inventory':
        return _buildInventoryTab(themeExtension);
      case 'customers':
        return _buildCustomersTab(themeExtension);
      case 'analytics':
        return _buildAnalyticsTab(themeExtension);
      default:
        return _buildProductsTab(themeExtension);
    }
  }

  Widget _buildProductsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // KPI Cards
        EnterpriseKPIGrid(
          kpiCards: [
            EnterpriseKPICard(
              title: 'Total Products',
              value: '156',
              subtitle: 'Active listings',
              trend: KPITrend.up,
              trendPercentage: 12.3,
              icon: Icons.inventory_2,
              backgroundColor: DayFiColors.secondary,
              onTap: _openProductDetails,
            ),
            EnterpriseKPICard(
              title: 'Low Stock',
              value: '8',
              subtitle: 'Need restocking',
              trend: KPITrend.down,
              trendPercentage: -25.0,
              icon: Icons.warning,
              color: DayFiColors.error,
              onTap: _openLowStockDetails,
            ),
            EnterpriseKPICard(
              title: 'Avg. Price',
              value: '₦25,500',
              subtitle: 'Per product',
              trend: KPITrend.up,
              trendPercentage: 5.8,
              icon: Icons.price_change,
              color: DayFiColors.success,
              onTap: _openPricingDetails,
            ),
            EnterpriseKPICard(
              title: 'Categories',
              value: '12',
              subtitle: 'Product categories',
              trend: KPITrend.neutral,
              trendPercentage: 0.0,
              icon: Icons.category,
              backgroundColor: DayFiColors.secondary,
              onTap: _openCategoryDetails,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Quick Actions
        EnterpriseQuickActionsCard(
          title: 'Shop Actions',
          actions: QuickActionCategories.getShopActions(
            onAddProduct: _addProduct,
            onViewOrders: _viewOrders,
            onManageInventory: _manageInventory,
            onViewAnalytics: _viewAnalytics,
          ),
        ),
        const SizedBox(height: 24),
        
        // Recent Products
        _buildRecentProducts(themeExtension),
      ],
    );
  }

  Widget _buildOrdersTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Order Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeExtension.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeExtension.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Today', '12', themeExtension.accentBlue),
              _buildStatItem('Pending', '8', DayFiColors.blue),
              _buildStatItem('Shipped', '25', DayFiColors.green),
              _buildStatItem('Delivered', '156', DayFiColors.green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Order List
        _buildOrderList(themeExtension),
      ],
    );
  }

  Widget _buildInventoryTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Inventory Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeExtension.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeExtension.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Value', '₦3.2M', themeExtension.primaryText),
              _buildStatItem('Low Stock', '8', DayFiColors.red),
              _buildStatItem('Out of Stock', '3', DayFiColors.red),
              _buildStatItem('Overstock', '5', DayFiColors.blue),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Low Stock Alerts
        _buildLowStockAlerts(themeExtension),
        const SizedBox(height: 16),
        
        // Inventory List
        _buildInventoryList(themeExtension),
      ],
    );
  }

  Widget _buildCustomersTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Customer Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeExtension.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeExtension.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '892', themeExtension.accentBlue),
              _buildStatItem('New', '45', DayFiColors.green),
              _buildStatItem('Repeat', '234', DayFiColors.blue),
              _buildStatItem('VIP', '28', DayFiColors.green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Customer List
        _buildCustomerList(themeExtension),
      ],
    );
  }

  Widget _buildAnalyticsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Analytics Overview
        EnterpriseKPIGrid(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          kpiCards: [
            EnterpriseKPICard(
              title: 'Revenue',
              value: '₦1,250,000',
              subtitle: 'This month',
              trend: KPITrend.up,
              trendPercentage: 18.5,
              icon: Icons.trending_up,
              color: DayFiColors.success,
            ),
            EnterpriseKPICard(
              title: 'Orders',
              value: '234',
              subtitle: 'This month',
              trend: KPITrend.up,
              trendPercentage: 12.3,
              icon: Icons.shopping_cart,
              backgroundColor: DayFiColors.secondary,
            ),
            EnterpriseKPICard(
              title: 'AOV',
              value: '₦5,340',
              subtitle: 'Avg order value',
              trend: KPITrend.up,
              trendPercentage: 8.7,
              icon: Icons.receipt_long,
              color: DayFiColors.success,
            ),
            EnterpriseKPICard(
              title: 'Conversion',
              value: '3.2%',
              subtitle: 'Conversion rate',
              trend: KPITrend.down,
              trendPercentage: -2.1,
              icon: Icons.show_chart,
              color: DayFiColors.error,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Analytics Charts
        _buildAnalyticsCharts(themeExtension),
      ],
    );
  }

  Widget _buildRecentProducts(AppThemeExtension themeExtension) {
    final products = [
      {'name': 'Premium Laptop', 'price': 250000.00, 'stock': 15, 'category': 'Electronics'},
      {'name': 'Wireless Mouse', 'price': 5000.00, 'stock': 45, 'category': 'Electronics'},
      {'name': 'Office Chair', 'price': 35000.00, 'stock': 8, 'category': 'Furniture'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Recent Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
          ),
          ...products.map((product) => _buildProductItem(product, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, AppThemeExtension themeExtension) {
    final stock = product['stock'] as int;
    Color stockColor = stock > 20 ? DayFiColors.green : stock > 10 ? DayFiColors.blue : DayFiColors.red;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeExtension.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.inventory_2,
          color: themeExtension.accentBlue,
          size: 20,
        ),
      ),
      title: Text(
        product['name'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeExtension.primaryText,
        ),
      ),
      subtitle: Text(
        product['category'],
        style: TextStyle(
          color: themeExtension.secondaryText,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦${product['price'].toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Stock: $stock',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: stockColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Order items would go here
          Text(
            'No recent orders',
            style: TextStyle(
              color: themeExtension.hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlerts(AppThemeExtension themeExtension) {
    final lowStockItems = [
      {'name': 'Premium Laptop', 'stock': 5, 'reorder': 20},
      {'name': 'Office Chair', 'stock': 8, 'reorder': 15},
      {'name': 'Wireless Keyboard', 'stock': 3, 'reorder': 10},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: DayFiColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeExtension.primaryText,
                  ),
                ),
              ],
            ),
          ),
          ...lowStockItems.map((item) => _buildLowStockItem(item, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildLowStockItem(Map<String, dynamic> item, AppThemeExtension themeExtension) {
    return ListTile(
      leading: Icon(
        Icons.inventory,
        color: DayFiColors.error,
        size: 20,
      ),
      title: Text(
        item['name'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeExtension.primaryText,
        ),
      ),
      subtitle: Text(
        'Reorder level: ${item['reorder']}',
        style: TextStyle(
          color: themeExtension.secondaryText,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DayFiColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${item['stock']} left',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DayFiColors.error,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Inventory Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Inventory items would go here
          Text(
            'No inventory items',
            style: TextStyle(
              color: themeExtension.hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Customer items would go here
          Text(
            'No customers found',
            style: TextStyle(
              color: themeExtension.hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCharts(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          // Chart placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: themeExtension.hintText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart,
                    size: 48,
                    color: themeExtension.hintText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sales Chart',
                    style: TextStyle(
                      color: themeExtension.hintText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).extension<AppThemeExtension>()!.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(AppThemeExtension themeExtension) {
    return FloatingActionButton.extended(
      onPressed: _addProduct,
      backgroundColor: themeExtension.accentBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
    );
  }

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'products':
        return 'Products';
      case 'orders':
        return 'Orders';
      case 'inventory':
        return 'Inventory';
      case 'customers':
        return 'Customers';
      case 'analytics':
        return 'Analytics';
      default:
        return tab;
    }
  }

  void _selectTab(String tab) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    // Open search functionality
  }

  void _openFilter() {
    HapticFeedback.lightImpact();
    // Open filter functionality
  }

  void _addProduct() {
    HapticFeedback.lightImpact();
    // Navigate to product creation
  }

  void _viewOrders() {
    HapticFeedback.lightImpact();
    // Navigate to orders
  }

  void _manageInventory() {
    HapticFeedback.lightImpact();
    // Navigate to inventory management
  }

  void _viewAnalytics() {
    HapticFeedback.lightImpact();
    // Navigate to analytics
  }

  void _openProductDetails() {
    HapticFeedback.lightImpact();
    // Navigate to product details
  }

  void _openLowStockDetails() {
    HapticFeedback.lightImpact();
    // Navigate to low stock details
  }

  void _openPricingDetails() {
    HapticFeedback.lightImpact();
    // Navigate to pricing details
  }

  void _openCategoryDetails() {
    HapticFeedback.lightImpact();
    // Navigate to category details
  }
}
