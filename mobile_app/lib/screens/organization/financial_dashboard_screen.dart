// lib/screens/organization/financial_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class OrganizationFinancialDashboardScreen extends ConsumerStatefulWidget {
  const OrganizationFinancialDashboardScreen({super.key});

  @override
  ConsumerState<OrganizationFinancialDashboardScreen> createState() => _OrganizationFinancialDashboardScreenState();
}

class _OrganizationFinancialDashboardScreenState extends ConsumerState<OrganizationFinancialDashboardScreen> {
  Map<String, dynamic>? organizationData;
  bool loading = true;
  String _selectedPeriod = 'month'; // week, month, quarter, year

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => loading = true);
    try {
      final response = await apiService.getOrganizationFinancialDashboard(_selectedPeriod);
      setState(() {
        organizationData = response;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load financial data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (organizationData == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.chartLine,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Financial Data Available',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Start creating invoices and processing transactions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) {
                setState(() => _selectedPeriod = period);
                _loadFinancialData();
              },
            ),
            const SizedBox(height: 24),

            // Overview Cards
            _OverviewCards(data: organizationData!),
            const SizedBox(height: 32),

            // Revenue Chart
            _RevenueChart(data: organizationData!),
            const SizedBox(height: 32),

            // Transaction Breakdown
            _TransactionBreakdown(data: organizationData!),
            const SizedBox(height: 32),

            // Team Performance
            _TeamPerformance(data: organizationData!),
            const SizedBox(height: 32),

            // Recent Activity
            _RecentActivity(data: organizationData!),
          ],
        ),
      ),
    );
  }
}

// ─── Period Selector ─────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ['week', 'month', 'quarter', 'year'].map((period) {
              final isSelected = selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(period[0].toUpperCase() + period.substring(1)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onPeriodChanged(period);
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Cards ─────────────────────────────────────────────────────

class _OverviewCards extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OverviewCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final overview = data['overview'] as Map<String, dynamic>? ?? {};

    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Total Revenue',
            value: '\$${(overview['totalRevenue'] ?? 0).toStringAsFixed(2)}',
            subtitle: '+${(overview['revenueGrowth'] ?? 0).toStringAsFixed(1)}%',
            icon: FontAwesomeIcons.dollarSign,
            color: Colors.green,
            isPositive: (overview['revenueGrowth'] ?? 0) >= 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            title: 'Transactions',
            value: (overview['totalTransactions'] ?? 0).toString(),
            subtitle: '+${(overview['transactionGrowth'] ?? 0).toStringAsFixed(1)}%',
            icon: FontAwesomeIcons.exchangeAlt,
            color: Colors.blue,
            isPositive: (overview['transactionGrowth'] ?? 0) >= 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            title: 'Active Invoices',
            value: (overview['activeInvoices'] ?? 0).toString(),
            subtitle: '${(overview['pendingInvoices'] ?? 0)} pending',
            icon: FontAwesomeIcons.fileInvoice,
            color: Colors.orange,
            isPositive: true,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final FaIconData icon;
  final Color color;
  final bool isPositive;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, color: color, size: 20),
              ),
              const Spacer(),
              FaIcon(
                isPositive ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.arrowDown,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// ─── Revenue Chart ─────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final revenueData = data['revenueChart'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: revenueData.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : _SimpleBarChart(data: revenueData),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<dynamic> data;

  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: data.map((item) {
        final value = item['value'] as double;
        final height = maxValue > 0 ? (value / maxValue) * 180 : 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 24,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['label'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '\$${value.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Transaction Breakdown ─────────────────────────────────────────────

class _TransactionBreakdown extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TransactionBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final breakdown = data['transactionBreakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _BreakdownItem(
            label: 'Invoice Payments',
            value: breakdown['invoicePayments'] ?? 0,
            total: breakdown['total'] ?? 1,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _BreakdownItem(
            label: 'Direct Payments',
            value: breakdown['directPayments'] ?? 0,
            total: breakdown['total'] ?? 1,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _BreakdownItem(
            label: 'Expense Reimbursements',
            value: breakdown['expenses'] ?? 0,
            total: breakdown['total'] ?? 1,
            color: Colors.orange,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value (${percentage.toStringAsFixed(1)}%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Team Performance ───────────────────────────────────────────────────

class _TeamPerformance extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TeamPerformance({required this.data});

  @override
  Widget build(BuildContext context) {
    final teamData = data['teamPerformance'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (teamData.isEmpty)
            Center(
              child: Text(
                'No team performance data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...teamData.map((member) => _TeamMemberPerformance(member: member)).toList(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.4);
  }
}

class _TeamMemberPerformance extends StatelessWidget {
  final Map<String, dynamic> member;

  const _TeamMemberPerformance({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              (member['name'] as String? ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] as String? ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${member['invoicesCreated'] ?? 0} invoices • ${member['revenueGenerated'] ?? 0} generated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(member['revenueGenerated'] ?? 0).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity ───────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RecentActivity({required this.data});

  @override
  Widget build(BuildContext context) {
    final activities = data['recentActivity'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (activities.isEmpty)
            Center(
              child: Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...activities.take(5).map((activity) => _ActivityTile(activity: activity)).toList(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.5);
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    FaIconData icon;
    Color color;
    
    switch (activity['type'] as String? ?? '') {
      case 'invoice_created':
        icon = FontAwesomeIcons.fileInvoice;
        color = Colors.blue;
        break;
      case 'invoice_paid':
        icon = FontAwesomeIcons.dollarSign;
        color = Colors.green;
        break;
      case 'expense_approved':
        icon = FontAwesomeIcons.checkCircle;
        color = Colors.orange;
        break;
      default:
        icon = FontAwesomeIcons.circle;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'] as String? ?? 'Unknown activity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity['timestamp'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (activity['amount'] != null)
            Text(
              '\$${(activity['amount'] as num).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
