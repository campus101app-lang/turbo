// lib/screens/accounts/accounts_screen.dart
//
// Shows three balance cards: NGN (NGNT), USD (USDC), XLM
// Each card has send/receive shortcuts.
// The NGN card has a "Fund" button that opens the Flutterwave deposit flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/wallet_provider.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/app_background.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(walletProvider);
    const xlmReserve = 2.0;
    final xlmDisplay = (w.xlmBalance - xlmReserve).clamp(0.0, double.infinity);

    // Rates
    final xlmPrice = w.xlmPriceUSD ?? 0.0;
    // ngnRate here = USD per 1 NGN (e.g. 0.00059).  Invert for NGN per USD.
    final usdToNgn = (w.ngnRate != null && w.ngnRate! > 0)
        ? (1 / w.ngnRate!)
        : 1700.0; // fallback

    final ngntUSD  = w.ngntBalance * (w.ngnRate ?? 0);
    final xlmUSD   = xlmDisplay * xlmPrice;
    final xlmNGN   = xlmUSD * usdToNgn;
    final usdcNGN  = w.usdcBalance * usdToNgn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
          children: [
            // ── NGN card ─────────────────────────────────────────────────
            _BalanceCard(
              label: 'Nigerian Naira',
              ticker: 'NGN',
              imagePath: 'assets/images/ngnt.png', // add this asset
              balance: w.ngntBalance,
              decimals: 2,
              subLabel:
                  '≈ \$${ngntUSD.toStringAsFixed(2)} USD',
              accentColor: const Color(0xFF008751), // Nigeria green
              isLoading: w.isLoading,
              actions: [
                _CardAction(
                  icon: Icons.add_rounded,
                  label: 'Fund',
                  onTap: () => context.push('/fund'),
                ),
                _CardAction(
                  icon: Icons.send_rounded,
                  label: 'Send',
                  onTap: () => context.push('/send', extra: {'asset': 'NGNT'}),
                ),
                _CardAction(
                  icon: Icons.qr_code_rounded,
                  label: 'Receive',
                  onTap: () => context.push('/receive', extra: {'asset': 'NGNT'}),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── USDC card ─────────────────────────────────────────────────
            _BalanceCard(
              label: 'Digital Dollar',
              ticker: 'USDC',
              imagePath: 'assets/images/usdc.png',
              balance: w.usdcBalance,
              decimals: 2,
              subLabel:
                  '≈ ₦${(w.usdcBalance * usdToNgn).toStringAsFixed(0)} NGN',
              accentColor: const Color(0xFF2775CA),
              isLoading: w.isLoading,
              actions: [
                _CardAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Swap',
                  onTap: () => context.push('/swap'),
                ),
                _CardAction(
                  icon: Icons.send_rounded,
                  label: 'Send',
                  onTap: () => context.push('/send', extra: {'asset': 'USDC'}),
                ),
                _CardAction(
                  icon: Icons.qr_code_rounded,
                  label: 'Receive',
                  onTap: () => context.push('/receive', extra: {'asset': 'USDC'}),
                ),
              ],
            ),

            // const SizedBox(height: 14),

            // // ── XLM card ──────────────────────────────────────────────────
            // _BalanceCard(
            //   label: 'Stellar Lumen',
            //   ticker: 'XLM',
            //   imagePath: 'assets/images/stellar.png',
            //   balance: xlmDisplay,
            //   decimals: 4,
            //   subLabel: '≈ \$${xlmUSD.toStringAsFixed(2)} USD',
            //   accentColor: const Color(0xFF7B5EA7),
            //   isLoading: w.isLoading,
            //   footnote: '2.0 XLM reserved by Stellar protocol',
            //   actions: [
            //     _CardAction(
            //       icon: Icons.swap_horiz_rounded,
            //       label: 'Swap',
            //       onTap: () => context.push('/swap'),
            //     ),
            //     _CardAction(
            //       icon: Icons.send_rounded,
            //       label: 'Send',
            //       onTap: () => context.push('/send', extra: {'asset': 'XLM'}),
            //     ),
            //     _CardAction(
            //       icon: Icons.qr_code_rounded,
            //       label: 'Receive',
            //       onTap: () => context.push('/receive', extra: {'asset': 'XLM'}),
            //     ),
            //   ],
            // ),

            const SizedBox(height: 32),

            // ── Exchange rate footer ───────────────────────────────────────
            if (w.ngnRate != null)
              Center(
                child: Text(
                  '1 USD ≈ ₦${usdToNgn.toStringAsFixed(0)} · '
                  '1 XLM ≈ \$${(w.xlmPriceUSD ?? 0).toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String label;
  final String ticker;
  final String imagePath;
  final double balance;
  final int decimals;
  final String subLabel;
  final Color accentColor;
  final bool isLoading;
  final String? footnote;
  final List<_CardAction> actions;

  const _BalanceCard({
    required this.label,
    required this.ticker,
    required this.imagePath,
    required this.balance,
    required this.decimals,
    required this.subLabel,
    required this.accentColor,
    required this.isLoading,
    required this.actions,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = ticker == 'USDC'
        ? '\$'
        : ticker == 'NGN' || ticker == 'NGNT'
            ? '₦'
            : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .textTheme
            .bodySmall
            ?.color
            ?.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(imagePath,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              ticker[0],
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                  ),
                  Text(
                    ticker == 'NGNT' ? 'NGN' : ticker,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Balance
          if (isLoading)
            Container(
              height: 44,
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  symbol,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontSize: 22,
                      ),
                ),
                const SizedBox(width: 2),
                Text(
                  balance.toStringAsFixed(decimals),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.88),
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.40),
                    fontSize: 12,
                  ),
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons row
          Row(
            children: actions.map((a) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: a != actions.last ? 8 : 0,
                  ),
                  child: _ActionButton(action: a, accentColor: accentColor),
                ),
              );
            }).toList(),
          ),

          // Footnote (e.g. XLM reserve notice)
          if (footnote != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(width: 4),
                Text(
                  footnote!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
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

class _CardAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CardAction({required this.icon, required this.label, required this.onTap});
}

class _ActionButton extends StatelessWidget {
  final _CardAction action;
  final Color accentColor;
  const _ActionButton({required this.action, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 18, color: accentColor),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}