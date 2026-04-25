// lib/widgets/balance_card.dart
//
// Balance card widget for displaying user balance with trend information
// Used in home screens and financial dashboards
//

import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/enterprise/kpi_card.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final bool showTrend;
  final KPITrend? trend;
  final double? trendPercentage;
  final bool showRefreshButton;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String? subtitle;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.currency,
    this.showTrend = false,
    this.trend,
    this.trendPercentage,
    this.showRefreshButton = false,
    this.onRefresh,
    this.isLoading = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeExtension.accentBlue.withOpacity(0.1),
            themeExtension.accentBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeExtension.accentBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: themeExtension.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: themeExtension.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (showRefreshButton)
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    color: themeExtension.accentBlue,
                    size: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Balance amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(balance, currency),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          
          // Trend information
          if (showTrend && trend != null && trendPercentage != null) ...[
            const SizedBox(height: 12),
            _buildTrendIndicator(themeExtension, context),
          ],
          
          // Loading indicator
          if (isLoading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeExtension.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Updating...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeExtension.accentBlue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(AppThemeExtension themeExtension, BuildContext context) {
    final isPositive = trend == KPITrend.up;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${trendPercentage!.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'USDC':
        return '\$${amount.toStringAsFixed(2)}';
      case 'NGN':
      case 'NGNT':
        return '₦${amount.toStringAsFixed(2)}';
      case 'XLM':
        return '${amount.toStringAsFixed(4)} XLM';
      default:
        return '$currency ${amount.toStringAsFixed(2)}';
    }
  }
}
