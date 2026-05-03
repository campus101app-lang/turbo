import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/screens/expenses/expenses_screen.dart';
import 'package:mobile_app/services/api_service.dart' show apiService;

class CreateExpenseScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const CreateExpenseScreen({super.key, required this.insideShell});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'other';
  String _currency = 'NGNT';

  static const _categories = ['office', 'travel', 'food', 'supplies', 'other'];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
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
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _go(int step) async {
    await _fadeCtrl.reverse();
    setState(() => _step = step);
    await _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      _snack('Please fill in all required fields');
      return;
    }
    setState(() => _saving = true);
    try {
      await apiService.createExpense({
        'title': _titleCtrl.text.trim(),
        'amount': amount,
        'category': _category,
        'currency': _currency,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      });
      ref.invalidate(expensesProvider);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header — same pattern as CreateInvoiceScreen
            _ExpenseHeader(
              step: _step,
              onBack: _step > 0 ? () => _go(_step - 1) : null,
              onClose: () => ref.read(shellNavProvider.notifier).goBack(),
            ),
            _StepDots(current: _step, total: 2),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _step == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ELabel('Title'),
                _EField(_titleCtrl, 'e.g. Office Supplies'),
                const SizedBox(height: 16),
                const _ELabel('Amount'),
                _EField(
                  _amountCtrl,
                  '0.00',
                  keyboard: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                const _ELabel('Currency'),
                Row(
                  children: [
                    _EChip(
                      label: 'NGN',
                      sel: _currency == 'NGNT',
                      onTap: () => setState(() => _currency = 'NGNT'),
                    ),
                    const SizedBox(width: 8),
                    _EChip(
                      label: 'USD',
                      sel: _currency == 'USDC',
                      onTap: () => setState(() => _currency = 'USDC'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _ELabel('Category'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (c) => _EChip(
                          label: c[0].toUpperCase() + c.substring(1),
                          sel: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                _EPrimaryBtn(
                  label: 'Continue',
                  onTap: () {
                    final amount = double.tryParse(_amountCtrl.text.trim());
                    if (_titleCtrl.text.trim().isEmpty) {
                      _snack('Title is required');
                      return;
                    }
                    if (amount == null || amount <= 0) {
                      _snack('Enter a valid amount');
                      return;
                    }
                    _go(1);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final sym = _currency == 'USDC' ? '\$' : '₦';
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ELabel('Note (optional)'),
                _EField(_descCtrl, 'Any additional details...', maxLines: 3),
                const SizedBox(height: 24),
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _titleCtrl.text.trim().isNotEmpty
                            ? _titleCtrl.text.trim()
                            : '—',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _category[0].toUpperCase() + _category.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$sym${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _EPrimaryBtn(
                  label: 'Submit Expense',
                  loading: _saving,
                  onTap: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header
class _ExpenseHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  static const _titles = ['Details', 'Review & Submit'];
  const _ExpenseHeader({
    required this.step,
    this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (onBack != null)
            _EIconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!)
          else
            const SizedBox(width: 36),
          Expanded(
            child: Text(
              _titles[step],
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          _EIconBtn(icon: Icons.close_rounded, onTap: onClose),
        ],
      ),
    );
  }
}

// ── Reusable small widgets (prefixed _E to avoid conflicts)
class _ELabel extends StatelessWidget {
  final String text;
  const _ELabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
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

class _EField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final int maxLines;
  const _EField(
    this.ctrl,
    this.hint, {
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.85)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: cs.onSurface.withOpacity(0.3),
        ),
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
        isDense: true,
      ),
    );
  }
}

class _EChip extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  const _EChip({required this.label, required this.sel, required this.onTap});
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
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? cs.surface : cs.onSurface.withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}

class _EPrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _EPrimaryBtn({required this.label, this.onTap, this.loading = false});
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

class _EIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _EIconBtn({required this.icon, required this.onTap});
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

// Reuse _StepDots from create_invoice_screen.dart or copy it here
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
                  : cs.onSurface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
