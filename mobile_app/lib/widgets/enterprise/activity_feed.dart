// lib/widgets/enterprise/activity_feed.dart
//
// Enterprise Activity Feed Component
// Displays recent business activities with real-time updates
//

import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

enum ActivityType {
  invoiceCreated,
  invoicePaid,
  expenseSubmitted,
  expenseApproved,
  orderReceived,
  orderShipped,
  memberInvited,
  workflowCompleted,
  paymentReceived,
  customerAdded,
}

class ActivityFeed extends StatefulWidget {
  final List<ActivityItem> activities;
  final String? title;
  final int maxItems;
  final bool showLoadMore;
  final VoidCallback? onLoadMore;
  final bool showTimestamp;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final Widget? emptyState;

  const ActivityFeed({
    super.key,
    required this.activities,
    this.title,
    this.maxItems = 10,
    this.showLoadMore = true,
    this.onLoadMore,
    this.showTimestamp = true,
    this.padding,
    this.isLoading = false,
    this.emptyState,
  });

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      margin: widget.padding ?? const EdgeInsets.all(16),
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
          _buildHeader(themeExtension),
          _buildContent(themeExtension),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            widget.title ?? 'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeExtension.primaryText,
            ),
          ),
          const Spacer(),
          if (widget.activities.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeExtension.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.activities.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeExtension.accentBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppThemeExtension themeExtension) {
    if (widget.isLoading) {
      return _buildLoadingState(themeExtension);
    }

    if (widget.activities.isEmpty) {
      return _buildEmptyState(themeExtension);
    }

    final displayActivities = widget.activities.take(widget.maxItems).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayActivities.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: themeExtension.cardBorder,
          ),
          itemBuilder: (context, index) {
            return _ActivityItemWidget(
              activity: displayActivities[index],
              showTimestamp: widget.showTimestamp,
              themeExtension: themeExtension,
              animation: _getItemAnimation(index),
            );
          },
        ),
        if (widget.showLoadMore && widget.activities.length > widget.maxItems)
          _buildLoadMoreButton(themeExtension),
      ],
    );
  }

  Widget _buildLoadingState(AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(3, (index) => _buildShimmerItem(themeExtension)),
      ),
    );
  }

  Widget _buildShimmerItem(AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeExtension.hintText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: themeExtension.hintText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeExtension.hintText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension themeExtension) {
    if (widget.emptyState != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: widget.emptyState!,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: themeExtension.hintText,
          ),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: themeExtension.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your business activities will appear here',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: themeExtension.hintText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(AppThemeExtension themeExtension) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextButton(
        onPressed: widget.onLoadMore,
        style: TextButton.styleFrom(
          foregroundColor: themeExtension.accentBlue,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'Load More Activities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Animation<double> _getItemAnimation(int index) {
    final start = index * 0.1;
    final end = start + 0.3;
    
    return CurvedAnimation(
      parent: _fadeController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0)),
    );
  }
}

class _ActivityItemWidget extends StatelessWidget {
  final ActivityItem activity;
  final bool showTimestamp;
  final AppThemeExtension themeExtension;
  final Animation<double> animation;

  const _ActivityItemWidget({
    required this.activity,
    required this.showTimestamp,
    required this.themeExtension,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityContent(),
              ),
              if (showTimestamp) ...[
                const SizedBox(width: 12),
                _buildTimestamp(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon() {
    Color iconColor;
    IconData iconData;
    Color backgroundColor;

    switch (activity.type) {
      case ActivityType.invoiceCreated:
        iconColor = DayFiColors.blue;
        iconData = Icons.add_chart;
        backgroundColor = DayFiColors.blueDimLight;
        break;
      case ActivityType.invoicePaid:
        iconColor = DayFiColors.green;
        iconData = Icons.payment;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case ActivityType.expenseSubmitted:
        iconColor = DayFiColors.blue;
        iconData = Icons.receipt_long;
        backgroundColor = DayFiColors.blueDimLight;
        break;
      case ActivityType.expenseApproved:
        iconColor = DayFiColors.green;
        iconData = Icons.check_circle;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case ActivityType.orderReceived:
        iconColor = DayFiColors.blue;
        iconData = Icons.shopping_cart;
        backgroundColor = DayFiColors.blueDimLight;
        break;
      case ActivityType.orderShipped:
        iconColor = DayFiColors.green;
        iconData = Icons.local_shipping;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case ActivityType.memberInvited:
        iconColor = DayFiColors.blue;
        iconData = Icons.person_add;
        backgroundColor = DayFiColors.blueDimLight;
        break;
      case ActivityType.workflowCompleted:
        iconColor = DayFiColors.green;
        iconData = Icons.task_alt;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case ActivityType.paymentReceived:
        iconColor = DayFiColors.green;
        iconData = Icons.account_balance;
        backgroundColor = DayFiColors.greenDimLight;
        break;
      case ActivityType.customerAdded:
        iconColor = DayFiColors.blue;
        iconData = Icons.person_add;
        backgroundColor = DayFiColors.blueDimLight;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildActivityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeExtension.primaryText,
          ),
        ),
        if (activity.description != null) ...[
          const SizedBox(height: 2),
          Text(
            activity.description!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: themeExtension.secondaryText,
            ),
          ),
        ],
        if (activity.metadata != null) ...[
          const SizedBox(height: 4),
          _buildMetadata(),
        ],
      ],
    );
  }

  Widget _buildMetadata() {
    final metadata = activity.metadata!;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: metadata.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: themeExtension.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: themeExtension.accentBlue,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      _formatTimestamp(activity.timestamp),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: themeExtension.hintText,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String? description;
  final DateTime timestamp;
  final Map<String, String>? metadata;
  final String? userId;
  final String? userName;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.metadata,
    this.userId,
    this.userName,
  });

  factory ActivityItem.invoiceCreated({
    required String id,
    required String invoiceNumber,
    required String customerEmail,
    required double amount,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.invoiceCreated,
      title: 'Invoice Created',
      description: 'Invoice $invoiceNumber for $customerEmail',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Invoice': invoiceNumber,
        'Amount': '₦${amount.toStringAsFixed(2)}',
      },
    );
  }

  factory ActivityItem.invoicePaid({
    required String id,
    required String invoiceNumber,
    required String customerEmail,
    required double amount,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.invoicePaid,
      title: 'Invoice Paid',
      description: '$customerEmail paid invoice $invoiceNumber',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Invoice': invoiceNumber,
        'Amount': '₦${amount.toStringAsFixed(2)}',
      },
    );
  }

  factory ActivityItem.expenseSubmitted({
    required String id,
    required String category,
    required double amount,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.expenseSubmitted,
      title: 'Expense Submitted',
      description: '$category expense of ₦${amount.toStringAsFixed(2)}',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Category': category,
        'Amount': '₦${amount.toStringAsFixed(2)}',
      },
    );
  }

  factory ActivityItem.orderReceived({
    required String id,
    required String orderNumber,
    required String customerName,
    required double amount,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.orderReceived,
      title: 'Order Received',
      description: 'Order $orderNumber from $customerName',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Order': orderNumber,
        'Amount': '₦${amount.toStringAsFixed(2)}',
      },
    );
  }

  factory ActivityItem.workflowCompleted({
    required String id,
    required String workflowName,
    required String completedBy,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.workflowCompleted,
      title: 'Workflow Completed',
      description: '$workflowName completed by $completedBy',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Workflow': workflowName,
        'Completed By': completedBy,
      },
    );
  }

  factory ActivityItem.memberInvited({
    required String id,
    required String memberEmail,
    required String role,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id,
      type: ActivityType.memberInvited,
      title: 'Team Member Invited',
      description: '$memberEmail invited as $role',
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'Role': role,
        'Email': memberEmail,
      },
    );
  }
}
