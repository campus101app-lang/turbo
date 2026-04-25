// lib/widgets/transaction_item.dart
//
// Transaction Item Widget for DayFi
// Displays individual transaction information
//

import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

class TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>()!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTransactionColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransactionIcon(),
                  color: _getTransactionColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['description'] ?? 'Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeExtension.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction['category'] ?? 'General',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeExtension.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction['date']),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(transaction['amount'], transaction['currency']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getAmountColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction['status'] ?? 'pending',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon() {
    final type = transaction['type'] as String?;
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getTransactionColor() {
    final type = transaction['type'] as String?;
    switch (type) {
      case 'income':
        return DayFiColors.success;
      case 'expense':
        return DayFiColors.error;
      case 'transfer':
        return DayFiColors.secondary;
      default:
        return DayFiColors.primary;
    }
  }

  Color _getAmountColor(BuildContext context) {
    final type = transaction['type'] as String?;
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>()!;
    
    switch (type) {
      case 'income':
        return DayFiColors.success;
      case 'expense':
        return DayFiColors.error;
      default:
        return themeExtension.primaryText;
    }
  }

  Color _getStatusColor() {
    final status = transaction['status'] as String?;
    switch (status) {
      case 'completed':
        return DayFiColors.success;
      case 'pending':
        return DayFiColors.warning;
      case 'failed':
        return DayFiColors.error;
      default:
        return DayFiColors.secondary;
    }
  }

  String _formatAmount(dynamic amount, String? currency) {
    final amountValue = (amount as num?)?.toDouble() ?? 0.0;
    final currencySymbol = currency ?? 'NGN';
    return '$currencySymbol ${amountValue.toStringAsFixed(2)}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
