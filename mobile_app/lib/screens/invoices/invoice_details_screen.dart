// lib/screens/invoices/invoice_detail_screen.dart
//
// Full inline detail view — no sheets, no dialogs.
// Reads selectedInvoiceProvider set by InvoicesScreen.
// Actions (send, mark paid, copy link, share) all inline.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/selected_invoice_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'invoices_screen.dart' show invoicesProvider;

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const InvoiceDetailScreen({super.key, required this.insideShell});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _sending = false;
  bool _marking = false;
  bool _cancelling = false;

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send(String id) async {
    setState(() => _sending = true);
    try {
      await apiService.sendInvoice(id);
      ref.invalidate(invoicesProvider);
      _snack('Invoice sent');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markPaid(String id) async {
    setState(() => _marking = true);
    try {
      await apiService.markInvoicePaid(id);
      ref.invalidate(invoicesProvider);
      _snack('Marked as paid');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _cancel(String id) async {
    setState(() => _cancelling = true);
    try {
      await apiService.deleteInvoice(id);
      ref.invalidate(invoicesProvider);
      _snack('Invoice cancelled');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = ref.watch(selectedInvoiceProvider);

    if (inv == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('No invoice selected')),
      );
    }

    final id = inv['id'] as String;
    final status = (inv['status'] as String?) ?? 'draft';
    final currency = (inv['currency'] as String?) ?? 'NGNT';
    final total = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    final sym = currency == 'USDC' ? '\$' : '₦';
    final link = inv['paymentLink'] as String?;
    final due = inv['dueDate'] != null
        ? DateTime.tryParse(inv['dueDate'] as String)
        : null;
    final lineItems =
        List<Map<String, dynamic>>.from(inv['lineItems'] ?? []);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Amount hero ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$sym${total.toStringAsFixed(2)}',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -2,
                            color: cs.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StatusPill(status: status),
                        if (inv['invoiceNumber'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            inv['invoiceNumber'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.35),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Details card ─────────────────────────────────────────
                  _Card(
                    child: Column(
                      children: [
                        if (inv['title'] != null)
                          _DetailRow('Title', inv['title'] as String),
                        _DetailRow(
                            'Client', (inv['clientName'] as String?) ?? '—'),
                        if (inv['clientEmail'] != null)
                          _DetailRow(
                              'Email', inv['clientEmail'] as String),
                        if (inv['clientPhone'] != null)
                          _DetailRow(
                              'Phone', inv['clientPhone'] as String),
                        _DetailRow('Currency', currency),
                        if (due != null)
                          _DetailRow('Due date',
                              DateFormat('MMM d, yyyy').format(due)),
                        if (inv['isRecurring'] == true)
                          _DetailRow('Recurring',
                              inv['recurringInterval'] as String? ?? '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Line items ───────────────────────────────────────────
                  if (lineItems.isNotEmpty) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LINE ITEMS',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cs.onSurface.withOpacity(0.35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...lineItems.map((item) {
                            final qty =
                                (item['quantity'] as num?)?.toInt() ?? 1;
                            final unit =
                                (item['unitPrice'] as num?)?.toDouble() ??
                                    0;
                            final lineTotal =
                                (item['total'] as num?)?.toDouble() ??
                                    (qty * unit);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (item['description']
                                                  as String?) ??
                                              '—',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w500),
                                        ),
                                        Text(
                                          '$qty × $sym${unit.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurface
                                                  .withOpacity(0.4)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$sym${lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Divider(
                              height: 20,
                              color: cs.onSurface.withOpacity(0.08)),
                          if ((inv['vatEnabled'] as bool?) == true)
                            _TotalsRow(
                                'VAT (7.5%)',
                                '$sym${((inv['vatAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}'),
                          _TotalsRow(
                            'Total',
                            '$sym${total.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Payment link ─────────────────────────────────────────
                  if (link != null) ...[
                    _Card(
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              link,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.5)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionIconBtn(
                            icon: Icons.copy_rounded,
                            onTap: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: link));
                              _snack('Payment link copied');
                            },
                          ),
                          const SizedBox(width: 6),
                          _ActionIconBtn(
                            icon: Icons.share_rounded,
                            onTap: () => Share.share(link),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Notes ────────────────────────────────────────────────
                  if ((inv['description'] as String?)?.isNotEmpty ??
                      false) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTES',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cs.onSurface.withOpacity(0.35),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            inv['description'] as String,
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.7),
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── WhatsApp share ────────────────────────────────────────
                  if (link != null &&
                      (status == 'sent' ||
                          status == 'viewed' ||
                          status == 'overdue')) ...[
                    _OutlineActionBtn(
                      label: 'Share via WhatsApp',
                      icon: Icons.chat_rounded,
                      onTap: () async {
                        final name =
                            (inv['clientName'] as String?) ?? 'there';
                        final phone =
                            (inv['clientPhone'] as String?) ?? '';
                        final msg =
                            'Hi $name, please find your invoice here: $link';
                        final url = phone.isNotEmpty
                            ? 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}'
                            : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Primary actions ──────────────────────────────────────
                  if (status == 'draft') ...[
                    _PrimaryActionBtn(
                      label: 'Send Invoice',
                      loading: _sending,
                      onTap: _sending ? null : () => _send(id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (status == 'sent' ||
                      status == 'viewed' ||
                      status == 'overdue') ...[
                    _PrimaryActionBtn(
                      label: 'Mark as Paid',
                      loading: _marking,
                      onTap: _marking ? null : () => _markPaid(id),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Cancel ───────────────────────────────────────────────
                  if (status != 'paid' && status != 'cancelled') ...[
                    _OutlineActionBtn(
                      label: 'Cancel Invoice',
                      icon: Icons.cancel_outlined,
                      danger: true,
                      loading: _cancelling,
                      onTap: _cancelling ? null : () => _cancel(id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
      ),
      child: child,
    );
  }
}

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
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withOpacity(0.45))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalsRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                color: bold
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w500)),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: GoogleFonts.bricolageGrotesque(
            fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: cs.onSurface.withOpacity(0.55)),
      ),
    );
  }
}

class _PrimaryActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryActionBtn(
      {required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
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
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: cs.surface))
            : Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutlineActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final bool loading;
  final VoidCallback? onTap;
  const _OutlineActionBtn({
    required this.label,
    required this.icon,
    this.danger = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color =
        danger ? DayFiColors.red : cs.onSurface.withOpacity(0.65);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
              color: danger
                  ? DayFiColors.red.withOpacity(0.4)
                  : cs.onSurface.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onTap,
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color))
            : Icon(icon, size: 16),
        label: loading
            ? const SizedBox.shrink()
            : Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color)),
      ),
    );
  }
}