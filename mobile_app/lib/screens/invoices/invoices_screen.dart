// lib/screens/invoices/invoices_screen.dart
//
// Redesigned: auth-style forms, AccountMoverCard aesthetic, no dialogs.
// Create/Detail flow uses ShellDest.createInvoice / ShellDest.invoiceDetail
// (add these to your ShellDest enum + IndexedStack if you want full sub-screen
//  routing; alternatively the FAB/detail sheet stays as a bottom sheet since
//  the form is already auth-styled).
//
// For now: create flow is a bottom sheet (matching auth form style exactly),
// tile tap opens a compact detail bottom sheet. Both use the same glass +
// Bricolage Grotesque language as auth screens.

import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
    final async = ref.watch(invoicesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _Fab(onTap: () => _showCreateSheet(context, ref)),
      body: SizedBox(
        width: double.infinity,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: apiService.parseError(e),
            onRetry: () => ref.invalidate(invoicesProvider),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return _EmptyView(onCreate: () => _showCreateSheet(context, ref));
            }

            const statusOrder = ['overdue', 'sent', 'viewed', 'draft', 'paid', 'cancelled'];
            final groups = <String, List<Map<String, dynamic>>>{
              for (final s in statusOrder) s: [],
            };
            for (final inv in invoices) {
              final s = (inv['status'] as String?) ?? 'draft';
              (groups[s] ??= []).add(inv);
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(invoicesProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 100),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _InsightsPanel(
                                    invoices: invoices,
                                    groups: groups,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _InvoiceList(
                                    groups: groups,
                                    order: statusOrder,
                                    onTap: (inv) => _showDetailSheet(context, ref, inv),
                                    onMenu: (action, inv) => _handleAction(context, ref, action, inv),
                                    onNew: () => _showCreateSheet(context, ref),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _InsightsPanel(invoices: invoices, groups: groups),
                                const SizedBox(height: 24),
                                _InvoiceList(
                                  groups: groups,
                                  order: statusOrder,
                                  onTap: (inv) => _showDetailSheet(context, ref, inv),
                                  onMenu: (action, inv) => _handleAction(context, ref, action, inv),
                                  onNew: () => _showCreateSheet(context, ref),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSheet(
        onCreated: () {
          ref.invalidate(invoicesProvider);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        invoice: inv,
        onRefresh: () {
          ref.invalidate(invoicesProvider);
          Navigator.of(context).pop();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ── Action handler ─────────────────────────────────────────────────────────

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Map<String, dynamic> inv,
  ) async {
    final id = inv['id'] as String;
    final link = inv['paymentLink'] as String?;

    void snack(String msg) {
      if (context.mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }

    switch (action) {
      case 'view':
        _showDetailSheet(context, ref, inv);
      case 'send':
        try {
          await apiService.sendInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Invoice sent');
        } catch (e) { snack(apiService.parseError(e)); }
      case 'copy_link':
        if (link != null) {
          await Clipboard.setData(ClipboardData(text: link));
          snack('Payment link copied');
        }
      case 'share_whatsapp':
        if (link != null) {
          final name = (inv['clientName'] as String?) ?? 'there';
          final amt = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
          final sym = (inv['currency'] as String?) == 'USDC' ? '\$' : '₦';
          final msg = 'Hi $name, invoice for $sym${amt.toStringAsFixed(0)}: $link';
          final phone = (inv['clientPhone'] as String?) ?? '';
          final url = phone.isNotEmpty
              ? 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}'
              : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      case 'share_email':
        if (link != null) Share.share('Pay my invoice here: $link');
      case 'reminder':
        try {
          await apiService.sendInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Reminder sent');
        } catch (e) { snack(apiService.parseError(e)); }
      case 'mark_paid':
        try {
          await apiService.markInvoicePaid(id);
          ref.invalidate(invoicesProvider);
          snack('Marked as paid');
        } catch (e) { snack(apiService.parseError(e)); }
      case 'cancel':
        try {
          await apiService.deleteInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Invoice cancelled');
        } catch (e) { snack(apiService.parseError(e)); }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FAB
// ══════════════════════════════════════════════════════════════════════════════

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(Icons.add_rounded, color: cs.surface, size: 22),
      ),
    ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHTS PANEL
// ══════════════════════════════════════════════════════════════════════════════

class _InsightsPanel extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  final Map<String, List<Map<String, dynamic>>> groups;
  const _InsightsPanel({required this.invoices, required this.groups});

  @override
  State<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<_InsightsPanel> {
  int _period = 1;
  static const _periods = ['1W', '1M', 'YTD', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final start = _periodStart(now, _period);

    final inPeriod = widget.invoices.where((inv) {
      final dt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
      return dt == null || !dt.isBefore(start);
    }).toList();

    double paid = 0, pending = 0, overdue = 0;
    for (final inv in inPeriod) {
      final amt = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
      final s = (inv['status'] as String?) ?? '';
      if (s == 'paid') paid += amt;
      if (s == 'sent' || s == 'viewed') pending += amt;
      if (s == 'overdue') overdue += amt;
    }
    final total = paid + pending + overdue;
    final paidPct = total > 0 ? paid / total * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section label ──────────────────────────────────────────────────
        const _SectionLabel('INSIGHTS'),
        const SizedBox(height: 12),

        // ── Status chips — AccountMoverCard style ──────────────────────────
        _StatusChips(groups: widget.groups),
        const SizedBox(height: 16),

        // ── Metric cards row — same pattern as AccountMoverCard ────────────
        Row(
          children: [
            Expanded(child: _MetricCard(
              label: 'Collected',
              value: _fmt(paid),
              symbol: '₦',
              accent: DayFiColors.green,
              pct: paidPct,
            )),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(
              label: 'Pending',
              value: _fmt(pending),
              symbol: '₦',
              accent: const Color(0xFFE57745),
              pct: total > 0 ? pending / total * 100 : 0,
            )),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(
              label: 'Overdue',
              value: _fmt(overdue),
              symbol: '₦',
              accent: DayFiColors.red,
              pct: total > 0 ? overdue / total * 100 : 0,
            )),
          ],
        ),
        const SizedBox(height: 12),

        // ── Sparkline card ─────────────────────────────────────────────────
        _SparkCard(
          invoices: inPeriod,
          period: _period,
          periods: _periods,
          onPeriod: (i) => setState(() => _period = i),
        ),
        const SizedBox(height: 12),

        // ── Breakdown card ─────────────────────────────────────────────────
        _BreakdownCard(
          total: total,
          paid: paid,
          pending: pending,
          overdue: overdue,
          count: inPeriod.length,
          paidPct: paidPct,
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Metric card (matches AccountMoverCard proportions) ────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String symbol;
  final Color accent;
  final double pct;
  const _MetricCard({
    required this.label, required this.value, required this.symbol,
    required this.accent, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: symbol,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.55),
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: value,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.primary,
                  height: 1,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkline card ─────────────────────────────────────────────────────────────

class _SparkCard extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final int period;
  final List<String> periods;
  final void Function(int) onPeriod;
  const _SparkCard({
    required this.invoices, required this.period,
    required this.periods, required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paidSpots = _buildSpots(invoices, period, 'paid');
    final dueSpots = _buildSpots(invoices, period, 'due');
    final overdueSpots = _buildSpots(invoices, period, 'overdue');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: LineChart(LineChartData(
              minY: 0, maxY: 1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                _bar(paidSpots, DayFiColors.green),
                _bar(dueSpots, const Color(0xFFE57745)),
                _bar(overdueSpots, DayFiColors.red),
              ],
            )),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: periods.asMap().entries.map((e) {
              final sel = period == e.key;
              return GestureDetector(
                onTap: () => onPeriod(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? cs.onSurface.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: sel ? cs.onSurface : cs.onSurface.withOpacity(0.35),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  LineChartBarData _bar(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: 1.5,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
  );
}

// ── Breakdown card ─────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final double total, paid, pending, overdue, paidPct;
  final int count;
  const _BreakdownCard({
    required this.total, required this.paid, required this.pending,
    required this.overdue, required this.count, required this.paidPct,
  });

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BREAKDOWN',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: cs.onSurface.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 12),
          _Row('Total invoiced', '₦${_fmt(total)}'),
          _Row('Invoices', '$count'),
          _Row('Avg. invoice', count > 0 ? '₦${_fmt(total / count)}' : '—'),
          _Row(
            'Collection rate',
            total > 0 ? '${paidPct.toStringAsFixed(0)}%' : '—',
            accent: paidPct > 70 ? DayFiColors.green
                : paidPct > 40 ? const Color(0xFFFFA726) : DayFiColors.red,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _Row(this.label, this.value, {this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(
            fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          const Spacer(),
          Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

// ── Status chips ───────────────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  const _StatusChips({required this.groups});

  static const _order = ['overdue', 'sent', 'viewed', 'draft', 'paid', 'cancelled'];

  Color _color(String s, BuildContext ctx) {
    switch (s) {
      case 'paid':      return DayFiColors.green;
      case 'sent':      return const Color(0xFF2775CA);
      case 'viewed':    return const Color(0xFF9C27B0);
      case 'overdue':   return DayFiColors.red;
      case 'cancelled': return Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3);
      default:          return Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: _order.map((s) {
        final count = (groups[s] ?? []).length;
        final color = _color(s, context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                '${s[0].toUpperCase()}${s.substring(1)}: $count',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: color, letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INVOICE LIST PANEL
// ══════════════════════════════════════════════════════════════════════════════

class _InvoiceList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  final List<String> order;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onMenu;
  final VoidCallback onNew;

  const _InvoiceList({
    required this.groups, required this.order, required this.onTap,
    required this.onMenu, required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('INVOICES'),
            const Spacer(),
            GestureDetector(
              onTap: onNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 13, color: cs.surface),
                    const SizedBox(width: 4),
                    Text('New', style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12, fontWeight: FontWeight.w700, color: cs.surface)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final status in order)
          if ((groups[status] ?? []).isNotEmpty) ...[
            _StatusHeader(status: status, count: groups[status]!.length),
            const SizedBox(height: 6),
            ...groups[status]!.asMap().entries.map((e) =>
              _InvoiceTile(
                invoice: e.value,
                onTap: () => onTap(e.value),
                onMenu: (action) => onMenu(action, e.value),
              ).animate().fadeIn(delay: (e.key * 30).ms),
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }
}

// ── Invoice tile ───────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;
  final void Function(String) onMenu;
  const _InvoiceTile({required this.invoice, required this.onTap, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = (invoice['status'] as String?) ?? 'draft';
    final total = (invoice['totalAmount'] as num?)?.toDouble() ?? 0;
    final currency = (invoice['currency'] as String?) ?? 'NGNT';
    final title = (invoice['title'] as String?) ?? 'Invoice';
    final client = (invoice['clientName'] as String?) ?? '—';
    final invoiceNumber = (invoice['invoiceNumber'] as String?) ?? '';
    final due = invoice['dueDate'] != null
        ? DateTime.tryParse(invoice['dueDate'] as String) : null;
    final hasLink = invoice['paymentLink'] != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
        ),
        child: Row(
          children: [
            // Left: info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoiceNumber.isNotEmpty)
                    Text(invoiceNumber, style: TextStyle(
                      fontSize: 10, color: cs.onSurface.withOpacity(0.35),
                      letterSpacing: 0.3)),
                  const SizedBox(height: 1),
                  Text(title, style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    letterSpacing: -0.2, color: cs.onSurface.withOpacity(0.9)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(client, style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
                  if (due != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Due ${DateFormat('MMM d, yyyy').format(due)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: status == 'overdue'
                            ? DayFiColors.red : cs.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Right: amount + pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency == 'USDC'
                      ? '\$${total.toStringAsFixed(2)}'
                      : '₦${total.toStringAsFixed(0)}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: -0.2, color: cs.onSurface.withOpacity(0.9)),
                ),
                const SizedBox(height: 5),
                _StatusPill(status: status),
              ],
            ),
            const SizedBox(width: 4),
            // ⋮ menu
            GestureDetector(
              onTap: () => _showMenu(context, status, hasLink),
              child: Container(
                width: 30, height: 30,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.more_vert_rounded, size: 15,
                    color: cs.onSurface.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, String status, bool hasLink) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        title: (invoice['title'] as String?) ?? 'Invoice',
        number: (invoice['invoiceNumber'] as String?) ?? '',
        entries: _entries(status, hasLink),
        onAction: onMenu,
      ),
    );
  }

  List<_MenuEntry> _entries(String status, bool hasLink) {
    switch (status) {
      case 'draft': return [
        const _MenuEntry('view',   Icons.open_in_new_rounded,          'View details'),
        const _MenuEntry('send',   Icons.send_rounded,                  'Send'),
        const _MenuEntry('cancel', Icons.cancel_outlined,               'Cancel', danger: true),
      ];
      case 'sent':
      case 'viewed': return [
        const _MenuEntry('view',           Icons.open_in_new_rounded,          'View details'),
        if (hasLink) const _MenuEntry('copy_link', Icons.link_rounded,         'Copy payment link'),
        const _MenuEntry('share_whatsapp', Icons.chat_rounded,                 'Share via WhatsApp'),
        const _MenuEntry('share_email',    Icons.mail_outline_rounded,         'Share via Email'),
        const _MenuEntry('mark_paid',      Icons.check_circle_outline_rounded, 'Mark as Paid'),
        const _MenuEntry('cancel',         Icons.cancel_outlined,              'Cancel', danger: true),
      ];
      case 'overdue': return [
        const _MenuEntry('view',      Icons.open_in_new_rounded,          'View details'),
        if (hasLink) const _MenuEntry('copy_link', Icons.link_rounded,    'Copy payment link'),
        const _MenuEntry('reminder',  Icons.notifications_outlined,        'Send reminder'),
        const _MenuEntry('mark_paid', Icons.check_circle_outline_rounded, 'Mark as Paid'),
        const _MenuEntry('cancel',    Icons.cancel_outlined,              'Cancel', danger: true),
      ];
      default: return [
        const _MenuEntry('view', Icons.open_in_new_rounded, 'View details'),
      ];
    }
  }
}

// ── Status header ──────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final String status;
  final int count;
  const _StatusHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatusPill(status: status),
      const SizedBox(width: 6),
      Text('$count', style: TextStyle(
        fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35))),
    ]);
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _color(BuildContext ctx) {
    switch (status) {
      case 'paid':      return DayFiColors.green;
      case 'sent':      return const Color(0xFF2775CA);
      case 'viewed':    return const Color(0xFF9C27B0);
      case 'overdue':   return DayFiColors.red;
      case 'cancelled': return Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3);
      default:          return Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CREATE SHEET — auth-form aesthetic
// ══════════════════════════════════════════════════════════════════════════════

class _CreateSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateSheet({required this.onCreated});

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final _titleCtrl       = TextEditingController();
  final _clientCtrl      = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _notesCtrl       = TextEditingController();
  final _formKey         = GlobalKey<FormState>();
  late List<_LineItem> _items;

  bool   _vat            = false;
  String _currency       = 'NGNT';
  String _payType        = 'crypto';
  DateTime? _due;
  bool   _recurring      = false;
  String _interval       = 'monthly';

  bool _savingDraft      = false;
  bool _sending          = false;
  bool get _busy         => _savingDraft || _sending;

  double get _subtotal   => _items.fold(0, (s, i) => s + i.total);
  double get _vatAmt     => _vat ? _subtotal * 0.075 : 0;
  double get _total      => _subtotal + _vatAmt;

  @override
  void initState() {
    super.initState();
    _items = [_LineItem()];
    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 200), value: 1.0);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _clientCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _notesCtrl.dispose();
    for (final i in _items) i.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _go(int step) async {
    await _fadeCtrl.reverse();
    setState(() => _step = step);
    await _fadeCtrl.forward();
  }

  Map<String, dynamic> _payload() => {
    'title': _titleCtrl.text.trim(),
    'clientName': _clientCtrl.text.trim(),
    if (_emailCtrl.text.trim().isNotEmpty) 'clientEmail': _emailCtrl.text.trim(),
    if (_phoneCtrl.text.trim().isNotEmpty) 'clientPhone': _phoneCtrl.text.trim(),
    if (_notesCtrl.text.trim().isNotEmpty) 'description': _notesCtrl.text.trim(),
    'lineItems': _items.map((i) => {
      'description': i.desc.text.trim(),
      'quantity': i.qty, 'unitPrice': i.price, 'total': i.total,
    }).toList(),
    'subtotal': _subtotal, 'vatAmount': _vatAmt,
    'totalAmount': _total, 'currency': _currency,
    'paymentType': _payType, 'vatEnabled': _vat, 'vatRate': 7.5,
    'isRecurring': _recurring,
    if (_recurring) 'recurringInterval': _interval,
    if (_due != null) 'dueDate': _due!.toIso8601String(),
  };

  Future<void> _draft() async {
    setState(() => _savingDraft = true);
    try {
      await apiService.createInvoice(_payload());
      widget.onCreated();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final res = await apiService.createInvoice(_payload());
      await apiService.sendInvoice(res['invoice']['id'] as String);
      widget.onCreated();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      height: maxH,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.07))),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                if (_step > 0)
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => _go(_step - 1),
                  )
                else
                  const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    ['Who & What', 'Line Items', 'Payment & Schedule'][_step],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      letterSpacing: -0.3, color: cs.onSurface),
                  ),
                ),
                _IconBtn(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Step dots
          _StepDots(current: _step, total: 3),
          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _step == 0 ? _step1()
                   : _step == 1 ? _step2()
                   : _step3(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  Widget _step1() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _Label('Invoice title'),
          _Field(_titleCtrl, 'e.g. Website Redesign — May 2025',
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          const _Label('Client name'),
          _Field(_clientCtrl, 'Client or company name',
            prefix: Icons.person_outline_rounded,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          const _Label('Client email (optional)'),
          _Field(_emailCtrl, 'client@email.com',
            keyboard: TextInputType.emailAddress,
            prefix: Icons.mail_outline_rounded),
          const SizedBox(height: 12),
          const _Label('Client phone (optional — for WhatsApp)'),
          _Field(_phoneCtrl, '+234 800 000 0000',
            keyboard: TextInputType.phone,
            prefix: Icons.phone_outlined),
          const SizedBox(height: 32),
          _PrimaryBtn(
            label: 'Continue',
            onTap: () { if (_formKey.currentState!.validate()) _go(1); },
          ),
        ],
      ),
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  Widget _step2() {
    final sym = _currency == 'USDC' ? '\$' : '₦';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _Label('Line items'),
        ..._items.asMap().entries.map((e) => _LineItemCard(
          item: e.value, symbol: sym,
          onChanged: () => setState(() {}),
          onRemove: _items.length > 1
              ? () => setState(() => _items.removeAt(e.key)) : null,
        )),
        TextButton.icon(
          onPressed: () => setState(() => _items.add(_LineItem())),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
          label: const Text('Add line item'),
        ),
        const SizedBox(height: 8),
        // VAT toggle
        _SwitchRow(label: 'Apply VAT (7.5%)', value: _vat,
            onChanged: (v) => setState(() => _vat = v)),
        const Divider(height: 28),
        // Totals
        _TotalsBlock(subtotal: _subtotal, vat: _vatAmt, total: _total,
            vatEnabled: _vat, symbol: sym),
        const SizedBox(height: 24),
        _PrimaryBtn(
          label: 'Continue',
          onTap: () {
            if (_items.isEmpty || _items.every((i) => i.total == 0)) {
              _snack('Add at least one line item with an amount');
            } else {
              _go(2);
            }
          },
        ),
      ],
    );
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────────

  Widget _step3() {
    final sym = _currency == 'USDC' ? '\$' : '₦';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _Label('Currency'),
        Row(children: [
          _Chip(label: 'NGN (NGNT)', sel: _currency == 'NGNT',
              onTap: () => setState(() => _currency = 'NGNT')),
          const SizedBox(width: 8),
          _Chip(label: 'USD (USDC)', sel: _currency == 'USDC',
              onTap: () => setState(() => _currency = 'USDC')),
        ]),
        const SizedBox(height: 16),
        const _Label('Payment method'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(label: 'On-chain',     icon: Icons.link_rounded,              sel: _payType == 'crypto',       onTap: () => setState(() => _payType = 'crypto')),
          _Chip(label: 'Bank transfer',icon: Icons.account_balance_outlined,  sel: _payType == 'bankTransfer', onTap: () => setState(() => _payType = 'bankTransfer')),
          _Chip(label: 'Both',         icon: Icons.swap_horiz_rounded,        sel: _payType == 'both',         onTap: () => setState(() => _payType = 'both')),
        ]),
        const SizedBox(height: 16),
        const _Label('Due date'),
        Wrap(spacing: 8, runSpacing: 6, children: [7, 14, 30, 60].map((d) {
          final exp = DateTime.now().add(Duration(days: d));
          final sel = _due != null && _due!.day == exp.day
              && _due!.month == exp.month && _due!.year == exp.year;
          return _Chip(
            label: 'Net $d', sel: sel,
            onTap: () => setState(() => _due = DateTime.now().add(Duration(days: d))));
        }).toList()),
        const SizedBox(height: 8),
        _DateRow(due: _due,
          onPick: () async {
            final d = await showDatePicker(context: context,
              initialDate: DateTime.now().add(const Duration(days: 14)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)));
            if (d != null) setState(() => _due = d);
          },
          onClear: () => setState(() => _due = null),
        ),
        const SizedBox(height: 16),
        _SwitchRow(label: 'Recurring invoice', sublabel: 'Auto-generate on a schedule',
            value: _recurring, onChanged: (v) => setState(() => _recurring = v)),
        if (_recurring) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6,
            children: ['weekly','monthly','quarterly','annually'].map((iv) =>
              _Chip(label: '${iv[0].toUpperCase()}${iv.substring(1)}',
                sel: _interval == iv, onTap: () => setState(() => _interval = iv)),
            ).toList(),
          ),
        ],
        const SizedBox(height: 16),
        const _Label('Notes (optional)'),
        _MultiField(_notesCtrl, 'Payment terms, bank details, message…'),
        const SizedBox(height: 16),
        // Summary
        _SummaryCard(
          title: _titleCtrl.text.trim(),
          client: _clientCtrl.text.trim(),
          count: _items.length,
          total: _total, symbol: sym, due: _due,
        ),
        const SizedBox(height: 20),
        // Dual buttons
        Row(children: [
          Expanded(
            child: _OutlineBtn(
              label: 'Save Draft',
              loading: _savingDraft,
              onTap: _busy ? null : _draft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _PrimaryBtn(
              label: 'Send Invoice →',
              loading: _sending,
              onTap: _busy ? null : _send,
            ),
          ),
        ]),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DETAIL SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _DetailSheet extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  const _DetailSheet({required this.invoice, required this.onRefresh, required this.onClose});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _sending = false, _marking = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = widget.invoice;
    final status   = (inv['status'] as String?) ?? 'draft';
    final currency = (inv['currency'] as String?) ?? 'NGNT';
    final total    = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    final link     = inv['paymentLink'] as String?;
    final sym      = currency == 'USDC' ? '\$' : '₦';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.07))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 32, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text('Invoice Detail', style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const Spacer(),
                  _IconBtn(icon: Icons.close_rounded, onTap: widget.onClose),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Amount hero — matches balance row aesthetic
            Text(
              '$sym${total.toStringAsFixed(2)}',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 40, fontWeight: FontWeight.w500,
                letterSpacing: -1.5, color: cs.primary, height: 1),
            ),
            const SizedBox(height: 6),
            _StatusPill(status: status),
            const SizedBox(height: 20),
            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _DetailRow('Invoice #', inv['invoiceNumber'] ?? ''),
                  _DetailRow('Client', inv['clientName'] ?? '—'),
                  _DetailRow('Currency', currency),
                  if (inv['dueDate'] != null)
                    _DetailRow('Due date',
                      DateFormat('MMM d, yyyy').format(
                        DateTime.parse(inv['dueDate'] as String))),
                  if (inv['title'] != null)
                    _DetailRow('Title', inv['title'] as String),
                ],
              ),
            ),
            // Payment link
            if (link != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(link,
                        style: TextStyle(fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      _IconBtn(icon: Icons.copy_rounded, onTap: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')));
                      }),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (status == 'draft')
                    _PrimaryBtn(
                      label: 'Send Invoice',
                      loading: _sending,
                      onTap: _sending ? null : () async {
                        setState(() => _sending = true);
                        try {
                          await apiService.sendInvoice(inv['id'] as String);
                          widget.onRefresh();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(apiService.parseError(e))));
                        } finally {
                          if (mounted) setState(() => _sending = false);
                        }
                      },
                    ),
                  if (status == 'sent' || status == 'viewed' || status == 'overdue')
                    _PrimaryBtn(
                      label: 'Mark as Paid',
                      loading: _marking,
                      onTap: _marking ? null : () async {
                        setState(() => _marking = true);
                        try {
                          await apiService.markInvoicePaid(inv['id'] as String);
                          widget.onRefresh();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(apiService.parseError(e))));
                        } finally {
                          if (mounted) setState(() => _marking = false);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: TextStyle(
            fontSize: 13, color: cs.onSurface.withOpacity(0.45))),
          const Spacer(),
          Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTION SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _MenuEntry {
  final String action;
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuEntry(this.action, this.icon, this.label, {this.danger = false});
}

class _ActionSheet extends StatelessWidget {
  final String title, number;
  final List<_MenuEntry> entries;
  final void Function(String) onAction;
  const _ActionSheet({
    required this.title, required this.number,
    required this.entries, required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.07))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2)),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (number.isNotEmpty)
                    Text(number, style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withOpacity(0.06)),
            ...entries.map((e) => ListTile(
              leading: Icon(e.icon, size: 19,
                color: e.danger ? DayFiColors.red : cs.onSurface.withOpacity(0.6)),
              title: Text(e.label, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: e.danger ? DayFiColors.red : null)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
              onTap: () {
                Navigator.of(context).pop();
                onAction(e.action);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED FORM WIDGETS — auth-screen aesthetic
// ══════════════════════════════════════════════════════════════════════════════

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600, letterSpacing: 0.2, fontSize: 12)),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final IconData? prefix;
  final String? Function(String?)? validator;
  const _Field(this.ctrl, this.hint, {
    this.keyboard = TextInputType.text, this.prefix, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(
        fontSize: 15, letterSpacing: -0.1,
        color: cs.onSurface.withOpacity(0.85)),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15, color: cs.onSurface.withOpacity(0.3), letterSpacing: -0.1),
        prefixIcon: prefix != null
            ? Icon(prefix, size: 17, color: cs.onSurface.withOpacity(0.35)) : null,
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error)),
        isDense: true,
      ),
    );
  }
}

class _MultiField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _MultiField(this.ctrl, this.hint);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.85)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.3)),
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.07),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5)),
        isDense: true,
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryBtn({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.onSurface, foregroundColor: cs.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.surface))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _OutlineBtn({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface))
            : Text(label, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.65))),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  final IconData? icon;
  const _Chip({required this.label, required this.sel, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? cs.onSurface : cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13,
                color: sel ? cs.surface : cs.onSurface.withOpacity(0.6)),
            const SizedBox(width: 5),
          ],
          Text(label, style: GoogleFonts.bricolageGrotesque(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: sel ? cs.surface : cs.onSurface.withOpacity(0.65))),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value,
      required this.onChanged, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (sublabel != null) Text(sublabel!, style: TextStyle(
            fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45))),
        ],
      )),
      Switch(value: value, onChanged: onChanged),
    ]);
  }
}

class _DateRow extends StatelessWidget {
  final DateTime? due;
  final VoidCallback onPick, onClear;
  const _DateRow({required this.due, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 14,
              color: cs.onSurface.withOpacity(0.4)),
          const SizedBox(width: 10),
          Text(
            due != null ? DateFormat('MMM d, yyyy').format(due!) : 'Custom date',
            style: TextStyle(fontSize: 14,
                color: due != null ? cs.onSurface : cs.onSurface.withOpacity(0.4))),
          const Spacer(),
          if (due != null) GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 14,
                color: cs.onSurface.withOpacity(0.4)),
          ),
        ]),
      ),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  final double subtotal, vat, total;
  final bool vatEnabled;
  final String symbol;
  const _TotalsBlock({required this.subtotal, required this.vat,
      required this.total, required this.vatEnabled, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        _TLine('Subtotal', subtotal, symbol),
        if (vatEnabled) _TLine('VAT (7.5%)', vat, symbol),
        Divider(height: 16, color: cs.onSurface.withOpacity(0.08)),
        _TLine('Total', total, symbol, bold: true),
      ]),
    );
  }
}

class _TLine extends StatelessWidget {
  final String label, symbol;
  final double amount;
  final bool bold;
  const _TLine(this.label, this.amount, this.symbol, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: TextStyle(
          fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? null : Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const Spacer(),
        Text('$symbol${amount.toStringAsFixed(2)}', style: TextStyle(
          fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, client, symbol;
  final int count;
  final double total;
  final DateTime? due;
  const _SummaryCard({required this.title, required this.client,
      required this.count, required this.total,
      required this.symbol, required this.due});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Summary', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: cs.onSurface.withOpacity(0.4), letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Text(title.isNotEmpty ? title : '—',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        Text(client.isNotEmpty ? client : '—',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
        Divider(height: 16, color: cs.onSurface.withOpacity(0.08)),
        Row(children: [
          Text('$count item${count == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          const Spacer(),
          Text('$symbol${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        if (due != null) ...[
          const SizedBox(height: 4),
          Text('Due ${DateFormat('MMM d, yyyy').format(due!)}',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
        ],
      ]),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current, total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 22 : 7, height: 6,
          decoration: BoxDecoration(
            color: i <= current
                ? cs.onSurface : cs.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(3)),
        )),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ── Line item model ────────────────────────────────────────────────────────────

class _LineItem {
  final desc  = TextEditingController();
  final qty   = TextEditingController(text: '1');
  final price = TextEditingController();

  double get qtyVal   => double.tryParse(qty.text) ?? 0;
  double get priceVal => double.tryParse(price.text) ?? 0;
  double get total    => qtyVal * priceVal;

  void dispose() { desc.dispose(); qty.dispose(); price.dispose(); }
}

class _LineItemCard extends StatelessWidget {
  final _LineItem item;
  final String symbol;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _LineItemCard({required this.item, required this.symbol,
      required this.onChanged, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(
            controller: item.desc,
            onChanged: (_) => onChanged(),
            style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.85)),
            decoration: InputDecoration(
              hintText: 'Item description',
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.3)),
              border: InputBorder.none, isDense: true),
          )),
          if (onRemove != null) GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 15,
                color: cs.onSurface.withOpacity(0.35))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          SizedBox(width: 60, child: TextField(
            controller: item.qty,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.85)),
            decoration: InputDecoration(
              hintText: 'Qty',
              prefix: Text('×', style: TextStyle(color: cs.onSurface.withOpacity(0.35))),
              border: InputBorder.none, isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: item.price,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.85)),
            decoration: InputDecoration(
              hintText: 'Unit price',
              prefix: Text('$symbol ', style: TextStyle(
                fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.4))),
              border: InputBorder.none, isDense: true),
          )),
          Text('$symbol${item.total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ── Empty / Error views ────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 44,
                color: cs.onSurface.withOpacity(0.18)),
            const SizedBox(height: 16),
            Text('No invoices yet', style: GoogleFonts.bricolageGrotesque(
              fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Create your first invoice to start getting paid.',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center),
            const SizedBox(height: 28),
            _PrimaryBtn(label: 'Create Invoice', onTap: onCreate),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Failed to load', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ));
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.bricolageGrotesque(
      fontSize: 11, fontWeight: FontWeight.w700,
      letterSpacing: 1.2, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)));
  }
}

// ── Chart helpers ──────────────────────────────────────────────────────────────

DateTime _periodStart(DateTime now, int p) {
  switch (p) {
    case 0: return now.subtract(const Duration(days: 7));
    case 1: return now.subtract(const Duration(days: 30));
    case 2: return DateTime(now.year, 1, 1);
    case 3: return now.subtract(const Duration(days: 90));
    case 4: return now.subtract(const Duration(days: 365));
    default: return now.subtract(const Duration(days: 30));
  }
}

List<FlSpot> _buildSpots(List<Map<String, dynamic>> invoices, int period, String kind) {
  final now = DateTime.now();
  final start = _periodStart(now, period);
  final buckets = period == 2 ? now.month : [7, 30, 30, 90, 30][period];
  final vals = List<double>.filled(buckets, 0);
  final span = now.difference(start).inDays.clamp(1, 366);

  for (final inv in invoices) {
    final dt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
    if (dt == null || dt.isBefore(start)) continue;
    final s = (inv['status'] as String?) ?? '';
    final amt = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    if (kind == 'paid' && s != 'paid') continue;
    if (kind == 'due' && s != 'sent' && s != 'viewed') continue;
    if (kind == 'overdue' && s != 'overdue') continue;
    final idx = period == 2
        ? (dt.month - 1).clamp(0, buckets - 1)
        : ((dt.difference(start).inDays / span * (buckets - 1)).round()).clamp(0, buckets - 1);
    vals[idx] += amt;
  }

  if (vals.every((v) => v == 0)) return [const FlSpot(0, 0.5), const FlSpot(1, 0.5)];
  final maxVal = vals.reduce((a, b) => a > b ? a : b);
  return List.generate(vals.length, (i) =>
      FlSpot(i.toDouble(), maxVal == 0 ? 0.5 : (vals[i] / maxVal).clamp(0.05, 1.0)));
}