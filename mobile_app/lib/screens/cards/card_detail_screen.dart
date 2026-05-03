// lib/screens/cards/card_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/selected_card_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import 'cards_screen.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const CardDetailScreen({super.key, this.insideShell = false});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  bool _toggling = false;
  bool _cancelling = false;

  Future<void> _toggleFreeze(DayFiCard card) async {
    final action = card.isFrozen ? 'Unfreeze' : 'Freeze';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action card?'),
        content: Text('This will ${action.toLowerCase()} this card for payments.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _toggling = true);
    try {
      if (card.isFrozen) {
        await apiService.unfreezeCard(card.id);
      } else {
        await apiService.freezeCard(card.id);
      }
      if (mounted) {
        ref.read(shellNavProvider.notifier).goBack();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(card.isFrozen ? 'Card unfrozen.' : 'Card frozen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _cancel(DayFiCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel card?'),
        content: const Text('This cannot be undone. The card will be permanently cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Card', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      await apiService.cancelCard(card.id);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
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
    final card = ref.watch(selectedCardProvider);
    if (card == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellNavProvider.notifier).goBack();
      });
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

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
          card.label ?? '${card.currency} Card',
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
            // Card visual
            CardVisual(card: card, onTap: () {}),
            const SizedBox(height: 24),

            // Details
            _DetailRow(label: 'Card number', value: card.cardNumber),
            _DetailRow(label: 'Currency', value: card.currency),
            _DetailRow(label: 'Type', value: card.type),
            _DetailRow(label: 'Status', value: card.status),
            if (card.spendingLimit != null)
              _DetailRow(
                label: 'Spend limit',
                value:
                    '${card.currency == 'USDC' || card.currency == 'USD' ? '\$' : '₦'}${NumberFormat('#,##0').format(card.spendingLimit)} / ${card.spendingLimitPeriod}',
              ),
            _DetailRow(
              label: 'Created',
              value: DateFormat('MMM d, yyyy').format(card.createdAt),
            ),

            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: card.isFrozen
                            ? DayFiColors.green.withValues(alpha: 0.5)
                            : const Color(0xFF64B5F6).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_toggling || _cancelling)
                        ? null
                        : () => _toggleFreeze(card),
                    icon: _toggling
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            card.isFrozen
                                ? Icons.play_circle_outline_rounded
                                : Icons.ac_unit_rounded,
                            size: 18,
                            color: card.isFrozen
                                ? DayFiColors.green
                                : const Color(0xFF64B5F6),
                          ),
                    label: Text(
                      card.isFrozen ? 'Unfreeze' : 'Freeze',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w600,
                        color: card.isFrozen
                            ? DayFiColors.green
                            : const Color(0xFF64B5F6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: DayFiColors.red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_cancelling || _toggling)
                        ? null
                        : () => _cancel(card),
                    icon: _cancelling
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cancel_outlined,
                            size: 18, color: DayFiColors.red),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w600,
                        color: DayFiColors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return widget.insideShell ? body : AppBackground(child: body);
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    )),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
