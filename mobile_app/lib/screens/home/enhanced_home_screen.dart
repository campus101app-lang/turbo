// lib/screens/home/enhanced_home_screen.dart
//
// Enhanced Home Screen with Enterprise Features
// KPI cards, quick actions, activity feed, and business insights
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';
import 'package:mobile_app/widgets/enterprise/activity_feed.dart';
import 'package:mobile_app/widgets/balance_card.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      backgroundColor: themeExtension.surfaceBackground,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: themeExtension.accentBlue.withValues(alpha: 0.1),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(themeExtension),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Column(
                  children: [
                    _buildBalanceSection(themeExtension),
                    _buildKPISection(themeExtension),
                    _buildQuickActionsSection(themeExtension),
                    _buildActivitySection(themeExtension),
                    _buildInsightsSection(themeExtension),
                    const SizedBox(height: 100), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(AppThemeExtension themeExtension) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: themeExtension.surfaceBackground,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Text(
              'Dashboard',
              style: TextStyle(
                color: themeExtension.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeExtension.surfaceBackground,
                  themeExtension.surfaceBackground.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 60),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeExtension.secondaryText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Business Financial Command Center',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeExtension.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeExtension.cardBorder.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: themeExtension.accentBlue.withValues(alpha: 0.1),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: IconButton(
            onPressed: _openNotifications,
            icon: Icon(
              Icons.notifications_outlined,
              color: themeExtension.primaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(AppThemeExtension themeExtension) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeExtension.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: _refreshBalance,
                  icon: Icon(
                    Icons.refresh,
                    color: themeExtension.accentBlue.withValues(alpha: 0.1),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'NGN 125,000.50',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeExtension.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: DayFiColors.success,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+12.5%',
                  style: TextStyle(
                    fontSize: 12,
                    color: DayFiColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection(AppThemeExtension themeExtension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Business Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        EnterpriseKPIGrid(
          kpiCards: [
            EnterpriseKPICard(
              title: 'Monthly Revenue',
              value: '₦450,000',
              subtitle: 'This month',
              trend: KPITrend.up,
              trendPercentage: 15.2,
              icon: Icons.trending_up,
              color: DayFiColors.green,
              onTap: _openRevenueDetails,
            ),
            EnterpriseKPICard(
              title: 'Active Customers',
              value: '127',
              subtitle: 'Total customers',
              trend: KPITrend.up,
              trendPercentage: 8.7,
              icon: Icons.people,
              color: DayFiColors.blue,
              onTap: _openCustomerDetails,
            ),
            EnterpriseKPICard(
              title: 'Pending Invoices',
              value: '₦125,000',
              subtitle: '12 invoices',
              trend: KPITrend.down,
              trendPercentage: -5.3,
              icon: Icons.receipt_long,
              color: DayFiColors.blue,
              onTap: _openInvoiceDetails,
            ),
            EnterpriseKPICard(
              title: 'Conversion Rate',
              value: '68.5%',
              subtitle: 'Last 30 days',
              trend: KPITrend.up,
              trendPercentage: 3.2,
              icon: Icons.show_chart,
              color: DayFiColors.green,
              onTap: _openAnalyticsDetails,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(AppThemeExtension themeExtension) {
    return EnterpriseQuickActionsCard(
      title: 'Quick Actions',
      actions: QuickActionCategories.getBillingActions(
        onCreateInvoice: _createInvoice,
        onReceivePayment: _receivePayment,
        onViewReports: _viewReports,
        onManageCustomers: _manageCustomers,
      ),
    );
  }

  Widget _buildActivitySection(AppThemeExtension themeExtension) {
    final activities = [
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
      ActivityItem.expenseSubmitted(
        id: '3',
        category: 'Office Supplies',
        amount: 25000.00,
      ),
      ActivityItem.orderReceived(
        id: '4',
        orderNumber: 'ORD-2024-001',
        customerName: 'John Doe',
        amount: 35000.00,
      ),
      ActivityItem.memberInvited(
        id: '5',
        memberEmail: 'team@company.com',
        role: 'Manager',
      ),
    ];

    return ActivityFeed(
      title: 'Recent Activity',
      activities: activities,
      maxItems: 5,
      showLoadMore: true,
      onLoadMore: _loadMoreActivities,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildInsightsSection(AppThemeExtension themeExtension) {
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
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: themeExtension.accentBlue.withValues(alpha: 0.1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Business Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeExtension.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Revenue Growth',
            'Your revenue increased by 15.2% this month compared to last month.',
            DayFiColors.green,
            themeExtension,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Customer Retention',
            '85% of your customers returned this month. Consider loyalty programs.',
            DayFiColors.blue,
            themeExtension,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Payment Collection',
            '3 invoices are overdue. Follow up with customers to improve cash flow.',
            DayFiColors.red,
            themeExtension,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    Color color,
    AppThemeExtension themeExtension,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeExtension.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: themeExtension.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
    // Refresh data logic here
  }

  Future<void> _refreshBalance() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 500));
    // Refresh balance logic here
  }

  void _openBalanceDetails() {
    HapticFeedback.lightImpact();
    // Navigate to balance details
  }

  void _openNotifications() {
    HapticFeedback.lightImpact();
    // Navigate to notifications
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

  void _openCustomerDetails() {
    HapticFeedback.lightImpact();
    // Navigate to customer details
  }

  void _openInvoiceDetails() {
    HapticFeedback.lightImpact();
    // Navigate to invoice details
  }

  void _openAnalyticsDetails() {
    HapticFeedback.lightImpact();
    // Navigate to analytics details
  }

  void _loadMoreActivities() {
    HapticFeedback.lightImpact();
    // Load more activities
  }
}
