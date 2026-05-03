// lib/screens/reports/reports_screen.dart
//
// Financial reports: income vs expenses bar chart, category breakdown,
// invoice collection rate, and CSV export.

import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final _reportsInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final res = await apiService.getInvoices(page: 1, limit: 200);
    return List<Map<String, dynamic>>.from(res['invoices'] ?? []);
  },
);

final _reportsExpensesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final res = await apiService.getExpenses(page: 1, limit: 200);
    return List<Map<String, dynamic>>.from(res['expenses'] ?? []);
  },
);

final _reportsTxProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final res = await apiService.getTransactions(page: 1, limit: 200);
    return List<Map<String, dynamic>>.from(res['transactions'] ?? []);
  },
);

// ── Helpers ────────────────────────────────────────────────────────────────────

double _n(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _fmt(double v) => NumberFormat('#,##0.00').format(v);

DateTime _monthStart(int monthsAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - monthsAgo, 1);
}

// ── ReportsScreen ──────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = '6m';

  int get _months => switch (_period) {
        '1m' => 1,
        '3m' => 3,
        '12m' => 12,
        _ => 6,
      };

  @override
  Widget build(BuildContext context) {
    final th = AppThemeExtension.of(context);
    final invoicesAsync = ref.watch(_reportsInvoicesProvider);
    final expensesAsync = ref.watch(_reportsExpensesProvider);
    final txAsync = ref.watch(_reportsTxProvider);

    final loading =
        invoicesAsync.isLoading || expensesAsync.isLoading || txAsync.isLoading;
    final invoices = invoicesAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];
    final txs = txAsync.value ?? [];

    return Scaffold(
      backgroundColor: th.surfaceBackground,
      body: RefreshIndicator(
        color: th.accentBlue,
        onRefresh: () async {
          ref.invalidate(_reportsInvoicesProvider);
          ref.invalidate(_reportsExpensesProvider);
          ref.invalidate(_reportsTxProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: th.surfaceBackground,
              elevation: 0,
              title: Text(
                'Reports',
                style: TextStyle(
                  color: th.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              actions: [
                if (!loading)
                  IconButton(
                    icon: Icon(Icons.download_outlined, color: th.primaryText),
                    tooltip: 'Export CSV',
                    onPressed: () => _exportCsv(invoices, expenses, txs),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: loading
                  ? const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PeriodSelector(
                            selected: _period,
                            onSelect: (p) => setState(() => _period = p),
                            th: th,
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            invoices: invoices,
                            expenses: expenses,
                            months: _months,
                            th: th,
                          ),
                          const SizedBox(height: 20),
                          _IncomeExpensesChart(
                            invoices: invoices,
                            expenses: expenses,
                            months: _months,
                            th: th,
                          ),
                          const SizedBox(height: 20),
                          _CollectionRateCard(invoices: invoices, th: th),
                          const SizedBox(height: 20),
                          _ExpenseCategoryCard(
                              expenses: expenses, months: _months, th: th),
                          const SizedBox(height: 20),
                          _InvoiceStatusCard(invoices: invoices, th: th),
                          const SizedBox(height: 20),
                          _RecentTxCard(txs: txs, months: _months, th: th),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv(
    List<Map<String, dynamic>> invoices,
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> txs,
  ) {
    final buf = StringBuffer();
    buf.writeln('Type,Date,Description,Amount,Currency,Status');

    for (final inv in invoices) {
      final date = (inv['createdAt'] as String?)?.substring(0, 10) ?? '';
      final desc = (inv['clientName'] ?? inv['clientEmail'] ?? 'Invoice')
          .toString()
          .replaceAll(',', ' ');
      buf.writeln(
          'Invoice,$date,$desc,${_n(inv['totalAmount'])},${inv['currency'] ?? 'USDC'},${inv['status'] ?? ''}');
    }

    for (final exp in expenses) {
      final date = (exp['createdAt'] as String?)?.substring(0, 10) ?? '';
      final desc = (exp['description'] ?? exp['category'] ?? 'Expense')
          .toString()
          .replaceAll(',', ' ');
      buf.writeln(
          'Expense,$date,$desc,${_n(exp['amount'])},${exp['currency'] ?? 'USDC'},${exp['status'] ?? ''}');
    }

    for (final tx in txs) {
      final date = (tx['createdAt'] as String?)?.substring(0, 10) ?? '';
      final desc = (tx['memo'] ?? tx['type'] ?? 'Transaction')
          .toString()
          .replaceAll(',', ' ');
      buf.writeln(
          'Transaction,$date,$desc,${_n(tx['amount'])},${tx['asset'] ?? 'USDC'},${tx['type'] ?? ''}');
    }

    final bytes = utf8.encode(buf.toString());
    Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'text/csv',
          name:
              'dayfi_report_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
        ),
      ],
      subject: 'DayFi Financial Report',
    );
  }
}

// ── Period selector ────────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final AppThemeExtension th;
  const _PeriodSelector(
      {required this.selected, required this.onSelect, required this.th});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['1m', '3m', '6m', '12m'].map((p) {
        final active = p == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? th.accentBlue : th.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? th.accentBlue : th.cardBorder,
                ),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : th.secondaryText,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> invoices, expenses;
  final int months;
  final AppThemeExtension th;
  const _SummaryRow(
      {required this.invoices,
      required this.expenses,
      required this.months,
      required this.th});

  @override
  Widget build(BuildContext context) {
    final cutoff = _monthStart(months);
    final income = invoices
        .where((i) {
          if (i['status'] != 'paid') return false;
          final dt = DateTime.tryParse(i['updatedAt']?.toString() ?? '');
          return dt != null && dt.isAfter(cutoff);
        })
        .fold<double>(0, (s, i) => s + _n(i['totalAmount']));

    final spend = expenses
        .where((e) {
          final dt = DateTime.tryParse(e['createdAt']?.toString() ?? '');
          return dt != null && dt.isAfter(cutoff);
        })
        .fold<double>(0, (s, e) => s + _n(e['amount']));

    final net = income - spend;
    final netPos = net >= 0;

    return Row(
      children: [
        _SummaryCard(
            label: 'Income',
            value: '\$${_fmt(income)}',
            color: DayFiColors.green,
            th: th),
        const SizedBox(width: 10),
        _SummaryCard(
            label: 'Expenses',
            value: '\$${_fmt(spend)}',
            color: DayFiColors.red,
            th: th),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Net',
          value: '${netPos ? '+' : '−'}\$${_fmt(net.abs())}',
          color: netPos ? DayFiColors.green : DayFiColors.red,
          th: th,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppThemeExtension th;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.th});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: th.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: th.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: th.secondaryText)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Income vs Expenses bar chart ───────────────────────────────────────────────

class _IncomeExpensesChart extends StatefulWidget {
  final List<Map<String, dynamic>> invoices, expenses;
  final int months;
  final AppThemeExtension th;
  const _IncomeExpensesChart(
      {required this.invoices,
      required this.expenses,
      required this.months,
      required this.th});

  @override
  State<_IncomeExpensesChart> createState() => _IncomeExpensesChartState();
}

class _IncomeExpensesChartState extends State<_IncomeExpensesChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final months = widget.months.clamp(1, 12);
    final now = DateTime.now();

    final incomeByMonth = List<double>.filled(months, 0);
    final expByMonth = List<double>.filled(months, 0);
    final labels = <String>[];

    for (var i = months - 1; i >= 0; i--) {
      labels.add(DateFormat('MMM').format(DateTime(now.year, now.month - i)));
    }

    for (final inv in widget.invoices) {
      if (inv['status'] != 'paid') continue;
      final dt = DateTime.tryParse(inv['updatedAt']?.toString() ?? '');
      if (dt == null) continue;
      for (var i = 0; i < months; i++) {
        final mStart = DateTime(now.year, now.month - (months - 1 - i));
        final mEnd = DateTime(mStart.year, mStart.month + 1);
        if (!dt.isBefore(mStart) && dt.isBefore(mEnd)) {
          incomeByMonth[i] += _n(inv['totalAmount']);
        }
      }
    }

    for (final exp in widget.expenses) {
      final dt = DateTime.tryParse(exp['createdAt']?.toString() ?? '');
      if (dt == null) continue;
      for (var i = 0; i < months; i++) {
        final mStart = DateTime(now.year, now.month - (months - 1 - i));
        final mEnd = DateTime(mStart.year, mStart.month + 1);
        if (!dt.isBefore(mStart) && dt.isBefore(mEnd)) {
          expByMonth[i] += _n(exp['amount']);
        }
      }
    }

    final maxY = [...incomeByMonth, ...expByMonth]
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.th.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.th.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Income vs Expenses',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.th.primaryText)),
            const Spacer(),
            _legendDot(DayFiColors.green, 'Income'),
            const SizedBox(width: 12),
            _legendDot(DayFiColors.red, 'Expenses'),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 10,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    if (response == null || response.spot == null) {
                      setState(() => _touchedIndex = -1);
                    } else {
                      setState(() => _touchedIndex =
                          response.spot!.touchedBarGroupIndex);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? 'Income' : 'Exp'}\n\$${_fmt(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[idx],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: widget.th.secondaryText)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) => Text(
                        '\$${v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 9, color: widget.th.secondaryText),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: widget.th.cardBorder,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months, (i) {
                  final touched = i == _touchedIndex;
                  final barWidth =
                      months <= 3 ? 16.0 : months <= 6 ? 10.0 : 6.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: incomeByMonth[i],
                        color: touched
                            ? DayFiColors.green
                            : DayFiColors.green.withValues(alpha: 0.7),
                        width: barWidth,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expByMonth[i],
                        color: touched
                            ? DayFiColors.red
                            : DayFiColors.red.withValues(alpha: 0.7),
                        width: barWidth,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 11, color: widget.th.secondaryText)),
    ]);
  }
}

// ── Collection rate card ───────────────────────────────────────────────────────

class _CollectionRateCard extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final AppThemeExtension th;
  const _CollectionRateCard({required this.invoices, required this.th});

  @override
  Widget build(BuildContext context) {
    final total = invoices.length;
    final paid = invoices.where((i) => i['status'] == 'paid').length;
    final overdue = invoices.where((i) => i['status'] == 'overdue').length;
    final pending =
        invoices.where((i) => ['sent', 'viewed'].contains(i['status'])).length;

    final rate = total > 0 ? (paid / total * 100) : 0.0;

    final paidAmt = invoices
        .where((i) => i['status'] == 'paid')
        .fold<double>(0, (s, i) => s + _n(i['totalAmount']));
    final totalAmt =
        invoices.fold<double>(0, (s, i) => s + _n(i['totalAmount']));
    final amtRate = totalAmt > 0 ? (paidAmt / totalAmt * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice Collection',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: th.primaryText)),
          const SizedBox(height: 16),
          Row(children: [
            _CollectionStat(
                label: 'Collection rate',
                value: '${rate.toStringAsFixed(0)}%',
                sub: '$paid of $total invoices',
                color: rate >= 70 ? DayFiColors.green : DayFiColors.red,
                th: th),
            const SizedBox(width: 12),
            _CollectionStat(
                label: 'Amount collected',
                value: '${amtRate.toStringAsFixed(0)}%',
                sub: '\$${_fmt(paidAmt)} of \$${_fmt(totalAmt)}',
                color: amtRate >= 70 ? DayFiColors.green : DayFiColors.red,
                th: th),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: th.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(DayFiColors.green),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _StatusPill('Paid', paid, DayFiColors.green, th),
            const SizedBox(width: 8),
            _StatusPill('Pending', pending, DayFiColors.blue, th),
            const SizedBox(width: 8),
            _StatusPill('Overdue', overdue, DayFiColors.red, th),
          ]),
        ],
      ),
    );
  }
}

class _CollectionStat extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final AppThemeExtension th;
  const _CollectionStat(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color,
      required this.th});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: th.secondaryText)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(sub,
            style: TextStyle(fontSize: 11, color: th.secondaryText)),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final AppThemeExtension th;
  const _StatusPill(this.label, this.count, this.color, this.th);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count $label',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Expense category breakdown ─────────────────────────────────────────────────

class _ExpenseCategoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final int months;
  final AppThemeExtension th;
  const _ExpenseCategoryCard(
      {required this.expenses, required this.months, required this.th});

  @override
  Widget build(BuildContext context) {
    final cutoff = _monthStart(months);
    final catMap = <String, double>{};
    for (final e in expenses) {
      final dt = DateTime.tryParse(e['createdAt']?.toString() ?? '');
      if (dt == null || dt.isBefore(cutoff)) continue;
      final rawCat = e['category'];
      final cat = (rawCat is String && rawCat.isNotEmpty) ? rawCat : 'Other';
      catMap[cat] = (catMap[cat] ?? 0) + _n(e['amount']);
    }

    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (s, e) => s + e.value);

    final colors = [
      DayFiColors.blue,
      DayFiColors.green,
      const Color(0xFFF59E0B),
      DayFiColors.red,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense Categories',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: th.primaryText)),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Text('No expenses in this period.',
                style: TextStyle(color: th.secondaryText))
          else
            ...sorted.take(6).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final pct = total > 0 ? cat.value / total : 0.0;
              final color = colors[i % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(cat.key,
                              style: TextStyle(
                                  fontSize: 13, color: th.primaryText))),
                      Text('\$${_fmt(cat.value)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: th.primaryText)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text('${(pct * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                color: th.secondaryText)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: th.cardBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Invoice status breakdown ───────────────────────────────────────────────────

class _InvoiceStatusCard extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final AppThemeExtension th;
  const _InvoiceStatusCard({required this.invoices, required this.th});

  @override
  Widget build(BuildContext context) {
    final groups = <String, double>{};
    for (final inv in invoices) {
      final rawStatus = inv['status'];
      final s = rawStatus is String ? rawStatus : 'draft';
      groups[s] = (groups[s] ?? 0) + _n(inv['totalAmount']);
    }

    const order = ['paid', 'sent', 'viewed', 'overdue', 'draft', 'cancelled'];
    final colorMap = {
      'paid': DayFiColors.green,
      'sent': DayFiColors.blue,
      'viewed': Color(0xFF8B5CF6),
      'overdue': DayFiColors.red,
      'draft': Color(0xFF6B7280),
      'cancelled': Color(0xFF9CA3AF),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice Breakdown',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: th.primaryText)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: order
                .where((s) => groups.containsKey(s))
                .map((s) {
                  final color = colorMap[s] ?? th.accentBlue;
                  final count =
                      invoices.where((i) => i['status'] == s).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count  ·  \$${_fmt(groups[s] ?? 0)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: th.primaryText,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Recent transactions ────────────────────────────────────────────────────────

class _RecentTxCard extends StatelessWidget {
  final List<Map<String, dynamic>> txs;
  final int months;
  final AppThemeExtension th;
  const _RecentTxCard(
      {required this.txs, required this.months, required this.th});

  @override
  Widget build(BuildContext context) {
    final cutoff = _monthStart(months);
    final filtered = txs.where((t) {
      final dt = DateTime.tryParse(t['createdAt']?.toString() ?? '');
      return dt != null && dt.isAfter(cutoff);
    }).take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: th.primaryText)),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Text('No transactions in this period.',
                style: TextStyle(color: th.secondaryText))
          else
            ...filtered.map((tx) {
              final rawType = tx['type'];
              final type = rawType is String ? rawType : '';
              final isIn = ['receive', 'deposit'].contains(type);
              final amt = _n(tx['amount']);
              final rawAsset = tx['asset'];
              final asset = rawAsset is String ? rawAsset : '';
              final dt =
                  DateTime.tryParse(tx['createdAt']?.toString() ?? '');
              final rawMemo = tx['memo'];
              final rawAddr = tx['recipientAddress'];
              final label = (rawMemo is String ? rawMemo : null)
                  ?? (rawAddr is String ? rawAddr : null)
                  ?? type;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      (isIn ? DayFiColors.green : DayFiColors.red)
                          .withValues(alpha: 0.15),
                  child: Icon(
                    isIn
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 14,
                    color: isIn ? DayFiColors.green : DayFiColors.red,
                  ),
                ),
                title: Text(
                  label.length > 30
                      ? '${label.substring(0, 28)}…'
                      : label,
                  style:
                      TextStyle(fontSize: 13, color: th.primaryText),
                ),
                subtitle: dt != null
                    ? Text(
                        DateFormat('d MMM, HH:mm').format(dt.toLocal()),
                        style: TextStyle(
                            fontSize: 11, color: th.secondaryText))
                    : null,
                trailing: Text(
                  '${isIn ? '+' : '−'}${amt.toStringAsFixed(2)} $asset',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isIn ? DayFiColors.green : DayFiColors.red,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
