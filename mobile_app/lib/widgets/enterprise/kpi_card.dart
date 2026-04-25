// lib/widgets/enterprise/kpi_card.dart
//
// Enterprise KPI Card Component
// Displays key performance indicators with trend indicators and animations
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';

enum KPITrend { up, down, neutral }

class EnterpriseKPICard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final KPITrend trend;
  final double? trendPercentage;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? error;
  final bool showTrend;
  final bool animateOnLoad;

  const EnterpriseKPICard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend = KPITrend.neutral,
    this.trendPercentage,
    this.color,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.error,
    this.showTrend = true,
    this.backgroundColor,
    this.animateOnLoad = true,
  });

  @override
  State<EnterpriseKPICard> createState() => _EnterpriseKPICardState();
}

class _EnterpriseKPICardState extends State<EnterpriseKPICard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animateOnLoad) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.color ?? themeExtension.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeExtension.cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(themeExtension, isDark),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(AppThemeExtension themeExtension, bool isDark) {
    if (widget.isLoading) {
      return _buildLoadingState(themeExtension);
    }

    if (widget.error != null) {
      return _buildErrorState(themeExtension);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.color ?? themeExtension.accentBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.color ?? themeExtension.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeExtension.secondaryText,
                ),
              ),
            ),
            if (widget.showTrend && widget.trend != KPITrend.neutral) ...[
              _buildTrendIndicator(themeExtension),
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Main value
        Text(
          widget.value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: themeExtension.primaryText,
            letterSpacing: -1,
          ),
        ),
        
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: themeExtension.hintText,
            ),
          ),
        ],
        
        // Trend percentage (if available)
        if (widget.showTrend && widget.trendPercentage != null) ...[
          const SizedBox(height: 12),
          _buildTrendPercentage(themeExtension),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator(AppThemeExtension themeExtension) {
    Color trendColor;
    IconData trendIcon;

    switch (widget.trend) {
      case KPITrend.up:
        trendColor = DayFiColors.green;
        trendIcon = Icons.trending_up;
        break;
      case KPITrend.down:
        trendColor = DayFiColors.red;
        trendIcon = Icons.trending_down;
        break;
      case KPITrend.neutral:
        trendColor = themeExtension.secondaryText;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        trendIcon,
        size: 16,
        color: trendColor,
      ),
    );
  }

  Widget _buildTrendPercentage(AppThemeExtension themeExtension) {
    if (widget.trendPercentage == null) return const SizedBox.shrink();

    final percentage = widget.trendPercentage!;
    final isPositive = percentage > 0;
    final color = isPositive ? DayFiColors.green : DayFiColors.red;
    final sign = isPositive ? '+' : '';

    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$sign${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'vs last period',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: themeExtension.hintText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppThemeExtension themeExtension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeExtension.hintText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeExtension.accentBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: themeExtension.hintText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 32,
          decoration: BoxDecoration(
            color: themeExtension.hintText.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: themeExtension.hintText.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(AppThemeExtension themeExtension) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeExtension.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                size: 20,
                color: themeExtension.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeExtension.errorColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.error ?? 'Unknown error',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: themeExtension.errorColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: themeExtension.accentBlue,
              ),
              const SizedBox(width: 4),
              Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeExtension.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enterprise KPI Grid for displaying multiple KPIs
class EnterpriseKPIGrid extends StatelessWidget {
  final List<EnterpriseKPICard> kpiCards;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const EnterpriseKPIGrid({
    super.key,
    required this.kpiCards,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.4,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: kpiCards.length,
        itemBuilder: (context, index) {
          return kpiCards[index];
        },
      ),
    );
  }
}

// Compact KPI Card for smaller spaces
class CompactKPICard extends StatelessWidget {
  final String title;
  final String value;
  final KPITrend? trend;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const CompactKPICard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? themeExtension.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeExtension.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: color ?? themeExtension.accentBlue,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: themeExtension.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: themeExtension.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (trend != null) ...[
              Icon(
                trend == KPITrend.up ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: trend == KPITrend.up ? DayFiColors.green : DayFiColors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
