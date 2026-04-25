// lib/screens/expenses/expenses_screen.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/app_bottomsheet.dart';
import '../../providers/wallet_provider.dart'; // for ngnRateProvider
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
    this.currency = 'NGNT',
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
    currency: j['currency'] ?? 'NGNT',
    status: j['status'] ?? 'pending',
    receiptUrl: j['receiptUrl'],
    rejectionNote: j['rejectionNote'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    approvedAt: j['approvedAt'] != null
        ? DateTime.tryParse(j['approvedAt'])
        : null,
    submittedBy: j['submittedBy'],
    approvedBy: j['approvedBy'],
  );

  /// Returns the expense amount normalised to NGN.
  /// USDC is treated as 1:1 USD, then converted. NGN is already NGN.
  double toNgn(double usdToNgn) {
    if (currency == 'USDC') return amount * usdToNgn;
    return amount; // NGNT
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _expensesProvider = FutureProvider.autoDispose<List<Expense>>((
  ref,
) async {
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
    final expAsync = ref.watch(_expensesProvider);
    final userAsync = ref.watch(_userMeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 118, 0, 100),
                child: expAsync.when(
                  loading: () => const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _buildError(context, ref, e.toString()),
                  data: (expenses) => _buildBody(context, ref, expenses, userAsync),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, ref),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return Container(
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
        onTap: () => _showCreateModal(context, ref),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.add,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load expenses',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(_expensesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
    AsyncValue<Map<String, dynamic>> userAsync,
  ) {
    final isMerchant = userAsync.value?['isMerchant'] == true;
    final currentUserId = userAsync.value?['id']?.toString();

    if (expenses.isEmpty) {
      return _EmptyState(onTap: () => _showCreateModal(context, ref));
    }

    final pending = expenses.where((e) => e.status == 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_expensesProvider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Expense Insights ────────────────────────────────────────
          Expanded(
            child: _ExpenseInsightsPanel(
              expenses: expenses,
              pending: pending,
              isMerchant: isMerchant,
            ),
          ),
          const SizedBox(width: 16),
          // ── Right: Expense List ───────────────────────────────────────────
          Expanded(
            child: _ExpenseListPanel(
              expenses: expenses,
              pending: pending,
              isMerchant: isMerchant,
              currentUserId: currentUserId,
              onShowDetail: (e) => _showDetailModal(context, ref, e, isMerchant, currentUserId),
              onShowCreate: () => _showCreateModal(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GlassModal(
        child: _CreateExpenseFlow(
          onCreated: () {
            ref.invalidate(_expensesProvider);
            ref.invalidate(_userMeProvider);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    bool isMerchant,
    String? currentUserId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GlassModal(
        child: _ExpenseDetailContent(
          expense: expense,
          isMerchant: isMerchant,
          currentUserId: currentUserId,
          onRefresh: () {
            ref.invalidate(_expensesProvider);
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// ─── Glass Modal ────────────────────────────────────────────────────────────────

class _GlassModal extends StatelessWidget {
  final Widget child;
  const _GlassModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 520,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Create Expense Flow ───────────────────────────────────────────────────────

class _CreateExpenseFlow extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateExpenseFlow({required this.onCreated});

  @override
  ConsumerState<_CreateExpenseFlow> createState() => _CreateExpenseFlowState();
}

class _CreateExpenseFlowState extends ConsumerState<_CreateExpenseFlow>
    with TickerProviderStateMixin {
  int _step = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedCategory = 'other';
  String _selectedCurrency = 'NGNT';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() => _step--);
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Create Expense',
          step: _step,
          totalSteps: 3,
          onBack: _step > 1 ? _prevStep : null,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Expense Details'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleCtrl,
          decoration: _modalField(context, 'e.g. Office Supplies'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _FieldLabel('Amount'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          decoration: _modalField(context, '0.00'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _FieldLabel('Category'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['office', 'travel', 'food', 'supplies', 'other'].map((cat) {
            return _SegmentButton(
              label: cat[0].toUpperCase() + cat.substring(1),
              selected: _selectedCategory == cat,
              onTap: () => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Description (Optional)'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 3,
          decoration: _modalField(context, 'Add details about this expense...'),
        ),
        const SizedBox(height: 20),
        _FieldLabel('Currency'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['NGNT', 'USDC'].map((curr) {
            return _SegmentButton(
              label: curr,
              selected: _selectedCurrency == curr,
              onTap: () => setState(() => _selectedCurrency = curr),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  Widget _buildStep3() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final symbol = _selectedCurrency == 'USDC' ? '\$' : '₦';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Review & Submit'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleCtrl.text.trim(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory[0].toUpperCase() + _selectedCategory.substring(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (_descriptionCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _descriptionCtrl.text.trim(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$symbol${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ModalPrimaryButton(
          label: 'Create Expense',
          onTap: _submitExpense,
        ),
      ],
    );
  }

  Future<void> _submitExpense() async {
    try {
      final amount = double.tryParse(_amountCtrl.text);
      if (amount == null || _titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      await apiService.createExpense({
        'title': _titleCtrl.text.trim(),
        'amount': amount,
        'category': _selectedCategory,
        'currency': _selectedCurrency,
        'description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
      });

      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create expense: $e')),
        );
      }
    }
  }
}

// ─── Expense Detail Content ────────────────────────────────────────────────────

class _ExpenseDetailContent extends ConsumerStatefulWidget {
  final Expense expense;
  final bool isMerchant;
  final String? currentUserId;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _ExpenseDetailContent({
    required this.expense,
    required this.isMerchant,
    required this.currentUserId,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  ConsumerState<_ExpenseDetailContent> createState() => _ExpenseDetailContentState();
}

class _ExpenseDetailContentState extends ConsumerState<_ExpenseDetailContent> {
  bool _approving = false;
  bool _rejecting = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final usdToNgn = ref.watch(ngnRateProvider) ?? 1354.92;
    final ngnAmount = widget.expense.toNgn(usdToNgn);
    final usdAmount = widget.expense.currency == 'NGNT'
        ? (usdToNgn > 0 ? ngnAmount / usdToNgn : 0.0)
        : widget.expense.amount;

    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Expense Details',
          onBack: null,
          onClose: widget.onClose, step: 0, totalSteps: 0,
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Amount
                Row(
                  children: [
                    _StatusPill(status: widget.expense.status),
                    const Spacer(),
                    Text(
                      widget.expense.currency == 'USDC'
                          ? '\$${widget.expense.amount.toStringAsFixed(2)}'
                          : '₦${widget.expense.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.expense.currency == 'USDC'
                      ? '≈ ₦${ngnAmount.toStringAsFixed(0)}'
                      : '≈ \$${usdAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Details
                _DetailRow(label: 'Title', value: widget.expense.title),
                if (widget.expense.description != null)
                  _DetailRow(label: 'Description', value: widget.expense.description!),
                _DetailRow(label: 'Category', value: widget.expense.category),
                _DetailRow(
                  label: 'Date',
                  value: DateFormat('MMM d, yyyy').format(widget.expense.createdAt),
                ),
                if (widget.expense.approvedAt != null)
                  _DetailRow(
                    label: 'Approved',
                    value: DateFormat('MMM d, yyyy').format(widget.expense.approvedAt!),
                  ),
                if (widget.expense.rejectionNote != null)
                  _DetailRow(label: 'Rejection Note', value: widget.expense.rejectionNote!),
                
                const SizedBox(height: 32),
                
                // Actions
                if (widget.isMerchant && widget.expense.status == 'pending')
                  _buildMerchantActions()
                else if (!widget.isMerchant && widget.expense.status == 'pending')
                  _buildEmployeeActions()
                else if (widget.expense.status == 'rejected')
                  _buildRejectedActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DayFiColors.red,
              side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
            ),
            onPressed: _rejecting ? null : _rejectExpense,
            child: _rejecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reject'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DayFiColors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: _approving ? null : _approveExpense,
            child: _approving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Approve'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DayFiColors.red,
              side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
            ),
            onPressed: _deleting ? null : _deleteExpense,
            child: _deleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete'),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DayFiColors.red,
              side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
            ),
            onPressed: _deleting ? null : _deleteExpense,
            child: _deleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete'),
          ),
        ),
      ],
    );
  }

  Future<void> _approveExpense() async {
    setState(() => _approving = true);
    try {
      await apiService.approveExpense(widget.expense.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    } finally {
      setState(() => _approving = false);
    }
  }

  Future<void> _rejectExpense() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _rejecting = true);
    try {
      await apiService.rejectExpense(widget.expense.id, reason);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    } finally {
      setState(() => _rejecting = false);
    }
  }

  Future<void> _deleteExpense() async {
    setState(() => _deleting = true);
    try {
      await apiService.deleteExpense(widget.expense.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      setState(() => _deleting = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
// ─── Expense Insights Panel ───────────────────────────────────────────────────

class _ExpenseInsightsPanel extends ConsumerWidget {
  final List<Expense> expenses;
  final List<Expense> pending;
  final bool isMerchant;

  const _ExpenseInsightsPanel({
    required this.expenses,
    required this.pending,
    required this.isMerchant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdToNgn = ref.watch(ngnRateProvider) ?? 1354.92;
    
    final approved = expenses.where((e) => e.status == 'approved').toList();
    final rejected = expenses.where((e) => e.status == 'rejected').toList();
    
    final totalApproved = approved.fold(0.0, (sum, e) => sum + e.toNgn(usdToNgn));
    final totalPending = pending.fold(0.0, (sum, e) => sum + e.toNgn(usdToNgn));
    final totalRejected = rejected.fold(0.0, (sum, e) => sum + e.toNgn(usdToNgn));
    
    final totalExpenses = totalApproved + totalPending + totalRejected;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Expense Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'This Month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Metric Cards Row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Expenses',
                value: '₦${totalExpenses.toStringAsFixed(0)}',
                icon: Icons.receipt_long,
                color: const Color(0xFF9B8EF8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Pending',
                value: '₦${totalPending.toStringAsFixed(0)}',
                icon: Icons.pending,
                color: const Color(0xFFFFA726),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Approved',
                value: '₦${totalApproved.toStringAsFixed(0)}',
                icon: Icons.check_circle,
                color: DayFiColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Rejected',
                value: '₦${totalRejected.toStringAsFixed(0)}',
                icon: Icons.cancel,
                color: DayFiColors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Category Breakdown
        _CategoryBreakdownCard(expenses: expenses, usdToNgn: usdToNgn),
        const SizedBox(height: 24),
        
        // Status Distribution
        _StatusDistributionCard(
          approved: approved.length,
          pending: pending.length,
          rejected: rejected.length,
          total: expenses.length,
        ),
      ],
    );
  }
}

// ─── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Breakdown Card ────────────────────────────────────────────────────

class _CategoryBreakdownCard extends ConsumerWidget {
  final List<Expense> expenses;
  final double usdToNgn;

  const _CategoryBreakdownCard({
    required this.expenses,
    required this.usdToNgn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      final amount = expense.toNgn(usdToNgn);
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + amount;
    }
    
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(5).map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key[0].toUpperCase() + entry.key.substring(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '₦${entry.value.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'office':
        return const Color(0xFF9B8EF8);
      case 'travel':
        return const Color(0xFFFFA726);
      case 'food':
        return DayFiColors.green;
      case 'supplies':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// ─── Status Distribution Card ───────────────────────────────────────────────────

class _StatusDistributionCard extends StatelessWidget {
  final int approved;
  final int pending;
  final int rejected;
  final int total;

  const _StatusDistributionCard({
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Text(
              'No expenses yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          else ...[
            _StatusBar(
              label: 'Approved',
              count: approved,
              total: total,
              color: DayFiColors.green,
            ),
            const SizedBox(height: 12),
            _StatusBar(
              label: 'Pending',
              count: pending,
              total: total,
              color: const Color(0xFFFFA726),
            ),
            const SizedBox(height: 12),
            _StatusBar(
              label: 'Rejected',
              count: rejected,
              total: total,
              color: DayFiColors.red,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status Bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ─── Expense List Panel ──────────────────────────────────────────────────────

class _ExpenseListPanel extends ConsumerWidget {
  final List<Expense> expenses;
  final List<Expense> pending;
  final bool isMerchant;
  final String? currentUserId;
  final ValueChanged<Expense> onShowDetail;
  final VoidCallback onShowCreate;

  const _ExpenseListPanel({
    required this.expenses,
    required this.pending,
    required this.isMerchant,
    required this.currentUserId,
    required this.onShowDetail,
    required this.onShowCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdToNgn = ref.watch(ngnRateProvider) ?? 1354.92;

    // Filter out pending expenses if merchant (will show separately below)
    final myExpenses = isMerchant
        ? expenses.where((e) => e.status != 'pending').toList()
        : expenses;

    // Date-grouped "My Expenses"
    final grouped = _groupByDate(myExpenses);
    final dateKeys = _sortedDateKeys(grouped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            if (myExpenses.isNotEmpty)
              _CreateButton(onTap: onShowCreate),
          ],
        ),
        const SizedBox(height: 24),
        
        // My Expenses (date-grouped)
        if (myExpenses.isEmpty)
          _EmptyExpenseCard(onCreate: onShowCreate)
        else ...[
          _SectionHeader(label: 'My Expenses', count: myExpenses.length),
          const SizedBox(height: 12),
          for (final dateLabel in dateKeys) ...[
            // Date sub-header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            ...grouped[dateLabel]!.map(
              (e) => _ExpenseTile(
                expense: e,
                usdToNgn: usdToNgn,
                onTap: () => onShowDetail(e),
              ),
            ),
          ],
        ],

        // Pending Approval (merchants only)
        if (isMerchant && pending.isNotEmpty) ...[
          const SizedBox(height: 32),
          _SectionHeader(label: 'Pending Approval', count: pending.length),
          const SizedBox(height: 12),
          ...pending.map(
            (e) => _ExpenseTile(
              expense: e,
              usdToNgn: usdToNgn,
              onTap: () => onShowDetail(e),
              showApprove: true,
            ),
          ),
        ],
      ],
    );
  }

  /// Groups expenses by a human-readable date label (Today / Yesterday / MMM d).
  Map<String, List<Expense>> _groupByDate(List<Expense> list) {
    final grouped = <String, List<Expense>>{};
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    for (final e in list) {
      final d = e.createdAt;
      final created = DateTime(d.year, d.month, d.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      final yestDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

      final String label;
      if (created == todayDate) {
        label = 'Today';
      } else if (created == yestDate) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d').format(d);
      }

      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  /// Returns sorted date keys in chronological order (newest first).
  List<String> _sortedDateKeys(Map<String, List<Expense>> grouped) {
    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      // For MMM d format, parse and compare dates
      try {
        final dateA = DateFormat('MMM d').parse(a);
        final dateB = DateFormat('MMM d').parse(b);
        return dateB.compareTo(dateA);
      } catch (_) {
        return a.compareTo(b);
      }
    });
    return keys;
  }
}

// ─── Create Button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'New Expense',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Expense Card ───────────────────────────────────────────────────────

class _EmptyExpenseCard extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyExpenseCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
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
            'No expenses yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first expense to start tracking.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _CreateButton(onTap: onCreate),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
// ─── Modal Components ───────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.title,
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        _SmallIconButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => Container(
          width: 32,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: i < current
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _ModalPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _ModalPrimaryButton({
    required this.label,
    required this.onTap,
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
          backgroundColor: cs.primary,
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
                  color: Theme.of(context).colorScheme.surface,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
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
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
  );
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'approved':
        c = DayFiColors.green;
        break;
      case 'pending':
        c = const Color(0xFFFFA726);
        break;
      case 'rejected':
        c = DayFiColors.red;
        break;
      default:
        c = const Color(0xFF78909C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
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

// ─── Expense Tile ───────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final double usdToNgn;
  final VoidCallback onTap;
  final bool showApprove;

  const _ExpenseTile({
    required this.expense,
    required this.usdToNgn,
    required this.onTap,
    this.showApprove = false,
  });

  @override
  Widget build(BuildContext context) {
    final ngnAmount = expense.toNgn(usdToNgn);
    final usdAmount = expense.currency == 'NGNT'
        ? (usdToNgn > 0 ? ngnAmount / usdToNgn : 0.0)
        : expense.amount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(expense.category),
                size: 20,
                color: _getCategoryColor(expense.category),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.category[0].toUpperCase() + expense.category.substring(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  expense.currency == 'USDC'
                      ? '\$${expense.amount.toStringAsFixed(2)}'
                      : '₦${expense.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusPill(status: expense.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'office':
        return Icons.business_center;
      case 'travel':
        return Icons.flight;
      case 'food':
        return Icons.restaurant;
      case 'supplies':
        return Icons.inventory;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'office':
        return const Color(0xFF9B8EF8);
      case 'travel':
        return const Color(0xFFFFA726);
      case 'food':
        return DayFiColors.green;
      case 'supplies':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first expense to start tracking.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Create Expense'),
          ),
        ],
      ),
    );
  }
}
// ─── Add missing imports ───────────────────────────────────────────────────────────
class _SummaryRow extends StatefulWidget {
  final List<Expense> expenses; 
  final double usdToNgn;

  const _SummaryRow({required this.expenses, required this.usdToNgn});

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  bool _allocationExpanded = true;

  @override
  Widget build(BuildContext context) {
    double approvedNgn = 0;
    double pendingNgn = 0;
    double rejectedNgn = 0;

    for (final e in widget.expenses) {
      final ngn = e.toNgn(widget.usdToNgn);
      if (e.status == 'approved' || e.status == 'reimbursed') {
        approvedNgn += ngn;
      }
      if (e.status == 'pending') pendingNgn += ngn;
      if (e.status == 'rejected') rejectedNgn += ngn;
    }

    final total = approvedNgn + pendingNgn + rejectedNgn;
    final approvedPct = total > 0 ? approvedNgn / total : 0.0;
    final pendingPct = total > 0 ? pendingNgn / total : 0.0;
    final rejectedPct = total > 0 ? rejectedNgn / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
     
        if (_allocationExpanded) ...[
          // const SizedBox(height: 10),
          if (widget.expenses.isEmpty)
            Text(
              'Add expenses to see approved vs pending vs rejected.',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: .4,
                height: 1,
              ),
            )
          else
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  width: .5,
                ),
                color: AppThemeExtension.of(context).cardSurface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MiniAllocationRow(
                    label: 'Approved',
                    valueLabel: '${(approvedPct * 100).toStringAsFixed(1)}%',
                    progress: approvedPct,
                    accent: DayFiColors.green,
                  ),
                  _MiniAllocationRow(
                    label: 'Pending',
                    valueLabel: '${(pendingPct * 100).toStringAsFixed(1)}%',
                    progress: pendingPct,
                    accent: const Color(0xFFFFA726),
                  ),
                  _MiniAllocationRow(
                    label: 'Rejected',
                    valueLabel: '${(rejectedPct * 100).toStringAsFixed(1)}%',
                    progress: rejectedPct,
                    accent: DayFiColors.red,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _MiniAllocationRow extends StatelessWidget {
  const _MiniAllocationRow({
    required this.label,
    required this.valueLabel,
    required this.progress,
    this.accent = DayFiColors.green,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: .325,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: ext.secondaryText.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Builder(
                builder: (context) {
                  final v = valueLabel.trim();
                  final hasPct = v.endsWith('%');
                  final digits = hasPct ? v.substring(0, v.length - 1) : v;
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: digits,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .95,
                            height: 1,
                            color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                          ),
                        ),
                        if (hasPct)
                          TextSpan(
                            text: '%',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.95,
                              height: 1,
                              color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          .withOpacity(0.72),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
            ),
          ],
        ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _StatusPill(
          status: label.toLowerCase().replaceAll(' ', '_'),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)'.toUpperCase(),
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ext.sectionHeader.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}


class _CreateExpenseSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateExpenseSheet({required this.onCreated});

  @override
  ConsumerState<_CreateExpenseSheet> createState() =>
      _CreateExpenseSheetState();
}

class _CreateExpenseSheetState extends ConsumerState<_CreateExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'other';
  String _currency = 'NGNT';
  bool _loading = false;

  static const _categories = [
    'travel',
    'meals',
    'accommodation',
    'equipment',
    'software',
    'marketing',
    'utilities',
    'salary',
    'other',
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
        'title': _titleCtrl.text.trim(),
        'amount': amt,
        'category': _category,
        'currency': _currency,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      });
      if (mounted) {
        widget.onCreated();
        // Add a brief delay to ensure backend processed the request
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
          // Handle
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
            'New Expense',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
            ),
          ),
          const SizedBox(height: 20),

          _Label('Title'),
          const SizedBox(height: 6),
          _Field(controller: _titleCtrl, hint: 'e.g. Flight to Abuja'),
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
              _SegmentedPicker(
                options: const ['NGNT', 'USDC'],
                selected: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c[0].toUpperCase()}${c.substring(1)}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          _Label('Note (optional)'),
          const SizedBox(height: 6),
          _Field(
            controller: _descCtrl,
            hint: 'Any additional details...',
            maxLines: 3,
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
                      'Create Expense',
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

// ─── Expense detail sheet ─────────────────────────────────────────────────────

class _ExpenseDetailSheet extends ConsumerStatefulWidget {
  final Expense expense;
  final bool isMerchant;
  final String? currentUserId;
  final VoidCallback onRefresh;

  const _ExpenseDetailSheet({
    required this.expense,
    required this.isMerchant,
    required this.currentUserId,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ExpenseDetailSheet> createState() =>
      _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends ConsumerState<_ExpenseDetailSheet> {
  bool _approving = false;
  bool _rejecting = false;
  bool _editing = false;
  bool _deleting = false;
  final _rejectCtrl = TextEditingController();

  @override
  void dispose() {
    _rejectCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _approve() async {
    final confirmed = await _confirmAction(
      title: 'Approve expense?',
      body: 'This marks the expense as approved.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !mounted) return;

    setState(() => _approving = true);
    try {
      await apiService.approveExpense(widget.expense.id);
      widget.onRefresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense approved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _edit() async {
    setState(() => _editing = true);
    try {
      final updated = await showDayFiBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        child: _EditExpenseSheet(expense: widget.expense),
      );
      if (updated != null) {
        widget.onRefresh();
        if (mounted) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await _confirmAction(
      title: 'Delete expense?',
      body: 'This permanently removes the expense.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await apiService.deleteExpense(widget.expense.id);
      widget.onRefresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _reject() async {
    if (_rejectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejection reason is required')),
      );
      return;
    }
    final confirmed = await _confirmAction(
      title: 'Reject expense?',
      body: 'This marks the expense as rejected.',
      confirmLabel: 'Reject',
    );
    if (!confirmed || !mounted) return;

    setState(() => _rejecting = true);
    try {
      await apiService.rejectExpense(
        widget.expense.id,
        _rejectCtrl.text.trim(),
      );
      widget.onRefresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final usdToNgn = ref.watch(ngnRateProvider) ?? 1354.92;
    final ngnAmount = e.toNgn(usdToNgn);
    final usdAmount = e.currency == 'NGNT'
        ? (usdToNgn > 0 ? ngnAmount / usdToNgn : 0.0)
        : e.amount;
    final isOwner = widget.currentUserId != null &&
        (e.submittedBy?['id']?.toString() == widget.currentUserId);
    final canAct = widget.isMerchant && e.status == 'pending' && !isOwner;
    final canOwnerManage = isOwner && e.status == 'pending';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
                'Expense',
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

          // Primary: NGN amount
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '₦',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: NumberFormat('#,##0.00').format(ngnAmount),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),
          // Secondary: USD equivalent
          Text(
            '\$${usdAmount.toStringAsFixed(2)} USD',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _StatusPill(status: e.status),
          const SizedBox(height: 20),

          _DetailRow(label: 'Title', value: e.title),
          _DetailRow(
            label: 'Category',
            value: '${e.category[0].toUpperCase()}${e.category.substring(1)}',
          ),
          _DetailRow(label: 'Currency', value: e.currency),
          _DetailRow(
            label: 'Date',
            value: DateFormat('MMM d, yyyy').format(e.createdAt),
          ),
          if (e.description != null && e.description!.isNotEmpty)
            _DetailRow(label: 'Note', value: e.description!),
          if (e.rejectionNote != null)
            _DetailRow(
              label: 'Rejection reason',
              value: e.rejectionNote!,
              // isWarning: true,
            ),
          if (e.approvedAt != null)
            _DetailRow(
              label: 'Approved at',
              value: DateFormat('MMM d, yyyy').format(e.approvedAt!),
            ),

          // Approval actions
          if (canAct) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _rejectCtrl,
              decoration: InputDecoration(
                hintText: 'Rejection reason (required to reject)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _rejecting ? null : _reject,
                    child: _rejecting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Reject',
                            style: GoogleFonts.bricolageGrotesque(
                              color: DayFiColors.red,
                              fontWeight: FontWeight.w600,
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
                    onPressed: _approving ? null : _approve,
                    child: _approving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Approve',
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
          if (canOwnerManage) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.35),
                      ),
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
                    onPressed: _deleting ? null : _delete,
                    child: _deleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Delete',
                            style: GoogleFonts.bricolageGrotesque(
                              color: DayFiColors.red,
                              fontWeight: FontWeight.w600,
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

class _EditExpenseSheet extends StatefulWidget {
  final Expense expense;
  const _EditExpenseSheet({required this.expense});

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _category;
  late String _currency;
  bool _saving = false;

  static const _categories = [
    'travel',
    'meals',
    'accommodation',
    'equipment',
    'software',
    'marketing',
    'utilities',
    'salary',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.expense.title;
    _amountCtrl.text = widget.expense.amount.toStringAsFixed(2);
    _descCtrl.text = widget.expense.description ?? '';
    _category = widget.expense.category;
    _currency = widget.expense.currency;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'title': _titleCtrl.text.trim(),
        'amount': amount,
        'category': _category,
        'currency': _currency,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      };
      final res = await apiService.updateExpense(widget.expense.id, payload);
      if (mounted) Navigator.pop(context, res['expense']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiService.parseError(e))),
        );
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Expense',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _Label('Title'),
          const SizedBox(height: 6),
          _Field(controller: _titleCtrl, hint: 'Expense title'),
          const SizedBox(height: 12),
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
              _SegmentedPicker(
                options: const ['NGNT', 'USDC'],
                selected: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c[0].toUpperCase()}${c.substring(1)}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Label('Note (optional)'),
          const SizedBox(height: 6),
          _Field(controller: _descCtrl, hint: 'Any additional details...', maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Save changes',
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


class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
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

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

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
            child: Text(
              o,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
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
