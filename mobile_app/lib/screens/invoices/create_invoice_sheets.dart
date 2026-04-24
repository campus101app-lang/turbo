// lib/features/invoices/create_invoice_sheets.dart
//
// Multi-step invoice creation flow:
//   Sheet 1 → Who & What   (Cancel button)
//   Sheet 2 → Line Items   (Back button, OCR scan, item library)
//   Sheet 3 → Payment      (Back button, smart due-date chips, recurring)
//
// Usage:
//   showDayFiBottomSheet(context: context, child: CreateInvoiceSheet1(onCreated: () {}));

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_item_library_provider.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared state passed across sheets
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceDraft {
  // Sheet 1
  String title = '';
  String clientName = '';
  String clientEmail = '';

  // Sheet 2
  List<_LineItem> lineItems = [_LineItem()];
  bool vatEnabled = false;
  double vatRate = 7.5;

  // Sheet 3
  String currency = 'NGNT';
  String paymentType = 'crypto';
  DateTime? dueDate;
  bool isRecurring = false;
  String recurringInterval = 'monthly';
  String description = '';

  double get subtotal => lineItems.fold(0, (s, i) => s + i.total);
  double get vatAmount => vatEnabled ? subtotal * (vatRate / 100) : 0;
  double get total => subtotal + vatAmount;

  Map<String, dynamic> toJson() => {
        'title': title,
        'clientName': clientName,
        if (clientEmail.isNotEmpty) 'clientEmail': clientEmail,
        if (description.isNotEmpty) 'description': description,
        'lineItems': lineItems.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'vatAmount': vatAmount,
        'totalAmount': total,
        'currency': currency,
        'paymentType': paymentType,
        'vatEnabled': vatEnabled,
        'vatRate': vatRate,
        'isRecurring': isRecurring,
        if (isRecurring) 'recurringInterval': recurringInterval,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };
}

class _LineItem {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get total => qty * price;

  Map<String, dynamic> toJson() => {
        'description': descCtrl.text.trim(),
        'quantity': qty,
        'unitPrice': price,
        'total': total,
      };

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable design tokens
// ─────────────────────────────────────────────────────────────────────────────

class _DS {
  static const radius = 14.0;
  static const pagePad = EdgeInsets.fromLTRB(24, 16, 24, 40);

  static InputDecoration field(BuildContext ctx, String hint) {
    final cs = Theme.of(ctx).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(.35), fontSize: 14),
      filled: true,
      fillColor: cs.onSurface.withOpacity(.07),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _ob(),
      enabledBorder: _ob(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: _ob(color: cs.error),
      focusedErrorBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
    );
  }

  static OutlineInputBorder _ob({Color? color}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: color != null
            ? BorderSide(color: color)
            : BorderSide.none,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Top handle + title row
class _SheetHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;

  const _SheetHeader({
    required this.title,
    this.showBack = false,
    this.onBack,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          children: [
            if (showBack)
              _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.pop(context),
              )
            else
              const SizedBox(width: 40),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
            _IconBtn(
              icon: Icons.close_rounded,
              onTap: onCancel ??
                  () {
                    // Pop all sheets back to the route that opened them
                    Navigator.of(context)
                        .popUntil((r) => r.settings.name != null || r.isFirst);
                  },
            ),
          ],
        ),
      ],
    );
  }
}

/// Step progress pill  e.g. "1 of 3"
class _StepPill extends StatelessWidget {
  final int step;
  final int total;
  const _StepPill({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final active = i < step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? cs.primary
                    : cs.onSurface.withOpacity(.18),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
      );
}

class _SegBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SegBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.onSurface.withOpacity(.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? cs.onPrimary : cs.onSurface.withOpacity(.7)),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18),
        ),
      );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryBtn(
      {required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.onSurface,
            foregroundColor: cs.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: loading ? null : onTap,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.surface),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock past clients for autocomplete (replace with real API call)
// ─────────────────────────────────────────────────────────────────────────────

final _pastClients = [
  {'name': 'Acme Corp', 'email': 'billing@acme.com'},
  {'name': 'Lagos Ventures', 'email': 'pay@lagosventures.ng'},
  {'name': 'Kemi Adeola', 'email': 'kemi@adeola.co'},
  {'name': 'Skyline Media', 'email': 'accounts@skylinemedia.ng'},
];

// Note: _itemLibrary is now managed by invoiceItemLibraryProvider for local persistence

// ═════════════════════════════════════════════════════════════════════════════
// SHEET 1 — Who & What
// ═════════════════════════════════════════════════════════════════════════════

class CreateInvoiceSheet1 extends StatefulWidget {
  final VoidCallback onCreated;
  const CreateInvoiceSheet1({super.key, required this.onCreated});

  @override
  State<CreateInvoiceSheet1> createState() => _CreateInvoiceSheet1State();
}

class _CreateInvoiceSheet1State extends State<CreateInvoiceSheet1> {
  final _formKey = GlobalKey<FormState>();
  final _draft = _InvoiceDraft();

  final _titleCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();

  List<Map<String, dynamic>> _suggestions = [];

  void _onClientChanged(String val) {
    setState(() {
      _suggestions = val.length < 2
          ? []
          : _pastClients
              .where((c) =>
                  (c['name'] as String)
                      .toLowerCase()
                      .contains(val.toLowerCase()))
              .toList();
    });
  }

  void _selectClient(Map<String, dynamic> c) {
    _clientNameCtrl.text = c['name'] as String;
    _clientEmailCtrl.text = c['email'] as String;
    setState(() => _suggestions = []);
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    _draft
      ..title = _titleCtrl.text.trim()
      ..clientName = _clientNameCtrl.text.trim()
      ..clientEmail = _clientEmailCtrl.text.trim();

    // Push Sheet 2 using your showDayFiBottomSheet
    // showDayFiBottomSheet(
    //   context: context,
    //   child: CreateInvoiceSheet2(draft: _draft, onCreated: widget.onCreated),
    // );
    //
    // For now, push as a regular modal route so it compiles standalone:
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateInvoiceSheet2(
            draft: _draft, onCreated: widget.onCreated),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: _DS.pagePad,
            children: [
              _SheetHeader(
                title: 'New Invoice',
                onCancel: () => Navigator.pop(context),
              ),
              _StepPill(step: 1, total: 3),
              const SizedBox(height: 8),

              // ── Invoice title ────────────────────────────────────────────
              _Label('Invoice title'),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _DS.field(context, 'e.g. Website Redesign – May 2025'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // ── Client name + autocomplete ───────────────────────────────
              _Label('Client'),
              TextFormField(
                controller: _clientNameCtrl,
                textCapitalization: TextCapitalization.words,
                onChanged: _onClientChanged,
                decoration: _DS.field(context, 'Client or company name')
                    .copyWith(
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              // Autocomplete dropdown
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: _suggestions
                        .map(
                          (c) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(.12),
                              child: Text(
                                (c['name'] as String)[0],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            title: Text(c['name'] as String,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(c['email'] as String,
                                style: const TextStyle(fontSize: 12)),
                            onTap: () => _selectClient(c),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _clientEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _DS.field(context, 'Client email (optional)')
                    .copyWith(
                  prefixIcon:
                      const Icon(Icons.mail_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 32),

              _PrimaryBtn(label: 'Continue', onTap: _next),
            ],
          ),
        ),
      ),
    
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHEET 2 — Line Items
// ═════════════════════════════════════════════════════════════════════════════

class CreateInvoiceSheet2 extends ConsumerStatefulWidget {
  // ignore: library_private_types_in_public_api
  final _InvoiceDraft draft;
  final VoidCallback onCreated;
  const CreateInvoiceSheet2(
      {super.key, required this.draft, required this.onCreated});

  @override
  ConsumerState<CreateInvoiceSheet2> createState() => _CreateInvoiceSheet2State();
}

class _CreateInvoiceSheet2State extends ConsumerState<CreateInvoiceSheet2> {
  _InvoiceDraft get _d => widget.draft;

  bool _scanning = false;

  Future<String?> _promptReceiptText() async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import receipt text'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Paste receipt title or first line...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Import')),
        ],
      ),
    );
    ctrl.dispose();
    return value;
  }

  Future<void> _scanReceipt() async {
    setState(() => _scanning = true);
    try {
      final importedText = await _promptReceiptText();
      if (!mounted) return;
      if (importedText == null || importedText.isEmpty) {
        setState(() => _scanning = false);
        return;
      }

      // Minimal OCR pipeline: import receipt text and prefill an editable item.
      final item = _LineItem();
      item.descCtrl.text = importedText;
      item.qtyCtrl.text = '1';
      item.priceCtrl.text = '';
      setState(() {
        _d.lineItems.add(item);
        _scanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt text imported. Review item details and enter amount manually.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan receipt. Add line items manually.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showItemLibrary() {
    final library = ref.read(invoiceItemLibraryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Library',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(ctx),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (library.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No items yet. Tap + Add to create one.',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...library.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.description),
                  trailing: Text(
                    '₦${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.primary),
                  ),
                  onTap: () {
                    final lineItem = _LineItem();
                    lineItem.descCtrl.text = item.description;
                    lineItem.qtyCtrl.text = '1';
                    lineItem.priceCtrl.text = item.price.toStringAsFixed(0);
                    setState(() => _d.lineItems.add(lineItem));
                    Navigator.pop(ctx);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext ctx) {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Item to Library'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Web Design',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₦)',
                hintText: '0.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0;
              if (desc.isNotEmpty && price > 0) {
                await ref
                    .read(invoiceItemLibraryProvider.notifier)
                    .addItem(description: desc, price: price);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_d.lineItems.isEmpty ||
        _d.lineItems.every((i) => i.total == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item with an amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateInvoiceSheet3(
            draft: _d, onCreated: widget.onCreated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtotal = _d.subtotal;
    final vatAmt = _d.vatAmount;
    final total = _d.total;

    return Material(
      child: DraggableScrollableSheet(
        initialChildSize: 0.93,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, ctrl) => Column(
          children: [
            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: _DS.pagePad,
                children: [
                  _SheetHeader(
                    title: 'Line Items',
                    showBack: true,
                    onBack: () => Navigator.pop(context),
                  ),
                  _StepPill(step: 2, total: 3),
                  const SizedBox(height: 8),

                  // ── Scan & Library quick actions ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: _scanning
                              ? Icons.hourglass_top_rounded
                              : Icons.document_scanner_outlined,
                          label: _scanning ? 'Scanning…' : 'Scan receipt',
                          onTap: _scanning ? null : _scanReceipt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.library_books_outlined,
                          label: 'Item library',
                          onTap: _showItemLibrary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Line item rows (swipe to delete) ─────────────────────
                  _Label('Items'),
                  ..._d.lineItems.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Dismissible(
                      key: ObjectKey(item),
                      direction: _d.lineItems.length > 1
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cs.error.withOpacity(.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: cs.error),
                      ),
                      onDismissed: (_) =>
                          setState(() => _d.lineItems.removeAt(idx)),
                      child: _LineItemCard(
                        item: item,
                        currency: _d.currency,
                        onChanged: () => setState(() {}),
                      ),
                    );
                  }),

                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _d.lineItems.add(_LineItem())),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add line item'),
                  ),
                  const SizedBox(height: 8),

                  // ── VAT toggle ───────────────────────────────────────────
                  _SwitchRow(
                    label: 'Apply VAT (7.5%)',
                    value: _d.vatEnabled,
                    onChanged: (v) => setState(() => _d.vatEnabled = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Sticky totals footer ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(
                        color: cs.onSurface.withOpacity(.08))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4))
                ],
            ),
            child: Column(
              children: [
                _TotalRow('Subtotal', subtotal, _d.currency),
                if (_d.vatEnabled)
                  _TotalRow('VAT (7.5%)', vatAmt, _d.currency),
                const Divider(height: 20),
                _TotalRow('Total', total, _d.currency, bold: true),
                const SizedBox(height: 16),
                _PrimaryBtn(label: 'Continue', onTap: _next),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHEET 3 — Payment & Schedule
// ═════════════════════════════════════════════════════════════════════════════

class CreateInvoiceSheet3 extends StatefulWidget {
  final _InvoiceDraft draft;
  final VoidCallback onCreated;
  const CreateInvoiceSheet3(
      {super.key, required this.draft, required this.onCreated});

  @override
  State<CreateInvoiceSheet3> createState() => _CreateInvoiceSheet3State();
}

class _CreateInvoiceSheet3State extends State<CreateInvoiceSheet3> {
  _InvoiceDraft get _d => widget.draft;
  final _descCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    _d.description = _descCtrl.text.trim();
    try {
      // Create the invoice via API
      await apiService.createInvoice(_d.toJson());
      
      // Notify parent to refresh invoices
      if (mounted) {
        widget.onCreated();
        // Pop all 3 sheets
        Navigator.of(context).popUntil((r) => r.isFirst);
        
        // Show success message
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
            content: Text('Error creating invoice: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _d.dueDate = d);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Currency hint: suggest USDC for non-Nigerian emails
    final suggestUsdc = _d.clientEmail.isNotEmpty &&
        !_d.clientEmail.endsWith('.ng');

    return Material(
      child: DraggableScrollableSheet(
        initialChildSize: 0.93,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, ctrl) => ListView(
          controller: ctrl,
          padding: _DS.pagePad,
          children: [
            _SheetHeader(
              title: 'Payment & Schedule',
              showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          _StepPill(step: 3, total: 3),
          const SizedBox(height: 8),

          // ── Currency suggestion banner ──────────────────────────────────
          if (suggestUsdc)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(.20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'International client detected — consider invoicing in USDC.',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _d.currency = 'USDC'),
                    child: Text('Switch',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                ],
              ),
            ),

          // ── Currency ──────────────────────────────────────────────────
          _Label('Currency'),
          Row(
            children: [
              _SegBtn(
                label: 'NGN (NGNT)',
                selected: _d.currency == 'NGNT',
                onTap: () => setState(() => _d.currency = 'NGNT'),
              ),
              const SizedBox(width: 8),
              _SegBtn(
                label: 'USD (USDC)',
                selected: _d.currency == 'USDC',
                onTap: () => setState(() => _d.currency = 'USDC'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Payment method ────────────────────────────────────────────
          _Label('Payment method'),
          Wrap(
            spacing: 8,
            children: [
              _SegBtn(
                label: 'On-chain',
                icon: Icons.link_rounded,
                selected: _d.paymentType == 'crypto',
                onTap: () => setState(() => _d.paymentType = 'crypto'),
              ),
              _SegBtn(
                label: 'Bank transfer',
                icon: Icons.account_balance_outlined,
                selected: _d.paymentType == 'bankTransfer',
                onTap: () =>
                    setState(() => _d.paymentType = 'bankTransfer'),
              ),
              _SegBtn(
                label: 'Both',
                icon: Icons.swap_horiz_rounded,
                selected: _d.paymentType == 'both',
                onTap: () => setState(() => _d.paymentType = 'both'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Due date with smart chips ─────────────────────────────────
          _Label('Due date'),
          Wrap(
            spacing: 8,
            children: [
              _DueDateChip(
                  label: 'Net 7',
                  days: 7,
                  draft: _d,
                  onSet: () => setState(() {})),
              _DueDateChip(
                  label: 'Net 14',
                  days: 14,
                  draft: _d,
                  onSet: () => setState(() {})),
              _DueDateChip(
                  label: 'Net 30',
                  days: 30,
                  draft: _d,
                  onSet: () => setState(() {})),
              _DueDateChip(
                  label: 'Net 60',
                  days: 60,
                  draft: _d,
                  onSet: () => setState(() {})),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16,
                      color: cs.onSurface.withOpacity(.5)),
                  const SizedBox(width: 10),
                  Text(
                    _d.dueDate != null
                        ? DateFormat('MMM d, yyyy').format(_d.dueDate!)
                        : 'Custom date',
                    style: TextStyle(
                        fontSize: 14,
                        color: _d.dueDate != null
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(.4)),
                  ),
                  const Spacer(),
                  if (_d.dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _d.dueDate = null),
                      child: Icon(Icons.close_rounded,
                          size: 16,
                          color: cs.onSurface.withOpacity(.5)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Recurring ────────────────────────────────────────────────
          _SwitchRow(
            label: 'Recurring invoice',
            sublabel: 'Auto-generate on a schedule',
            value: _d.isRecurring,
            onChanged: (v) => setState(() => _d.isRecurring = v),
          ),
          if (_d.isRecurring) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['weekly', 'monthly', 'quarterly', 'annually']
                  .map((iv) => _SegBtn(
                        label:
                            iv[0].toUpperCase() + iv.substring(1),
                        selected: _d.recurringInterval == iv,
                        onTap: () =>
                            setState(() => _d.recurringInterval = iv),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),

          // ── Optional notes ────────────────────────────────────────────
          _Label('Notes (optional)'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: _DS.field(context,
                'Payment terms, bank details, thank-you message…'),
          ),
          const SizedBox(height: 32),

          // ── Summary card ──────────────────────────────────────────────
          _SummaryCard(draft: _d),
          const SizedBox(height: 24),

          _PrimaryBtn(
            label: 'Create Invoice',
            onTap: _submit,
            loading: _loading,
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(.09)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: cs.onSurface.withOpacity(.7)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(.75))),
          ],
        ),
      ),
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final _LineItem item;
  final String currency;
  final VoidCallback onChanged;

  const _LineItemCard(
      {required this.item,
      required this.currency,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final symbol = currency == 'USDC' ? '\$' : '₦';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: item.descCtrl,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Item description',
              hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.35),
                  fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Qty
              SizedBox(
                width: 64,
                child: TextField(
                  controller: item.qtyCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.35),
                        fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    prefix: Text('×',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.4))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Unit price
              Expanded(
                child: TextField(
                  controller: item.priceCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  decoration: InputDecoration(
                    hintText: 'Unit price',
                    hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.35),
                        fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    prefix: Text('$symbol ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.5))),
                  ),
                ),
              ),
              // Line total
              Text(
                '$symbol${item.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.sublabel});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15)),
                if (sublabel != null)
                  Text(sublabel!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.5))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool bold;

  const _TotalRow(this.label, this.amount, this.currency,
      {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final symbol = currency == 'USDC' ? '\$' : '₦';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.6))),
          const Spacer(),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final String label;
  final int days;
  final _InvoiceDraft draft;
  final VoidCallback onSet;

  const _DueDateChip(
      {required this.label,
      required this.days,
      required this.draft,
      required this.onSet});

  bool get _selected {
    if (draft.dueDate == null) return false;
    final expected = DateTime.now()
        .add(Duration(days: days))
        .toLocal();
    return draft.dueDate!.year == expected.year &&
        draft.dueDate!.month == expected.month &&
        draft.dueDate!.day == expected.day;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        draft.dueDate =
            DateTime.now().add(Duration(days: days));
        onSet();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _selected
              ? cs.primary
              : cs.onSurface.withOpacity(.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _selected
                  ? cs.onPrimary
                  : cs.onSurface.withOpacity(.7)),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _InvoiceDraft draft;
  const _SummaryCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final symbol = draft.currency == 'USDC' ? '\$' : '₦';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice summary',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(.5),
                  letterSpacing: .5)),
          const SizedBox(height: 10),
          Text(draft.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(draft.clientName,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(.6), fontSize: 14)),
          const Divider(height: 20),
          Row(
            children: [
              Text('${draft.lineItems.length} item(s)',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(.6),
                      fontSize: 13)),
              const Spacer(),
              Text(
                '$symbol${draft.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          if (draft.dueDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Due ${DateFormat('MMM d, yyyy').format(draft.dueDate!)}',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withOpacity(.5)),
            ),
          ],
        ],
      ),
    );
  }
}