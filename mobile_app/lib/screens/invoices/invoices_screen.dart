// lib/screens/invoices/invoices_screen.dart
//
// Features:
//   - List all invoices with status pills (draft/sent/viewed/paid/overdue)
//   - Create invoice: title, client, line items, VAT toggle, due date,
//     payment type (NGNT on-chain | bank transfer | both), recurring
//   - Send invoice → generates shareable payment link
//   - Tap invoice → detail sheet with copy/share link

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

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
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _buildError(context, ref, e.toString()),
        data:    (invoices) => _buildList(context, ref, invoices),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoice(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Invoice',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Failed to load invoices', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.invalidate(invoicesProvider),
          child: const Text('Retry'),
        ),
      ]),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<Map<String, dynamic>> invoices) {
    if (invoices.isEmpty) {
      return _EmptyState(onCreateTap: () => _showCreateInvoice(context, ref));
    }

    // Group by status
    final groups = <String, List<Map<String, dynamic>>>{
      'overdue': [],
      'sent':    [],
      'viewed':  [],
      'paid':    [],
      'draft':   [],
    };
    for (final inv in invoices) {
      final status = (inv['status'] as String?) ?? 'draft';
      groups[status] ??= [];
      groups[status]!.add(inv);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(invoicesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        children: [
          // Summary chips
          _SummaryRow(invoices: invoices),
          const SizedBox(height: 20),

          for (final entry in groups.entries) ...[
            if (entry.value.isNotEmpty) ...[
              _SectionHeader(status: entry.key, count: entry.value.length),
              const SizedBox(height: 8),
              ...entry.value.map((inv) => _InvoiceTile(
                    invoice: inv,
                    onTap: () => _showInvoiceDetail(context, ref, inv),
                  )),
              const SizedBox(height: 16),
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
      child: _CreateInvoiceSheet(
        onCreated: () => ref.invalidate(invoicesProvider),
      ),
    );
  }

  // ── Invoice detail ─────────────────────────────────────────────────────────

  void _showInvoiceDetail(
      BuildContext context, WidgetRef ref, Map<String, dynamic> inv) {
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

class _SummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  const _SummaryRow({required this.invoices});

  @override
  Widget build(BuildContext context) {
    double totalPaid    = 0;
    double totalPending = 0;
    int    overdueCount = 0;

    for (final inv in invoices) {
      final amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
      final status = (inv['status'] as String?) ?? '';
      if (status == 'paid')                        totalPaid    += amount;
      if (status == 'sent' || status == 'viewed')  totalPending += amount;
      if (status == 'overdue')                     overdueCount++;
    }

    return Row(children: [
      Expanded(child: _SummaryCard(
        label: 'Total Paid',
        value: '₦${_fmt(totalPaid)}',
        color: DayFiColors.green,
      )),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
        label: 'Pending',
        value: '₦${_fmt(totalPending)}',
        color: const Color(0xFFFFA726),
      )),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
        label: 'Overdue',
        value: overdueCount.toString(),
        color: DayFiColors.red,
      )),
    ]);
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color, fontSize: 11, fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 18,
            )),
      ]),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String status;
  final int count;
  const _SectionHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatusPill(status: status),
      const SizedBox(width: 8),
      Text('$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
          )),
    ]);
  }
}

// ─── Invoice tile ─────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status      = (invoice['status'] as String?) ?? 'draft';
    final total       = (invoice['totalAmount'] as num?)?.toDouble() ?? 0;
    final currency    = (invoice['currency'] as String?) ?? 'NGNT';
    final clientName  = (invoice['clientName'] as String?) ?? '—';
    final invoiceNum  = (invoice['invoiceNumber'] as String?) ?? '';
    final title       = (invoice['title'] as String?) ?? 'Invoice';
    final dueDate     = invoice['dueDate'] != null
        ? DateTime.tryParse(invoice['dueDate'])
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .textTheme
              .bodySmall
              ?.color
              ?.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoiceNum,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 11,
                  )),
              const SizedBox(height: 2),
              Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 14,
                  )),
              Text(clientName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  )),
              if (dueDate != null) ...[
                const SizedBox(height: 4),
                Text('Due ${DateFormat('MMM d, yyyy').format(dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: status == 'overdue'
                          ? DayFiColors.red
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    )),
              ],
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              currency == 'USDC'
                  ? '\$${total.toStringAsFixed(2)}'
                  : '₦${total.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            _StatusPill(status: status),
          ]),
        ]),
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
      case 'paid':     return DayFiColors.green;
      case 'sent':     return const Color(0xFF2775CA);
      case 'viewed':   return const Color(0xFF9C27B0);
      case 'overdue':  return DayFiColors.red;
      case 'draft':    return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
      default:         return Theme.of(context).colorScheme.primary;
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
          color: c, fontSize: 11, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Create invoice sheet ─────────────────────────────────────────────────────

class _CreateInvoiceSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateInvoiceSheet({required this.onCreated});

  @override
  State<_CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends State<_CreateInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();

  // Fields
  final _titleController       = TextEditingController();
  final _clientNameController  = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _descController        = TextEditingController();

  String _currency      = 'NGNT';
  String _paymentType   = 'crypto';      // crypto | bankTransfer | both
  bool   _vatEnabled    = false;
  double _vatRate       = 7.5;
  bool   _isRecurring   = false;
  String _recurringInterval = 'monthly';
  DateTime? _dueDate;
  bool _loading = false;

  // Line items
  final List<_LineItem> _lineItems = [_LineItem()];

  double get _subtotal => _lineItems.fold(0, (s, i) => s + i.total);
  double get _vatAmount => _vatEnabled ? _subtotal * (_vatRate / 100) : 0;
  double get _total     => _subtotal + _vatAmount;

  @override
  void dispose() {
    _titleController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _descController.dispose();
    for (final i in _lineItems) { i.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lineItems.isEmpty || _lineItems.every((i) => i.total == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await apiService.createInvoice({
        'title':       _titleController.text.trim(),
        'clientName':  _clientNameController.text.trim(),
        'clientEmail': _clientEmailController.text.trim().isEmpty
            ? null
            : _clientEmailController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'lineItems':   _lineItems.map((i) => i.toJson()).toList(),
        'subtotal':    _subtotal,
        'vatAmount':   _vatAmount,
        'totalAmount': _total,
        'currency':    _currency,
        'paymentType': _paymentType,
        'vatEnabled':  _vatEnabled,
        'vatRate':     _vatRate,
        'isRecurring': _isRecurring,
        if (_isRecurring) 'recurringInterval': _recurringInterval,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiService.parseError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
    ),
    filled: true,
    fillColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.93,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, scrollCtrl) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('New Invoice',
                    style: Theme.of(context).textTheme.titleLarge),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Invoice title ──────────────────────────────────────────
              _Label('Invoice title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _dec('e.g. Web Design Services'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Client ─────────────────────────────────────────────────
              _Label('Client name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientNameController,
                decoration: _dec('Client or company name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientEmailController,
                decoration: _dec('Client email (optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // ── Currency & payment type ────────────────────────────────
              _Label('Currency & Payment type'),
              const SizedBox(height: 8),
              Row(children: [
                _SegmentButton(
                  label: 'NGN (NGNT)', selected: _currency == 'NGNT',
                  onTap: () => setState(() => _currency = 'NGNT'),
                ),
                const SizedBox(width: 8),
                _SegmentButton(
                  label: 'USD (USDC)', selected: _currency == 'USDC',
                  onTap: () => setState(() => _currency = 'USDC'),
                ),
              ]),
              const SizedBox(height: 8),
              // Payment method
              Row(children: [
                _SegmentButton(
                  label: 'On-chain', selected: _paymentType == 'crypto',
                  onTap: () => setState(() => _paymentType = 'crypto'),
                ),
                const SizedBox(width: 8),
                _SegmentButton(
                  label: 'Bank transfer', selected: _paymentType == 'bankTransfer',
                  onTap: () => setState(() => _paymentType = 'bankTransfer'),
                ),
                const SizedBox(width: 8),
                _SegmentButton(
                  label: 'Both', selected: _paymentType == 'both',
                  onTap: () => setState(() => _paymentType = 'both'),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Line items ─────────────────────────────────────────────
              _Label('Line items'),
              const SizedBox(height: 8),
              ..._lineItems.asMap().entries.map((e) => _LineItemRow(
                    item: e.value,
                    currency: _currency,
                    onChanged: () => setState(() {}),
                    onRemove: _lineItems.length > 1
                        ? () => setState(() => _lineItems.removeAt(e.key))
                        : null,
                  )),
              TextButton.icon(
                onPressed: () => setState(() => _lineItems.add(_LineItem())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add line item'),
              ),
              const SizedBox(height: 16),

              // ── VAT ────────────────────────────────────────────────────
              Row(children: [
                Expanded(child: Text('VAT (7.5%)',
                    style: Theme.of(context).textTheme.bodyMedium)),
                Switch(
                  value: _vatEnabled,
                  onChanged: (v) => setState(() => _vatEnabled = v),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Totals ─────────────────────────────────────────────────
              _TotalsCard(
                subtotal: _subtotal,
                vatAmount: _vatAmount,
                total: _total,
                currency: _currency,
              ),
              const SizedBox(height: 16),

              // ── Due date ───────────────────────────────────────────────
              _Label('Due date (optional)'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _dueDate != null
                          ? DateFormat('MMM d, yyyy').format(_dueDate!)
                          : 'Select due date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _dueDate != null
                            ? null
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close_rounded, size: 16),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── Recurring ──────────────────────────────────────────────
              Row(children: [
                Expanded(child: Text('Recurring invoice',
                    style: Theme.of(context).textTheme.bodyMedium)),
                Switch(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
              ]),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                Row(children: ['weekly', 'monthly', 'quarterly', 'annually']
                    .map((interval) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SegmentButton(
                            label: interval[0].toUpperCase() + interval.substring(1),
                            selected: _recurringInterval == interval,
                            onTap: () => setState(() => _recurringInterval = interval),
                          ),
                        ))
                    .toList()),
              ],
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Create Invoice',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Line item model ──────────────────────────────────────────────────────────

class _LineItem {
  final descCtrl  = TextEditingController();
  final qtyCtrl   = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  double get qty   => double.tryParse(qtyCtrl.text)   ?? 0;
  double get price => double.tryParse(priceCtrl.text)  ?? 0;
  double get total => qty * price;

  Map<String, dynamic> toJson() => {
    'description': descCtrl.text.trim(),
    'quantity':    qty,
    'unitPrice':   price,
    'total':       total,
  };

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _LineItemRow extends StatelessWidget {
  final _LineItem item;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _LineItemRow({
    required this.item,
    required this.currency,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = currency == 'USDC' ? '\$' : '₦';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: item.descCtrl,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          // Qty
          SizedBox(
            width: 50,
            child: TextField(
              controller: item.qtyCtrl,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Qty',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          const Text(' × ', style: TextStyle(fontSize: 13)),
          // Unit price
          Expanded(
            child: TextField(
              controller: item.priceCtrl,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '${prefix}Unit price',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$prefix${item.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600, fontSize: 13,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Totals card ──────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final double subtotal, vatAmount, total;
  final String currency;
  const _TotalsCard({required this.subtotal, required this.vatAmount,
      required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    final sym = currency == 'USDC' ? '\$' : '₦';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        _TotalRow(label: 'Subtotal', value: '$sym${subtotal.toStringAsFixed(2)}'),
        if (vatAmount > 0) ...[
          const SizedBox(height: 6),
          _TotalRow(label: 'VAT (7.5%)', value: '$sym${vatAmount.toStringAsFixed(2)}'),
        ],
        const Divider(height: 16),
        _TotalRow(
          label: 'Total',
          value: '$sym${total.toStringAsFixed(2)}',
          bold: true,
        ),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            )),
      ],
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

  Future<void> _sendInvoice() async {
    setState(() => _sending = true);
    try {
      await apiService.sendInvoice(widget.invoice['id'] as String);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiService.parseError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv         = widget.invoice;
    final status      = (inv['status'] as String?) ?? 'draft';
    final paymentLink = inv['paymentLink'] as String?;
    final currency    = (inv['currency'] as String?) ?? 'NGNT';
    final total       = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    final sym         = currency == 'USDC' ? '\$' : '₦';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Invoice', style: Theme.of(context).textTheme.titleLarge),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
        ]),
        const SizedBox(height: 20),

        // Amount
        Text('$sym${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w300, letterSpacing: -2,
            )),
        const SizedBox(height: 8),
        _StatusPill(status: status),
        const SizedBox(height: 20),

        // Details
        _DetailRow(label: 'Invoice #', value: inv['invoiceNumber'] ?? ''),
        _DetailRow(label: 'Client',    value: inv['clientName'] ?? ''),
        _DetailRow(label: 'Currency',  value: currency),
        if (inv['dueDate'] != null)
          _DetailRow(
            label: 'Due date',
            value: DateFormat('MMM d, yyyy')
                .format(DateTime.parse(inv['dueDate'] as String)),
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
            child: Row(children: [
              Expanded(
                child: Text(paymentLink,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
                onTap: () => Share.share(
                  'Pay my invoice here: $paymentLink',
                ),
                child: const Icon(Icons.share_rounded, size: 16),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Actions
        if (status == 'draft') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width, 48),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _sending ? null : _sendInvoice,
              child: _sending
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Send Invoice'),
            ),
          ),
        ],
      ]),
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
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              )),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ));
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            )),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
        const SizedBox(height: 16),
        Text('No invoices yet',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text('Create your first invoice to get paid',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            )),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onCreateTap,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Invoice'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ]),
    );
  }
}