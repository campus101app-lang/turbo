// lib/screens/expenses/expense_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/selected_expense_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'expenses_screen.dart' show expensesProvider;

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const ExpenseDetailScreen({super.key, required this.insideShell});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _approving = false;
  bool _rejecting = false;
  bool _deleting  = false;

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _approve(String id) async {
    setState(() => _approving = true);
    try {
      await apiService.approveExpense(id);
      ref.invalidate(expensesProvider);
      _snack('Expense approved');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _reject(String id) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _rejecting = true);
    try {
      await apiService.rejectExpense(id, reason);
      ref.invalidate(expensesProvider);
      _snack('Expense rejected');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _deleting = true);
    try {
      await apiService.deleteExpense(id);
      ref.invalidate(expensesProvider);
      _snack('Expense deleted');
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Why is this being rejected?',
            border: OutlineInputBorder(),
          ),
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

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final expense = ref.watch(selectedExpenseProvider);

    if (expense == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('No expense selected')),
      );
    }

    final sym       = expense.currency == 'USDC' ? '\$' : '₦';
    final isPending  = expense.status == 'pending';
    final isApproved = expense.status == 'approved';
    final isRejected = expense.status == 'rejected';

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
                  // ── Amount hero ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$sym${expense.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -2,
                            color: cs.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StatusPill(status: expense.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Details card ─────────────────────────────────────
                  _Card(
                    child: Column(
                      children: [
                        _DetailRow('Title',    expense.title),
                        _DetailRow('Category',
                          expense.category[0].toUpperCase() +
                          expense.category.substring(1)),
                        _DetailRow('Currency', expense.currency),
                        _DetailRow('Date',
                          DateFormat('MMM d, yyyy').format(expense.createdAt)),
                        if (expense.description != null &&
                            expense.description!.isNotEmpty)
                          _DetailRow('Note', expense.description!),
                        if (expense.approvedAt != null)
                          _DetailRow('Approved',
                            DateFormat('MMM d, yyyy').format(expense.approvedAt!)),
                        if (expense.rejectionNote != null)
                          _DetailRow('Rejection reason', expense.rejectionNote!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ──────────────────────────────────────────
                  if (isPending) ...[
                    // Approve
                    _PrimaryBtn(
                      label: 'Approve',
                      loading: _approving,
                      onTap: _approving ? null : () => _approve(expense.id),
                    ),
                    const SizedBox(height: 10),
                    // Reject
                    _OutlineBtn(
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      danger: true,
                      loading: _rejecting,
                      onTap: _rejecting ? null : () => _reject(expense.id),
                    ),
                    const SizedBox(height: 10),
                    // Delete (own pending expense)
                    _OutlineBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      danger: true,
                      loading: _deleting,
                      onTap: _deleting ? null : () => _delete(expense.id),
                    ),
                  ] else if (isRejected || isApproved) ...[
                    _OutlineBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      danger: true,
                      loading: _deleting,
                      onTap: _deleting ? null : () => _delete(expense.id),
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
        border: Border.all(color: cs.onSurface.withOpacity(0.05), width: 0.5),
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
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.45))),
          const Spacer(),
          Flexible(
            child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _color(BuildContext ctx) {
    switch (status) {
      case 'approved': return DayFiColors.green;
      case 'pending':  return const Color(0xFFFFA726);
      case 'rejected': return DayFiColors.red;
      default:         return Theme.of(ctx).colorScheme.onSurface.withOpacity(0.4);
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
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 11, fontWeight: FontWeight.w700, color: c),
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
          backgroundColor: cs.onSurface,
          foregroundColor: cs.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.surface))
            : Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger, loading;
  final VoidCallback? onTap;
  const _OutlineBtn({
    required this.label,
    required this.icon,
    this.danger  = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = danger ? DayFiColors.red : cs.onSurface.withOpacity(0.65);
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: danger
                ? DayFiColors.red.withOpacity(0.4)
                : cs.onSurface.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onTap,
        icon: loading
            ? SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, size: 16),
        label: loading
            ? const SizedBox.shrink()
            : Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}