// lib/screens/cards/cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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

  bool get isActive => status == 'active';
  bool get isFrozen => status == 'frozen';
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
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (cards) => _buildBody(context, ref, cards),
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
            'Failed to load cards',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(_cardsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<DayFiCard> cards,
  ) {
    if (cards.isEmpty)
      // ignore: curly_braces_in_flow_control_structures
      return _EmptyState(onTap: () => _showCreateSheet(context, ref));

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
              itemBuilder: (_, i) => CardVisual(
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
          Text(
            'All Cards',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          ...cards.map(
            (c) => _CardTile(
              card: c,
              onTap: () => _showDetailSheet(context, ref, c),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    ref.read(shellNavProvider.notifier).goTo(ShellDest.createCard);
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, DayFiCard card) {
    ref.read(selectedCardProvider.notifier).state = card;
    ref.read(shellNavProvider.notifier).goTo(ShellDest.cardDetail);
  }
}

// ─── Card visual (the skeuomorphic card) ─────────────────────────────────────

class CardVisual extends StatelessWidget {
  final DayFiCard card;
  final VoidCallback onTap;
  const CardVisual({super.key, required this.card, required this.onTap});

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
                : [card.cardColor, card.cardColor.withOpacity(0.7)],
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
        child: Stack(
          children: [
            // Frosted overlay if frozen
            if (card.isFrozen)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FROZEN',
                          style: GoogleFonts.bricolageGrotesque(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.label ?? '${card.currency} Card',
                        style: GoogleFonts.bricolageGrotesque(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.type.toUpperCase(),
                          style: GoogleFonts.bricolageGrotesque(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Card number
                  Text(
                    card.cardNumber,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),

                  // Bottom row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARDHOLDER',
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            card.cardholderName.toUpperCase(),
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXPIRES',
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear.toString().substring(2)}',
                            style: GoogleFonts.bricolageGrotesque(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final active = cards.where((c) => c.isActive).length;
    final frozen = cards.where((c) => c.isFrozen).length;
    final usdcCards = cards.where((c) => c.currency == 'USDC').length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Active',
            value: '$active',
            color: DayFiColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Frozen',
            value: '$frozen',
            color: const Color(0xFF64B5F6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'USDC',
            value: '$usdcCards',
            color: const Color(0xFF6C47FF),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.bricolageGrotesque(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
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
                color: Theme.of(context).colorScheme.surface,
                          
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          , width: .5),
        ),
        child: Row(
          children: [
            // Color dot
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card.cardColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                card.isFrozen
                    ? Icons.ac_unit_rounded
                    : Icons.credit_card_rounded,
                color: card.isFrozen ? Colors.blueAccent : card.cardColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label ?? '${card.currency} Card',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                    ),
                  ),
                  Text(
                    '•••• ${card.last4} · ${card.currency}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      color: ext.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(status: card.status),
          ],
        ),
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
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'active':
        return DayFiColors.green;
      case 'frozen':
        return const Color(0xFF64B5F6);
      case 'cancelled':
        return DayFiColors.red;
      default:
        return const Color(0xFF6C47FF);
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card tips and walkthrough are coming soon.')),
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
                      color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          .withValues(alpha: 0.5),
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
                  border: Border.all(color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          , width: .5),
                        color: Theme.of(context).colorScheme.surface,
                          
                ),
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'spend globally with a virtual card',
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
                              foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: onTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'CREATE CARD',
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
                              foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
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

