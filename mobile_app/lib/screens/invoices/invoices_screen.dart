// lib/screens/invoices/invoices_screen.dart
//
// Features:
//   - List all invoices with status pills (draft/sent/viewed/paid/overdue)
//   - Create invoice: title, client, line items, VAT toggle, due date,
//     payment type (NGNT on-chain | bank transfer | both), recurring
//   - Send invoice → generates shareable payment link
//   - Tap invoice → detail sheet with copy/share link

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/screens/invoices/create_invoice_sheets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final invoicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final result = await apiService.getInvoices(page: 1, limit: 50);
    return List<Map<String, dynamic>>.from(result['invoices'] ?? []);
  },
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (invoices) => _buildList(context, ref, invoices),
      ),

      floatingActionButton: Container(
        height: 60,
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () => _showCreateInvoice(context, ref),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.add,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load invoices',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(invoicesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> invoices,
  ) {
    if (invoices.isEmpty) {
      return _EmptyState(onTapAction: () => _showCreateInvoice(context, ref));
    }

    // Group by status
    final groups = <String, List<Map<String, dynamic>>>{
      'overdue': [],
      'sent': [],
      'viewed': [],
      'paid': [],
      'draft': [],
    };
    for (final inv in invoices) {
      final status = (inv['status'] as String?) ?? 'draft';
      groups[status] ??= [];
      groups[status]!.add(inv);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(invoicesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 118, 16, 100),
        children: [
          // Summary chips
          _SummaryRow(invoices: invoices),
          const SizedBox(height: 20),

          for (final entry in groups.entries) ...[
            if (entry.value.isNotEmpty) ...[
              _SectionHeader(status: entry.key, count: entry.value.length),
              const SizedBox(height: 8),
              ...entry.value.map(
                (inv) => _InvoiceTile(
                  invoice: inv,
                  onTap: () => _showInvoiceDetail(context, ref, inv),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }

  // ── Create invoice bottom sheet ────────────────────────────────────────────

  void _showCreateInvoice(BuildContext context, WidgetRef ref) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: CreateInvoiceSheet1(
        onCreated: () => ref.invalidate(invoicesProvider),
      ),
    );
  }

  // ── Invoice detail ─────────────────────────────────────────────────────────

  void _showInvoiceDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> inv,
  ) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _InvoiceDetailSheet(
        invoice: inv,
        onRefresh: () => ref.invalidate(invoicesProvider),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  const _SummaryRow({required this.invoices});

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  int _periodIndex = 1;
  static const _periodLabels = ['1W', '1M', 'YTD', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = _periodStart(now, _periodIndex);
    final inPeriod = widget.invoices.where((inv) {
      final createdAt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
      if (createdAt == null) return true;
      return !createdAt.isBefore(start);
    }).toList();

    double paidAmount = 0;
    double pendingAmount = 0;
    double overdueAmount = 0;

    for (final inv in inPeriod) {
      final amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
      final status = (inv['status'] as String?) ?? '';
      if (status == 'paid') paidAmount += amount;
      if (status == 'sent' || status == 'viewed') pendingAmount += amount;
      if (status == 'overdue') overdueAmount += amount;
    }

    final dueAmount = pendingAmount + overdueAmount;
    final total = paidAmount + dueAmount;
    final paidPct = total > 0 ? (paidAmount / total) * 100 : 0.0;
    final duePct = total > 0 ? (dueAmount / total) * 100 : 0.0;

    final paidSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'paid');
    final dueSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'due');
    final overdueSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'overdue');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          width: 1,
        ),
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  dotColor: const Color(0xFF598FE0),
                  label: 'Paid',
                  value: '₦${_fmt(paidAmount)}',
                  percent: paidPct,
                  positiveColor: DayFiColors.green,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  dotColor: const Color(0xFFFFA726),
                  label: 'Pending',
                  value: '₦${_fmt(dueAmount)}',
                  percent: duePct,
                  positiveColor: const Color(0xFFE57745),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  dotColor: DayFiColors.red,
                  label: 'Overdue',
                  value: '₦${_fmt(overdueAmount)}',
                  percent: paidPct,
                  positiveColor: DayFiColors.red,
                ),
              ),
            ],
          ),

          SizedBox(
            height: 48,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 10, top: 6),
              child: LineChart(
                _summaryLineChartData(
                  paidSpots: paidSpots,
                  dueSpots: dueSpots,
                  overdueSpots: overdueSpots,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _periodLabels.asMap().entries.map((e) {
                final selected = _periodIndex == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _periodIndex = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

class _SummaryMetric extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final double percent;
  final Color positiveColor;
  final Widget? secondaryLegend;
  const _SummaryMetric({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.percent,
    required this.positiveColor,
    this.secondaryLegend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.25,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.92),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.92),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            color: positiveColor.withOpacity(0.16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.arrowTrendUp,
                size: 12,
                color: positiveColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  color: positiveColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
        if (secondaryLegend != null) ...[
          const SizedBox(height: 6),
          secondaryLegend!,
        ],
      ],
    );
  }
}

DateTime _periodStart(DateTime now, int periodIndex) {
  switch (periodIndex) {
    case 0:
      return now.subtract(const Duration(days: 7));
    case 1:
      return now.subtract(const Duration(days: 30));
    case 2:
      return DateTime(now.year, 1, 1);
    case 3:
      return now.subtract(const Duration(days: 90));
    case 4:
      return now.subtract(const Duration(days: 365));
    default:
      return now.subtract(const Duration(days: 30));
  }
}

List<FlSpot> _buildSeriesSpots(
  List<Map<String, dynamic>> invoices,
  int periodIndex,
  String kind,
) {
  final now = DateTime.now();
  final start = _periodStart(now, periodIndex);
  final bucketCount = periodIndex == 2
      ? now.month
      : [7, 30, 30, 30, 30][periodIndex];
  final values = List<double>.filled(bucketCount, 0);
  final daysSpan = now.difference(start).inDays.clamp(1, 366);

  for (final inv in invoices) {
    final createdAt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
    if (createdAt == null || createdAt.isBefore(start)) continue;
    final status = (inv['status'] as String?) ?? '';
    final amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0;

    final isPaid = status == 'paid';
    final isDue = status == 'sent' || status == 'viewed';
    final isOverdue = status == 'overdue';

    if (kind == 'paid' && !isPaid) continue;
    if (kind == 'due' && !isDue) continue;
    if (kind == 'overdue' && !isOverdue) continue;

    int idx;
    if (periodIndex == 2) {
      idx = (createdAt.month - 1).clamp(0, bucketCount - 1);
    } else {
      final dayOffset = createdAt.difference(start).inDays.clamp(0, daysSpan);
      idx = ((dayOffset / daysSpan) * (bucketCount - 1)).round().clamp(
        0,
        bucketCount - 1,
      );
    }
    values[idx] += amount;
  }

  if (values.every((v) => v == 0)) {
    return [const FlSpot(0, 0.5), const FlSpot(1, 0.5)];
  }
  final max = values.reduce((a, b) => a > b ? a : b);
  return List.generate(values.length, (i) {
    final y = max == 0 ? 0.5 : (values[i] / max).clamp(0.05, 1.0);
    return FlSpot(i.toDouble(), y);
  });
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

LineChartData _summaryLineChartData({
  required List<FlSpot> paidSpots,
  required List<FlSpot> dueSpots,
  required List<FlSpot> overdueSpots,
}) {
  return LineChartData(
    minX: 0,
    maxX: (paidSpots.length - 1).toDouble(),
    minY: 0,
    maxY: 1,
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
    titlesData: const FlTitlesData(show: false),
    lineTouchData: const LineTouchData(enabled: false),
    lineBarsData: [
      LineChartBarData(
        spots: paidSpots,
        isCurved: true,
        color: const Color(0xFF598FE0),
        barWidth: 2.1,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: dueSpots,
        isCurved: true,
        color: const Color(0xFFE57745),
        barWidth: 2.1,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: overdueSpots,
        isCurved: true,
        color: DayFiColors.red,
        barWidth: 2.1,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ],
  );
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String status;
  final int count;
  const _SectionHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusPill(status: status),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─── Invoice tile ─────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = (invoice['status'] as String?) ?? 'draft';
    final total = (invoice['totalAmount'] as num?)?.toDouble() ?? 0;
    final currency = (invoice['currency'] as String?) ?? 'NGNT';
    final clientName = (invoice['clientName'] as String?) ?? '—';
    final invoiceNum = (invoice['invoiceNumber'] as String?) ?? '';
    final title = (invoice['title'] as String?) ?? 'Invoice';
    final dueDate = invoice['dueDate'] != null
        ? DateTime.tryParse(invoice['dueDate'])
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceNum,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    clientName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Due ${DateFormat('MMM d, yyyy').format(dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: status == 'overdue'
                            ? DayFiColors.red
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency == 'USDC'
                      ? '\$${total.toStringAsFixed(2)}'
                      : '₦${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusPill(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case 'paid':
        return DayFiColors.green;
      case 'sent':
        return const Color(0xFF2775CA);
      case 'viewed':
        return const Color(0xFF9C27B0);
      case 'overdue':
        return DayFiColors.red;
      case 'draft':
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Invoice detail sheet ─────────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onRefresh;
  const _InvoiceDetailSheet({required this.invoice, required this.onRefresh});

  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  bool _sending = false;
  bool _markingPaid = false;
  bool _editing = false;

  Future<void> _shareText(String text) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0) {
      await Share.share(
        text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
      return;
    }
    await Share.share(text);
  }

  Future<void> _sendInvoice() async {
    setState(() => _sending = true);
    try {
      await apiService.sendInvoice(widget.invoice['id'] as String);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markPaid() async {
    setState(() => _markingPaid = true);
    try {
      await apiService.markInvoicePaid(widget.invoice['id'] as String);
      widget.onRefresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as paid.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _markingPaid = false);
    }
  }

  Future<void> _editInvoice() async {
    setState(() => _editing = true);
    try {
      final updated = await showDayFiBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        child: _EditInvoiceSheet(invoice: widget.invoice),
      );
      if (updated != null) {
        widget.onRefresh();
        if (mounted) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final status = (inv['status'] as String?) ?? 'draft';
    final paymentLink = inv['paymentLink'] as String?;
    final currency = (inv['currency'] as String?) ?? 'NGNT';
    final total = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    final sym = currency == 'USDC' ? '\$' : '₦';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoice', style: Theme.of(context).textTheme.titleLarge),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount
          Text(
            '$sym${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          _StatusPill(status: status),
          const SizedBox(height: 20),

          // Details
          _DetailRow(label: 'Invoice #', value: inv['invoiceNumber'] ?? ''),
          _DetailRow(label: 'Client', value: inv['clientName'] ?? ''),
          _DetailRow(label: 'Currency', value: currency),
          if (inv['dueDate'] != null)
            _DetailRow(
              label: 'Due date',
              value: DateFormat(
                'MMM d, yyyy',
              ).format(DateTime.parse(inv['dueDate'] as String)),
            ),

          const SizedBox(height: 24),

          // Payment link
          if (paymentLink != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      paymentLink,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: paymentLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment link copied')),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 16),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _shareText('Pay my invoice here: $paymentLink'),
                    child: const Icon(Icons.share_rounded, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Actions
          if (status == 'draft') ...[
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _editing ? null : _editInvoice,
                child: const Text('Edit Invoice'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width, 48),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.90),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _sending ? null : _sendInvoice,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Send Invoice'),
              ),
            ),
          ] else if (status == 'sent' ||
              status == 'viewed' ||
              status == 'overdue') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width, 48),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.90),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _markingPaid ? null : _markPaid,
                child: _markingPaid
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Mark as Paid'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditInvoiceSheet extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const _EditInvoiceSheet({required this.invoice});

  @override
  State<_EditInvoiceSheet> createState() => _EditInvoiceSheetState();
}

class _EditInvoiceSheetState extends State<_EditInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _clientNameCtrl;
  late final TextEditingController _clientEmailCtrl;
  late final TextEditingController _descriptionCtrl;
  bool _saving = false;
  late String _currency;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.invoice['title']?.toString() ?? '',
    );
    _clientNameCtrl = TextEditingController(
      text: widget.invoice['clientName']?.toString() ?? '',
    );
    _clientEmailCtrl = TextEditingController(
      text: widget.invoice['clientEmail']?.toString() ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.invoice['description']?.toString() ?? '',
    );
    _currency = (widget.invoice['currency'] as String?) ?? 'NGNT';
    _dueDate = widget.invoice['dueDate'] != null
        ? DateTime.tryParse(widget.invoice['dueDate'] as String)
        : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'title': _titleCtrl.text.trim(),
        'clientName': _clientNameCtrl.text.trim(),
        'clientEmail': _clientEmailCtrl.text.trim().isEmpty
            ? null
            : _clientEmailCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        'currency': _currency,
        'dueDate': _dueDate?.toIso8601String(),
      };
      final res = await apiService.updateInvoice(
        widget.invoice['id'] as String,
        payload,
      );
      if (mounted) Navigator.pop(context, res['invoice']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Invoice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _clientNameCtrl,
              decoration: const InputDecoration(labelText: 'Client name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Client name is required'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _clientEmailCtrl,
              decoration: const InputDecoration(labelText: 'Client email'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'NGNT',
                    groupValue: _currency,
                    title: const Text('NGNT'),
                    onChanged: (v) => setState(() => _currency = v ?? 'NGNT'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'USDC',
                    groupValue: _currency,
                    title: const Text('USDC'),
                    onChanged: (v) => setState(() => _currency = v ?? 'USDC'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                icon: const Icon(Icons.event),
                label: Text(
                  _dueDate == null
                      ? 'Set due date'
                      : DateFormat('MMM d, yyyy').format(_dueDate!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTapAction;

  const _EmptyState({required this.onTapAction});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 54,
                  width: MediaQuery.of(context).size.width * .85,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: ext.cardBorder.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    color: ext.monthlyCardSurface,
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ext.cardBorder, width: .5),
                  color: ext.cardSurface,
                ),
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'create your first invoice to get paid',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: .4,
                        color: ext.sectionHeader,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Theme.of(
                                context,
                              ).textTheme.bodySmall!.color!.withOpacity(0.1),
                              foregroundColor: ext.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: onTapAction,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'NEW INVOICE',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  height: 1,
                                  color: ext.sectionHeader,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Theme.of(
                                context,
                              ).textTheme.bodySmall!.color!.withOpacity(0.1),
                              foregroundColor: ext.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              launchUrl(
                                Uri.parse('https://dayfi.co'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'LEARN MORE',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  height: 1,
                                  color: ext.sectionHeader,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
