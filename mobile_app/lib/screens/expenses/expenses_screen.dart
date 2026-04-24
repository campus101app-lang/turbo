// lib/screens/expenses/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class Expense {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final String currency;
  final String status;
  final String? receiptUrl;
  final String? rejectionNote;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? submittedBy;
  final Map<String, dynamic>? approvedBy;

  const Expense({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    this.currency = 'NGN',
    required this.status,
    this.receiptUrl,
    this.rejectionNote,
    required this.createdAt,
    this.approvedAt,
    this.submittedBy,
    this.approvedBy,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'],
        amount: (j['amount'] ?? 0).toDouble(),
        category: j['category'] ?? 'other',
        currency: j['currency'] ?? 'NGN',
        status: j['status'] ?? 'pending',
        receiptUrl: j['receiptUrl'],
        rejectionNote: j['rejectionNote'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        approvedAt: j['approvedAt'] != null ? DateTime.tryParse(j['approvedAt']) : null,
        submittedBy: j['submittedBy'],
        approvedBy: j['approvedBy'],
      );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final result = await apiService.getExpenses(limit: 100);
  return (result['expenses'] as List)
      .map((e) => Expense.fromJson(e as Map<String, dynamic>))
      .toList();
});

final _userMeProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (_) => apiService.getMe(),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expAsync  = ref.watch(_expensesProvider);
    final userAsync = ref.watch(_userMeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: expAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _buildError(context, ref, e.toString()),
        data:    (expenses) => _buildBody(context, ref, expenses, userAsync),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Expense',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Failed to load expenses',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.invalidate(_expensesProvider),
          child: const Text('Retry'),
        ),
      ]),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
    AsyncValue<Map<String, dynamic>> userAsync,
  ) {
    final isMerchant = userAsync.value?['isMerchant'] == true;

    if (expenses.isEmpty) {
      return _EmptyState(onTap: () => _showCreateSheet(context, ref));
    }

    // Split: my expenses vs pending approval
    final mine   = expenses.where((e) => true).toList(); // all visible to user
    final pending = expenses.where((e) => e.status == 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_expensesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        children: [
          _SummaryRow(expenses: expenses),
          const SizedBox(height: 20),

          // ── My Expenses ──────────────────────────────────────────
          _SectionLabel(label: 'My Expenses', count: mine.length),
          const SizedBox(height: 8),
          ...mine.map((e) => _ExpenseTile(
                expense: e,
                onTap: () => _showDetailSheet(context, ref, e, isMerchant),
              )),

          // ── Pending Approval (merchants only) ────────────────────
          if (isMerchant && pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel(
              label: 'Pending Approval',
              count: pending.length,
              accent: const Color(0xFFFFA726),
            ),
            const SizedBox(height: 8),
            ...pending.map((e) => _ExpenseTile(
                  expense: e,
                  onTap: () => _showDetailSheet(context, ref, e, isMerchant),
                  showApprove: true,
                )),
          ],
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CreateExpenseSheet(onCreated: () => ref.invalidate(_expensesProvider)),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    bool isMerchant,
  ) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _ExpenseDetailSheet(
        expense: expense,
        isMerchant: isMerchant,
        onRefresh: () => ref.invalidate(_expensesProvider),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<Expense> expenses;
  const _SummaryRow({required this.expenses});

  @override
  Widget build(BuildContext context) {
    double totalApproved = 0;
    double totalPending  = 0;
    double totalRejected = 0;

    for (final e in expenses) {
      if (e.status == 'approved' || e.status == 'reimbursed') totalApproved += e.amount;
      if (e.status == 'pending') totalPending += e.amount;
      if (e.status == 'rejected') totalRejected += e.amount;
    }

    return Row(children: [
      Expanded(child: _SummaryCard(
        label: 'Approved',
        value: '₦${_fmt(totalApproved)}',
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
        label: 'Rejected',
        value: '₦${_fmt(totalRejected)}',
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
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.outfit(
              color: color, fontSize: 11, fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
              color: color, fontWeight: FontWeight.w700, fontSize: 18,
            )),
      ]),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color? accent;
  const _SectionLabel({required this.label, required this.count, this.accent});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(children: [
      _StatusPill(status: label.toLowerCase().replaceAll(' ', '_'), accent: accent),
      const SizedBox(width: 8),
      Text('$count',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
          )),
    ]);
  }
}

// ─── Expense tile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final bool showApprove;

  const _ExpenseTile({
    required this.expense,
    required this.onTap,
    this.showApprove = false,
  });

  @override
  Widget build(BuildContext context) {
    final ext    = AppThemeExtension.of(context);
    final symbol = expense.currency == 'USDC' ? '\$' : '₦';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ext.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.cardBorder, width: .5),
        ),
        child: Row(children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(expense.category),
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ext.primaryText,
                  )),
              const SizedBox(height: 2),
              Text(
                '${expense.category[0].toUpperCase()}${expense.category.substring(1)} · '
                '${DateFormat('MMM d').format(expense.createdAt)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: ext.secondaryText,
                ),
              ),
            ]),
          ),
          // Amount + status
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '$symbol${NumberFormat('#,##0.00').format(expense.amount)}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            _StatusPill(status: expense.status),
          ]),
        ]),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'travel':        return Icons.flight_rounded;
      case 'meals':         return Icons.restaurant_rounded;
      case 'accommodation': return Icons.hotel_rounded;
      case 'equipment':     return Icons.devices_rounded;
      case 'software':      return Icons.code_rounded;
      case 'marketing':     return Icons.campaign_rounded;
      case 'utilities':     return Icons.bolt_rounded;
      case 'salary':        return Icons.payments_rounded;
      default:              return Icons.receipt_rounded;
    }
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  final Color? accent;
  const _StatusPill({required this.status, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _label(status),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'pending':     return 'Pending';
      case 'approved':    return 'Approved';
      case 'rejected':    return 'Rejected';
      case 'reimbursed':  return 'Reimbursed';
      case 'my_expenses': return 'My Expenses';
      case 'pending_approval': return 'Pending Approval';
      default: return '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'approved':
      case 'reimbursed': return DayFiColors.green;
      case 'rejected':   return DayFiColors.red;
      case 'pending':    return const Color(0xFFFFA726);
      default:           return const Color(0xFF6C47FF);
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
        const SizedBox(height: 6),
        Text('No expenses yet', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('Track your business spending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            )),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Expense'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ]),
    );
  }
}

// ─── Create expense sheet ─────────────────────────────────────────────────────

class _CreateExpenseSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateExpenseSheet({required this.onCreated});

  @override
  ConsumerState<_CreateExpenseSheet> createState() => _CreateExpenseSheetState();
}

class _CreateExpenseSheetState extends ConsumerState<_CreateExpenseSheet> {
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  String _category = 'other';
  String _currency = 'NGN';
  bool   _loading  = false;

  static const _categories = [
    'travel', 'meals', 'accommodation', 'equipment',
    'software', 'marketing', 'utilities', 'salary', 'other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return _snack('Title is required');
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) return _snack('Enter a valid amount');

    setState(() => _loading = true);
    try {
      await apiService.createExpense({
        'title':       _titleCtrl.text.trim(),
        'amount':      amt,
        'category':    _category,
        'currency':    _currency,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('New Expense',
            style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: ext.primaryText,
            )),
        const SizedBox(height: 20),

        // Title
        _Label('Title'),
        const SizedBox(height: 6),
        _Field(controller: _titleCtrl, hint: 'e.g. Flight to Abuja'),
        const SizedBox(height: 16),

        // Amount + currency
        _Label('Amount'),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _Field(
            controller: _amountCtrl,
            hint: '0.00',
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 12),
          _SegmentedPicker(
            options: const ['NGN', 'USDC'],
            selected: _currency,
            onChanged: (v) => setState(() => _currency = v),
          ),
        ]),
        const SizedBox(height: 16),

        // Category
        _Label('Category'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c[0].toUpperCase()}${c.substring(1)}'),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _category = v); },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        _Label('Note (optional)'),
        const SizedBox(height: 6),
        _Field(
          controller: _descCtrl,
          hint: 'Any additional details...',
          maxLines: 3,
        ),
        const SizedBox(height: 28),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text('Create Expense',
                    style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                    )),
          ),
        ),
      ]),
    );
  }
}

// ─── Expense detail sheet ─────────────────────────────────────────────────────

class _ExpenseDetailSheet extends StatefulWidget {
  final Expense expense;
  final bool isMerchant;
  final VoidCallback onRefresh;

  const _ExpenseDetailSheet({
    required this.expense,
    required this.isMerchant,
    required this.onRefresh,
  });

  @override
  State<_ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends State<_ExpenseDetailSheet> {
  bool _approving = false;
  bool _rejecting = false;
  final _rejectCtrl = TextEditingController();

  @override
  void dispose() {
    _rejectCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _approving = true);
    try {
      await apiService.approveExpense(widget.expense.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _reject() async {
    if (_rejectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rejection reason is required')));
      return;
    }
    setState(() => _rejecting = true);
    try {
      await apiService.rejectExpense(widget.expense.id, _rejectCtrl.text.trim());
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e      = widget.expense;
    final symbol = e.currency == 'USDC' ? '\$' : '₦';
    final canAct = widget.isMerchant && e.status == 'pending';

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Expense',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ]),
        const SizedBox(height: 20),

        // Amount
        Text(
          '$symbol${NumberFormat('#,##0.00').format(e.amount)}',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300, letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        _StatusPill(status: e.status),
        const SizedBox(height: 20),

        // Details
        _DetailRow(label: 'Title',    value: e.title),
        _DetailRow(label: 'Category', value: '${e.category[0].toUpperCase()}${e.category.substring(1)}'),
        _DetailRow(label: 'Currency', value: e.currency),
        _DetailRow(label: 'Date',     value: DateFormat('MMM d, yyyy').format(e.createdAt)),
        if (e.description != null && e.description!.isNotEmpty)
          _DetailRow(label: 'Note', value: e.description!),
        if (e.rejectionNote != null)
          _DetailRow(label: 'Rejection reason', value: e.rejectionNote!, isWarning: true),
        if (e.approvedAt != null)
          _DetailRow(label: 'Approved at',
              value: DateFormat('MMM d, yyyy').format(e.approvedAt!)),

        // Approval actions
        if (canAct) ...[
          const SizedBox(height: 24),

          // Reject reason field
          TextField(
            controller: _rejectCtrl,
            decoration: InputDecoration(
              hintText: 'Rejection reason (required to reject)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(children: [
            // Reject
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _rejecting ? null : _reject,
                child: _rejecting
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Reject',
                        style: GoogleFonts.outfit(
                          color: DayFiColors.red, fontWeight: FontWeight.w600,
                        )),
              ),
            ),
            const SizedBox(width: 12),
            // Approve
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DayFiColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _approving ? null : _approve,
                child: _approving
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Approve',
                        style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.w600,
                        )),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isWarning;
  const _DetailRow({required this.label, required this.value, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            )),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isWarning ? DayFiColors.red : null,
              )),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ));
  }
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
      style: GoogleFonts.outfit(fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentedPicker({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(o,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                )),
          ),
        );
      }).toList(),
    );
  }
}