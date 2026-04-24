// lib/screens/cards/cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class DayFiCard {
  final String id;
  final String cardNumber;
  final String last4;
  final String cardholderName;
  final int expiryMonth;
  final int expiryYear;
  final String type;
  final String currency;
  final String status;
  final String? label;
  final String color;
  final double? spendingLimit;
  final String? spendingLimitPeriod;
  final DateTime createdAt;
  final DateTime? frozenAt;

  const DayFiCard({
    required this.id,
    required this.cardNumber,
    required this.last4,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.type,
    required this.currency,
    required this.status,
    this.label,
    this.color = '#6C47FF',
    this.spendingLimit,
    this.spendingLimitPeriod,
    required this.createdAt,
    this.frozenAt,
  });

  factory DayFiCard.fromJson(Map<String, dynamic> j) => DayFiCard(
        id: j['id'] ?? '',
        cardNumber: j['cardNumber'] ?? '**** **** **** ****',
        last4: j['last4'] ?? '0000',
        cardholderName: j['cardholderName'] ?? '',
        expiryMonth: j['expiryMonth'] ?? 1,
        expiryYear: j['expiryYear'] ?? 2028,
        type: j['type'] ?? 'virtual',
        currency: j['currency'] ?? 'USDC',
        status: j['status'] ?? 'active',
        label: j['label'],
        color: j['color'] ?? '#6C47FF',
        spendingLimit: j['spendingLimit'] != null
            ? (j['spendingLimit'] as num).toDouble()
            : null,
        spendingLimitPeriod: j['spendingLimitPeriod'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        frozenAt: j['frozenAt'] != null ? DateTime.tryParse(j['frozenAt']) : null,
      );

  bool get isActive   => status == 'active';
  bool get isFrozen   => status == 'frozen';
  Color get cardColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6C47FF);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _cardsProvider = FutureProvider.autoDispose<List<DayFiCard>>((ref) async {
  final result = await apiService.getCards();
  return (result['cards'] as List)
      .map((c) => DayFiCard.fromJson(c as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(_cardsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _buildError(context, ref, e.toString()),
        data:    (cards) => _buildBody(context, ref, cards),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Card',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Failed to load cards', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      TextButton(onPressed: () => ref.invalidate(_cardsProvider), child: const Text('Retry')),
    ]));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<DayFiCard> cards) {
    if (cards.isEmpty) return _EmptyState(onTap: () => _showCreateSheet(context, ref));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_cardsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        children: [
          // Horizontal card scroll
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) => _CardVisual(
                card: cards[i],
                onTap: () => _showDetailSheet(context, ref, cards[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary
          _SummaryRow(cards: cards),
          const SizedBox(height: 20),

          // List
          Text('All Cards',
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              )),
          const SizedBox(height: 10),
          ...cards.map((c) => _CardTile(
                card: c,
                onTap: () => _showDetailSheet(context, ref, c),
              )),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CreateCardSheet(onCreated: () => ref.invalidate(_cardsProvider)),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, DayFiCard card) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CardDetailSheet(card: card, onRefresh: () => ref.invalidate(_cardsProvider)),
    );
  }
}

// ─── Card visual (the skeuomorphic card) ─────────────────────────────────────

class _CardVisual extends StatelessWidget {
  final DayFiCard card;
  final VoidCallback onTap;
  const _CardVisual({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.72;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: card.isFrozen
                ? [Colors.grey.shade700, Colors.grey.shade900]
                : [
                    card.cardColor,
                    card.cardColor.withOpacity(0.7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: card.isFrozen
                  ? Colors.black.withOpacity(0.3)
                  : card.cardColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(children: [
          // Frosted overlay if frozen
          if (card.isFrozen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.ac_unit_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text('FROZEN',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        )),
                  ]),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(card.label ?? '${card.currency} Card',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(card.type.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        )),
                  ),
                ]),

                // Card number
                Text(card.cardNumber,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      letterSpacing: 2,
                    )),

                // Bottom row
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CARDHOLDER',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9, letterSpacing: 1,
                        )),
                    Text(card.cardholderName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        )),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('EXPIRES',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9, letterSpacing: 1,
                        )),
                    Text(
                      '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear.toString().substring(2)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<DayFiCard> cards;
  const _SummaryRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    final active   = cards.where((c) => c.isActive).length;
    final frozen   = cards.where((c) => c.isFrozen).length;
    final usdcCards = cards.where((c) => c.currency == 'USDC').length;

    return Row(children: [
      Expanded(child: _SummaryCard(label: 'Active', value: '$active', color: DayFiColors.green)),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(label: 'Frozen', value: '$frozen', color: const Color(0xFF64B5F6))),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(label: 'USDC', value: '$usdcCards', color: const Color(0xFF6C47FF))),
    ]);
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
            style: GoogleFonts.outfit(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
              color: color, fontWeight: FontWeight.w700, fontSize: 22)),
      ]),
    );
  }
}

// ─── Card tile (list row) ─────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final DayFiCard card;
  final VoidCallback onTap;
  const _CardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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
          // Color dot
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: card.cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              card.isFrozen ? Icons.ac_unit_rounded : Icons.credit_card_rounded,
              color: card.isFrozen ? Colors.blueAccent : card.cardColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.label ?? '${card.currency} Card',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: ext.primaryText,
                  )),
              Text('•••• ${card.last4} · ${card.currency}',
                  style: GoogleFonts.outfit(
                    fontSize: 12, color: ext.secondaryText)),
            ]),
          ),
          _StatusPill(status: card.status),
        ]),
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'active':    return DayFiColors.green;
      case 'frozen':    return const Color(0xFF64B5F6);
      case 'cancelled': return DayFiColors.red;
      default:          return const Color(0xFF6C47FF);
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
        Icon(Icons.credit_card_rounded, size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
        const SizedBox(height: 6),
        Text('No cards yet', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('Create a virtual card to start spending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            )),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Card'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ]),
    );
  }
}

// ─── Create card sheet ────────────────────────────────────────────────────────

class _CreateCardSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateCardSheet({required this.onCreated});

  @override
  ConsumerState<_CreateCardSheet> createState() => _CreateCardSheetState();
}

class _CreateCardSheetState extends ConsumerState<_CreateCardSheet> {
  final _nameCtrl  = TextEditingController();
  final _labelCtrl = TextEditingController();
  String _currency = 'USDC';
  String _color    = '#6C47FF';
  bool   _loading  = false;

  static const _palette = [
    '#6C47FF', '#FF6B6B', '#00BFA5', '#FF8F00',
    '#1E88E5', '#E91E63', '#43A047',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cardholder name is required')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await apiService.createCard({
        'cardholderName': _nameCtrl.text.trim(),
        'currency':       _currency,
        'label':          _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        'color':          _color,
      });

      // Show CVV once
      final cvv = result['cvv'] as String?;
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        if (cvv != null) {
          showDayFiBottomSheet(
            context: context,
            child: _CvvRevealSheet(cvv: cvv),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        Text('New Virtual Card',
            style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w700, color: ext.primaryText)),
        const SizedBox(height: 20),

        _Label('Cardholder Name'),
        const SizedBox(height: 6),
        _Field(controller: _nameCtrl, hint: 'e.g. Tunde Okafor'),
        const SizedBox(height: 16),

        _Label('Card Label (optional)'),
        const SizedBox(height: 6),
        _Field(controller: _labelCtrl, hint: 'e.g. Marketing Card'),
        const SizedBox(height: 16),

        _Label('Currency'),
        const SizedBox(height: 8),
        Row(children: [
          _CurrencyOption(
            label: 'USDC', subtitle: 'Spend globally',
            selected: _currency == 'USDC',
            onTap: () => setState(() => _currency = 'USDC'),
          ),
          const SizedBox(width: 12),
          _CurrencyOption(
            label: 'NGN', subtitle: 'Naira spending',
            selected: _currency == 'NGN',
            onTap: () => setState(() => _currency = 'NGN'),
          ),
        ]),
        const SizedBox(height: 16),

        _Label('Card Color'),
        const SizedBox(height: 8),
        Row(
          children: _palette.map((hex) {
            Color c;
            try { c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
            catch (_) { c = const Color(0xFF6C47FF); }
            final selected = _color == hex;
            return GestureDetector(
              onTap: () => setState(() => _color = hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 10),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: selected
                      ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

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
                : Text('Create Card',
                    style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _CurrencyOption({
    required this.label, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary.withOpacity(0.4)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: selected ? primary : Theme.of(context).colorScheme.onSurface,
                )),
            Text(subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                )),
          ]),
        ),
      ),
    );
  }
}

// ─── CVV reveal sheet (shown once after creation) ─────────────────────────────

class _CvvRevealSheet extends StatelessWidget {
  final String cvv;
  const _CvvRevealSheet({required this.cvv});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Icon(Icons.shield_rounded,
            size: 48, color: DayFiColors.green),
        const SizedBox(height: 12),
        Text('Your CVV',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Save this now — it will never be shown again',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            )),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: DayFiColors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DayFiColors.green.withOpacity(0.3)),
          ),
          child: Text(cvv,
              style: GoogleFonts.spaceMono(
                fontSize: 36, fontWeight: FontWeight.w700,
                color: DayFiColors.green, letterSpacing: 8,
              )),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('I\'ve saved it',
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

// ─── Card detail sheet ────────────────────────────────────────────────────────

class _CardDetailSheet extends StatefulWidget {
  final DayFiCard card;
  final VoidCallback onRefresh;
  const _CardDetailSheet({required this.card, required this.onRefresh});

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  bool _toggling  = false;
  bool _cancelling = false;

  Future<void> _toggleFreeze() async {
    setState(() => _toggling = true);
    try {
      if (widget.card.isFrozen) {
        await apiService.unfreezeCard(widget.card.id);
      } else {
        await apiService.freezeCard(widget.card.id);
      }
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel card?'),
        content: const Text('This action cannot be undone. The card will be permanently cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Card', style: TextStyle(color: DayFiColors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _cancelling = true);
    try {
      await apiService.cancelCard(widget.card.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          Text('Card Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ]),
        const SizedBox(height: 20),

        // Mini card visual
        _CardVisual(card: c, onTap: () {}),
        const SizedBox(height: 20),

        _DetailRow(label: 'Card number', value: c.cardNumber),
        _DetailRow(label: 'Currency',    value: c.currency),
        _DetailRow(label: 'Type',        value: c.type),
        _DetailRow(label: 'Status',      value: c.status),
        if (c.spendingLimit != null)
          _DetailRow(
            label: 'Spend limit',
            value: '${c.currency == 'USDC' ? '\$' : '₦'}${NumberFormat('#,##0').format(c.spendingLimit)} / ${c.spendingLimitPeriod}',
          ),
        _DetailRow(label: 'Created',
            value: DateFormat('MMM d, yyyy').format(c.createdAt)),

        const SizedBox(height: 24),

        // Actions
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: c.isFrozen
                      ? DayFiColors.green.withOpacity(0.5)
                      : const Color(0xFF64B5F6).withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _toggling ? null : _toggleFreeze,
              icon: _toggling
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(
                      c.isFrozen ? Icons.play_circle_outline_rounded : Icons.ac_unit_rounded,
                      size: 18,
                      color: c.isFrozen ? DayFiColors.green : const Color(0xFF64B5F6),
                    ),
              label: Text(
                c.isFrozen ? 'Unfreeze' : 'Freeze',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: c.isFrozen ? DayFiColors.green : const Color(0xFF64B5F6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: DayFiColors.red.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cancelling ? null : _cancel,
              icon: _cancelling
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.cancel_outlined, size: 18, color: DayFiColors.red),
              label: Text('Cancel',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, color: DayFiColors.red)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w500, fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field({required this.controller, required this.hint,
      this.maxLines = 1, this.keyboardType});

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