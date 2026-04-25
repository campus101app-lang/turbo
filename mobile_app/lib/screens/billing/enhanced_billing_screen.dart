// lib/screens/billing/enhanced_billing_screen.dart
//
// Enhanced Billing Screen with Enterprise Features
// Professional invoice management, payment processing, and analytics
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';
import 'package:mobile_app/widgets/enterprise/activity_feed.dart';

class EnhancedBillingScreen extends StatefulWidget {
  const EnhancedBillingScreen({super.key});

  @override
  State<EnhancedBillingScreen> createState() => _EnhancedBillingScreenState();
}

class _EnhancedBillingScreenState extends State<EnhancedBillingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedTab = 'overview';
  final List<String> _tabs = ['overview', 'invoices', 'payments', 'customers', 'reports'];

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
          'Billing',
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
      case 'overview':
        return _buildOverviewTab(themeExtension);
      case 'invoices':
        return _buildInvoicesTab(themeExtension);
      case 'payments':
        return _buildPaymentsTab(themeExtension);
      case 'customers':
        return _buildCustomersTab(themeExtension);
      case 'reports':
        return _buildReportsTab(themeExtension);
      default:
        return _buildOverviewTab(themeExtension);
    }
  }

  Widget _buildOverviewTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // KPI Cards
        EnterpriseKPIGrid(
          kpiCards: [
            EnterpriseKPICard(
              title: 'Total Revenue',
              value: '₦2,450,000',
              subtitle: 'This month',
              trend: KPITrend.up,
              trendPercentage: 18.5,
              icon: Icons.trending_up,
              color: DayFiColors.green,
              onTap: _openRevenueDetails,
            ),
            EnterpriseKPICard(
              title: 'Outstanding',
              value: '₦425,000',
              subtitle: '15 invoices',
              trend: KPITrend.down,
              trendPercentage: -8.2,
              icon: Icons.money_off,
              color: DayFiColors.red,
              onTap: _openOutstandingDetails,
            ),
            EnterpriseKPICard(
              title: 'Avg. Payment Time',
              value: '12 days',
              subtitle: 'From invoice date',
              trend: KPITrend.down,
              trendPercentage: -15.3,
              icon: Icons.schedule,
              color: DayFiColors.green,
              onTap: _openPaymentTimeDetails,
            ),
            EnterpriseKPICard(
              title: 'Conversion Rate',
              value: '78.5%',
              subtitle: 'Invoices to payments',
              trend: KPITrend.up,
              trendPercentage: 5.7,
              icon: Icons.show_chart,
              color: DayFiColors.blue,
              onTap: _openConversionDetails,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Quick Actions
        EnterpriseQuickActionsCard(
          title: 'Billing Actions',
          actions: QuickActionCategories.getBillingActions(
            onCreateInvoice: _createInvoice,
            onReceivePayment: _receivePayment,
            onViewReports: _viewReports,
            onManageCustomers: _manageCustomers,
          ),
        ),
        const SizedBox(height: 24),
        
        // Recent Activity
        ActivityFeed(
          title: 'Recent Billing Activity',
          activities: [
            ActivityItem.invoiceCreated(
              id: '1',
              invoiceNumber: 'INV-2024-001',
              customerEmail: 'customer@example.com',
              amount: 75000.00,
            ),
            ActivityItem.invoicePaid(
              id: '2',
              invoiceNumber: 'INV-2024-002',
              customerEmail: 'client@example.com',
              amount: 50000.00,
            ),
            ActivityItem.invoiceCreated(
              id: '3',
              invoiceNumber: 'INV-2024-003',
              customerEmail: 'business@example.com',
              amount: 125000.00,
            ),
          ],
          maxItems: 5,
          onLoadMore: _loadMoreActivities,
        ),
      ],
    );
  }

  Widget _buildInvoicesTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Invoice Stats
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
              _buildStatItem('Total', '45', themeExtension.primaryText),
              _buildStatItem('Paid', '32', DayFiColors.green),
              _buildStatItem('Pending', '10', DayFiColors.blue),
              _buildStatItem('Overdue', '3', DayFiColors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Invoice List
        _buildInvoiceList(themeExtension),
      ],
    );
  }

  Widget _buildPaymentsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Payment Stats
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
              _buildStatItem('Today', '₦125,000', DayFiColors.green),
              _buildStatItem('This Week', '₦450,000', DayFiColors.green),
              _buildStatItem('This Month', '₦1,850,000', DayFiColors.green),
              _buildStatItem('Pending', '₦85,000', DayFiColors.blue),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Payment List
        _buildPaymentList(themeExtension),
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
              _buildStatItem('Total', '127', DayFiColors.primary),
              _buildStatItem('Active', '95', DayFiColors.green),
              _buildStatItem('New', '12', DayFiColors.blue),
              _buildStatItem('Inactive', '20', DayFiColors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Customer List
        _buildCustomerList(themeExtension),
      ],
    );
  }

  Widget _buildReportsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Report Options
        Container(
          margin: const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildReportCard('Revenue Report', Icons.trending_up, themeExtension),
              _buildReportCard('Customer Report', Icons.people, themeExtension),
              _buildReportCard('Payment Report', Icons.payment, themeExtension),
              _buildReportCard('Tax Report', Icons.receipt, themeExtension),
            ],
          ),
        ),
        
        // Recent Reports
        _buildRecentReports(themeExtension),
      ],
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

  Widget _buildInvoiceList(AppThemeExtension themeExtension) {
    final invoices = [
      {'number': 'INV-2024-001', 'customer': 'customer@example.com', 'amount': 75000.00, 'status': 'paid'},
      {'number': 'INV-2024-002', 'customer': 'client@example.com', 'amount': 50000.00, 'status': 'pending'},
      {'number': 'INV-2024-003', 'customer': 'business@example.com', 'amount': 125000.00, 'status': 'overdue'},
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
        children: [
          ...invoices.map((invoice) => _buildInvoiceItem(invoice, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(Map<String, dynamic> invoice, AppThemeExtension themeExtension) {
    final status = invoice['status'] as String;
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'paid':
        statusColor = DayFiColors.green;
        statusText = 'Paid';
        break;
      case 'pending':
        statusColor = DayFiColors.blue;
        statusText = 'Pending';
        break;
      case 'overdue':
        statusColor = DayFiColors.red;
        statusText = 'Overdue';
        break;
      default:
        statusColor = themeExtension.secondaryText;
        statusText = 'Unknown';
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.receipt_long,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        invoice['number'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeExtension.primaryText,
        ),
      ),
      subtitle: Text(
        invoice['customer'],
        style: TextStyle(
          color: themeExtension.secondaryText,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦${invoice['amount'].toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(AppThemeExtension themeExtension) {
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
            'Recent Payments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Payment items would go here
          Text(
            'No recent payments',
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

  Widget _buildReportCard(String title, IconData icon, AppThemeExtension themeExtension) {
    return GestureDetector(
      onTap: () => _openReport(title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeExtension.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeExtension.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: themeExtension.accentBlue,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(AppThemeExtension themeExtension) {
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
            'Recent Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Report items would go here
          Text(
            'No recent reports',
            style: TextStyle(
              color: themeExtension.hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(AppThemeExtension themeExtension) {
    return FloatingActionButton.extended(
      onPressed: _createInvoice,
      backgroundColor: themeExtension.accentBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Create Invoice'),
    );
  }

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'overview':
        return 'Overview';
      case 'invoices':
        return 'Invoices';
      case 'payments':
        return 'Payments';
      case 'customers':
        return 'Customers';
      case 'reports':
        return 'Reports';
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

  void _createInvoice() {
    HapticFeedback.lightImpact();
    // Navigate to invoice creation
  }

  void _receivePayment() {
    HapticFeedback.lightImpact();
    // Navigate to payment reception
  }

  void _viewReports() {
    HapticFeedback.lightImpact();
    // Navigate to reports
  }

  void _manageCustomers() {
    HapticFeedback.lightImpact();
    // Navigate to customer management
  }

  void _openRevenueDetails() {
    HapticFeedback.lightImpact();
    // Navigate to revenue details
  }

  void _openOutstandingDetails() {
    HapticFeedback.lightImpact();
    // Navigate to outstanding details
  }

  void _openPaymentTimeDetails() {
    HapticFeedback.lightImpact();
    // Navigate to payment time details
  }

  void _openConversionDetails() {
    HapticFeedback.lightImpact();
    // Navigate to conversion details
  }

  void _loadMoreActivities() {
    HapticFeedback.lightImpact();
    // Load more activities
  }

  void _openReport(String reportType) {
    HapticFeedback.lightImpact();
    // Open specific report
  }
}
