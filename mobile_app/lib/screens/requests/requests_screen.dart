// lib/screens/requests/requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class PaymentRequest {
  final String id;
  final String requestNumber;
  final double amount;
  final String asset;
  final String? note;
  final String? payerName;
  final String? payerEmail;
  final String? paymentLink;
  final String status;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const PaymentRequest({
    required this.id,
    required this.requestNumber,
    required this.amount,
    required this.asset,
    this.note,
    this.payerName,
    this.payerEmail,
    this.paymentLink,
    required this.status,
    this.paidAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> j) => PaymentRequest(
    id: j['id'] ?? '',
    requestNumber: j['requestNumber'] ?? '',
    amount: (j['amount'] ?? 0).toDouble(),
    asset: j['asset'] ?? 'USDC',
    note: j['note'],
    payerName: j['payerName'],
    payerEmail: j['payerEmail'],
    paymentLink: j['paymentLink'],
    status: j['status'] ?? 'pending',
    paidAt: j['paidAt'] != null ? DateTime.tryParse(j['paidAt']) : null,
    expiresAt: j['expiresAt'] != null
        ? DateTime.tryParse(j['expiresAt'])
        : null,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  String get assetSymbol => asset == 'NGNT' ? '₦' : '\$';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _requestsProvider = FutureProvider.autoDispose<List<PaymentRequest>>((
  ref,
) async {
  final result = await apiService.getRequests(limit: 100);
  return (result['requests'] as List)
      .map((r) => PaymentRequest.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String _filter = 'all'; // all | pending | paid | expired

  @override
  Widget build(BuildContext context) {
    final reqAsync = ref.watch(_requestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e.toString()),
        data: (requests) => _buildBody(context, requests),
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
          onTap: () => _showCreateSheet(context),
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

  Widget _buildError(BuildContext context, String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load requests',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(_requestsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<PaymentRequest> all) {
    final filtered = _filter == 'all'
        ? all
        : all.where((r) => r.status == _filter).toList();

    final totalPending = all
        .where((r) => r.isPending)
        .fold<double>(0, (s, r) => s + r.amount);
    final totalPaid = all
        .where((r) => r.isPaid)
        .fold<double>(0, (s, r) => s + r.amount);

    if (all.isEmpty) return _EmptyState(onTap: () => _showCreateSheet(context));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_requestsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        children: [
          // Summary
          _SummaryRow(
            pending: all.where((r) => r.isPending).length,
            paid: all.where((r) => r.isPaid).length,
            totalPending: totalPending,
            totalPaid: totalPaid,
          ),
          const SizedBox(height: 20),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'pending', 'paid', 'expired', 'cancelled']
                  .map(
                    (f) => _FilterChip(
                      label: '${f[0].toUpperCase()}${f.substring(1)}',
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No ${_filter == 'all' ? '' : _filter} requests',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            )
          else
            ...filtered.map(
              (r) => _RequestTile(
                request: r,
                onTap: () => _showDetailSheet(context, r),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CreateRequestSheet(
        onCreated: () => ref.invalidate(_requestsProvider),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, PaymentRequest r) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _RequestDetailSheet(
        request: r,
        onRefresh: () => ref.invalidate(_requestsProvider),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int pending, paid;
  final double totalPending, totalPaid;
  const _SummaryRow({
    required this.pending,
    required this.paid,
    required this.totalPending,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Pending',
            count: pending,
            value: '\$${_fmt(totalPending)}',
            color: const Color(0xFFFFA726),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Collected',
            count: paid,
            value: '\$${_fmt(totalPaid)}',
            color: DayFiColors.green,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final int count;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.bricolageGrotesque(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.bricolageGrotesque(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

// ─── Request tile ─────────────────────────────────────────────────────────────

class _RequestTile extends StatelessWidget {
  final PaymentRequest request;
  final VoidCallback onTap;
  const _RequestTile({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final r = request;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: ext.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.cardBorder, width: .5),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _statusColor(r.status).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon(r.status),
                size: 20,
                color: _statusColor(r.status),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.payerName != null && r.payerName!.isNotEmpty
                        ? 'From ${r.payerName}'
                        : r.requestNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ext.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.note != null && r.note!.isNotEmpty
                        ? r.note!
                        : DateFormat('MMM d, yyyy').format(r.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      color: ext.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${r.assetSymbol}${NumberFormat('#,##0.00').format(r.amount)}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: r.isPaid ? DayFiColors.green : ext.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusPill(status: r.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':
        return DayFiColors.green;
      case 'pending':
        return const Color(0xFFFFA726);
      case 'expired':
        return DayFiColors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return const Color(0xFF6C47FF);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.request_quote_rounded;
    }
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'paid':
        return DayFiColors.green;
      case 'pending':
        return const Color(0xFFFFA726);
      case 'expired':
        return DayFiColors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return const Color(0xFF6C47FF);
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More request help content is coming soon.')),
    );
  }

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
                      'request money from clients instantly',
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
                            onPressed: onTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'NEW CREATE',
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
                            onPressed: () => _showComingSoon(context),
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

// ─── Create request sheet ─────────────────────────────────────────────────────

class _CreateRequestSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateRequestSheet({required this.onCreated});

  @override
  ConsumerState<_CreateRequestSheet> createState() =>
      _CreateRequestSheetState();
}

class _CreateRequestSheetState extends ConsumerState<_CreateRequestSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _payerCtrl = TextEditingController();
  final _payerEmail = TextEditingController();

  String _asset = 'USDC';
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _payerCtrl.dispose();
    _payerEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      _snack('Enter a valid amount');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await apiService.createRequest({
        'amount': amt,
        'asset': _asset,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'payerName': _payerCtrl.text.trim().isEmpty
            ? null
            : _payerCtrl.text.trim(),
        'payerEmail': _payerEmail.text.trim().isEmpty
            ? null
            : _payerEmail.text.trim(),
      });

      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        // Show the link right away
        final link = result['request']?['paymentLink'] as String?;
        if (link != null) {
          showDayFiBottomSheet(
            context: context,
            child: _LinkRevealSheet(link: link, amount: amt, asset: _asset),
          );
        }
      }
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Request Payment',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ext.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A payment link will be generated to share with your client',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 20),

          // Amount + asset
          _Label('Amount'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _amountCtrl,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _SegmentPicker(
                options: const ['USDC', 'NGNT'],
                selected: _asset,
                onChanged: (v) => setState(() => _asset = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payer name
          _Label('Payer name (optional)'),
          const SizedBox(height: 6),
          _Field(controller: _payerCtrl, hint: 'e.g. Adebayo Motors Ltd'),
          const SizedBox(height: 16),

          // Payer email
          _Label('Payer email (optional)'),
          const SizedBox(height: 6),
          _Field(
            controller: _payerEmail,
            hint: 'client@company.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Note
          _Label('Note (optional)'),
          const SizedBox(height: 6),
          _Field(
            controller: _noteCtrl,
            hint: 'e.g. Payment for October consulting',
            maxLines: 2,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Generate Payment Link',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Link reveal sheet ────────────────────────────────────────────────────────

class _LinkRevealSheet extends StatelessWidget {
  final String link;
  final double amount;
  final String asset;
  const _LinkRevealSheet({
    required this.link,
    required this.amount,
    required this.asset,
  });

  Future<void> _shareText(BuildContext context, String text) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      await Share.share(
        text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
      return;
    }
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = asset == 'NGNT' ? '₦' : '\$';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.link_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Payment link ready!',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$symbol${NumberFormat('#,##0.00').format(amount)} $asset',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Link box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _shareText(
                    context,
                    'Please pay me $symbol${NumberFormat('#,##0.00').format(amount)} $asset via this link:\n$link',
                  ),
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Share',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Request detail sheet ─────────────────────────────────────────────────────

class _RequestDetailSheet extends StatefulWidget {
  final PaymentRequest request;
  final VoidCallback onRefresh;
  const _RequestDetailSheet({required this.request, required this.onRefresh});

  @override
  State<_RequestDetailSheet> createState() => _RequestDetailSheetState();
}

class _RequestDetailSheetState extends State<_RequestDetailSheet> {
  bool _marking = false;
  bool _cancelling = false;
  bool _editing = false;

  Future<void> _shareText(String text) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      await Share.share(
        text,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
      return;
    }
    await Share.share(text);
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _markPaid() async {
    if (!await _confirm('Mark as paid?', 'Confirm this request is now paid.')) return;
    setState(() => _marking = true);
    try {
      await apiService.markRequestPaid(widget.request.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _cancel() async {
    if (!await _confirm('Cancel request?', 'This action cannot be undone.')) return;
    setState(() => _cancelling = true);
    try {
      await apiService.cancelRequest(widget.request.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _edit() async {
    setState(() => _editing = true);
    try {
      final updated = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditRequestSheet(request: widget.request),
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
    final r = widget.request;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Request',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount
          Text(
            '${r.assetSymbol}${NumberFormat('#,##0.00').format(r.amount)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            r.asset,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 12),
          _StatusPill(status: r.status),
          const SizedBox(height: 20),

          // Details
          _DetailRow(label: 'Reference', value: r.requestNumber),
          if (r.payerName != null)
            _DetailRow(label: 'From', value: r.payerName!),
          if (r.payerEmail != null)
            _DetailRow(label: 'Email', value: r.payerEmail!),
          if (r.note != null) _DetailRow(label: 'Note', value: r.note!),
          _DetailRow(
            label: 'Created',
            value: DateFormat('MMM d, yyyy').format(r.createdAt),
          ),
          if (r.paidAt != null)
            _DetailRow(
              label: 'Paid at',
              value: DateFormat('MMM d, yyyy').format(r.paidAt!),
            ),
          if (r.expiresAt != null)
            _DetailRow(
              label: 'Expires',
              value: DateFormat('MMM d, yyyy').format(r.expiresAt!),
            ),

          // Share link
          if (r.paymentLink != null && r.isPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.paymentLink!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: r.paymentLink!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _shareText(
                      'Please pay ${r.assetSymbol}${NumberFormat('#,##0.00').format(r.amount)} ${r.asset}:\n${r.paymentLink}',
                    ),
                    child: Icon(
                      Icons.share_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/requests/pay/${r.requestNumber}');
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open pay page'),
              ),
            ),
          ],

          // Actions
          if (r.isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _editing ? null : _edit,
                    child: _editing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Edit',
                            style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _cancelling ? null : _cancel,
                    child: _cancelling
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DayFiColors.red,
                            ),
                          )
                        : Text(
                            'Cancel',
                            style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w600,
                              color: DayFiColors.red,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DayFiColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _marking ? null : _markPaid,
                    child: _marking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Mark as Paid',
                            style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.bricolageGrotesque(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }
}

class _SegmentPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isSel = o == selected;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSel
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              o,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                color: isSel
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EditRequestSheet extends StatefulWidget {
  final PaymentRequest request;
  const _EditRequestSheet({required this.request});

  @override
  State<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<_EditRequestSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _payerCtrl;
  late final TextEditingController _payerEmailCtrl;
  late String _asset;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.request.amount.toStringAsFixed(2));
    _noteCtrl = TextEditingController(text: widget.request.note ?? '');
    _payerCtrl = TextEditingController(text: widget.request.payerName ?? '');
    _payerEmailCtrl = TextEditingController(text: widget.request.payerEmail ?? '');
    _asset = widget.request.asset;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _payerCtrl.dispose();
    _payerEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await apiService.updateRequest(widget.request.id, {
        'amount': amount,
        'asset': _asset,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'payerName': _payerCtrl.text.trim().isEmpty ? null : _payerCtrl.text.trim(),
        'payerEmail': _payerEmailCtrl.text.trim().isEmpty ? null : _payerEmailCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, res['request'] as Map<String, dynamic>? ?? {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Request', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _Label('Amount'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _amountCtrl,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _SegmentPicker(
                options: const ['USDC', 'NGNT'],
                selected: _asset,
                onChanged: (v) => setState(() => _asset = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Label('Payer name'),
          const SizedBox(height: 6),
          _Field(controller: _payerCtrl, hint: 'Client name'),
          const SizedBox(height: 12),
          _Label('Payer email'),
          const SizedBox(height: 6),
          _Field(controller: _payerEmailCtrl, hint: 'client@company.com'),
          const SizedBox(height: 12),
          _Label('Note'),
          const SizedBox(height: 6),
          _Field(controller: _noteCtrl, hint: 'Reason', maxLines: 2),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
