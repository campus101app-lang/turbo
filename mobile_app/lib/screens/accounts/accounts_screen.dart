// lib/screens/accounts/accounts_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/theme/app_theme.dart';
import '../../providers/shell_navigation_provider.dart';
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
  return 1600.0;
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
  Timer? _refreshTimer;
  String? _drillAsset; // null = show all, 'USDC' | 'NGNT'

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

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
      final amt = _asDouble(tx['amount']).abs();
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

    if (relevant.isEmpty) {
      return [balance * currentPrice, balance * currentPrice];
    }
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

    // const xlmReserve = 1.5;
    // final xlmPrice = w.xlmPriceUSD ?? 0.0;
    // final xlmDisplay = (w.xlmBalance - xlmReserve).clamp(0.0, double.infinity);

    final usdToNgn = ngnRateAsync.when(
      data: (rate) => rate,
      loading: () => (w.ngnRate != null && w.ngnRate! > 0)
          ? (w.ngnRate! < 1 ? 1 / w.ngnRate! : w.ngnRate!)
          : 1600.0,
      error: (_, __) => (w.ngnRate != null && w.ngnRate! > 0)
          ? (w.ngnRate! < 1 ? 1 / w.ngnRate! : w.ngnRate!)
          : 1600.0,
    );

    final priceHistory = priceHistoryAsync.value ?? {};
    final txs = txAsync.value ?? [];

    // final xlmUSD = xlmDisplay * xlmPrice;
    final ngntUSD = w.ngntBalance * (w.ngnRate ?? 0);
    final assetsInUSD = ngntUSD + w.usdcBalance;

    // final assetsInNGN = assetsInUSD * usdToNgn;

    // Build sparkline points per asset
    // final xlmPoints = _buildPoints(
    //   txs,
    //   'XLM',
    //   xlmDisplay,
    //   xlmPrice,
    //   priceHistory,
    // );
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

    // final xlmChange = _computeChange(xlmPoints);
    final usdcChange = _computeChange(usdcPoints);
    // const ngntChange = 0.0;

    // For portfolio-level change use lastKnownTotal
    // final last = w.lastKnownTotal;
    // final totalChangePct = (last != null && last > 0)
    // ? ((assetsInUSD - last) / last) * 100
    // : 0.0;
    // final totalUp = totalChangePct >= 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // bottomNavigationBar: _buildActionRow(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.00),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_ngnRateProvider);
              ref.invalidate(_txAccountsProvider);
              ref.invalidate(_xlmPriceHistoryAccountsProvider);
              await ref.read(walletProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 32.0, 0, 100),
              children: [
                //    // ── Top movers ────────────────────────────────────────────
                // _FoldableSectionHeader(
                //   title: 'ALL ASSETS',
                //   rightLabel: 'ALL ASSETS',
                //   expanded: _moversExpanded,
                //   onTap: () => setState(() => _moversExpanded = !_moversExpanded),
                // ),
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
                              ).colorScheme.onSurface.withOpacity(0.04),
                              width: 1,
                            ),
                            color: Theme.of(
                              context,
                            ).canvasColor.withOpacity(.75),
                          ),
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.04),
                            width: .5,
                          ),
                          color: Theme.of(context).colorScheme.surface,
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
                                      // color: Theme.of(
                                      //   context,
                                      // ).colorScheme.primary,
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
                                    // color: Theme.of(
                                    //   context,
                                    // ).colorScheme.primary,
                                    letterSpacing: .4,
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
                                // color: const Color.fromARGB(255, 91, 157, 233),
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

                const SizedBox(height: 8),
                // ── Two asset cards ────────────────────────────────────
                _buildAssetCards(w, usdcChange, usdcPoints, ngntPoints, ext, usdToNgn),

                const SizedBox(height: 10),
                // ── Swap button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => ref.read(shellNavProvider.notifier).goTo(ShellDest.swap),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF008751).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF008751).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.swap_horiz_rounded,
                                color: Color(0xFF008751), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Swap NGNT ↔ USDC',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Exchange on-chain instantly',
                                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // ── Transaction drill-down ─────────────────────────────
                _buildTxSection(txs, ext),

                const SizedBox(height: 12),
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
                              ).colorScheme.onSurface.withOpacity(0.04),
                              width: 1,
                            ),
                            color: Theme.of(
                              context,
                            ).canvasColor.withOpacity(.75),
                          ),
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.04),
                            width: .5,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'make it yours',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: .4,
                                // color: ext.sectionHeader,
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(.555)
                                          .withOpacity(.06),
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(.555),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Account customization is coming soon.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        15,
                                        0,
                                        15,
                                      ),
                                      child: Text(
                                        'TRY IT',
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: .2,
                                          height: 1,
                                          // color: ext.sectionHeader,
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(.555)
                                          .withOpacity(.06),
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(.555),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'More account options are coming soon.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        15,
                                        0,
                                        15,
                                      ),
                                      child: Text(
                                        'OKAY',
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: .2,
                                          height: 1,
                                          // color: ext.sectionHeader,
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
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Asset cards row (3 cards, horizontally scrollable) ────────────────────

  Widget _buildAssetCards(
    WalletState w,
    double usdcChange,
    List<double> usdcPoints,
    List<double> ngntPoints,
    AppThemeExtension ext,
    double usdToNgn,
  ) {

    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // NGNT card
          SizedBox(
            width: 160,
            child: GestureDetector(
              onTap: () => setState(() =>
                  _drillAsset = _drillAsset == 'NGNT' ? null : 'NGNT'),
              child: _cardBorder(
                _drillAsset == 'NGNT',
                AccountMoverCard(
                  ticker: 'NGN',
                  name: 'NG Naira',
                  gainUp: true,
                  gainAmountAbsNgn: 0,
                  accent: const Color(0xFF008751),
                  line: _toSpots(ngntPoints),
                  imagePath: 'assets/images/ng.png',
                  valueUSD: w.ngntBalance * (w.ngnRate ?? 0),
                  balanceLabel: '${w.ngntBalance.toStringAsFixed(2)} NGNT',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // USDC card
          SizedBox(
            width: 160,
            child: GestureDetector(
              onTap: () => setState(() =>
                  _drillAsset = _drillAsset == 'USDC' ? null : 'USDC'),
              child: _cardBorder(
                _drillAsset == 'USDC',
                AccountMoverCard(
                  ticker: 'USD',
                  name: 'US Dollar',
                  gainUp: usdcChange >= 0,
                  gainAmountAbsNgn:
                      w.usdcBalance * usdToNgn * usdcChange.abs() / 100,
                  accent: usdcChange >= 0 ? DayFiColors.green : ext.errorColor,
                  line: _toSpots(usdcPoints),
                  imagePath: 'assets/images/us.png',
                  valueUSD: w.usdcBalance,
                  balanceLabel: '${w.usdcBalance.toStringAsFixed(2)} USDC',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _cardBorder(bool selected, Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: selected
            ? Border.all(color: DayFiColors.blue, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  // ── Transaction drill-down section ─────────────────────────────────────────

  Widget _buildTxSection(
      List<Map<String, dynamic>> txs, AppThemeExtension ext) {
    if (_drillAsset == null) return const SizedBox.shrink();

    final filtered = txs.where((t) {
      final asset = t['asset'] as String? ?? '';
      final swapTo = t['swapToAsset'] as String? ?? '';
      return asset == _drillAsset || swapTo == _drillAsset;
    }).take(20).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(children: [
                Text(
                  '$_drillAsset Transactions',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _drillAsset = null),
                  child: const Icon(Icons.close, size: 18),
                ),
              ]),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text('No transactions found.',
                    style: TextStyle(color: ext.secondaryText)),
              )
            else
              ...filtered.map((tx) {
                final type = tx['type'] as String? ?? '';
                final isIn = ['receive', 'deposit'].contains(type);
                final amt = (tx['amount'] as num?)?.toDouble() ?? 0;
                final asset = tx['asset'] as String? ?? '';
                final dt =
                    DateTime.tryParse(tx['createdAt']?.toString() ?? '');
                final label = tx['memo'] as String? ??
                    tx['recipientAddress'] as String? ??
                    type;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        (isIn ? DayFiColors.green : DayFiColors.red)
                            .withValues(alpha: 0.15),
                    child: Icon(
                      isIn
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 13,
                      color: isIn ? DayFiColors.green : DayFiColors.red,
                    ),
                  ),
                  title: Text(
                    label.length > 28
                        ? '${label.substring(0, 26)}…'
                        : label,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: dt != null
                      ? Text(
                          '${dt.day}/${dt.month}/${dt.year}',
                          style: TextStyle(
                              fontSize: 11, color: ext.secondaryText),
                        )
                      : null,
                  trailing: Text(
                    '${isIn ? '+' : '−'}${amt.toStringAsFixed(2)} $asset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isIn ? DayFiColors.green : DayFiColors.red,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    final walletState = ref.watch(walletProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 88, vertical: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            _ActionButton(
              icon: "assets/icons/svgs/receive.svg",
              label: 'Receive',
              onTap: () => context.push('/receive'),
            ),
            _ActionButton(
              icon: "assets/icons/svgs/swap.svg",
              label: 'Swap',
              onTap: () => _handleSwapTap(walletState),
            ),
            _ActionButton(
              icon: "assets/icons/svgs/send.svg",
              label: 'Send',
              onTap: () => _handleSendTap(walletState),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0);
  }

  void _handleSendTap(WalletState walletState) {
    if (walletState.usdcBalance == 0 && walletState.xlmBalance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Cannot send: wallet has no balance'),
          backgroundColor: Color(0xFFFFA726),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    context.push('/send');
  }

  void _handleSwapTap(WalletState walletState) {
    if (walletState.usdcBalance == 0 && walletState.xlmBalance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Cannot swap: wallet has no balance'),
          backgroundColor: Color(0xFFFFA726),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    context.push('/swap');
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                height: 22,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.60),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
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
                  fontWeight: FontWeight.w600,
                  color: ext.sectionHeader,
                  // letterSpacing: -.1,
                  fontSize: 12,
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

class AccountMoverCard extends StatelessWidget {
  const AccountMoverCard({
    super.key,
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
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          width: .5,
        ),
        color: Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.555),
                        ),
                      ),
                      // Text(
                      //   balanceLabel.toString().split(" ").last,
                      //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      //     color: Theme.of(
                      //       context,
                      //     ).colorScheme.onSurface.withOpacity(.65),
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: 10,
                      //     height: 1,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text.rich(
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: balanceLabel.toString().split(" ").first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: '  ${balanceLabel.toString().split(" ").last}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

