// lib/screens/accounts/accounts_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _ngnRateProvider = FutureProvider<double>((ref) async {
  try {
    final res = await http
        .get(Uri.parse('https://api.frankfurter.app/latest?from=USD&to=NGN'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['rates']['NGN'] as num).toDouble();
    }
  } catch (_) {}
  return 1700.0;
});

final _txAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final result = await apiService.getTransactions(page: 1, limit: 100);
  return List<Map<String, dynamic>>.from(result['transactions'] ?? []);
});

final _xlmPriceHistoryAccountsProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  try {
    final res = await http
        .get(
          Uri.parse(
            'https://api.coingecko.com/api/v3/coins/stellar/market_chart?vs_currency=usd&days=30&interval=daily',
          ),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prices = data['prices'] as List;
      final result = <String, double>{};
      for (final p in prices) {
        final dt = DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt());
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        result[key] = (p[1] as num).toDouble();
      }
      return result;
    }
  } catch (_) {}
  return {};
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _moversExpanded = true;
  bool _accountsExpanded = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(walletProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<FlSpot> _toSpots(List<double> points) {
    if (points.isEmpty) {
      return [const FlSpot(0, 0.5), const FlSpot(1, 0.5)];
    }

    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    // Flat line — all values equal (e.g. USDC, NGN)
    if (range == 0) {
      return List.generate(points.length, (i) => FlSpot(i.toDouble(), 0.5));
    }

    return List.generate(points.length, (i) {
      final x = i.toDouble();
      final y = (points[i] - min) / range; // normalized 0.0 → 1.0
      return FlSpot(x, y);
    });
  }

  // ── Same chart helpers as HomeScreen ──────────────────────────────────────

  List<double> _buildPoints(
    List<Map<String, dynamic>> txs,
    String asset,
    double currentBalance,
    double xlmPrice,
    Map<String, double> priceHistory,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final filtered =
        txs
            .where((t) {
              final txAsset = t['asset'] as String? ?? '';
              final type = t['type'] as String? ?? '';
              if (txAsset == asset) return true;
              if (type == 'swap') {
                final swapToAsset = t['swapToAsset'] as String? ?? '';
                if (txAsset == asset || swapToAsset == asset) return true;
              }
              return false;
            })
            .where((t) {
              final dt = DateTime.tryParse(t['createdAt'] ?? '');
              return dt != null && dt.isAfter(cutoff);
            })
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              b['createdAt'],
            ).compareTo(DateTime.parse(a['createdAt'])),
          );

    if (filtered.isEmpty) {
      if (asset == 'XLM' && priceHistory.isNotEmpty) {
        return _buildPriceOnlyPoints(currentBalance, xlmPrice, priceHistory);
      }
      final usd = asset == 'XLM' ? currentBalance * xlmPrice : currentBalance;
      return [usd, usd];
    }

    double running = currentBalance;
    final snapshots = <MapEntry<DateTime, double>>[];
    snapshots.add(MapEntry(DateTime.now(), running));

    for (final tx in filtered) {
      final dt = DateTime.parse(tx['createdAt']);
      final amt = (tx['amount'] as num).toDouble().abs();
      final type = tx['type'] as String? ?? '';
      final swapToAsset = tx['swapToAsset'] as String? ?? '';

      if (type == 'receive') {
        running -= amt;
      } else if (type == 'send') {
        running += amt;
      } else if (type == 'swap') {
        if (swapToAsset == asset) {
          running -= amt;
        } else if (tx['asset'] == asset) {
          running += amt;
        }
      }
      running = running.clamp(0, double.infinity);
      snapshots.add(MapEntry(dt, running));
    }

    final chronological = snapshots.reversed.toList();
    return chronological.map((e) {
      final bal = e.value;
      if (asset == 'XLM') {
        final key =
            '${e.key.year}-${e.key.month.toString().padLeft(2, '0')}-${e.key.day.toString().padLeft(2, '0')}';
        final historicalPrice = priceHistory[key] ?? xlmPrice;
        return bal * historicalPrice;
      }
      return bal;
    }).toList();
  }

  List<double> _buildPriceOnlyPoints(
    double balance,
    double currentPrice,
    Map<String, double> priceHistory,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final relevant = priceHistory.entries.where((e) {
      final dt = DateTime.tryParse(e.key);
      return dt != null && dt.isAfter(cutoff);
    }).toList()..sort((a, b) => a.key.compareTo(b.key));

    if (relevant.isEmpty)
      return [balance * currentPrice, balance * currentPrice];
    return relevant.map((e) => balance * e.value).toList()
      ..add(balance * currentPrice);
  }

  double _computeChange(List<double> points) {
    if (points.length < 2) return 0.0;
    final first = points.first;
    if (first <= 0) return 0.0;
    return ((points.last - first) / first) * 100;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(walletProvider);
    final ngnRateAsync = ref.watch(_ngnRateProvider);
    final txAsync = ref.watch(_txAccountsProvider);
    final priceHistoryAsync = ref.watch(_xlmPriceHistoryAccountsProvider);
    final ext = AppThemeExtension.of(context);

    const xlmReserve = 2.0;
    final xlmPrice = w.xlmPriceUSD ?? 0.0;
    final xlmDisplay = (w.xlmBalance - xlmReserve).clamp(0.0, double.infinity);

    final usdToNgn = ngnRateAsync.when(
      data: (rate) => rate,
      loading: () => (w.ngnRate != null && w.ngnRate! > 0)
          ? (w.ngnRate! < 1 ? 1 / w.ngnRate! : w.ngnRate!)
          : 1700.0,
      error: (_, __) => (w.ngnRate != null && w.ngnRate! > 0)
          ? (w.ngnRate! < 1 ? 1 / w.ngnRate! : w.ngnRate!)
          : 1700.0,
    );

    final priceHistory = priceHistoryAsync.value ?? {};
    final txs = txAsync.value ?? [];

    final xlmUSD = xlmDisplay * xlmPrice;
    final ngntUSD = w.ngntBalance * (w.ngnRate ?? 0);
    final assetsInUSD = ngntUSD + w.usdcBalance + xlmUSD;
    final assetsInNGN = assetsInUSD * usdToNgn;

    // Build sparkline points per asset
    final xlmPoints = _buildPoints(
      txs,
      'XLM',
      xlmDisplay,
      xlmPrice,
      priceHistory,
    );
    final usdcPoints = _buildPoints(
      txs,
      'USDC',
      w.usdcBalance,
      1.0,
      priceHistory,
    );
    final ngntPoints = List<double>.filled(
      2,
      w.ngntBalance.toDouble(),
    ); // flat, stable

    final xlmChange = _computeChange(xlmPoints);
    final usdcChange = _computeChange(usdcPoints);
    const ngntChange = 0.0;

    // For portfolio-level change use lastKnownTotal
    final last = w.lastKnownTotal;
    final totalChangePct = (last != null && last > 0)
        ? ((assetsInUSD - last) / last) * 100
        : 0.0;
    final totalUp = totalChangePct >= 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_ngnRateProvider);
          ref.invalidate(_txAccountsProvider);
          ref.invalidate(_xlmPriceHistoryAccountsProvider);
          await ref.read(walletProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 124, 0, 100),
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '\$',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 2,
                                  height: 1,
                                ),
                              ),
                            ),
                            Text(
                              // assetsInNGN.toStringAsFixed(0),
                              assetsInUSD.toStringAsFixed(2),
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1.4,
                                height: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'total balance',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 91, 157, 233),
                            height: 1,
                            letterSpacing: 0.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),

            // ── Top movers ────────────────────────────────────────────
            _FoldableSectionHeader(
              title: 'ALL ASSETS',
              rightLabel: 'ALL ASSETS',
              expanded: _moversExpanded,
              onTap: () => setState(() => _moversExpanded = !_moversExpanded),
            ),

            if (_moversExpanded) ...[
              const SizedBox(height: 6),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 96,
                child: Row(
                  children: [
                    // const SizedBox(width: 8),
                    Expanded(
                      child: _AccountMoverCard(
                        ticker: 'NGN',
                        name: 'NG Naira',
                        gainUp: true,
                        gainAmountAbsNgn: 0,
                        accent: const Color(0xFF008751),
                        line: _toSpots(ngntPoints),
                        imagePath: 'assets/images/ng.png',
                        valueUSD: w.ngntBalance * (w.ngnRate ?? 0), // ← ADD
                        balanceLabel:
                            '${w.ngntBalance.toStringAsFixed(2)} NGNT',
                      ),
                    ),
                    Expanded(
                      child: _AccountMoverCard(
                        ticker: 'USD',
                        name: 'US Dollar',
                        gainUp: usdcChange >= 0,
                        gainAmountAbsNgn:
                            (w.usdcBalance * usdToNgn * usdcChange.abs() / 100),
                        accent: usdcChange >= 0
                            ? DayFiColors.green
                            : ext.errorColor,
                        line: _toSpots(usdcPoints),
                        imagePath: 'assets/images/us.png',
                        valueUSD: w.usdcBalance, // ← ADD
                        balanceLabel:
                            '${w.usdcBalance.toStringAsFixed(2)} USDC',
                      ),
                    ),
                    // ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ─── Foldable section header (exact copy from doc 7) ─────────────────────────

class _FoldableSectionHeader extends StatelessWidget {
  const _FoldableSectionHeader({
    required this.title,
    required this.rightLabel,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final String rightLabel;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // FaIcon(
            //   expanded
            //       ? FontAwesomeIcons.chevronDown
            //       : FontAwesomeIcons.chevronRight,
            //   size: 12,
            //   color: ext.sectionHeader,
            // ),
            // const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .3,
                  color: ext.primaryText,
                ),
              ),
            ),
            // if (rightLabel.trim().isNotEmpty)
            //   Text(
            //     rightLabel,
            //     style: GoogleFonts.bricolageGrotesque(
            //       fontSize: 12,
            //       fontWeight: FontWeight.w700,
            //       color: ext.sectionHeader,
            //       letterSpacing: .300,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

// ─── Mover card (exact styling from doc 7, adapted for accounts) ─────────────

class _AccountMoverCard extends StatelessWidget {
  const _AccountMoverCard({
    required this.ticker,
    required this.name,
    required this.gainUp,
    required this.gainAmountAbsNgn,
    required this.accent,
    required this.line,
    required this.imagePath,
    required this.valueUSD,
    required this.balanceLabel,
  });

  final String ticker;
  final String name;
  final bool gainUp;
  final double gainAmountAbsNgn;
  final Color accent;
  final List<FlSpot> line;
  final String imagePath;
  final double valueUSD;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final maxX = line.isEmpty ? 4.0 : line.last.x;

    return Container(
      // width: (MediaQuery.of(context).size.width * 0.44),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.cardBorder, width: .5),
        color: ext.cardSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                          color: ext.primaryText,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   name,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: GoogleFonts.bricolageGrotesque(
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w400,
                      //     letterSpacing: .3,
                      //     color: ext.primaryText,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imagePath,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.currency_exchange, size: 24, color: accent),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  TextSpan(
                    children: [
                      TextSpan(
                        text: balanceLabel.toString().split(" ").last == "USDC"
                            ? '\$'
                            : balanceLabel.toString().split(" ").last == "NGNT"
                            ? '₦'
                            : '',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ext.primaryText.withValues(alpha: 0.82),
                          letterSpacing: 1,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: balanceLabel.toString().split(" ").first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Text(
                //   balanceLabel.toString().split(" ").last,
                //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                //     color: Theme.of(
                //       context,
                //     ).colorScheme.onSurface.withOpacity(.65),
                //     fontWeight: FontWeight.w500,
                //     fontSize: 12,
                //     height: 1,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
