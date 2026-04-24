// lib/screens/expenses/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart'; // for ngnRateProvider
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
      body: expAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (expenses) => _buildBody(context, ref, expenses, userAsync),
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
          onTap: () => _showCreateSheet(context, ref),
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
      return _EmptyState(onTap: () => _showCreateSheet(context, ref));
    }

    final pending = expenses.where((e) => e.status == 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_expensesProvider),
      child: _ExpensesBody(
        expenses: expenses,
        pending: pending,
        isMerchant: isMerchant,
        currentUserId: currentUserId,
        onShowDetail: (e) =>
            _showDetailSheet(context, ref, e, isMerchant, currentUserId),
        onShowCreate: () => _showCreateSheet(context, ref),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CreateExpenseSheet(
        onCreated: () {
          // Invalidate both providers to ensure data refreshes
          ref.invalidate(_expensesProvider);
          ref.invalidate(_userMeProvider);
        },
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    bool isMerchant,
    String? currentUserId,
  ) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _ExpenseDetailSheet(
        expense: expense,
        isMerchant: isMerchant,
        currentUserId: currentUserId,
        onRefresh: () => ref.invalidate(_expensesProvider),
      ),
    );
  }
}

// ─── Body (ConsumerWidget so it can watch ngnRateProvider) ───────────────────

class _ExpensesBody extends ConsumerWidget {
  final List<Expense> expenses;
  final List<Expense> pending;
  final bool isMerchant;
  final String? currentUserId;
  final ValueChanged<Expense> onShowDetail;
  final VoidCallback onShowCreate;

  const _ExpensesBody({
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 118, 16, 100),
      children: [
        // ── Summary row ──────────────────────────────────────────────
        _SummaryRow(expenses: expenses, usdToNgn: usdToNgn),
        const SizedBox(height: 32),

        // ── My Expenses (date-grouped) ───────────────────────────────
        _SectionLabel(label: 'My Expenses', count: myExpenses.length),
        const SizedBox(height: 8),

        for (final dateLabel in dateKeys) ...[
          // Date sub-header
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          for (final e in grouped[dateLabel]!)
            _ExpenseTile(
              expense: e,
              usdToNgn: usdToNgn,
              onTap: () => onShowDetail(e),
            ),
        ],

        // ── Pending Approval (merchants only) ────────────────────────
        if (isMerchant && pending.isNotEmpty) ...[
          const SizedBox(height: 32),
          _SectionLabel(label: 'Pending Approval', count: pending.length),
          const SizedBox(height: 8),
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

  List<String> _sortedDateKeys(Map<String, List<Expense>> grouped) {
    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      // Both are "MMM d" — compare by the first expense date in each group
      final da = grouped[a]!.first.createdAt;
      final db = grouped[b]!.first.createdAt;
      return db.compareTo(da); // newest first
    });
    return keys;
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends ConsumerWidget {
  final List<Expense> expenses;
  final double usdToNgn;

  const _SummaryRow({required this.expenses, required this.usdToNgn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double approvedNgn = 0;
    double pendingNgn = 0;
    double rejectedNgn = 0;

    for (final e in expenses) {
      final ngn = e.toNgn(usdToNgn);
      if (e.status == 'approved' || e.status == 'reimbursed') {
        approvedNgn += ngn;
      }
      if (e.status == 'pending') pendingNgn += ngn;
      if (e.status == 'rejected') rejectedNgn += ngn;
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Approved',
            amountNgn: approvedNgn,
            usdToNgn: usdToNgn,
            color: DayFiColors.green,
            icon: FontAwesomeIcons.checkCircle,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _SummaryCard(
            label: 'Pending',
            amountNgn: pendingNgn,
            usdToNgn: usdToNgn,
            color: const Color(0xFFFFA726),
            icon: FontAwesomeIcons.hourglassHalf,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _SummaryCard(
            label: 'Rejected',
            amountNgn: rejectedNgn,
            usdToNgn: usdToNgn,
            color: DayFiColors.red,
            icon: FontAwesomeIcons.xmarkCircle,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amountNgn;
  final double usdToNgn;
  final Color color;
  final FaIconData icon;

  const _SummaryCard({
    required this.label,
    required this.amountNgn,
    required this.usdToNgn,
    required this.color,
    required this.icon,
  });

  String _fmtNgn(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  String _fmtUsd(double ngn, double rate) {
    if (rate <= 0) return '\$0.00';
    final usd = ngn / rate;
    if (usd >= 1000) return '\$${(usd / 1000).toStringAsFixed(1)}k';
    return '\$${usd.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.cardBorder, width: .75),
        color: ext.monthlyCardSurface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            FaIcon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            // Text(
            //   label,
            //   style: GoogleFonts.outfit(
            //     fontSize: 10,
            //     fontWeight: FontWeight.w500,
            //     letterSpacing: .4,
            //     color: color,
            //   ),
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            // ),
            // const SizedBox(height: 8),
            // ── Primary: NGN ─────────────────────────────────────────
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '₦',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: ext.primaryText,
                    ),
                  ),
                  TextSpan(
                    text: _fmtNgn(amountNgn),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .8,
                      color: ext.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            // ── Secondary: USD equivalent ─────────────────────────────
            Text(
              _fmtUsd(amountNgn, usdToNgn),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ext.secondaryText.withOpacity(0.7),
                letterSpacing: .3,
              ),
            ),
          ],
        ),
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

// ─── Expense tile ─────────────────────────────────────────────────────────────

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
    final ext = AppThemeExtension.of(context);

    // Always display in NGN; show USD equivalent as subtitle
    final ngnAmount = expense.toNgn(usdToNgn);
    final usdAmount = expense.currency == 'NGNT'
        ? (usdToNgn > 0 ? ngnAmount / usdToNgn : 0.0)
        : expense.amount; // USDC is already USD

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: ext.cardSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              _categoryIcon(expense.category),
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.95),
                      letterSpacing: .4,
                    ),
                  ),
                  // const SizedBox(height: 2),
                  Text(
                    '${expense.category[0].toUpperCase()}${expense.category.substring(1)}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: -.1,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        expense.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .1,
                          height: 1.4,
                        ),

                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Amount + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Primary: NGN
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '₦',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: _fmtNgn(ngnAmount),
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(.95),
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Secondary: USD equivalent
                  Text(
                    '\$${usdAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: -.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtNgn(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return NumberFormat('#,##0').format(v);
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'travel':
        return Icons.flight_rounded;
      case 'meals':
        return Icons.restaurant_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'equipment':
        return Icons.devices_rounded;
      case 'software':
        return Icons.code_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'salary':
        return Icons.payments_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Text(
      _label(status).toUpperCase(),
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ext.sectionHeader,
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'reimbursed':
        return 'Reimbursed';
      case 'my_expenses':
        return 'My Expenses';
      case 'pending_approval':
        return 'Pending Approval';
      default:
        return '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense guides are coming soon.')),
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
                      'track your business spending',
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
                                'ADD EXPENSE',
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

// ─── Create expense sheet ─────────────────────────────────────────────────────

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
              color: ext.primaryText,
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
              isWarning: true,
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

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isWarning;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isWarning ? DayFiColors.red : null,
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
