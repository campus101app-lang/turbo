// lib/screens/cards/create_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class CreateCardScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const CreateCardScreen({super.key, this.insideShell = false});

  @override
  ConsumerState<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends ConsumerState<CreateCardScreen> {
  final _nameCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '5');
  // Flutterwave virtual cards use "USD" not "USDC"
  String _currency = 'USD';
  String _color = '#6C47FF';
  bool _loading = false;

  static const _palette = [
    '#6C47FF',
    '#FF6B6B',
    '#00BFA5',
    '#FF8F00',
    '#1E88E5',
    '#E91E63',
    '#43A047',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Cardholder name is required');
      return;
    }
    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt < 5) {
      _snack('Minimum initial deposit is \$5');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await apiService.createCard({
        'cardholderName': name,
        'currency': _currency,
        'amount': amt,
        if (_labelCtrl.text.trim().isNotEmpty) 'label': _labelCtrl.text.trim(),
        'color': _color,
      });

      final cvv = result['cvv'] as String?;
      if (mounted) {
        final notifier = ref.read(shellNavProvider.notifier);
        notifier.goBack();
        if (cvv != null) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                'Save your CVV',
                style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This is shown once only. Write it down.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cvv,
                      style: GoogleFonts.spaceMono(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = AppThemeExtension.of(context);

    Widget body = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => ref.read(shellNavProvider.notifier).goBack(),
        ),
        title: Text(
          'New Virtual Card',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Virtual cards are issued in USD. An initial deposit is required to activate the card.',
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _Label('Cardholder Name', ext),
            const SizedBox(height: 6),
            _Field(controller: _nameCtrl, hint: 'e.g. Tunde Okafor'),
            const SizedBox(height: 16),

            _Label('Card Label (optional)', ext),
            const SizedBox(height: 6),
            _Field(controller: _labelCtrl, hint: 'e.g. Marketing Card'),
            const SizedBox(height: 16),

            _Label('Initial Deposit (USD)', ext),
            const SizedBox(height: 6),
            _Field(
              controller: _amountCtrl,
              hint: 'Min \$5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Funds are loaded from your USDC balance',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 20),

            _Label('Card Color', ext),
            const SizedBox(height: 10),
            Row(
              children: _palette.map((hex) {
                Color c;
                try {
                  c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                } catch (_) {
                  c = const Color(0xFF6C47FF);
                }
                final selected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Create Card',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    return widget.insideShell ? body : AppBackground(child: body);
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppThemeExtension ext;
  const _Label(this.text, this.ext);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ext.sectionHeader,
          letterSpacing: 0.2,
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
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.bricolageGrotesque(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35), fontSize: 14),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
