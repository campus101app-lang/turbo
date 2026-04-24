// lib/screens/home/home_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

final userProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => apiService.getMe(),
);

final _txHomeProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final result = await apiService.getTransactions(page: 1, limit: 100);
  return List<Map<String, dynamic>>.from(result['transactions'] ?? []);
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _balanceHidden = false;
  bool _holdingsExpanded = true;
  bool _moversExpanded = true;
  Timer? _refreshTimer;

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

  // ── Chart data helpers (ported from portfolio_screen) ──────────────────────

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

    if (relevant.isEmpty) return [balance * currentPrice, balance * currentPrice];
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final txAsync = ref.watch(_txHomeProvider);
    final priceHistoryAsync = ref.watch(_xlmPriceHistoryHomeProvider);
    final priceHistory = priceHistoryAsync.value ?? {};

    const xlmReserve = 2.0;
    final xlmPrice = walletState.xlmPriceUSD ?? 0.0;
    final xlmDisplayBalance = (walletState.xlmBalance - xlmReserve > 0)
        ? (walletState.xlmBalance - xlmReserve)
        : 0.0;
    final xlmUSD = xlmDisplayBalance * xlmPrice;
    final usdcUSD = walletState.usdcBalance;

    final txs = txAsync.value ?? [];

    final xlmPoints = _buildPoints(txs, 'XLM', xlmDisplayBalance, xlmPrice, priceHistory);
    final usdcPoints = _buildPoints(txs, 'USDC', walletState.usdcBalance, 1.0, priceHistory);
    final combinedPoints = _combinePoints(xlmPoints, usdcPoints);

    final xlmChange = _computeChange(xlmPoints);
    final usdcChange = _computeChange(usdcPoints);
    final totalChange = _computeChange(combinedPoints);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
          ref.invalidate(userProvider);
          ref.invalidate(_txHomeProvider);
          ref.invalidate(_xlmPriceHistoryHomeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            const SizedBox(height: 140),

            // ── Balance ──────────────────────────────────────────────
            _buildBalanceSection(walletState, totalChange),

            const SizedBox(height: 20),

            // ── Portfolio chip ───────────────────────────────────────
            _buildPortfolioChip(walletState),

            const SizedBox(height: 28),

            // ── Chart ────────────────────────────────────────────────
            if (combinedPoints.length >= 2)
              _buildChart(combinedPoints, totalChange),

            const SizedBox(height: 32),

            // ── Top Movers ───────────────────────────────────────────
            _buildSectionHeader(
              title: 'Top movers today',
              rightLabel: 'XLM · USDC',
              expanded: _moversExpanded,
              onTap: () => setState(() => _moversExpanded = !_moversExpanded),
            ),

            if (_moversExpanded) ...[
              const SizedBox(height: 6),
              _buildMoversRow(
                xlmBalance: xlmDisplayBalance,
                xlmUSD: xlmUSD,
                xlmChange: xlmChange,
                xlmPoints: xlmPoints,
                usdcBalance: walletState.usdcBalance,
                usdcUSD: usdcUSD,
                usdcChange: usdcChange,
                usdcPoints: usdcPoints,
              ),
            ],

            const SizedBox(height: 32),

            // ── Holdings ─────────────────────────────────────────────
            _buildSectionHeader(
              title: 'Holdings',
              rightLabel: 'ALL',
              expanded: _holdingsExpanded,
              onTap: () => setState(() => _holdingsExpanded = !_holdingsExpanded),
            ),

            if (_holdingsExpanded) ...[
              const SizedBox(height: 12),
              _HoldingRow(
                imagePath: 'assets/images/stellar.png',
                code: 'XLM',
                name: 'Stellar Lumen',
                balance: xlmDisplayBalance,
                usdValue: xlmUSD,
                changePercent: xlmChange,
                points: xlmPoints,
              ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.04, end: 0),
              const SizedBox(height: 8),
              _HoldingRow(
                imagePath: 'assets/images/usdc.png',
                code: 'USDC',
                name: 'Digital Dollar',
                balance: walletState.usdcBalance,
                usdValue: usdcUSD,
                changePercent: usdcChange,
                points: usdcPoints,
              ).animate().fadeIn(delay: 180.ms).slideX(begin: 0.04, end: 0),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Balance section ────────────────────────────────────────────────────────

  Widget _buildBalanceSection(WalletState walletState, double changePct) {
    const xlmReserve = 2.0;
    final xlmPrice = walletState.xlmPriceUSD ?? 0.0;
    final reservedUSD = xlmReserve * xlmPrice;
    final rawTotal = walletState.totalUSD - reservedUSD;
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
        // Change % badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pos
                    ? DayFiColors.green.withOpacity(0.15)
                    : DayFiColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${pos ? '' : '−'}${changePct.abs().toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: pos ? DayFiColors.green : DayFiColors.red,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 8),

        // Balance label row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Wallet Balance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
                letterSpacing: 0.4,
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
                    ? "assets/icons/svgs/eye_closed.svg"
                    : "assets/icons/svgs/eye_open.svg",
                height: 21,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),

        const SizedBox(height: 8),

        // Big balance
        if (walletState.isLoading && walletState.lastKnownTotal == null)
          Text(
            '\$—',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.40),
              fontSize: 28,
            ),
          )
        else if (_balanceHidden)
          _buildBalanceRow('***', '.**', isHidden: true)
        else
          _buildBalanceRow(
            (displayTotal ?? 0.0).toInt().toString(),
            '.${(displayTotal ?? 0.0).toStringAsFixed(2).split('.')[1]}',
          ),
      ],
    );
  }

  Widget _buildBalanceRow(String whole, String decimal, {bool isHidden = false}) {
    final opacity = isHidden ? .40 : .85;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '\$',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
              letterSpacing: 0.4,
              fontSize: 28,
            ),
          ),
        ),
        Text(
          whole,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(opacity),
            letterSpacing: 0.4,
            height: .88,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            decimal,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 30,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(opacity),
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Portfolio chip ─────────────────────────────────────────────────────────

  Widget _buildPortfolioChip(WalletState walletState) {
    final assets = ['assets/images/stellar.png', 'assets/images/usdc.png'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () => context.push('/portfolio'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16.0 + (assets.length * 16.0),
                  height: 26,
                  child: Stack(
                    children: List.generate(assets.length, (i) {
                      return Positioned(
                        left: i * 16.0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                assets[i],
                                fit: BoxFit.contain,
                                height: assets[i] == "assets/images/stellar.png" ? 20 : 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
                    letterSpacing: 0.4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: -1,
                  child: SvgPicture.asset(
                    "assets/icons/svgs/dropdown.svg",
                    height: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Chart ──────────────────────────────────────────────────────────────────

  Widget _buildChart(List<double> points, double changePct) {
    final pos = changePct >= 0;
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: points,
          color: pos ? DayFiColors.green : DayFiColors.red,
          fillColor: pos
              ? DayFiColors.green.withOpacity(0.07)
              : DayFiColors.red.withOpacity(0.07),
        ),
        child: const SizedBox.expand(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required String rightLabel,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                  letterSpacing: .3,
                ),
              ),
            ),
            Text(
              rightLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top movers row ─────────────────────────────────────────────────────────

  Widget _buildMoversRow({
    required double xlmBalance,
    required double xlmUSD,
    required double xlmChange,
    required List<double> xlmPoints,
    required double usdcBalance,
    required double usdcUSD,
    required double usdcChange,
    required List<double> usdcPoints,
  }) {
    return Row(
      children: [
        Expanded(
          child: _MoverCard(
            imagePath: 'assets/images/stellar.png',
            code: 'XLM',
            name: 'Stellar Lumen',
            usdValue: xlmUSD,
            changePercent: xlmChange,
            points: xlmPoints,
          ).animate().fadeIn(delay: 100.ms),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MoverCard(
            imagePath: 'assets/images/usdc.png',
            code: 'USDC',
            name: 'Digital Dollar',
            usdValue: usdcUSD,
            changePercent: usdcChange,
            points: usdcPoints,
          ).animate().fadeIn(delay: 180.ms),
        ),
      ],
    );
  }
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
          // Header row
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
          // Sparkline
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
          // Value + change pill
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
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(imagePath, width: 36, height: 36),
          ),
          const SizedBox(width: 12),
          // Name + balance
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.88),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${balance.toStringAsFixed(code == 'USDC' ? 2 : 4)} $code',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Sparkline
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
          // Value + change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${usdValue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.88),
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

// ── Sparkline painter ──────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color, fillColor;
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
      size.height - ((points[i] - min) / range) * size.height * 0.82 - size.height * 0.09,
    );

    // fill
    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      fill.lineTo(pt(i).dx, pt(i).dy);
    }
    fill..lineTo(size.width, size.height)..close();
    canvas.drawPath(fill, Paint()..color = fillColor..style = PaintingStyle.fill);

    // line
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
  bool shouldRepaint(_SparklinePainter o) => o.points != points || o.color != color;
}