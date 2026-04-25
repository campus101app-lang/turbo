// lib/widgets/enterprise/quick_actions_card.dart
//
// Enterprise Quick Actions Card Component
// Provides quick access to common business operations
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';

class EnterpriseQuickActionsCard extends StatelessWidget {
  final List<QuickAction> actions;
  final String? title;
  final bool showTitle;
  final EdgeInsetsGeometry? padding;
  final double? cardHeight;
  final Color? backgroundColor;

  const EnterpriseQuickActionsCard({
    super.key,
    required this.actions,
    this.title,
    this.showTitle = true,
    this.padding,
    this.cardHeight,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      margin: padding ?? const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? themeExtension.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title ?? 'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeExtension.primaryText,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildActionsGrid(themeExtension),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(AppThemeExtension themeExtension) {
    return SizedBox(
      height: cardHeight ?? 120,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return _QuickActionButton(
            action: actions[index],
            themeExtension: themeExtension,
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;
  final AppThemeExtension themeExtension;

  const _QuickActionButton({
    required this.action,
    required this.themeExtension,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.backgroundColor?.withOpacity(0.1) ?? 
                 themeExtension.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.backgroundColor?.withOpacity(0.2) ?? 
                   themeExtension.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.backgroundColor ?? themeExtension.accentBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action.icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: themeExtension.primaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? badge;
  final bool isPro;

  QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.badge,
    this.isPro = false,
  });
}

// Horizontal Quick Actions for smaller spaces
class HorizontalQuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  final EdgeInsetsGeometry? padding;
  final double? itemWidth;

  const HorizontalQuickActions({
    super.key,
    required this.actions,
    this.padding,
    this.itemWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      height: 100,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            width: itemWidth,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: action.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: action.backgroundColor?.withOpacity(0.1) ?? 
                         themeExtension.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: action.backgroundColor?.withOpacity(0.2) ?? 
                           themeExtension.cardBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: action.backgroundColor ?? themeExtension.accentBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            action.icon,
                            size: 20,
                            color: Colors.white,
                          ),
                          if (action.badge != null)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: DayFiColors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  action.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: themeExtension.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Quick Action Categories
class QuickActionCategories {
  static List<QuickAction> getBillingActions({
    required VoidCallback onCreateInvoice,
    required VoidCallback onReceivePayment,
    required VoidCallback onViewReports,
    required VoidCallback onManageCustomers,
  }) {
    return [
      QuickAction(
        label: 'Create Invoice',
        icon: Icons.add_chart,
        onTap: onCreateInvoice,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Receive Payment',
        icon: Icons.payment,
        onTap: onReceivePayment,
        backgroundColor: DayFiColors.success,
      ),
      QuickAction(
        label: 'View Reports',
        icon: Icons.analytics,
        onTap: onViewReports,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Manage Customers',
        icon: Icons.people,
        onTap: onManageCustomers,
        backgroundColor: DayFiColors.secondary,
      ),
    ];
  }

  static List<QuickAction> getShopActions({
    required VoidCallback onAddProduct,
    required VoidCallback onViewOrders,
    required VoidCallback onManageInventory,
    required VoidCallback onViewAnalytics,
  }) {
    return [
      QuickAction(
        label: 'Add Product',
        icon: Icons.add_shopping_cart,
        onTap: onAddProduct,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'View Orders',
        icon: Icons.receipt_long,
        onTap: onViewOrders,
        backgroundColor: DayFiColors.success,
        badge: '3', // Pending orders count
      ),
      QuickAction(
        label: 'Inventory',
        icon: Icons.inventory,
        onTap: onManageInventory,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Analytics',
        icon: Icons.trending_up,
        onTap: onViewAnalytics,
        backgroundColor: DayFiColors.secondary,
      ),
    ];
  }

  static List<QuickAction> getOrganizationActions({
    required VoidCallback onInviteMember,
    required VoidCallback onViewWorkflows,
    required VoidCallback onManageRoles,
    required VoidCallback onViewTeamAnalytics,
  }) {
    return [
      QuickAction(
        label: 'Invite Member',
        icon: Icons.person_add,
        onTap: onInviteMember,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Workflows',
        icon: Icons.account_tree,
        onTap: onViewWorkflows,
        backgroundColor: DayFiColors.success,
      ),
      QuickAction(
        label: 'Manage Roles',
        icon: Icons.admin_panel_settings,
        onTap: onManageRoles,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Team Analytics',
        icon: Icons.insights,
        onTap: onViewTeamAnalytics,
        backgroundColor: DayFiColors.secondary,
      ),
    ];
  }

  static List<QuickAction> getFinanceActions({
    required VoidCallback onSendMoney,
    required VoidCallback onRequestPayment,
    required VoidCallback onViewTransactions,
    required VoidCallback onManageWallet,
  }) {
    return [
      QuickAction(
        label: 'Send Money',
        icon: Icons.send,
        onTap: onSendMoney,
        backgroundColor: DayFiColors.secondary,
      ),
      QuickAction(
        label: 'Request Payment',
        icon: Icons.request_quote,
        onTap: onRequestPayment,
        backgroundColor: DayFiColors.success,
      ),
      QuickAction(
        label: 'Transactions',
        icon: Icons.list_alt,
        onTap: onViewTransactions,
        backgroundColor: DayFiColors.secondary,
        badge: '5', // Recent transactions count
      ),
      QuickAction(
        label: 'Manage Wallet',
        icon: Icons.account_balance_wallet,
        onTap: onManageWallet,
        backgroundColor: DayFiColors.secondary,
      ),
    ];
  }
}
