// lib/screens/home/home_screen.dart
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
import 'package:intl/intl.dart' show DateFormat;
import 'package:mobile_app/screens/accounts/accounts_screen.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final userProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => apiService.getMe(),
);

final _txHomeProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final result = await apiService.getTransactions(page: 1, limit: 100);
  final txs = List<Map<String, dynamic>>.from(result['transactions'] ?? []);
  return txs.where((tx) {
    final asset = (tx['asset'] as String?)?.toUpperCase() ?? '';
    final swapFrom = (tx['swapFromAsset'] as String?)?.toUpperCase() ?? '';
    final swapTo = (tx['swapToAsset'] as String?)?.toUpperCase() ?? '';
    return asset != 'XLM' && swapFrom != 'XLM' && swapTo != 'XLM';
  }).toList();
});

final _xlmPriceHistoryHomeProvider = FutureProvider<Map<String, double>>((
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

// ── HomeScreen ─────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _balanceHidden = false;
  Timer? _refreshTimer;

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(walletProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Chart helpers ──────────────────────────────────────────────────────────

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

  List<double> _combinePoints(List<double> a, List<double> b) {
    final len = a.length > b.length ? a.length : b.length;
    if (len == 0) return [];

    List<double> interp(List<double> src) {
      if (src.length == len) return src;
      return List.generate(len, (i) {
        final t = i / (len - 1);
        final si = t * (src.length - 1);
        final lo = si.floor().clamp(0, src.length - 1);
        final hi = si.ceil().clamp(0, src.length - 1);
        return src[lo] + (src[hi] - src[lo]) * (si - lo);
      });
    }

    final ia = interp(a), ib = interp(b);
    return List.generate(len, (i) => ia[i] + ib[i]);
  }

  double _computeChange(List<double> points) {
    if (points.length < 2) return 0.0;
    final first = points.first;
    if (first <= 0) return 0.0;
    return ((points.last - first) / first) * 100;
  }

  List<FlSpot> _toSpots(List<double> points) {
    if (points.isEmpty) return [const FlSpot(0, 0.5), const FlSpot(1, 0.5)];
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range == 0) {
      return List.generate(points.length, (i) => FlSpot(i.toDouble(), 0.5));
    }
    return List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), (points[i] - min) / range),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final txAsync = ref.watch(_txHomeProvider);
    final priceHistoryAsync = ref.watch(_xlmPriceHistoryHomeProvider);
    final priceHistory = priceHistoryAsync.value ?? {};
    final ngnRateAsync = ref.watch(ngnRateProvider);

    const xlmReserve = 1.5;
    final xlmPrice = walletState.xlmPriceUSD;
    final xlmDisplayBalance = walletState.xlmBalance - xlmReserve > 0
        ? walletState.xlmBalance - xlmReserve
        : 0.0;

    final usdToNgn = ref.watch(ngnRateProvider) ?? 1600.0;

    final txs = txAsync.value ?? [];
    final recentTxs = [...txs]
      ..sort((a, b) {
        final aDate =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final xlmPoints = _buildPoints(
      txs,
      'XLM',
      xlmDisplayBalance,
      xlmPrice,
      priceHistory,
    );
    final usdcPoints = _buildPoints(
      txs,
      'USDC',
      walletState.usdcBalance,
      1.0,
      priceHistory,
    );
    final combinedPoints = _combinePoints(xlmPoints, usdcPoints);

    final usdcChange = _computeChange(usdcPoints);
    final totalChange = _computeChange(combinedPoints);

    final ext = AppThemeExtension.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(walletProvider.notifier).refresh();
                    ref.invalidate(userProvider);
                    ref.invalidate(_txHomeProvider);
                    ref.invalidate(_xlmPriceHistoryHomeProvider);
                    ref.invalidate(ngnRateProvider);
                  },
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(0, 118, 0, 0),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Balance card ─────────────────────────────────
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 100,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AccountMoverCard(
                                          ticker: 'NGN',
                                          name: 'NG Naira',
                                          gainUp: true,
                                          gainAmountAbsNgn: 0,
                                          accent: const Color(0xFF008751),
                                          line: _toSpots(
                                            ngnRateAsync != null
                                                ? List.filled(7, usdToNgn)
                                                : [],
                                          ),
                                          imagePath: 'assets/images/ng.png',
                                          valueUSD:
                                              walletState.ngntBalance *
                                              (walletState.ngnRate ?? 0),
                                          balanceLabel:
                                              '${walletState.ngntBalance.toStringAsFixed(2)} NGNT',
                                        ),
                                      ),
                                      Expanded(
                                        child: AccountMoverCard(
                                          ticker: 'USD',
                                          name: 'US Dollar',
                                          gainUp: usdcChange >= 0,
                                          gainAmountAbsNgn:
                                              walletState.usdcBalance *
                                              usdToNgn *
                                              usdcChange.abs() /
                                              100,
                                          accent: usdcChange >= 0
                                              ? DayFiColors.green
                                              : ext.errorColor,
                                          line: _toSpots(usdcPoints),
                                          imagePath: 'assets/images/us.png',
                                          valueUSD: walletState.usdcBalance,
                                          balanceLabel:
                                              '${walletState.usdcBalance.toStringAsFixed(2)} USDC',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Center(
                                      child: Container(
                                        height: 54,
                                        width:
                                            MediaQuery.of(context).size.width *
                                            .85,
                                        margin: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          0,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.04),
                                          ),
                                          color: Theme.of(
                                            context,
                                          ).canvasColor.withOpacity(.75),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.fromLTRB(
                                        0,
                                        6,
                                        0,
                                        0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.04),
                                          width: .5,
                                        ),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        18,
                                        8,
                                        4,
                                      ),
                                      child: _buildBalanceSection(
                                        walletState,
                                        totalChange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                // ── Recent transactions ────────────────────────────────
                                if (recentTxs.isNotEmpty) ...[
                                  _SectionHeader(
                                    label: 'Most recent',
                                    trailing: '',
                                    onTrailingTap: () =>
                                        context.push('/transactions'),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      6,
                                      16,
                                      0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.04),
                                      ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      6,
                                      6,
                                      4,
                                    ),
                                    child: Column(
                                      children: [
                                        ...recentTxs.take(3).map((tx) {
                                          final isSend = tx['type'] == 'send';
                                          final isSwap = tx['type'] == 'swap';
                                          final amount = _asDouble(
                                            tx['amount'],
                                          );
                                          final asset =
                                              tx['asset'] as String? ?? '';
                                          final swapToAsset =
                                              tx['swapToAsset'] as String? ??
                                              '';
                                          final rawSwapToAmount =
                                              tx['receivedAmount'] ??
                                              tx['swapToAmount'];
                                          final swapToAmount =
                                              rawSwapToAmount != null
                                              ? _asDouble(rawSwapToAmount)
                                              : null;
                                          final createdAt =
                                              DateTime.tryParse(
                                                tx['createdAt'] ?? '',
                                              ) ??
                                              DateTime.now();
                                          final status =
                                              tx['status'] as String?;
                                          final accent = isSend
                                              ? DayFiColors.red
                                              : isSwap
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : DayFiColors.green;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                // Icon + asset badge
                                                Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: 32,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.topCenter,
                                                        child: SvgPicture.asset(
                                                          isSwap
                                                              ? 'assets/icons/svgs/swap.svg'
                                                              : isSend
                                                              ? 'assets/icons/svgs/send.svg'
                                                              : 'assets/icons/svgs/receive.svg',
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    .75,
                                                                  ),
                                                          width: 22,
                                                          height: 22,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        child: Image.asset(
                                                          asset.toUpperCase() ==
                                                                  'USDC'
                                                              ? 'assets/images/usdc.png'
                                                              : 'assets/images/stellar.png',
                                                          width: 14,
                                                          height: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 14),
                                                // Label + time
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        isSwap
                                                            ? 'Swapped $asset → $swapToAsset'
                                                            : '${isSend ? 'Sent' : 'Received'} $asset',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        .95,
                                                                      ),
                                                            ),
                                                      ),
                                                      Text(
                                                        status?.toLowerCase() ==
                                                                'confirmed'
                                                            ? DateFormat(
                                                                'h:mm a',
                                                              ).format(
                                                                createdAt
                                                                    .toLocal(),
                                                              )
                                                            : (status ?? ''),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        .65,
                                                                      ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 14,
                                                              letterSpacing:
                                                                  -.1,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Amount
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isSwap
                                                          ? '${amount.toStringAsFixed(2)} $asset'
                                                          : '${isSend ? '-' : '+'}${amount.toStringAsFixed(2)} $asset',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                    Text(
                                                      isSwap
                                                          ? '$amount $asset → ${swapToAmount != null ? '${swapToAmount.toStringAsFixed(2)} ' : ''}$swapToAsset'
                                                          : '${amount.toStringAsFixed(2)} $asset',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      .65,
                                                                    ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .color!
                                                .withOpacity(0.1),
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(.555),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Full activity view is coming soon.',
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
                                              'VIEW ALL',
                                              style:
                                                  GoogleFonts.bricolageGrotesque(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: .2,
                                                    height: 1,
                                                    color: ext.sectionHeader,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action handlers ────────────────────────────────────────────────────────

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

  // ── Balance section ────────────────────────────────────────────────────────

  Widget _buildBalanceSection(WalletState walletState, double changePct) {
    const xlmReserve = 1.5;
    final xlmPrice = walletState.xlmPriceUSD ?? 0.0;
    final rawTotal = walletState.totalUSD - (xlmReserve * xlmPrice);
    final liveTotal = rawTotal < 0
        ? 0.0
        : double.parse(rawTotal.toStringAsFixed(2));

    final displayTotal =
        (walletState.hasError || walletState.isOffline) && liveTotal == 0
        ? walletState.lastKnownTotal
        : liveTotal;

    final pos = changePct >= 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: pos
                    ? DayFiColors.green.withOpacity(0.15)
                    : DayFiColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${pos ? '' : '−'}${changePct.abs().toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pos ? DayFiColors.green : DayFiColors.red,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'total balance',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: 0.65,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () => setState(() => _balanceHidden = !_balanceHidden),
              child: SvgPicture.asset(
                _balanceHidden
                    ? 'assets/icons/svgs/eye_closed.svg'
                    : 'assets/icons/svgs/eye_open.svg',
                height: 21,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
        if (walletState.isLoading && walletState.lastKnownTotal == null)
          _buildBalanceRow('—', '.—')
        else if (_balanceHidden)
          _buildBalanceRow('***', '.**', isHidden: true)
        else
          _buildBalanceRow(
            (displayTotal ?? 0.0).toInt().toString(),
            '.${(displayTotal ?? 0.0).toStringAsFixed(2).split('.')[1]}',
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: 'assets/icons/svgs/send.svg',
              label: 'SEND',
              onPressed: () => _handleSendTap(walletState),
            ),
            const SizedBox(width: 6),
            _buildActionButton(
              icon: 'assets/icons/svgs/receive.svg',
              label: 'RECEIVE',
              onPressed: () => context.push('/receive'),
            ),
            const SizedBox(width: 6),
            _buildActionButton(
              icon: 'assets/icons/svgs/swap.svg',
              label: 'CONVERT',
              onPressed: () => _handleSwapTap(walletState),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(.555).withOpacity(.06),
          foregroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(.555),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                height: 18,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(.555),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
    String whole,
    String decimal, {
    bool isHidden = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '\$',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              height: 1,
            ),
          ),
        ),
        Text(
          whole,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 40,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            decimal,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              height: 1,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    this.trailing,
    this.onTrailingTap,
  });

  final String label;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w600,
              color: ext.sectionHeader,
              fontSize: 12,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!.toUpperCase(),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ext.sectionHeader.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sparkline painter ──────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final Color fillColor;
  final double strokeWidth;

  const _SparklinePainter({
    required this.points,
    required this.color,
    required this.fillColor,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min).clamp(0.001, double.infinity);
    final xStep = size.width / (points.length - 1);

    Offset pt(int i) => Offset(
      i * xStep,
      size.height -
          ((points[i] - min) / range) * size.height * 0.82 -
          size.height * 0.09,
    );

    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      fill.lineTo(pt(i).dx, pt(i).dy);
    }
    fill
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < points.length; i++) {
      final p = pt(i - 1), c = pt(i);
      final cx = (p.dx + c.dx) / 2;
      line.cubicTo(cx, p.dy, cx, c.dy, c.dx, c.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter o) =>
      o.points != points || o.color != color;
}

// ── Mover card ─────────────────────────────────────────────────────────────────

class _MoverCard extends StatelessWidget {
  final String imagePath;
  final String code;
  final String name;
  final double usdValue;
  final double changePercent;
  final List<double> points;

  const _MoverCard({
    required this.imagePath,
    required this.code,
    required this.name,
    required this.usdValue,
    required this.changePercent,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final pos = changePercent >= 0;
    final accent = pos ? DayFiColors.green : DayFiColors.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(imagePath, width: 28, height: 28),
              ),
              const Spacer(),
              Icon(
                Icons.nightlight_round,
                size: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            code,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: .4,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          if (points.length >= 2)
            SizedBox(
              height: 32,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: points,
                  color: accent,
                  fillColor: Colors.transparent,
                  strokeWidth: 1.8,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${usdValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pos ? '▲' : '▼'} ${changePercent.abs().toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Holding row ────────────────────────────────────────────────────────────────

class _HoldingRow extends StatelessWidget {
  final String imagePath;
  final String code;
  final String name;
  final double balance;
  final double usdValue;
  final double changePercent;
  final List<double> points;

  const _HoldingRow({
    required this.imagePath,
    required this.code,
    required this.name,
    required this.balance,
    required this.usdValue,
    required this.changePercent,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final pos = changePercent >= 0;
    final accent = pos ? DayFiColors.green : DayFiColors.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(imagePath, width: 36, height: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.1,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.88),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${balance.toStringAsFixed(code == 'USDC' ? 2 : 4)} $code',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (points.length >= 2)
            SizedBox(
              width: 52,
              height: 28,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: points,
                  color: accent,
                  fillColor: Colors.transparent,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${usdValue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.88),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${pos ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

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
