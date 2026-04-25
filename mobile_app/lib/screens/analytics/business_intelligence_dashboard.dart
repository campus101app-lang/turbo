// lib/screens/analytics/business_intelligence_dashboard.dart
//
// Business Intelligence Dashboard
// Advanced analytics, insights, and reporting for enterprise decision-making
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';

class BusinessIntelligenceDashboard extends StatefulWidget {
  const BusinessIntelligenceDashboard({super.key});

  @override
  State<BusinessIntelligenceDashboard> createState() => _BusinessIntelligenceDashboardState();
}

class _BusinessIntelligenceDashboardState extends State<BusinessIntelligenceDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedPeriod = '30d';
  final List<String> _periods = ['7d', '30d', '90d', '1y', 'all'];

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
      appBar: AppBar(
        title: Text(
          'Business Intelligence',
          style: TextStyle(
            color: themeExtension.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: themeExtension.surfaceBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportReport,
            icon: Icon(
              Icons.download,
              color: themeExtension.primaryText,
            ),
          ),
          IconButton(
            onPressed: _openSettings,
            icon: Icon(
              Icons.settings,
              color: themeExtension.primaryText,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: themeExtension.accentBlue,
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildPeriodSelector(themeExtension),
                  const SizedBox(height: 16),
                  _buildExecutiveSummary(themeExtension),
                  const SizedBox(height: 24),
                  _buildRevenueAnalytics(themeExtension),
                  const SizedBox(height: 24),
                  _buildCustomerAnalytics(themeExtension),
                  const SizedBox(height: 24),
                  _buildOperationalMetrics(themeExtension),
                  const SizedBox(height: 24),
                  _buildPredictiveInsights(themeExtension),
                  const SizedBox(height: 24),
                  _buildQuickActions(themeExtension),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppThemeExtension themeExtension) {
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
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectPeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? themeExtension.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPeriodTitle(period),
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

  Widget _buildExecutiveSummary(AppThemeExtension themeExtension) {
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
                Icons.analytics,
                color: themeExtension.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Executive Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: themeExtension.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          EnterpriseKPIGrid(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            kpiCards: [
              EnterpriseKPICard(
                title: 'Total Revenue',
                value: '₦4.2M',
                subtitle: 'Last 30 days',
                trend: KPITrend.up,
                trendPercentage: 18.5,
                icon: Icons.trending_up,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Net Profit',
                value: '₦1.8M',
                subtitle: '42.8% margin',
                trend: KPITrend.up,
                trendPercentage: 12.3,
                icon: Icons.attach_money,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Active Customers',
                value: '1,247',
                subtitle: '15.2% growth',
                trend: KPITrend.up,
                trendPercentage: 8.7,
                icon: Icons.people,
                color: DayFiColors.blue,
              ),
              EnterpriseKPICard(
                title: 'Avg Order Value',
                value: '₦3,368',
                subtitle: '+12.5% vs last month',
                trend: KPITrend.up,
                trendPercentage: 12.5,
                icon: Icons.receipt_long,
                color: DayFiColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics(AppThemeExtension themeExtension) {
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
            'Revenue Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          _buildRevenueChart(themeExtension),
          const SizedBox(height: 20),
          _buildRevenueBreakdown(themeExtension),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AppThemeExtension themeExtension) {
    return Container(
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
              'Revenue Trend Chart',
              style: TextStyle(
                color: themeExtension.hintText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily revenue over selected period',
              style: TextStyle(
                fontSize: 12,
                color: themeExtension.hintText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown(AppThemeExtension themeExtension) {
    final breakdown = [
      {'source': 'Invoices', 'amount': '₦2.8M', 'percentage': 66.7},
      {'source': 'Products', 'amount': '₦1.1M', 'percentage': 26.2},
      {'source': 'Services', 'amount': '₦0.3M', 'percentage': 7.1},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeExtension.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        ...breakdown.map((item) => _buildRevenueItem(item, themeExtension)),
      ],
    );
  }

  Widget _buildRevenueItem(Map<String, dynamic> item, AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: themeExtension.accentBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              item['source'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: themeExtension.primaryText,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item['amount'],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: themeExtension.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item['percentage']}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: themeExtension.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAnalytics(AppThemeExtension themeExtension) {
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
            'Customer Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          EnterpriseKPIGrid(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            kpiCards: [
              EnterpriseKPICard(
                title: 'New Customers',
                value: '189',
                subtitle: 'This month',
                trend: KPITrend.up,
                trendPercentage: 23.5,
                icon: Icons.person_add,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Retention Rate',
                value: '78.5%',
                subtitle: 'Customer retention',
                trend: KPITrend.up,
                trendPercentage: 5.2,
                icon: Icons.sync,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Churn Rate',
                value: '2.1%',
                subtitle: 'Monthly churn',
                trend: KPITrend.down,
                trendPercentage: -15.3,
                icon: Icons.trending_down,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'LTV',
                value: '₦45.2K',
                subtitle: 'Lifetime value',
                trend: KPITrend.up,
                trendPercentage: 8.7,
                icon: Icons.attach_money,
                color: DayFiColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalMetrics(AppThemeExtension themeExtension) {
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
            'Operational Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          EnterpriseKPIGrid(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            kpiCards: [
              EnterpriseKPICard(
                title: 'Invoices/Day',
                value: '12.5',
                subtitle: 'Average per day',
                trend: KPITrend.up,
                trendPercentage: 8.3,
                icon: Icons.receipt_long,
                color: DayFiColors.blue,
              ),
              EnterpriseKPICard(
                title: 'Payment Time',
                value: '8.2 days',
                subtitle: 'Avg collection',
                trend: KPITrend.down,
                trendPercentage: -18.5,
                icon: Icons.schedule,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Workflow Efficiency',
                value: '92.3%',
                subtitle: 'Completion rate',
                trend: KPITrend.up,
                trendPercentage: 5.7,
                icon: Icons.task_alt,
                color: DayFiColors.green,
              ),
              EnterpriseKPICard(
                title: 'Team Productivity',
                value: '87.1%',
                subtitle: 'Team efficiency',
                trend: KPITrend.up,
                trendPercentage: 3.2,
                icon: Icons.speed,
                color: DayFiColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveInsights(AppThemeExtension themeExtension) {
    final insights = [
      {
        'title': 'Revenue Projection',
        'description': 'Based on current trends, revenue expected to grow 15% next month',
        'type': 'positive',
        'icon': Icons.trending_up,
      },
      {
        'title': 'Customer Churn Risk',
        'description': '12 customers at high risk of churn based on recent activity patterns',
        'type': 'warning',
        'icon': Icons.warning,
      },
      {
        'title': 'Inventory Alert',
        'description': '3 products predicted to run out of stock within 2 weeks',
        'type': 'warning',
        'icon': Icons.inventory,
      },
      {
        'title': 'Opportunity',
        'description': 'Cross-sell opportunities identified for 45 existing customers',
        'type': 'opportunity',
        'icon': Icons.lightbulb,
      },
    ];

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
                Icons.lightbulb,
                color: themeExtension.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'AI-Powered Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeExtension.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...insights.map((insight) => _buildInsightItem(insight, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight, AppThemeExtension themeExtension) {
    Color iconColor;
    Color backgroundColor;

    switch (insight['type']) {
      case 'positive':
        iconColor = DayFiColors.green;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case 'warning':
        iconColor = DayFiColors.red;
        backgroundColor = DayFiColors.redDimLight;
        break;
      case 'opportunity':
        iconColor = DayFiColors.blue;
        backgroundColor = DayFiColors.blueDimLight;
        break;
      default:
        iconColor = themeExtension.accentBlue;
        backgroundColor = themeExtension.accentBlue.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'] as IconData,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeExtension.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'],
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

  Widget _buildQuickActions(AppThemeExtension themeExtension) {
    return EnterpriseQuickActionsCard(
      title: 'Quick Actions',
      actions: [
        QuickAction(
          label: 'Export Report',
          icon: Icons.download,
          onTap: _exportReport,
          backgroundColor: DayFiColors.secondary,
        ),
        QuickAction(
          label: 'Share Insights',
          icon: Icons.share,
          onTap: _shareInsights,
          backgroundColor: DayFiColors.success,
        ),
        QuickAction(
          label: 'Schedule Report',
          icon: Icons.schedule,
          onTap: _scheduleReport,
          backgroundColor: DayFiColors.secondary,
        ),
        QuickAction(
          label: 'Deep Dive',
          icon: Icons.analytics,
          onTap: _deepDive,
          backgroundColor: DayFiColors.secondary,
        ),
      ],
    );
  }

  String _getPeriodTitle(String period) {
    switch (period) {
      case '7d':
        return '7 Days';
      case '30d':
        return '30 Days';
      case '90d':
        return '90 Days';
      case '1y':
        return '1 Year';
      case 'all':
        return 'All Time';
      default:
        return period;
    }
  }

  void _selectPeriod(String period) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPeriod = period;
    });
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _exportReport() {
    HapticFeedback.lightImpact();
    // Export report functionality
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    // Open settings
  }

  void _shareInsights() {
    HapticFeedback.lightImpact();
    // Share insights functionality
  }

  void _scheduleReport() {
    HapticFeedback.lightImpact();
    // Schedule report functionality
  }

  void _deepDive() {
    HapticFeedback.lightImpact();
    // Deep dive functionality
  }
}
