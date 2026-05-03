// lib/screens/invoices/invoices_screen.dart
//
// Full inline shell — no bottom sheets, no modals.
// "New Invoice" → shellNavProvider.goTo(ShellDest.createInvoice)
// Tile tap      → sets selectedInvoiceProvider + goTo(ShellDest.invoiceDetail)
// Dropdowns     → web-style overlay anchored to field (same pattern as BusinessProfileScreen)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/shell_navigation_provider.dart';
import '../../providers/selected_invoice_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final invoicesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final result = await apiService.getInvoices(page: 1, limit: 50);
  return List<Map<String, dynamic>>.from(result['invoices'] ?? []);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);
    final notifier = ref.read(shellNavProvider.notifier);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _Fab(
        onTap: () => notifier.goTo(ShellDest.createInvoice),
      ),
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
              return _EmptyView(
                onCreate: () => notifier.goTo(ShellDest.createInvoice),
              );
            }

            const statusOrder = [
              'overdue', 'sent', 'viewed', 'draft', 'paid', 'cancelled',
            ];
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
                                    onTap: (inv) => _openDetail(ref, notifier, inv),
                                    onMenu: (action, inv) =>
                                        _handleAction(context, ref, action, inv),
                                    onNew: () => notifier.goTo(ShellDest.createInvoice),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _InsightsPanel(
                                    invoices: invoices, groups: groups),
                                const SizedBox(height: 24),
                                _InvoiceList(
                                  groups: groups,
                                  order: statusOrder,
                                  onTap: (inv) => _openDetail(ref, notifier, inv),
                                  onMenu: (action, inv) =>
                                      _handleAction(context, ref, action, inv),
                                  onNew: () => notifier.goTo(ShellDest.createInvoice),
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

  void _openDetail(
    WidgetRef ref,
    dynamic notifier,
    Map<String, dynamic> inv,
  ) {
    ref.read(selectedInvoiceProvider.notifier).state = inv;
    notifier.goTo(ShellDest.invoiceDetail);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Map<String, dynamic> inv,
  ) async {
    final id = inv['id'] as String;
    final link = inv['paymentLink'] as String?;

    void snack(String msg) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
    }

    switch (action) {
      case 'view':
        _openDetail(ref, ref.read(shellNavProvider.notifier), inv);
      case 'send':
        try {
          await apiService.sendInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Invoice sent');
        } catch (e) {
          snack(apiService.parseError(e));
        }
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
          final msg =
              'Hi $name, invoice for $sym${amt.toStringAsFixed(0)}: $link';
          final phone = (inv['clientPhone'] as String?) ?? '';
          final url = phone.isNotEmpty
              ? 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}'
              : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        }
      case 'share_email':
        if (link != null) Share.share('Pay my invoice here: $link');
      case 'reminder':
        try {
          await apiService.sendInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Reminder sent');
        } catch (e) {
          snack(apiService.parseError(e));
        }
      case 'mark_paid':
        try {
          await apiService.markInvoicePaid(id);
          ref.invalidate(invoicesProvider);
          snack('Marked as paid');
        } catch (e) {
          snack(apiService.parseError(e));
        }
      case 'cancel':
        try {
          await apiService.deleteInvoice(id);
          ref.invalidate(invoicesProvider);
          snack('Invoice cancelled');
        } catch (e) {
          snack(apiService.parseError(e));
        }
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
// INSIGHTS PANEL  (unchanged from original — same widgets)
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
    final now = DateTime.now();
    final start = _periodStart(now, _period);

    final inPeriod = widget.invoices.where((inv) {
      final dt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
      return dt == null || !dt.isBefore(start);
    }).toList();

    double paidNgn = 0, paidUsd = 0;
    double pendingNgn = 0, pendingUsd = 0;
    double overdueNgn = 0, overdueUsd = 0;
    for (final inv in inPeriod) {
      final amt = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
      final s = (inv['status'] as String?) ?? '';
      final isUsd = (inv['currency'] as String?) == 'USDC';
      if (s == 'paid') { if (isUsd) paidUsd += amt; else paidNgn += amt; }
      if (s == 'sent' || s == 'viewed') { if (isUsd) pendingUsd += amt; else pendingNgn += amt; }
      if (s == 'overdue') { if (isUsd) overdueUsd += amt; else overdueNgn += amt; }
    }
    final invoiceCount = inPeriod.length.toDouble();
    final paidCount = inPeriod.where((i) => i['status'] == 'paid').length.toDouble();
    final pendingCount = inPeriod.where((i) => ['sent','viewed'].contains(i['status'])).length.toDouble();
    final overdueCount = inPeriod.where((i) => i['status'] == 'overdue').length.toDouble();
    final paidPct = invoiceCount > 0 ? paidCount / invoiceCount * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('INSIGHTS'),
        const SizedBox(height: 12),
        _StatusChips(groups: widget.groups),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Collected',
                value: _fmtMixed(paidNgn, paidUsd),
                symbol: '',
                accent: DayFiColors.green,
                pct: paidPct,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Pending',
                value: _fmtMixed(pendingNgn, pendingUsd),
                symbol: '',
                accent: const Color(0xFFE57745),
                pct: invoiceCount > 0 ? pendingCount / invoiceCount * 100 : 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Overdue',
                value: _fmtMixed(overdueNgn, overdueUsd),
                symbol: '',
                accent: DayFiColors.red,
                pct: invoiceCount > 0 ? overdueCount / invoiceCount * 100 : 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SparkCard(
          invoices: inPeriod,
          period: _period,
          periods: _periods,
          onPeriod: (i) => setState(() => _period = i),
        ),
        const SizedBox(height: 12),
        _BreakdownCard(
          total: paidNgn + pendingNgn + overdueNgn,
          paid: paidNgn,
          pending: pendingNgn,
          overdue: overdueNgn,
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

  String _fmtMixed(double ngn, double usd) {
    final parts = <String>[];
    if (ngn > 0) {
      if (ngn >= 1000000) parts.add('₦${(ngn / 1000000).toStringAsFixed(1)}M');
      else if (ngn >= 1000) parts.add('₦${(ngn / 1000).toStringAsFixed(0)}k');
      else parts.add('₦${ngn.toStringAsFixed(0)}');
    }
    if (usd > 0) parts.add('\$${usd.toStringAsFixed(2)}');
    return parts.isEmpty ? '₦0' : parts.join(' + ');
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, symbol;
  final Color accent;
  final double pct;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.symbol,
    required this.accent,
    required this.pct,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _SparkCard extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final int period;
  final List<String> periods;
  final void Function(int) onPeriod;
  const _SparkCard({
    required this.invoices,
    required this.period,
    required this.periods,
    required this.onPeriod,
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
              minY: 0,
              maxY: 1,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel
                        ? cs.onSurface.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: sel
                          ? cs.onSurface
                          : cs.onSurface.withOpacity(0.35),
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

  LineChartBarData _bar(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
}

class _BreakdownCard extends StatelessWidget {
  final double total, paid, pending, overdue, paidPct;
  final int count;
  const _BreakdownCard({
    required this.total,
    required this.paid,
    required this.pending,
    required this.overdue,
    required this.count,
    required this.paidPct,
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurface.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 12),
          _Row('Total invoiced', '₦${_fmt(total)}'),
          _Row('Invoices', '$count'),
          _Row(
              'Avg. invoice', count > 0 ? '₦${_fmt(total / count)}' : '—'),
          _Row(
            'Collection rate',
            total > 0 ? '${paidPct.toStringAsFixed(0)}%' : '—',
            accent: paidPct > 70
                ? DayFiColors.green
                : paidPct > 40
                    ? const Color(0xFFFFA726)
                    : DayFiColors.red,
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
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent)),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  const _StatusChips({required this.groups});

  static const _order = [
    'overdue', 'sent', 'viewed', 'draft', 'paid', 'cancelled',
  ];

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
      spacing: 6,
      runSpacing: 6,
      children: _order.map((s) {
        final count = (groups[s] ?? []).length;
        final color = _color(s, context);
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                '${s[0].toUpperCase()}${s.substring(1)}: $count',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.1,
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

class _InvoiceList extends ConsumerStatefulWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  final List<String> order;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(String, Map<String, dynamic>) onMenu;
  final VoidCallback onNew;

  const _InvoiceList({
    required this.groups,
    required this.order,
    required this.onTap,
    required this.onMenu,
    required this.onNew,
  });

  @override
  ConsumerState<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends ConsumerState<_InvoiceList> {
  bool _bulkMode = false;
  Set<String> _selected = {};
  bool _marking = false;

  void _enterBulk(String id) => setState(() {
        _bulkMode = true;
        _selected = {id};
      });

  void _toggle(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
          if (_selected.isEmpty) _bulkMode = false;
        } else {
          _selected.add(id);
        }
      });

  void _exitBulk() => setState(() {
        _bulkMode = false;
        _selected = {};
      });

  Future<void> _markPaid() async {
    setState(() => _marking = true);
    final ids = List<String>.from(_selected);
    int done = 0;
    for (final id in ids) {
      try {
        await apiService.markInvoicePaid(id);
        done++;
      } catch (_) {}
    }
    ref.invalidate(invoicesProvider);
    _exitBulk();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Marked $done invoice${done == 1 ? '' : 's'} as paid'),
      ));
    }
    if (mounted) setState(() => _marking = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_bulkMode) ...[
                  GestureDetector(
                    onTap: _exitBulk,
                    child: Icon(Icons.close_rounded,
                        size: 20, color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selected.length} selected',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                ] else ...[
                  const _SectionLabel('INVOICES'),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onNew,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.onSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 13, color: cs.surface),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            for (final status in widget.order)
              if ((widget.groups[status] ?? []).isNotEmpty) ...[
                _StatusHeader(
                    status: status, count: widget.groups[status]!.length),
                const SizedBox(height: 6),
                ...widget.groups[status]!.asMap().entries.map((e) {
                  final id = (e.value['id'] as String?) ?? '';
                  return _InvoiceTile(
                    invoice: e.value,
                    onTap: _bulkMode
                        ? () => _toggle(id)
                        : () => widget.onTap(e.value),
                    onLongPress: _bulkMode ? null : () => _enterBulk(id),
                    onMenu: (action) => widget.onMenu(action, e.value),
                    bulkMode: _bulkMode,
                    selected: _selected.contains(id),
                  ).animate().fadeIn(delay: (e.key * 30).ms);
                }),
                const SizedBox(height: 18),
              ],
            if (_bulkMode) const SizedBox(height: 72),
          ],
        ),
        if (_bulkMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(color: cs.onSurface.withOpacity(0.08))),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed:
                      _selected.isEmpty || _marking ? null : _markPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DayFiColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _marking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Mark ${_selected.length} as Paid',
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;
  final void Function(String) onMenu;
  final bool bulkMode;
  final bool selected;
  final VoidCallback? onLongPress;

  const _InvoiceTile({
    required this.invoice,
    required this.onTap,
    required this.onMenu,
    this.bulkMode = false,
    this.selected = false,
    this.onLongPress,
  });

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
        ? DateTime.tryParse(invoice['dueDate'] as String)
        : null;
    final hasLink = invoice['paymentLink'] != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.35)
                : cs.onSurface.withValues(alpha: 0.05),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            if (bulkMode) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey(true),
                        size: 20,
                        color: cs.primary)
                    : Icon(Icons.circle_outlined,
                        key: const ValueKey(false),
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoiceNumber.isNotEmpty)
                    Text(invoiceNumber,
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.35),
                            letterSpacing: 0.3)),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(client,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45))),
                  if (due != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Due ${DateFormat('MMM d, yyyy').format(due)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: status == 'overdue'
                            ? DayFiColors.red
                            : cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                  if (status == 'overdue' && due != null) ...[
                    const SizedBox(height: 4),
                    _AgingBadge(dueDate: due),
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
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 5),
                _StatusPill(status: status),
              ],
            ),
            if (!bulkMode) ...[
              const SizedBox(width: 4),
              _TileMenuBtn(
                invoice: invoice,
                status: status,
                hasLink: hasLink,
                onMenu: onMenu,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Aging badge ────────────────────────────────────────────────────────────────

class _AgingBadge extends StatelessWidget {
  final DateTime dueDate;
  const _AgingBadge({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(dueDate).inDays;
    if (days <= 0) return const SizedBox.shrink();
    final label = days == 1 ? '1 day overdue' : '$days days overdue';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DayFiColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: DayFiColors.red,
        ),
      ),
    );
  }
}

// ── Tile context menu button (inline popover, no sheet) ────────────────────────

class _TileMenuBtn extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final String status;
  final bool hasLink;
  final void Function(String) onMenu;
  const _TileMenuBtn({
    required this.invoice,
    required this.status,
    required this.hasLink,
    required this.onMenu,
  });

  @override
  State<_TileMenuBtn> createState() => _TileMenuBtnState();
}

class _TileMenuBtnState extends State<_TileMenuBtn> {
  OverlayEntry? _overlay;
  final _key = GlobalKey();

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  List<_MenuEntry> get _entries {
    switch (widget.status) {
      case 'draft':
        return [
          const _MenuEntry('view', Icons.open_in_new_rounded, 'View details'),
          const _MenuEntry('send', Icons.send_rounded, 'Send'),
          const _MenuEntry('cancel', Icons.cancel_outlined, 'Cancel',
              danger: true),
        ];
      case 'sent':
      case 'viewed':
        return [
          const _MenuEntry('view', Icons.open_in_new_rounded, 'View details'),
          if (widget.hasLink)
            const _MenuEntry(
                'copy_link', Icons.link_rounded, 'Copy payment link'),
          const _MenuEntry(
              'share_whatsapp', Icons.chat_rounded, 'Share via WhatsApp'),
          const _MenuEntry(
              'share_email', Icons.mail_outline_rounded, 'Share via Email'),
          const _MenuEntry('mark_paid',
              Icons.check_circle_outline_rounded, 'Mark as Paid'),
          const _MenuEntry('cancel', Icons.cancel_outlined, 'Cancel',
              danger: true),
        ];
      case 'overdue':
        return [
          const _MenuEntry('view', Icons.open_in_new_rounded, 'View details'),
          if (widget.hasLink)
            const _MenuEntry(
                'copy_link', Icons.link_rounded, 'Copy payment link'),
          const _MenuEntry('reminder', Icons.notifications_outlined,
              'Send reminder'),
          const _MenuEntry('mark_paid',
              Icons.check_circle_outline_rounded, 'Mark as Paid'),
          const _MenuEntry('cancel', Icons.cancel_outlined, 'Cancel',
              danger: true),
        ];
      default:
        return [
          const _MenuEntry('view', Icons.open_in_new_rounded, 'View details'),
        ];
    }
  }

  void _show() {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      return;
    }
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenW = MediaQuery.of(context).size.width;
    const menuW = 200.0;
    final left =
        (offset.dx + menuW > screenW) ? screenW - menuW - 8 : offset.dx;

    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _overlay?.remove();
                _overlay = null;
              },
            ),
          ),
          Positioned(
            left: left,
            top: offset.dy + size.height + 4,
            width: menuW,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _entries.map((e) {
                    return InkWell(
                      onTap: () {
                        _overlay?.remove();
                        _overlay = null;
                        widget.onMenu(e.action);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(e.icon,
                                size: 15,
                                color: e.danger
                                    ? DayFiColors.red
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.55)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: e.danger ? DayFiColors.red : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      key: _key,
      onTap: _show,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_vert_rounded,
            size: 15, color: cs.onSurface.withOpacity(0.4)),
      ),
    );
  }
}

class _MenuEntry {
  final String action;
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuEntry(this.action, this.icon, this.label, {this.danger = false});
}

// ── Status widgets ─────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final String status;
  final int count;
  const _StatusHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatusPill(status: status),
      const SizedBox(width: 6),
      Text('$count',
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.35))),
    ]);
  }
}

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

// ── Empty / Error ──────────────────────────────────────────────────────────────

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
            Icon(Icons.receipt_long_outlined,
                size: 44, color: cs.onSurface.withOpacity(0.18)),
            const SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first invoice to start getting paid.',
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.onSurface,
                  foregroundColor: cs.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onCreate,
                child: const Text('Create Invoice',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
      ),
    );
  }
}

// ── Chart helpers ──────────────────────────────────────────────────────────────

DateTime _periodStart(DateTime now, int p) {
  switch (p) {
    case 0:  return now.subtract(const Duration(days: 7));
    case 1:  return now.subtract(const Duration(days: 30));
    case 2:  return DateTime(now.year, 1, 1);
    case 3:  return now.subtract(const Duration(days: 90));
    case 4:  return now.subtract(const Duration(days: 365));
    default: return now.subtract(const Duration(days: 30));
  }
}

List<FlSpot> _buildSpots(
  List<Map<String, dynamic>> invoices,
  int period,
  String kind,
) {
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
        : ((dt.difference(start).inDays / span * (buckets - 1)).round())
            .clamp(0, buckets - 1);
    vals[idx] += amt;
  }

  if (vals.every((v) => v == 0))
    return [const FlSpot(0, 0.5), const FlSpot(1, 0.5)];
  final maxVal = vals.reduce((a, b) => a > b ? a : b);
  return List.generate(
    vals.length,
    (i) => FlSpot(i.toDouble(),
        maxVal == 0 ? 0.5 : (vals[i] / maxVal).clamp(0.05, 1.0)),
  );
}