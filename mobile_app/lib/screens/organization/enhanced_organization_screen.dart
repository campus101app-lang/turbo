// lib/screens/organization/enhanced_organization_screen.dart
//
// Enhanced Organization Screen with Enterprise Features
// Multi-tenant team management, workflows, and collaboration tools
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';
import 'package:mobile_app/widgets/enterprise/quick_actions_card.dart';
import 'package:mobile_app/widgets/enterprise/activity_feed.dart';

class EnhancedOrganizationScreen extends StatefulWidget {
  const EnhancedOrganizationScreen({super.key});

  @override
  State<EnhancedOrganizationScreen> createState() => _EnhancedOrganizationScreenState();
}

class _EnhancedOrganizationScreenState extends State<EnhancedOrganizationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedTab = 'team';
  final List<String> _tabs = ['team', 'workflows', 'roles', 'settings', 'analytics'];

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
          'Organization',
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
          onPressed: _openSettings,
          icon: Icon(
            Icons.settings,
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
      case 'team':
        return _buildTeamTab(themeExtension);
      case 'workflows':
        return _buildWorkflowsTab(themeExtension);
      case 'roles':
        return _buildRolesTab(themeExtension);
      case 'settings':
        return _buildSettingsTab(themeExtension);
      case 'analytics':
        return _buildAnalyticsTab(themeExtension);
      default:
        return _buildTeamTab(themeExtension);
    }
  }

  Widget _buildTeamTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Team KPI Cards
        EnterpriseKPIGrid(
          kpiCards: [
            EnterpriseKPICard(
              title: 'Team Members',
              value: '24',
              subtitle: 'Active members',
              trend: KPITrend.up,
              trendPercentage: 8.3,
              icon: Icons.people,
              backgroundColor: DayFiColors.secondary,
              onTap: _openTeamDetails,
            ),
            EnterpriseKPICard(
              title: 'Pending Invites',
              value: '3',
              subtitle: 'Awaiting response',
              trend: KPITrend.down,
              trendPercentage: -25.0,
              icon: Icons.mail,
              backgroundColor: DayFiColors.secondary,
              onTap: _openInviteDetails,
            ),
            EnterpriseKPICard(
              title: 'Active Today',
              value: '18',
              subtitle: 'Logged in today',
              trend: KPITrend.up,
              trendPercentage: 12.5,
              icon: Icons.person_pin,
              color: DayFiColors.success,
              onTap: _openActivityDetails,
            ),
            EnterpriseKPICard(
              title: 'Departments',
              value: '5',
              subtitle: 'Team departments',
              trend: KPITrend.neutral,
              trendPercentage: 0.0,
              icon: Icons.business,
              backgroundColor: DayFiColors.secondary,
              onTap: _openDepartmentDetails,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Quick Actions
        EnterpriseQuickActionsCard(
          title: 'Team Actions',
          actions: QuickActionCategories.getOrganizationActions(
            onInviteMember: _inviteMember,
            onViewWorkflows: _viewWorkflows,
            onManageRoles: _manageRoles,
            onViewTeamAnalytics: _viewTeamAnalytics,
          ),
        ),
        const SizedBox(height: 24),
        
        // Team Activity
        ActivityFeed(
          title: 'Team Activity',
          activities: [
            ActivityItem.memberInvited(
              id: '1',
              memberEmail: 'john@company.com',
              role: 'Manager',
            ),
            ActivityItem.workflowCompleted(
              id: '2',
              workflowName: 'Invoice Approval',
              completedBy: 'Admin User',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            ActivityItem.memberInvited(
              id: '3',
              memberEmail: 'sarah@company.com',
              role: 'Staff',
              timestamp: DateTime.now().subtract(const Duration(hours: 4)),
            ),
          ],
          maxItems: 5,
          onLoadMore: _loadMoreActivities,
        ),
      ],
    );
  }

  Widget _buildWorkflowsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Workflow Stats
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
              _buildStatItem('Active', '8', themeExtension.accentBlue),
              _buildStatItem('Pending', '12', DayFiColors.secondary),
              _buildStatItem('Completed', '45', DayFiColors.success),
              _buildStatItem('Failed', '2', DayFiColors.error),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Workflow Categories
        _buildWorkflowCategories(themeExtension),
        const SizedBox(height: 16),
        
        // Recent Workflows
        _buildRecentWorkflows(themeExtension),
      ],
    );
  }

  Widget _buildRolesTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Role Overview
        const EnterpriseKPIGrid(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          kpiCards: [
            EnterpriseKPICard(
              title: 'Owner',
              value: '1',
              subtitle: 'Organization owner',
              icon: Icons.admin_panel_settings,
              backgroundColor: DayFiColors.secondary,
            ),
            EnterpriseKPICard(
              title: 'Admin',
              value: '3',
              subtitle: 'System administrators',
              icon: Icons.security,
              backgroundColor: DayFiColors.secondary,
            ),
            EnterpriseKPICard(
              title: 'Manager',
              value: '5',
              subtitle: 'Team managers',
              icon: Icons.supervisor_account,
              color: DayFiColors.success,
            ),
            EnterpriseKPICard(
              title: 'Staff',
              value: '15',
              subtitle: 'Regular staff',
              icon: Icons.people,
              backgroundColor: DayFiColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Role Permissions
        _buildRolePermissions(themeExtension),
      ],
    );
  }

  Widget _buildSettingsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Organization Settings
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organization Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeExtension.primaryText,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingItem('Organization Name', 'Tech Solutions Ltd', themeExtension),
              _buildSettingItem('Business Type', 'Limited Liability', themeExtension),
              _buildSettingItem('Created', 'Jan 15, 2024', themeExtension),
              _buildSettingItem('Plan', 'Enterprise', themeExtension),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Security Settings
        _buildSecuritySettings(themeExtension),
        const SizedBox(height: 16),
        
        // Notification Settings
        _buildNotificationSettings(themeExtension),
      ],
    );
  }

  Widget _buildAnalyticsTab(AppThemeExtension themeExtension) {
    return Column(
      children: [
        // Team Performance KPIs
        const EnterpriseKPIGrid(
          kpiCards: [
            EnterpriseKPICard(
              title: 'Productivity',
              value: '87%',
              subtitle: 'Team productivity score',
              trend: KPITrend.up,
              trendPercentage: 5.2,
              icon: Icons.trending_up,
              color: DayFiColors.success,
            ),
            EnterpriseKPICard(
              title: 'Collaboration',
              value: '92%',
              subtitle: 'Cross-team collaboration',
              trend: KPITrend.up,
              trendPercentage: 8.7,
              icon: Icons.groups,
              color: DayFiColors.success,
            ),
            EnterpriseKPICard(
              title: 'Efficiency',
              value: '78%',
              subtitle: 'Workflow efficiency',
              trend: KPITrend.down,
              trendPercentage: -3.1,
              icon: Icons.speed,
              color: DayFiColors.error,
            ),
            EnterpriseKPICard(
              title: 'Engagement',
              value: '85%',
              subtitle: 'Team engagement rate',
              trend: KPITrend.up,
              trendPercentage: 2.8,
              icon: Icons.event,
              color: DayFiColors.success,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Team Analytics Charts
        _buildTeamAnalyticsCharts(themeExtension),
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

  Widget _buildWorkflowCategories(AppThemeExtension themeExtension) {
    final categories = [
      {'name': 'Invoice Approval', 'count': 12, 'icon': Icons.receipt_long},
      {'name': 'Expense Approval', 'count': 8, 'icon': Icons.money_off},
      {'name': 'Purchase Orders', 'count': 6, 'icon': Icons.shopping_cart},
      {'name': 'Leave Requests', 'count': 15, 'icon': Icons.beach_access},
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
              'Workflow Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
          ),
          ...categories.map((category) => _buildWorkflowCategory(category, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildWorkflowCategory(Map<String, dynamic> category, AppThemeExtension themeExtension) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeExtension.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          category['icon'] as IconData,
          color: themeExtension.accentBlue,
          size: 20,
        ),
      ),
      title: Text(
        category['name'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeExtension.primaryText,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: themeExtension.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${category['count']}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: themeExtension.accentBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkflows(AppThemeExtension themeExtension) {
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
            'Recent Workflows',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Workflow items would go here
          Text(
            'No recent workflows',
            style: TextStyle(
              color: themeExtension.hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissions(AppThemeExtension themeExtension) {
    final roles = [
      {'name': 'Owner', 'permissions': 'Full access to all features'},
      {'name': 'Admin', 'permissions': 'Manage users, billing, settings'},
      {'name': 'Manager', 'permissions': 'Create invoices, approve expenses'},
      {'name': 'Staff', 'permissions': 'View own data, create expenses'},
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
              'Role Permissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
          ),
          ...roles.map((role) => _buildRoleItem(role, themeExtension)),
        ],
      ),
    );
  }

  Widget _buildRoleItem(Map<String, dynamic> role, AppThemeExtension themeExtension) {
    return ListTile(
      leading: Icon(
        Icons.admin_panel_settings,
        color: themeExtension.accentBlue,
        size: 20,
      ),
      title: Text(
        role['name'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeExtension.primaryText,
        ),
      ),
      subtitle: Text(
        role['permissions'],
        style: TextStyle(
          color: themeExtension.secondaryText,
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value, AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeExtension.secondaryText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(AppThemeExtension themeExtension) {
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
            'Security Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingToggle('Two-Factor Authentication', true, themeExtension),
          _buildSettingToggle('Session Timeout', true, themeExtension),
          _buildSettingToggle('IP Restrictions', false, themeExtension),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(AppThemeExtension themeExtension) {
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
            'Notification Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingToggle('Email Notifications', true, themeExtension),
          _buildSettingToggle('Push Notifications', true, themeExtension),
          _buildSettingToggle('Workflow Alerts', true, themeExtension),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(String title, bool value, AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeExtension.primaryText,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              // Update setting
            },
            activeColor: themeExtension.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAnalyticsCharts(AppThemeExtension themeExtension) {
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
            'Team Performance Analytics',
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
                    'Team Performance Chart',
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

  Widget _buildFloatingActionButton(AppThemeExtension themeExtension) {
    return FloatingActionButton.extended(
      onPressed: _inviteMember,
      backgroundColor: themeExtension.accentBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add),
      label: const Text('Invite Member'),
    );
  }

  String _getTabTitle(String tab) {
    switch (tab) {
      case 'team':
        return 'Team';
      case 'workflows':
        return 'Workflows';
      case 'roles':
        return 'Roles';
      case 'settings':
        return 'Settings';
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

  void _openSettings() {
    HapticFeedback.lightImpact();
    // Open settings
  }

  void _inviteMember() {
    HapticFeedback.lightImpact();
    // Navigate to member invitation
  }

  void _viewWorkflows() {
    HapticFeedback.lightImpact();
    // Navigate to workflows
  }

  void _manageRoles() {
    HapticFeedback.lightImpact();
    // Navigate to role management
  }

  void _viewTeamAnalytics() {
    HapticFeedback.lightImpact();
    // Navigate to team analytics
  }

  void _openTeamDetails() {
    HapticFeedback.lightImpact();
    // Navigate to team details
  }

  void _openInviteDetails() {
    HapticFeedback.lightImpact();
    // Navigate to invite details
  }

  void _openActivityDetails() {
    HapticFeedback.lightImpact();
    // Navigate to activity details
  }

  void _openDepartmentDetails() {
    HapticFeedback.lightImpact();
    // Navigate to department details
  }

  void _loadMoreActivities() {
    HapticFeedback.lightImpact();
    // Load more activities
  }
}
