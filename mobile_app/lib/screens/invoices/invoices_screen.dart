// lib/screens/invoices/invoices_screen.dart
//
// Web-first two-column layout:
//   Left  — invoice insights (metrics + chart + period selector)
//   Right — invoice list grouped by status
//
// Modal — centered 520px glass card, fixed 80vh height, scrollable.
//   Create flow navigates internally across 3 steps with fade transitions.
//   apiService & invoiceItemLibraryProvider calls are untouched.

import 'dart:ui';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/providers/invoice_item_library_provider.dart';
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
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFab(context, ref),
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 118, 0, 100),
                child: invoicesAsync.when(
                  loading: () => const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _buildError(context, ref, e.toString()),
                  data: (invoices) => _buildBody(context, ref, invoices),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      width: 60,
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
        onTap: () => _showInvoiceModal(context, ref),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.plus,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return SizedBox(
      height: 300,
      child: Center(
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
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> invoices,
  ) {
    if (invoices.isEmpty) {
      return _EmptyState(onTapCreate: () => _showInvoiceModal(context, ref));
    }

    // Group invoices by status
    const order = ['overdue', 'sent', 'viewed', 'draft', 'paid'];
    final groups = <String, List<Map<String, dynamic>>>{
      for (final s in order) s: [],
    };
    for (final inv in invoices) {
      final status = (inv['status'] as String?) ?? 'draft';
      (groups[status] ??= []).add(inv);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Insights ────────────────────────────────────────────────
        Expanded(child: _InsightsPanel(invoices: invoices)),
        const SizedBox(width: 16),
        // ── Right: Invoice list ───────────────────────────────────────────
        Expanded(
          child: _InvoiceListPanel(
            groups: groups,
            order: order,
            onTapInvoice: (inv) => _showDetailModal(context, ref, inv),
            onCreateTap: () => _showInvoiceModal(context, ref),
          ),
        ),
      ],
    );
  }

  void _showInvoiceModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => _GlassModal(
        child: _CreateInvoiceFlow(
          onCreated: () {
            ref.invalidate(invoicesProvider);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> inv,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => _GlassModal(
        child: _InvoiceDetailContent(
          invoice: inv,
          onRefresh: () {
            ref.invalidate(invoicesProvider);
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// ─── Glass modal ──────────────────────────────────────────────────────────────

class _GlassModal extends StatefulWidget {
  final Widget child;
  const _GlassModal({required this.child});

  @override
  State<_GlassModal> createState() => _GlassModalState();
}

class _GlassModalState extends State<_GlassModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetFill = isDark
        ? DayFiColors.surface.withOpacity(0.88)
        : DayFiColors.lightSurface.withOpacity(0.90);
    final borderColor = isDark
        ? DayFiColors.border.withOpacity(0.7)
        : DayFiColors.lightBorder.withOpacity(0.85);
    final scrimColor = isDark
        ? DayFiColors.background.withOpacity(0.55)
        : DayFiColors.lightBackground.withOpacity(0.45);

    return AnimatedBuilder(
      animation: _fade,
      builder: (ctx, _) {
        final t = _fade.value;
        return Stack(
          children: [
            // Blur + scrim backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                  child: Container(
                    color: scrimColor.withOpacity(scrimColor.opacity * t),
                  ),
                ),
              ),
            ),
            // Centered modal card
            Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.96 + 0.04 * t,
                  child: GestureDetector(
                    onTap: () {}, // absorb taps so backdrop doesn't close
                    child: SizedBox(
                      width: 520,
                      height: MediaQuery.of(context).size.height * 0.80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: sheetFill,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: borderColor,
                                width: 0.75,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.45 : 0.10,
                                  ),
                                  blurRadius: 48,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Create invoice flow (3 steps, internal fade transitions) ─────────────────

class _CreateInvoiceFlow extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateInvoiceFlow({required this.onCreated});

  @override
  ConsumerState<_CreateInvoiceFlow> createState() => _CreateInvoiceFlowState();
}

class _CreateInvoiceFlowState extends ConsumerState<_CreateInvoiceFlow>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0,1,2
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Shared draft state
  // Sheet 1
  final _titleCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();

  // Sheet 2
  late List<_ModalLineItem> _lineItems;
  bool _vatEnabled = false;
  static const _vatRate = 7.5;

  // Sheet 3
  String _currency = 'NGNT';
  String _paymentType = 'crypto';
  DateTime? _dueDate;
  bool _isRecurring = false;
  String _recurringInterval = 'monthly';
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  // Autocomplete
  List<Map<String, dynamic>> _suggestions = [];
  static const _pastClients = [
    {'name': 'Acme Corp', 'email': 'billing@acme.com'},
    {'name': 'Lagos Ventures', 'email': 'pay@lagosventures.ng'},
    {'name': 'Kemi Adeola', 'email': 'kemi@adeola.co'},
    {'name': 'Skyline Media', 'email': 'accounts@skylinemedia.ng'},
  ];

  double get _subtotal => _lineItems.fold(0, (s, i) => s + i.total);
  double get _vatAmount => _vatEnabled ? _subtotal * (_vatRate / 100) : 0;
  double get _total => _subtotal + _vatAmount;

  @override
  void initState() {
    super.initState();
    _lineItems = [_ModalLineItem()];
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _descCtrl.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await _fadeCtrl.reverse();
    setState(() => _step = step);
    await _fadeCtrl.forward();
  }

  void _nextStep1() {
    if (!_formKey1.currentState!.validate()) return;
    _goTo(1);
  }

  void _nextStep2() {
    if (_lineItems.isEmpty || _lineItems.every((i) => i.total == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item with an amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _goTo(2);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _titleCtrl.text.trim(),
        'clientName': _clientNameCtrl.text.trim(),
        if (_clientEmailCtrl.text.trim().isNotEmpty)
          'clientEmail': _clientEmailCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'lineItems': _lineItems
            .map(
              (i) => {
                'description': i.descCtrl.text.trim(),
                'quantity': i.qty,
                'unitPrice': i.price,
                'total': i.total,
              },
            )
            .toList(),
        'subtotal': _subtotal,
        'vatAmount': _vatAmount,
        'totalAmount': _total,
        'currency': _currency,
        'paymentType': _paymentType,
        'vatEnabled': _vatEnabled,
        'vatRate': _vatRate,
        'isRecurring': _isRecurring,
        if (_isRecurring) 'recurringInterval': _recurringInterval,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      };
      await apiService.createInvoice(payload);
      if (mounted) {
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invoice created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onClientChanged(String val) {
    setState(() {
      _suggestions = val.length < 2
          ? []
          : _pastClients
                .where(
                  (c) => (c['name'] as String).toLowerCase().contains(
                    val.toLowerCase(),
                  ),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Modal header ────────────────────────────────────────────────────
        _ModalHeader(
          step: _step,
          onBack: _step > 0 ? () => _goTo(_step - 1) : null,
          onClose: () => Navigator.of(context).pop(),
        ),
        // ── Step indicator ──────────────────────────────────────────────────
        _StepIndicator(current: _step, total: 3),
        // ── Content (fades between steps) ───────────────────────────────────
        Expanded(
          child: FadeTransition(opacity: _fadeAnim, child: _buildStep()),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Who & What ────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        children: [
          _FieldLabel('Invoice title'),
          TextFormField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _modalField(
              context,
              'e.g. Website Redesign – May 2025',
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          _FieldLabel('Client name'),
          TextFormField(
            controller: _clientNameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: _onClientChanged,
            decoration: _modalField(context, 'Client or company name').copyWith(
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          if (_suggestions.isNotEmpty)
            _AutocompleteDropdown(
              suggestions: _suggestions,
              onSelect: (c) {
                _clientNameCtrl.text = c['name'] as String;
                _clientEmailCtrl.text = c['email'] as String;
                setState(() => _suggestions = []);
              },
            ),
          const SizedBox(height: 12),
          _FieldLabel('Client email (optional)'),
          TextFormField(
            controller: _clientEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _modalField(context, 'client@email.com').copyWith(
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 32),
          _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep1),
        ],
      ),
    );
  }

  // ── Step 2: Line Items ────────────────────────────────────────────────────

  Widget _buildStep2() {
    final symbol = _currency == 'USDC' ? '\$' : '₦';
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.library_books_outlined,
                label: 'Item library',
                onTap: () => _showItemLibrary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _FieldLabel('Line items'),
        ..._lineItems.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return _ModalLineItemCard(
            item: item,
            symbol: symbol,
            onChanged: () => setState(() {}),
            onRemove: _lineItems.length > 1
                ? () => setState(() => _lineItems.removeAt(idx))
                : null,
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _lineItems.add(_ModalLineItem())),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
          label: const Text('Add line item'),
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          label: 'Apply VAT (7.5%)',
          value: _vatEnabled,
          onChanged: (v) => setState(() => _vatEnabled = v),
        ),
        const Divider(height: 32),
        _TotalsBlock(
          subtotal: _subtotal,
          vatAmount: _vatAmount,
          total: _total,
          vatEnabled: _vatEnabled,
          symbol: symbol,
        ),
        const SizedBox(height: 24),
        _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep2),
      ],
    );
  }

  // ── Step 3: Payment & Schedule ────────────────────────────────────────────

  Widget _buildStep3() {
    final suggestUsdc =
        _clientEmailCtrl.text.isNotEmpty &&
        !_clientEmailCtrl.text.endsWith('.ng');
    final symbol = _currency == 'USDC' ? '\$' : '₦';

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: [
        if (suggestUsdc)
          _SuggestionBanner(
            message: 'International client — consider invoicing in USDC.',
            actionLabel: 'Switch',
            onAction: () => setState(() => _currency = 'USDC'),
          ),

        _FieldLabel('Currency'),
        Row(
          children: [
            _SegmentButton(
              label: 'NGN (NGNT)',
              selected: _currency == 'NGNT',
              onTap: () => setState(() => _currency = 'NGNT'),
            ),
            const SizedBox(width: 8),
            _SegmentButton(
              label: 'USD (USDC)',
              selected: _currency == 'USDC',
              onTap: () => setState(() => _currency = 'USDC'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _FieldLabel('Payment method'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SegmentButton(
              label: 'On-chain',
              icon: Icons.link_rounded,
              selected: _paymentType == 'crypto',
              onTap: () => setState(() => _paymentType = 'crypto'),
            ),
            _SegmentButton(
              label: 'Bank transfer',
              icon: Icons.account_balance_outlined,
              selected: _paymentType == 'bankTransfer',
              onTap: () => setState(() => _paymentType = 'bankTransfer'),
            ),
            _SegmentButton(
              label: 'Both',
              icon: Icons.swap_horiz_rounded,
              selected: _paymentType == 'both',
              onTap: () => setState(() => _paymentType = 'both'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _FieldLabel('Due date'),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [7, 14, 30, 60].map((days) {
            final expected = DateTime.now().add(Duration(days: days));
            final selected =
                _dueDate != null &&
                _dueDate!.year == expected.year &&
                _dueDate!.month == expected.month &&
                _dueDate!.day == expected.day;
            return _SegmentButton(
              label: 'Net $days',
              selected: selected,
              onTap: () => setState(
                () => _dueDate = DateTime.now().add(Duration(days: days)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _DatePickerRow(
          dueDate: _dueDate,
          onPick: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 14)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (d != null) setState(() => _dueDate = d);
          },
          onClear: () => setState(() => _dueDate = null),
        ),
        const SizedBox(height: 20),

        _SwitchRow(
          label: 'Recurring invoice',
          sublabel: 'Auto-generate on a schedule',
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['weekly', 'monthly', 'quarterly', 'annually']
                .map(
                  (iv) => _SegmentButton(
                    label: iv[0].toUpperCase() + iv.substring(1),
                    selected: _recurringInterval == iv,
                    onTap: () => setState(() => _recurringInterval = iv),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),

        _FieldLabel('Notes (optional)'),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: _modalField(
            context,
            'Payment terms, bank details, thank-you message…',
          ),
        ),
        const SizedBox(height: 20),

        // Summary card
        _InvoiceSummaryCard(
          title: _titleCtrl.text.trim(),
          clientName: _clientNameCtrl.text.trim(),
          itemCount: _lineItems.length,
          total: _total,
          symbol: symbol,
          dueDate: _dueDate,
        ),
        const SizedBox(height: 24),

        _ModalPrimaryButton(
          label: 'Create Invoice',
          onTap: _submitting ? null : _submit,
          loading: _submitting,
        ),
      ],
    );
  }

  void _showItemLibrary(BuildContext context) {
    // Keeps apiService/provider calls untouched — delegates to original logic
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _GlassModal(
        child: _ItemLibraryContent(
          onSelectItem: (desc, price) {
            final item = _ModalLineItem();
            item.descCtrl.text = desc;
            item.qtyCtrl.text = '1';
            item.priceCtrl.text = price.toStringAsFixed(0);
            setState(() => _lineItems.add(item));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

// ─── Item library modal content ───────────────────────────────────────────────

class _ItemLibraryContent extends ConsumerWidget {
  final void Function(String desc, double price) onSelectItem;
  const _ItemLibraryContent({required this.onSelectItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(invoiceItemLibraryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Text(
                'Item Library',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _SmallIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: library.items.isEmpty
              ? Center(
                  child: Text(
                    'No saved items yet.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  itemCount: library.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = library.items[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.description),
                      trailing: Text(
                        '₦${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onTap: () => onSelectItem(item.description, item.price),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Invoice detail content ────────────────────────────────────────────────────

class _InvoiceDetailContent extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _InvoiceDetailContent({
    required this.invoice,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  State<_InvoiceDetailContent> createState() => _InvoiceDetailContentState();
}

class _InvoiceDetailContentState extends State<_InvoiceDetailContent> {
  bool _sending = false;
  bool _markingPaid = false;

  Future<void> _sendInvoice() async {
    setState(() => _sending = true);
    try {
      await apiService.sendInvoice(widget.invoice['id'] as String);
      widget.onRefresh();
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

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final status = (inv['status'] as String?) ?? 'draft';
    final paymentLink = inv['paymentLink'] as String?;
    final currency = (inv['currency'] as String?) ?? 'NGNT';
    final total = (inv['totalAmount'] as num?)?.toDouble() ?? 0;
    final sym = currency == 'USDC' ? '\$' : '₦';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text(
                'Invoice Detail',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              _SmallIconButton(
                icon: Icons.close_rounded,
                onTap: widget.onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            children: [
              // Amount hero
              Center(
                child: Column(
                  children: [
                    Text(
                      '$sym${total.toStringAsFixed(2)}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusPill(status: status),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Detail rows
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
              if (inv['title'] != null)
                _DetailRow(label: 'Title', value: inv['title'] as String),

              // Payment link
              if (paymentLink != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                    ),
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
                      _SmallIconButton(
                        icon: Icons.copy_rounded,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: paymentLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment link copied'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _SmallIconButton(
                        icon: Icons.share_rounded,
                        onTap: () =>
                            Share.share('Pay my invoice here: $paymentLink'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Actions
              if (status == 'draft') ...[
                _ModalPrimaryButton(
                  label: 'Send Invoice',
                  onTap: _sending ? null : _sendInvoice,
                  loading: _sending,
                ),
              ] else if (status == 'sent' ||
                  status == 'viewed' ||
                  status == 'overdue') ...[
                _ModalPrimaryButton(
                  label: 'Mark as Paid',
                  onTap: _markingPaid ? null : _markPaid,
                  loading: _markingPaid,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Insights panel (left column) ─────────────────────────────────────────────

class _InsightsPanel extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  const _InsightsPanel({required this.invoices});

  @override
  State<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<_InsightsPanel> {
  int _periodIndex = 1;
  static const _periodLabels = ['1W', '1M', 'YTD', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = _periodStart(now, _periodIndex);
    final inPeriod = widget.invoices.where((inv) {
      final createdAt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
      return createdAt == null || !createdAt.isBefore(start);
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
    final totalRevenue = paidAmount + dueAmount;
    final paidPct = totalRevenue > 0 ? (paidAmount / totalRevenue) * 100 : 0.0;
    final duePct = totalRevenue > 0 ? (dueAmount / totalRevenue) * 100 : 0.0;

    final paidSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'paid');
    final dueSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'due');
    final overdueSpots = _buildSeriesSpots(inPeriod, _periodIndex, 'overdue');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Text(
            'INSIGHTS',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),

        // ── Metrics card ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            ),
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.06),
          ),
          child: Column(
            children: [
              // Metric row
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      dotColor: const Color(0xFF598FE0),
                      label: 'Collected',
                      value: '₦${_fmt(paidAmount)}',
                      percent: paidPct,
                      accentColor: DayFiColors.green,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      dotColor: const Color(0xFFFFA726),
                      label: 'Pending',
                      value: '₦${_fmt(dueAmount)}',
                      percent: duePct,
                      accentColor: const Color(0xFFE57745),
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      dotColor: DayFiColors.red,
                      label: 'Overdue',
                      value: '₦${_fmt(overdueAmount)}',
                      percent: totalRevenue > 0
                          ? (overdueAmount / totalRevenue) * 100
                          : 0,
                      accentColor: DayFiColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Line chart
              SizedBox(
                height: 60,
                child: LineChart(
                  _summaryLineChartData(
                    paidSpots: paidSpots,
                    dueSpots: dueSpots,
                    overdueSpots: overdueSpots,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Period selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _periodLabels.asMap().entries.map((e) {
                  final selected = _periodIndex == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _periodIndex = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
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
                                ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Quick stats ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            ),
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BREAKDOWN',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 14),
              _StatRow(
                label: 'Total invoiced',
                value: '₦${_fmt(totalRevenue)}',
              ),
              _StatRow(
                label: 'Invoices sent',
                value:
                    '${inPeriod.where((i) => i['status'] != 'draft').length}',
              ),
              _StatRow(
                label: 'Avg. invoice',
                value: inPeriod.isEmpty
                    ? '—'
                    : '₦${_fmt(totalRevenue / inPeriod.length)}',
              ),
              _StatRow(
                label: 'Collection rate',
                value: totalRevenue > 0
                    ? '${paidPct.toStringAsFixed(0)}%'
                    : '—',
                accent: paidPct > 70
                    ? DayFiColors.green
                    : paidPct > 40
                    ? const Color(0xFFFFA726)
                    : DayFiColors.red,
              ),
            ],
          ),
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

// ─── Invoice list panel (right column) ────────────────────────────────────────

class _InvoiceListPanel extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groups;
  final List<String> order;
  final void Function(Map<String, dynamic>) onTapInvoice;
  final VoidCallback onCreateTap;

  const _InvoiceListPanel({
    required this.groups,
    required this.order,
    required this.onTapInvoice,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Row(
            children: [
              Text(
                'INVOICES',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCreateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final status in order) ...[
          if ((groups[status] ?? []).isNotEmpty) ...[
            _ListSectionHeader(status: status, count: groups[status]!.length),
            const SizedBox(height: 6),
            ...groups[status]!.map(
              (inv) => _InvoiceTile(
                invoice: inv,
                onTap: () => onTapInvoice(inv),
              ).animate().fadeIn(duration: 300.ms),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.step,
    required this.onBack,
    required this.onClose,
  });

  static const _titles = ['Who & What', 'Line Items', 'Payment & Schedule'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          if (onBack != null)
            _SmallIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack!,
            )
          else
            const SizedBox(width: 36),
          Expanded(
            child: Text(
              _titles[step],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          _SmallIconButton(icon: Icons.close_rounded, onTap: onClose),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i <= current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 24 : 8,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _ModalPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _ModalPrimaryButton({
    required this.label,
    this.onTap,
    this.loading = false,
  });

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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.surface,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

InputDecoration _modalField(BuildContext context, String hint) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurface.withOpacity(.35), fontSize: 14),
    filled: true,
    fillColor: cs.onSurface.withOpacity(.07),
    hoverColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error),
    ),
    isDense: true,
  );
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.onSurface.withOpacity(.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? cs.onPrimary : cs.onSurface.withOpacity(.7),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimary : cs.onSurface.withOpacity(.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.5),
                  ),
                ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  final double subtotal;
  final double vatAmount;
  final double total;
  final bool vatEnabled;
  final String symbol;

  const _TotalsBlock({
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.vatEnabled,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _TotalLine('Subtotal', subtotal, symbol),
          if (vatEnabled) _TotalLine('VAT (7.5%)', vatAmount, symbol),
          const Divider(height: 16),
          _TotalLine('Total', total, symbol, bold: true),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final bool bold;
  const _TotalLine(this.label, this.amount, this.symbol, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold
                  ? null
                  : Theme.of(context).colorScheme.onSurface.withOpacity(.55),
            ),
          ),
          const Spacer(),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutocompleteDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final void Function(Map<String, dynamic>) onSelect;

  const _AutocompleteDropdown({
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: suggestions
            .map(
              (c) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(.12),
                  child: Text(
                    (c['name'] as String)[0],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  c['name'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  c['email'] as String,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => onSelect(c),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(.09)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.onSurface.withOpacity(.7)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _SuggestionBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DatePickerRow({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: cs.onSurface.withOpacity(.5),
            ),
            const SizedBox(width: 10),
            Text(
              dueDate != null
                  ? DateFormat('MMM d, yyyy').format(dueDate!)
                  : 'Custom date',
              style: TextStyle(
                fontSize: 14,
                color: dueDate != null
                    ? cs.onSurface
                    : cs.onSurface.withOpacity(.4),
              ),
            ),
            const Spacer(),
            if (dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: cs.onSurface.withOpacity(.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final String title;
  final String clientName;
  final int itemCount;
  final double total;
  final String symbol;
  final DateTime? dueDate;

  const _InvoiceSummaryCard({
    required this.title,
    required this.clientName,
    required this.itemCount,
    required this.total,
    required this.symbol,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice summary',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(.45),
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title.isNotEmpty ? title : '—',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            clientName.isNotEmpty ? clientName : '—',
            style: TextStyle(
              color: cs.onSurface.withOpacity(.55),
              fontSize: 13,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Text(
                '$itemCount item(s)',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(.55),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$symbol${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (dueDate != null) ...[
            const SizedBox(height: 5),
            Text(
              'Due ${DateFormat('MMM d, yyyy').format(dueDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Invoice list widgets ─────────────────────────────────────────────────────

class _ListSectionHeader extends StatelessWidget {
  final String status;
  final int count;
  const _ListSectionHeader({required this.status, required this.count});

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
        margin: const EdgeInsets.only(bottom: 8, top: 2),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
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
                    const SizedBox(height: 3),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
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

// ─── Insights sub-widgets ─────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final double percent;
  final Color accentColor;

  const _MetricTile({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.percent,
    required this.accentColor,
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
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: accentColor.withOpacity(0.14),
          ),
          child: Text(
            '${percent.toStringAsFixed(0)}%',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _StatRow({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTapCreate;
  const _EmptyState({required this.onTapCreate});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: SizedBox(
        width: 480,
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No invoices yet',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your first invoice to start getting paid.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Theme.of(
                          context,
                        ).textTheme.bodySmall!.color!.withOpacity(0.1),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: onTapCreate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'NEW INVOICE',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                            color: ext.sectionHeader,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Theme.of(
                          context,
                        ).textTheme.bodySmall!.color!.withOpacity(0.1),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('https://dayfi.co'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'LEARN MORE',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
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
      ),
    );
  }
}

// ─── Modal line item model ────────────────────────────────────────────────────

class _ModalLineItem {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get total => qty * price;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ModalLineItemCard extends StatelessWidget {
  final _ModalLineItem item;
  final String symbol;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ModalLineItemCard({
    required this.item,
    required this.symbol,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.descCtrl,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    hintText: 'Item description',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(.35),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    hoverColor: Colors.transparent,
                    isDense: true,
                  ),
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: cs.onSurface.withOpacity(.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: item.qtyCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(.35),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    hoverColor: Colors.transparent,
                    isDense: true,
                    prefix: Text(
                      '×',
                      style: TextStyle(color: cs.onSurface.withOpacity(.4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.priceCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Unit price',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(.35),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    hoverColor: Colors.transparent,
                    isDense: true,
                    prefix: Text(
                      '$symbol ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(.5),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                '$symbol${item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart helpers ────────────────────────────────────────────────────────────

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
      : [7, 30, 30, 90, 30][periodIndex];
  final values = List<double>.filled(bucketCount, 0);
  final daysSpan = now.difference(start).inDays.clamp(1, 366);

  for (final inv in invoices) {
    final createdAt = DateTime.tryParse((inv['createdAt'] ?? '').toString());
    if (createdAt == null || createdAt.isBefore(start)) continue;
    final status = (inv['status'] as String?) ?? '';
    final amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0;

    if (kind == 'paid' && status != 'paid') continue;
    if (kind == 'due' && status != 'sent' && status != 'viewed') continue;
    if (kind == 'overdue' && status != 'overdue') continue;

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
  final maxVal = values.reduce((a, b) => a > b ? a : b);
  return List.generate(values.length, (i) {
    final y = maxVal == 0 ? 0.5 : (values[i] / maxVal).clamp(0.05, 1.0);
    return FlSpot(i.toDouble(), y);
  });
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
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: dueSpots,
        isCurved: true,
        color: const Color(0xFFE57745),
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      LineChartBarData(
        spots: overdueSpots,
        isCurved: true,
        color: DayFiColors.red,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ],
  );
}
