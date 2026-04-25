// lib/screens/home/cached_home_screen.dart
//
// Cached Home Screen with Tab Caching and Refresh Functionality
// Implements intelligent caching with refresh for all tabs
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';
import 'package:mobile_app/widgets/enterprise/activity_feed.dart';
import 'package:mobile_app/services/tab_cache_service.dart';
import 'package:mobile_app/services/offline_service.dart';
import 'package:mobile_app/services/notification_service.dart';

class CachedHomeScreen extends StatefulWidget {
  const CachedHomeScreen({super.key});

  @override
  State<CachedHomeScreen> createState() => _CachedHomeScreenState();
}

class _CachedHomeScreenState extends State<CachedHomeScreen>
    with TickerProviderStateMixin {
  final TabCacheService _cacheService = TabCacheService();
  final OfflineService _offlineService = OfflineService();
  final NotificationService _notificationService = NotificationService();

  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _listenToCacheEvents();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
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

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
  }

  Future<void> _initializeServices() async {
    try {
      _cacheService.initialize();
      _offlineService.initialize();
      _notificationService.initialize();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  void _listenToCacheEvents() {
    _cacheService.getCacheEvents('home').listen((event) {
      if (event.type == TabCacheEventType.autoRefreshRequested) {
        _refreshData();
      }
    });
  }

  Future<Map<String, dynamic>?> _loadHomeData() async {
    try {
      // Simulate API call with offline fallback
      final isOnline = await _offlineService.hasLocalData('home_data');
      
      if (isOnline) {
        final cachedData = await _offlineService.getLocalData('home_data');
        if (cachedData != null) {
          return cachedData;
        }
      }

      // Generate fresh data
      return await _generateHomeData();
    } catch (e) {
      debugPrint('Error loading home data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _generateHomeData() async {
    return {
      'balance': 125000.50,
      'currency': 'NGN',
      'kpis': [
        {
          'title': 'Monthly Revenue',
          'value': '₦450,000',
          'subtitle': 'This month',
          'trend': 'up',
          'trendPercentage': 15.2,
          'icon': 'trending_up',
          'color': 'green',
        },
        {
          'title': 'Active Customers',
          'value': '127',
          'subtitle': 'Total customers',
          'trend': 'up',
          'trendPercentage': 8.7,
          'icon': 'people',
          'color': 'blue',
        },
        {
          'title': 'Pending Invoices',
          'value': '₦125,000',
          'subtitle': '12 invoices',
          'trend': 'down',
          'trendPercentage': -5.3,
          'icon': 'receipt_long',
          'color': 'blue',
        },
        {
          'title': 'Conversion Rate',
          'value': '68.5%',
          'subtitle': 'Last 30 days',
          'trend': 'up',
          'trendPercentage': 3.2,
          'icon': 'show_chart',
          'color': 'green',
        },
      ],
      'activities': [
        {
          'id': '1',
          'type': 'invoice_created',
          'title': 'Invoice Created',
          'description': 'Invoice INV-2024-001 for customer@example.com',
          'amount': 75000.00,
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'id': '2',
          'type': 'invoice_paid',
          'title': 'Invoice Paid',
          'description': 'client@example.com paid invoice INV-2024-002',
          'amount': 50000.00,
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        },
        {
          'id': '3',
          'type': 'expense_submitted',
          'title': 'Expense Submitted',
          'description': 'Office Supplies expense of ₦25,000',
          'amount': 25000.00,
          'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        },
        {
          'id': '4',
          'type': 'order_received',
          'title': 'Order Received',
          'description': 'Order ORD-2024-001 from John Doe',
          'amount': 35000.00,
          'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
        },
        {
          'id': '5',
          'type': 'member_invited',
          'title': 'Team Member Invited',
          'description': 'team@company.com invited as Manager',
          'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
        },
      ],
      'insights': [
        {
          'title': 'Revenue Growth',
          'description': 'Your revenue increased by 15.2% this month compared to last month.',
          'type': 'positive',
          'icon': 'trending_up',
        },
        {
          'title': 'Customer Retention',
          'description': '85% of your customers returned this month. Consider loyalty programs.',
          'type': 'positive',
          'icon': 'people',
        },
        {
          'title': 'Payment Collection',
          'description': '3 invoices are overdue. Follow up with customers to improve cash flow.',
          'type': 'warning',
          'icon': 'warning',
        },
      ],
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    
    try {
      await _cacheService.refreshTabData('home', _loadHomeData, isCritical: true);
      _lastRefreshTime = DateTime.now();
      
      // Show success notification
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      setState(() => _isRefreshing = false);
    }
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
                opacity: _contentFadeAnimation,
                child: Column(
                  children: [
                    _buildLastRefreshInfo(themeExtension),
                    TabCacheWidget(
                      tabKey: 'home',
                      dataLoader: _loadHomeData,
                      autoRefresh: true,
                      refreshInterval: const Duration(minutes: 5),
                      builder: (cachedData, isLoading, refresh) {
                        if (isLoading && cachedData == null) {
                          return _buildLoadingState(themeExtension);
                        }
                        
                        if (cachedData == null) {
                          return _buildErrorState(themeExtension, refresh);
                        }
                        
                        return _buildContent(cachedData, themeExtension, refresh);
                      },
                    ),
                    const SizedBox(height: 100),
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
                      color: themeExtension.accentBlue,
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
            onPressed: _refreshData,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeExtension.accentBlue,
                      ),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: themeExtension.primaryText,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastRefreshInfo(AppThemeExtension themeExtension) {
    if (_lastRefreshTime == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeExtension.cardBorder.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: themeExtension.accentBlue,
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: ${_formatRefreshTime(_lastRefreshTime!)}',
            style: TextStyle(
              fontSize: 12,
              color: themeExtension.accentBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic> data,
    AppThemeExtension themeExtension,
    VoidCallback refresh,
  ) {
    return Column(
      children: [
        // Balance Section
        Container(
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
                      onPressed: refresh,
                      icon: Icon(
                        Icons.refresh,
                        color: themeExtension.accentBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data['currency'] as String} ${(data['balance'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: DayFiColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '',
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
        ),

        // KPI Section
        _buildKPISection(data['kpis'] as List, themeExtension),

        // Quick Actions
        EnterpriseQuickActionsCard(
          title: 'Quick Actions',
          actions: QuickActionCategories.getBillingActions(
            onCreateInvoice: _createInvoice,
            onReceivePayment: _receivePayment,
            onViewReports: _viewReports,
            onManageCustomers: _manageCustomers,
          ),
        ),

        // Activity Feed
        ActivityFeed(
          title: 'Recent Activity',
          activities: (data['activities'] as List)
              .map((activity) => _createActivityItem(activity))
              .toList(),
          maxItems: 5,
          showLoadMore: true,
          onLoadMore: _loadMoreActivities,
        ),

        // Insights Section
        _buildInsightsSection(data['insights'] as List, themeExtension),
      ],
    );
  }

  Widget _buildKPISection(List kpis, AppThemeExtension themeExtension) {
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
          kpiCards: kpis.map((kpi) => _createKPICard(kpi)).toList(),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(List insights, AppThemeExtension themeExtension) {
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
                color: themeExtension.accentBlue,
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
        iconColor = DayFiColors.success;
        backgroundColor = DayFiColors.successDimLight;
        break;
      case 'warning':
        iconColor = DayFiColors.error;
        backgroundColor = DayFiColors.errorDimLight;
        break;
      case 'opportunity':
        iconColor = DayFiColors.secondary;
        backgroundColor = DayFiColors.secondaryDimLight;
        break;
      default:
        iconColor = themeExtension.accentBlue;
        backgroundColor = themeExtension.accentBlue.withAlpha(25);
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
              _getIconData(insight['icon'] as String),
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
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeExtension.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'] as String,
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

  Widget _buildLoadingState(AppThemeExtension themeExtension) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                themeExtension.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              color: themeExtension.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppThemeExtension themeExtension, VoidCallback refresh) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: themeExtension.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: TextStyle(
              color: themeExtension.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: themeExtension.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeExtension.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  EnterpriseKPICard _createKPICard(Map<String, dynamic> kpi) {
    return EnterpriseKPICard(
      title: kpi['title'] as String,
      value: kpi['value'] as String,
      subtitle: kpi['subtitle'] as String,
      trend: _parseTrend(kpi['trend'] as String),
      trendPercentage: (kpi['trendPercentage'] as double),
      icon: _getIconData(kpi['icon'] as String),
      color: _parseColor(kpi['color'] as String),
      onTap: () => _openKPIDetails(kpi['title'] as String),
    );
  }

  ActivityItem _createActivityItem(Map<String, dynamic> activity) {
    switch (activity['type'] as String) {
      case 'invoice_created':
        return ActivityItem.invoiceCreated(
          id: activity['id'] as String,
          invoiceNumber: 'INV-2024-001',
          customerEmail: 'customer@example.com',
          amount: activity['amount'] as double,
        );
      case 'invoice_paid':
        return ActivityItem.invoicePaid(
          id: activity['id'] as String,
          invoiceNumber: 'INV-2024-002',
          customerEmail: 'client@example.com',
          amount: activity['amount'] as double,
        );
      case 'expense_submitted':
        return ActivityItem.expenseSubmitted(
          id: activity['id'] as String,
          category: 'Office Supplies',
          amount: activity['amount'] as double,
        );
      case 'order_received':
        return ActivityItem.orderReceived(
          id: activity['id'] as String,
          orderNumber: 'ORD-2024-001',
          customerName: 'John Doe',
          amount: activity['amount'] as double,
        );
      case 'member_invited':
        return ActivityItem.memberInvited(
          id: activity['id'] as String,
          memberEmail: 'team@company.com',
          role: 'Manager',
        );
      default:
        return ActivityItem.invoiceCreated(
          id: activity['id'] as String,
          invoiceNumber: 'UNKNOWN',
          customerEmail: 'unknown@example.com',
          amount: 0.0,
        );
    }
  }

  KPITrend _parseTrend(String trend) {
    switch (trend.toLowerCase()) {
      case 'up':
        return KPITrend.up;
      case 'down':
        return KPITrend.down;
      default:
        return KPITrend.neutral;
    }
  }

  Color _parseColor(String color) {
    switch (color.toLowerCase()) {
      case 'green':
        return DayFiColors.success;
      case 'blue':
        return DayFiColors.secondary;
      case 'red':
        return DayFiColors.error;
      default:
        return DayFiColors.secondary;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'trending_up':
        return Icons.trending_up;
      case 'people':
        return Icons.people;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'show_chart':
        return Icons.show_chart;
      case 'warning':
        return Icons.warning;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action handlers
  void _openBalanceDetails() {
    HapticFeedback.lightImpact();
    // Navigate to balance details
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

  void _openKPIDetails(String title) {
    HapticFeedback.lightImpact();
    // Navigate to KPI details
  }

  void _loadMoreActivities() {
    HapticFeedback.lightImpact();
    // Load more activities
  }
}
