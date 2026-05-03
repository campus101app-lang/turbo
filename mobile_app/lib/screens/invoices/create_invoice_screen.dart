// lib/screens/invoices/create_invoice_screen.dart
//
// Full inline 3-step create form — no sheets, no dialogs.
// Web-style overlay dropdowns (same pattern as BusinessProfileScreen).
// Navigates back via shellNavProvider.goBack() on success.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'invoices_screen.dart' show invoicesProvider;

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const CreateInvoiceScreen({super.key, required this.insideShell});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Step 1
  final _titleCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step 2
  late List<_LineItem> _items;
  bool _vat = false;
  String _currency = 'NGNT';

  // Step 3
  String _payType = 'crypto';
  DateTime? _due;
  bool _recurring = false;
  String _interval = 'monthly';
  final _notesCtrl = TextEditingController();

  // Overlay dropdowns
  OverlayEntry? _payOverlay;
  OverlayEntry? _intervalOverlay;
  final _payKey = GlobalKey();
  final _intervalKey = GlobalKey();

  bool _savingDraft = false;
  bool _sending = false;
  bool get _busy => _savingDraft || _sending;

  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _vatAmt => _vat ? _subtotal * 0.075 : 0;
  double get _total => _subtotal + _vatAmt;

  @override
  void initState() {
    super.initState();
    _items = [_LineItem()];
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    for (final i in _items) i.dispose();
    _fadeCtrl.dispose();
    _payOverlay?.remove();
    _intervalOverlay?.remove();
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
    if (_emailCtrl.text.trim().isNotEmpty)
      'clientEmail': _emailCtrl.text.trim(),
    if (_phoneCtrl.text.trim().isNotEmpty)
      'clientPhone': _phoneCtrl.text.trim(),
    if (_notesCtrl.text.trim().isNotEmpty)
      'description': _notesCtrl.text.trim(),
    'lineItems': _items
        .map(
          (i) => {
            'description': i.desc.text.trim(),
            'quantity': i.qtyVal,
            'unitPrice': i.priceVal,
            'total': i.total,
          },
        )
        .toList(),
    'subtotal': _subtotal,
    'vatAmount': _vatAmt,
    'totalAmount': _total,
    'currency': _currency,
    'paymentType': _payType,
    'vatEnabled': _vat,
    'vatRate': 7.5,
    'isRecurring': _recurring,
    if (_recurring) 'recurringInterval': _interval,
    if (_due != null) 'dueDate': _due!.toIso8601String(),
  };

  Future<void> _draft() async {
    setState(() => _savingDraft = true);
    try {
      await apiService.createInvoice(_payload());
      ref.invalidate(invoicesProvider);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
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
      ref.invalidate(invoicesProvider);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Overlay dropdown helper ────────────────────────────────────────────────

  void _showOverlay({
    required GlobalKey anchorKey,
    required OverlayEntry? Function() getCurrent, // ← getter
    required void Function(OverlayEntry?) setter,
    required List<_DropdownOption> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    final current = getCurrent();
    if (current != null) {
      current.remove();
      setter(null);
      return;
    }
    final box = anchorKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                getCurrent()?.remove();
                setter(null);
              },
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.06),
                    ),
                    itemBuilder: (ctx, i) {
                      final opt = options[i];
                      final isSel = opt.value == selected;
                      return InkWell(
                        onTap: () {
                          onSelect(opt.value);
                          getCurrent()?.remove();
                          setter(null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              if (opt.icon != null) ...[
                                Icon(
                                  opt.icon,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSel
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSel)
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    setter(entry);
    Overlay.of(context).insert(entry);
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              onBack: _step > 0 ? () => _go(_step - 1) : null,
              onClose: () => ref.read(shellNavProvider.notifier).goBack(),
            ),
            _StepDots(current: _step, total: 3),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                    ? _buildStep2()
                    : _buildStep3(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Who & What ─────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Invoice title'),
                  _Field(
                    _titleCtrl,
                    'e.g. Website Redesign — May 2025',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _Label('Client name'),
                  _Field(
                    _clientCtrl,
                    'Client or company name',
                    prefix: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  const _Label('Client email (optional)'),
                  _Field(
                    _emailCtrl,
                    'client@email.com',
                    keyboard: TextInputType.emailAddress,
                    prefix: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  const _Label('Client phone (optional — for WhatsApp)'),
                  _Field(
                    _phoneCtrl,
                    '+234 800 000 0000',
                    keyboard: TextInputType.phone,
                    prefix: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 32),
                  _PrimaryBtn(
                    label: 'Continue',
                    onTap: () {
                      if (_formKey.currentState!.validate()) _go(1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Line Items ─────────────────────────────────────────────────────

  Widget _buildStep2() {
    final sym = _currency == 'USDC' ? '\$' : '₦';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency toggle at top of step 2
                const _Label('Currency'),
                Row(
                  children: [
                    _Chip(
                      label: 'NGN (NGNT)',
                      sel: _currency == 'NGNT',
                      onTap: () => setState(() => _currency = 'NGNT'),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: 'USD (USDC)',
                      sel: _currency == 'USDC',
                      onTap: () => setState(() => _currency = 'USDC'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Label('Line items'),
                ..._items.asMap().entries.map(
                  (e) => _LineItemCard(
                    item: e.value,
                    symbol: sym,
                    onChanged: () => setState(() {}),
                    onRemove: _items.length > 1
                        ? () => setState(() => _items.removeAt(e.key))
                        : null,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_LineItem())),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                  label: const Text('Add line item'),
                ),
                const SizedBox(height: 8),
                _SwitchRow(
                  label: 'Apply VAT (7.5%)',
                  value: _vat,
                  onChanged: (v) => setState(() => _vat = v),
                ),
                const Divider(height: 28),
                _TotalsBlock(
                  subtotal: _subtotal,
                  vat: _vatAmt,
                  total: _total,
                  vatEnabled: _vat,
                  symbol: sym,
                ),
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
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Payment & Schedule ─────────────────────────────────────────────

  Widget _buildStep3() {
    final sym = _currency == 'USDC' ? '\$' : '₦';

    final payOptions = [
      const _DropdownOption('crypto', 'On-chain', Icons.link_rounded),
      const _DropdownOption(
        'bankTransfer',
        'Bank transfer',
        Icons.account_balance_outlined,
      ),
      const _DropdownOption('both', 'Both', Icons.swap_horiz_rounded),
    ];

    final intervalOptions = [
      const _DropdownOption('weekly', 'Weekly'),
      const _DropdownOption('monthly', 'Monthly'),
      const _DropdownOption('quarterly', 'Quarterly'),
      const _DropdownOption('annually', 'Annually'),
    ];

    final selectedPay = payOptions.firstWhere((o) => o.value == _payType);
    final selectedInterval = intervalOptions.firstWhere(
      (o) => o.value == _interval,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Payment method — overlay dropdown ────────────────────
                const _Label('Payment method'),
                _DropdownField(
                  anchorKey: _payKey,
                  label: selectedPay.label,
                  icon: selectedPay.icon,
                  onTap: () => _showOverlay(
                    anchorKey: _payKey,
                    getCurrent: () => _payOverlay,
                    setter: (e) => setState(() => _payOverlay = e),
                    options: payOptions,
                    selected: _payType,
                    onSelect: (v) => setState(() => _payType = v),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Due date ─────────────────────────────────────────────
                const _Label('Due date'),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [7, 14, 30, 60].map((d) {
                    final exp = DateTime.now().add(Duration(days: d));
                    final sel =
                        _due != null &&
                        _due!.day == exp.day &&
                        _due!.month == exp.month &&
                        _due!.year == exp.year;
                    return _Chip(
                      label: 'Net $d',
                      sel: sel,
                      onTap: () => setState(
                        () => _due = DateTime.now().add(Duration(days: d)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                _DateRow(
                  due: _due,
                  onPick: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d != null) setState(() => _due = d);
                  },
                  onClear: () => setState(() => _due = null),
                ),
                const SizedBox(height: 16),

                // ── Recurring ────────────────────────────────────────────
                _SwitchRow(
                  label: 'Recurring invoice',
                  sublabel: 'Auto-generate on a schedule',
                  value: _recurring,
                  onChanged: (v) => setState(() => _recurring = v),
                ),
                if (_recurring) ...[
                  const SizedBox(height: 10),
                  const _Label('Repeat every'),
                  _DropdownField(
                    anchorKey: _intervalKey,
                    label: selectedInterval.label,
                    onTap: () => _showOverlay(
                      anchorKey: _intervalKey,
                      getCurrent: () => _intervalOverlay,
                      setter: (e) => setState(() => _intervalOverlay = e),
                      options: intervalOptions,
                      selected: _interval,
                      onSelect: (v) => setState(() => _interval = v),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Notes ────────────────────────────────────────────────
                const _Label('Notes (optional)'),
                _MultiField(
                  _notesCtrl,
                  'Payment terms, bank details, message…',
                ),
                const SizedBox(height: 16),

                // ── Summary ──────────────────────────────────────────────
                _SummaryCard(
                  title: _titleCtrl.text.trim(),
                  client: _clientCtrl.text.trim(),
                  count: _items.length,
                  total: _total,
                  symbol: sym,
                  due: _due,
                ),
                const SizedBox(height: 20),

                // ── Actions ──────────────────────────────────────────────
                Row(
                  children: [
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED FORM WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  const _Header({required this.step, this.onBack, required this.onClose});

  static const _titles = ['Who & What', 'Line Items', 'Payment & Schedule'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (onBack != null)
            _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!)
          else
            const SizedBox(width: 36),
          Expanded(
            child: Text(
              _titles[step],
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
            ),
          ),
          _IconBtn(icon: Icons.close_rounded, onTap: onClose),
        ],
      ),
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
        children: List.generate(
          total,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 22 : 7,
            height: 6,
            decoration: BoxDecoration(
              color: i <= current
                  ? cs.onSurface
                  // ignore: deprecated_member_use
                  : cs.onSurface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownOption {
  final String value, label;
  final IconData? icon;
  const _DropdownOption(this.value, this.label, [this.icon]);
}

class _DropdownField extends StatelessWidget {
  final GlobalKey anchorKey;
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _DropdownField({
    required this.anchorKey,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      key: anchorKey,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 14,
          top: 13,
          bottom: 13,
          right: 10,
        ),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: cs.onSurface.withOpacity(0.45)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: -0.1,
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              // ignore: deprecated_member_use
              color: cs.onSurface.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final IconData? prefix;
  final String? Function(String?)? validator;
  const _Field(
    this.ctrl,
    this.hint, {
    this.keyboard = TextInputType.text,
    this.prefix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(
        fontSize: 15,
        letterSpacing: -0.1,
        color: cs.onSurface.withOpacity(0.85),
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: cs.onSurface.withOpacity(0.3),
          letterSpacing: -0.1,
        ),
        prefixIcon: prefix != null
            ? Icon(prefix, size: 17, color: cs.onSurface.withOpacity(0.35))
            : null,
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
        hintStyle: TextStyle(
          fontSize: 14,
          color: cs.onSurface.withOpacity(0.3),
        ),
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.07),
        contentPadding: const EdgeInsets.all(14),
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

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _OutlineBtn({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.65),
                ),
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  final IconData? icon;
  const _Chip({
    required this.label,
    required this.sel,
    required this.onTap,
    this.icon,
  });

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: sel ? cs.surface : cs.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? cs.surface : cs.onSurface.withOpacity(0.65),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.45),
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

class _DateRow extends StatelessWidget {
  final DateTime? due;
  final VoidCallback onPick, onClear;
  const _DateRow({
    required this.due,
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
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: cs.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 10),
            Text(
              due != null
                  ? DateFormat('MMM d, yyyy').format(due!)
                  : 'Custom date',
              style: TextStyle(
                fontSize: 14,
                color: due != null
                    ? cs.onSurface
                    : cs.onSurface.withOpacity(0.4),
              ),
            ),
            const Spacer(),
            if (due != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  final double subtotal, vat, total;
  final bool vatEnabled;
  final String symbol;
  const _TotalsBlock({
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.vatEnabled,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _TLine('Subtotal', subtotal, symbol),
          if (vatEnabled) _TLine('VAT (7.5%)', vat, symbol),
          Divider(height: 16, color: cs.onSurface.withOpacity(0.08)),
          _TLine('Total', total, symbol, bold: true),
        ],
      ),
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
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold
                  ? null
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, client, symbol;
  final int count;
  final double total;
  final DateTime? due;
  const _SummaryCard({
    required this.title,
    required this.client,
    required this.count,
    required this.total,
    required this.symbol,
    required this.due,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.4),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.isNotEmpty ? title : '—',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            client.isNotEmpty ? client : '—',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          Divider(height: 16, color: cs.onSurface.withOpacity(0.08)),
          Row(
            children: [
              Text(
                '$count item${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              Text(
                '$symbol${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (due != null) ...[
            const SizedBox(height: 4),
            Text(
              'Due ${DateFormat('MMM d, yyyy').format(due!)}',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _LineItem {
  final desc = TextEditingController();
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  double get qtyVal => double.tryParse(qty.text) ?? 0;
  double get priceVal => double.tryParse(price.text) ?? 0;
  double get total => qtyVal * priceVal;
  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
  }
}

class _LineItemCard extends StatelessWidget {
  final _LineItem item;
  final String symbol;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _LineItemCard({
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
        color: cs.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.desc,
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.85),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Item description',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: cs.onSurface.withOpacity(0.35),
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
                  controller: item.qty,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.85),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    prefix: Text(
                      '×',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.35)),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.price,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.85),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Unit price',
                    prefix: Text(
                      '$symbol ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                '$symbol${item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
