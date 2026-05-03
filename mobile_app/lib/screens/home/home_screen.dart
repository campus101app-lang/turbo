// lib/screens/home/home_screen.dart
//
// Merged dashboard: live wallet data + KPI cards + activity feed + insights.
// Replaces both home_screen.dart and enhanced_home_screen.dart.

import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/screens/accounts/accounts_screen.dart';

import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final userProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => apiService.getMe(),
);

final _txHomeProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final result = await apiService.getTransactions(page: 1, limit: 100);
  return List<Map<String, dynamic>>.from(result['transactions'] ?? []);
});

final _invoicesHomeProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final result = await apiService.getInvoices(page: 1, limit: 50);
  return List<Map<String, dynamic>>.from(result['invoices'] ?? []);
});

final _expensesHomeProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final result = await apiService.getExpenses(page: 1, limit: 50);
  return List<Map<String, dynamic>>.from(result['expenses'] ?? []);
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

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _fmtMixed(double ngn, double usd) {
    final parts = <String>[];
    if (ngn > 0) {
      if (ngn >= 1000000) parts.add('₦${(ngn / 1000000).toStringAsFixed(1)}M');
      else if (ngn >= 1000) parts.add('₦${(ngn / 1000).toStringAsFixed(0)}k');
      else parts.add('₦${ngn.toStringAsFixed(0)}');
    }
    if (usd > 0) parts.add('\$${usd.toStringAsFixed(2)}');
    return parts.isEmpty ? '₦0' : parts.join(' + ');
  }

  // ── Sparkline helpers ──────────────────────────────────────────────────────

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
    final invoicesAsync = ref.watch(_invoicesHomeProvider);
    final expensesAsync = ref.watch(_expensesHomeProvider);
    final usdToNgn = ref.watch(ngnRateProvider) ?? 1600.0;
    final userAsync = ref.watch(userProvider);

    final txs = txAsync.value ?? [];
    final invoices = invoicesAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

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

    // USDC sparkline — no XLM, no price history needed
    final usdcPoints = _buildPoints(
      txs,
      'USDC',
      walletState.usdcBalance,
      1.0,
      {},
    );
    final usdcChange = _computeChange(usdcPoints);

    // NGNT sparkline — reconstruct from txns, converted to USD via ngntPriceUSD
    final ngntPriceUsd = walletState.ngntPriceUSD ?? 0.0;
    final rawNgntPoints = _buildPoints(txs, 'NGNT', walletState.ngntBalance, 1.0, {});
    final ngntPoints = rawNgntPoints.map((v) => v * ngntPriceUsd).toList();

    // Combined portfolio 7d change
    final combinedPoints = _combinePoints(usdcPoints, ngntPoints);
    final totalChange = _computeChange(combinedPoints);

    // KPI derivations
    final pendingInvoices = invoices
        .where((i) => ['sent', 'viewed', 'overdue'].contains(i['status']))
        .toList();
    double pendingNgn = 0, pendingUsd = 0;
    for (final i in pendingInvoices) {
      final amt = _asDouble(i['totalAmount']);
      if ((i['currency'] as String?) == 'USDC') pendingUsd += amt;
      else pendingNgn += amt;
    }
    final pendingFmt = _fmtMixed(pendingNgn, pendingUsd);
    final overdueCount = invoices.where((i) => i['status'] == 'overdue').length;
    double paidNgn = 0, paidUsd = 0;
    for (final i in invoices) {
      if (i['status'] != 'paid') continue;
      final dt = DateTime.tryParse(i['updatedAt']?.toString() ?? '');
      if (dt == null) continue;
      final now2 = DateTime.now();
      if (dt.year != now2.year || dt.month != now2.month) continue;
      final amt = _asDouble(i['totalAmount']);
      if ((i['currency'] as String?) == 'USDC') paidUsd += amt;
      else paidNgn += amt;
    }
    final paidFmt = _fmtMixed(paidNgn, paidUsd);
    final paidThisMonth = paidNgn;

    final totalExpensesThisMonth = expenses
        .where((e) {
          final dt = DateTime.tryParse(e['createdAt']?.toString() ?? '');
          if (dt == null) return false;
          final now = DateTime.now();
          return dt.year == now.year && dt.month == now.month;
        })
        .fold<double>(0, (s, e) => s + _asDouble(e['amount']));

    final userName = userAsync.value?['fullName'] as String? ?? '';
    final firstName = userName.isNotEmpty ? userName.split(' ').first : 'there';

    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
          ref.invalidate(userProvider);
          ref.invalidate(_txHomeProvider);
          ref.invalidate(_invoicesHomeProvider);
          ref.invalidate(_expensesHomeProvider);
          ref.invalidate(ngnRateProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Greeting(firstName: firstName, walletState: walletState),
                    const SizedBox(height: 20),
                    if (isWide)
                      _WideLayout(
                        walletState: walletState,
                        usdcChange: usdcChange,
                        usdcPoints: usdcPoints,
                        // ngntPoints: ngntPoints,
                        usdToNgn: usdToNgn,
                        balanceHidden: _balanceHidden,
                        onToggleHide: () =>
                            setState(() => _balanceHidden = !_balanceHidden),
                        recentTxs: recentTxs,
                        invoices: invoices,
                        pendingFmt: pendingFmt,
                        pendingCount: pendingInvoices.length,
                        overdueCount: overdueCount,
                        paidFmt: paidFmt,
                        paidThisMonth: paidThisMonth,
                        totalExpensesThisMonth: totalExpensesThisMonth,
                        asDouble: _asDouble,
                        toSpots: _toSpots,
                        totalChange: totalChange,
                        xlmPoints: ngntPoints,
                        combinedPoints: combinedPoints,
                      )
                    else
                      _NarrowLayout(
                        walletState: walletState,
                        usdcChange: usdcChange,
                        usdcPoints: usdcPoints,
                        totalChange: totalChange,
                        xlmPoints: ngntPoints,
                        combinedPoints: combinedPoints,
                        usdToNgn: usdToNgn,
                        balanceHidden: _balanceHidden,
                        onToggleHide: () =>
                            setState(() => _balanceHidden = !_balanceHidden),
                        recentTxs: recentTxs,
                        invoices: invoices,
                        pendingFmt: pendingFmt,
                        pendingCount: pendingInvoices.length,
                        overdueCount: overdueCount,
                        paidFmt: paidFmt,
                        paidThisMonth: paidThisMonth,
                        totalExpensesThisMonth: totalExpensesThisMonth,
                        asDouble: _asDouble,
                        toSpots: _toSpots,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Greeting ───────────────────────────────────────────────────────────────────

class _Greeting extends ConsumerWidget {
  final String firstName;
  final WalletState walletState;
  const _Greeting({required this.firstName, required this.walletState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $firstName 👋',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              Text(
                'Here\'s your business at a glance.',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 50.ms),
            ],
          ),
        ),
        // Quick actions
        _QuickActionPill(
          label: '+ Invoice',
          onTap: () =>
              ref.read(shellNavProvider.notifier).goTo(ShellDest.createInvoice),
        ),
        const SizedBox(width: 8),
        _QuickActionPill(
          label: 'Send',
          icon: Icons.arrow_upward_rounded,
          onTap: () => ref.read(shellNavProvider.notifier).goTo(ShellDest.send),
        ),
        const SizedBox(width: 8),
        _QuickActionPill(
          label: 'Request',
          icon: Icons.arrow_downward_rounded,
          onTap: () => ref.read(shellNavProvider.notifier).goTo(ShellDest.receive),
        ),
      ],
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _QuickActionPill({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: cs.surface),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wide layout (web) ──────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final WalletState walletState;
  final double totalChange, usdcChange, usdToNgn;
  final List<double> xlmPoints, usdcPoints, combinedPoints;
  final bool balanceHidden;
  final VoidCallback onToggleHide;
  final List<Map<String, dynamic>> recentTxs, invoices;
  final String pendingFmt, paidFmt;
  final double paidThisMonth, totalExpensesThisMonth;
  final int pendingCount, overdueCount;
  final double Function(dynamic, [double]) asDouble;
  final List<FlSpot> Function(List<double>) toSpots;

  const _WideLayout({
    required this.walletState,
    required this.totalChange,
    required this.usdcChange,
    required this.usdToNgn,
    required this.xlmPoints,
    required this.usdcPoints,
    required this.combinedPoints,
    required this.balanceHidden,
    required this.onToggleHide,
    required this.recentTxs,
    required this.invoices,
    required this.pendingFmt,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidFmt,
    required this.paidThisMonth,
    required this.totalExpensesThisMonth,
    required this.asDouble,
    required this.toSpots,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: balance + KPIs + insights
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _BalanceCard(
                walletState: walletState,
                totalChange: totalChange,
                usdcChange: usdcChange,
                usdToNgn: usdToNgn,
                xlmPoints: xlmPoints,
                usdcPoints: usdcPoints,
                balanceHidden: balanceHidden,
                onToggleHide: onToggleHide,
                toSpots: toSpots,
              ),
              const SizedBox(height: 16),
              _KpiRow(
                pendingFmt: pendingFmt,
                pendingCount: pendingCount,
                overdueCount: overdueCount,
                paidFmt: paidFmt,
                totalExpensesThisMonth: totalExpensesThisMonth,
              ),
              const SizedBox(height: 16),
              _InsightsCard(
                invoices: invoices,
                overdueCount: overdueCount,
                paidThisMonth: paidThisMonth,
                totalExpensesThisMonth: totalExpensesThisMonth,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column: recent transactions
        Expanded(
          flex: 4,
          child: _RecentActivity(txs: recentTxs, asDouble: asDouble),
        ),
      ],
    );
  }
}

// ── Narrow layout (mobile) ─────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final WalletState walletState;
  final double totalChange, usdcChange, usdToNgn;
  final List<double> xlmPoints, usdcPoints, combinedPoints;
  final bool balanceHidden;
  final VoidCallback onToggleHide;
  final List<Map<String, dynamic>> recentTxs, invoices;
  final String pendingFmt, paidFmt;
  final double paidThisMonth, totalExpensesThisMonth;
  final int pendingCount, overdueCount;
  final double Function(dynamic, [double]) asDouble;
  final List<FlSpot> Function(List<double>) toSpots;

  const _NarrowLayout({
    required this.walletState,
    required this.totalChange,
    required this.usdcChange,
    required this.usdToNgn,
    required this.xlmPoints,
    required this.usdcPoints,
    required this.combinedPoints,
    required this.balanceHidden,
    required this.onToggleHide,
    required this.recentTxs,
    required this.invoices,
    required this.pendingFmt,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidFmt,
    required this.paidThisMonth,
    required this.totalExpensesThisMonth,
    required this.asDouble,
    required this.toSpots,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BalanceCard(
          walletState: walletState,
          totalChange: totalChange,
          usdcChange: usdcChange,
          usdToNgn: usdToNgn,
          xlmPoints: xlmPoints,
          usdcPoints: usdcPoints,
          balanceHidden: balanceHidden,
          onToggleHide: onToggleHide,
          toSpots: toSpots,
        ),
        const SizedBox(height: 16),
        _KpiRow(
          pendingFmt: pendingFmt,
          pendingCount: pendingCount,
          overdueCount: overdueCount,
          paidFmt: paidFmt,
          totalExpensesThisMonth: totalExpensesThisMonth,
        ),
        const SizedBox(height: 16),
        _RecentActivity(txs: recentTxs, asDouble: asDouble),
        const SizedBox(height: 16),
        _InsightsCard(
          invoices: invoices,
          overdueCount: overdueCount,
          paidThisMonth: paidThisMonth,
          totalExpensesThisMonth: totalExpensesThisMonth,
        ),
      ],
    );
  }
}

// ── Balance card ───────────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  final WalletState walletState;
  final double totalChange, usdcChange, usdToNgn;
  final List<double> xlmPoints, usdcPoints;
  final bool balanceHidden;
  final VoidCallback onToggleHide;
  final List<FlSpot> Function(List<double>) toSpots;

  const _BalanceCard({
    required this.walletState,
    required this.totalChange,
    required this.usdcChange,
    required this.usdToNgn,
    required this.xlmPoints,
    required this.usdcPoints,
    required this.balanceHidden,
    required this.onToggleHide,
    required this.toSpots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ext = AppThemeExtension.of(context);

    // Total = USDC + NGNT converted to USD
    final ngnUsdRate = walletState.ngnRate ?? 0;
    final ngntUsd = walletState.ngntBalance * ngnUsdRate;
    final liveTotal = (walletState.usdcBalance + ngntUsd).clamp(
      0,
      double.infinity,
    );
    final displayTotal =
        (walletState.hasError || walletState.isOffline) && liveTotal == 0
        ? walletState.lastKnownTotal
        : double.parse(liveTotal.toStringAsFixed(2));

    final pos = usdcChange >= 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Currency cards row
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
                  line: toSpots(List.filled(7, usdToNgn)),
                  imagePath: 'assets/images/ng.png',
                  valueUSD:
                      walletState.ngntBalance * (walletState.ngnRate ?? 0),
                  balanceLabel:
                      '${walletState.ngntBalance.toStringAsFixed(2)} NGNT',
                ),
              ),
              const SizedBox(width: 10),
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
                  accent: usdcChange >= 0 ? DayFiColors.green : ext.errorColor,
                  line: toSpots(usdcPoints),
                  imagePath: 'assets/images/us.png',
                  valueUSD: walletState.usdcBalance,
                  balanceLabel:
                      '${walletState.usdcBalance.toStringAsFixed(2)} USDC',
                ),
              ),
            ],
            ),
          ),
          const SizedBox(height: 16),

          // Total balance display
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: pos
                            ? DayFiColors.green.withOpacity(0.15)
                            : DayFiColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pos ? '+' : '−'}${totalChange.abs().toStringAsFixed(2)}%  7d',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pos ? DayFiColors.green : DayFiColors.red,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'total balance',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggleHide,
                      child: Icon(
                        balanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _BalanceDisplay(
                  total: displayTotal ?? 0,
                  hidden: balanceHidden,
                  loading:
                      walletState.isLoading &&
                      walletState.lastKnownTotal == null,
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Send',
                      onTap: () => ref
                          .read(shellNavProvider.notifier)
                          .goTo(ShellDest.send),
                    ),
                    _ActionBtn(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Receive',
                      onTap: () => ref
                          .read(shellNavProvider.notifier)
                          .goTo(ShellDest.receive),
                    ),
                    _ActionBtn(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Convert',
                      onTap: () => ref
                          .read(shellNavProvider.notifier)
                          .goTo(ShellDest.swap),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceDisplay extends StatelessWidget {
  final double total;
  final bool hidden, loading;
  const _BalanceDisplay({
    required this.total,
    required this.hidden,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final whole = loading
        ? '—'
        : hidden
        ? '***'
        : total.toInt().toString();
    final dec = loading || hidden
        ? '.—'
        : '.${total.toStringAsFixed(2).split('.')[1]}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '\$',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.primary,
              height: 1,
            ),
          ),
        ),
        Text(
          whole,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 38,
            fontWeight: FontWeight.w500,
            color: cs.primary,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            dec,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 38,
              fontWeight: FontWeight.w500,
              color: cs.primary,
              height: 1,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.7)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI row ────────────────────────────────────────────────────────────────────

class _KpiRow extends ConsumerWidget {
  final String pendingFmt, paidFmt;
  final double totalExpensesThisMonth;
  final int pendingCount, overdueCount;
  const _KpiRow({
    required this.pendingFmt,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidFmt,
    required this.totalExpensesThisMonth,
  });

  String _fmt(double v) {
    if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}k';
    return '₦${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(shellNavProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Collected',
            value: paidFmt,
            sub: 'This month',
            accent: DayFiColors.green,
            icon: Icons.check_circle_outline_rounded,
            onTap: () => nav.goTo(ShellDest.billing),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Pending',
            value: pendingFmt,
            sub: '$pendingCount invoices',
            accent: const Color(0xFFE57745),
            icon: Icons.hourglass_bottom_rounded,
            onTap: () => nav.goTo(ShellDest.billing),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Overdue',
            value: '$overdueCount',
            sub: 'invoices',
            accent: overdueCount > 0 ? DayFiColors.red : DayFiColors.green,
            icon: Icons.warning_amber_rounded,
            onTap: () => nav.goTo(ShellDest.billing),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Expenses',
            value: _fmt(totalExpensesThisMonth),
            sub: 'This month',
            accent: const Color(0xFF9C27B0),
            icon: Icons.attach_money_rounded,
            onTap: () => nav.goTo(ShellDest.expenses),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: accent),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: cs.onSurface.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.45),
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms),
    );
  }
}

// ── Recent activity ────────────────────────────────────────────────────────────

class _RecentActivity extends ConsumerWidget {
  final List<Map<String, dynamic>> txs;
  final double Function(dynamic, [double]) asDouble;
  const _RecentActivity({required this.txs, required this.asDouble});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref
                      .read(shellNavProvider.notifier)
                      .goTo(ShellDest.transactions),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (txs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            )
          else
            ...txs.take(8).map((tx) => _TxRow(tx: tx, asDouble: asDouble)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  final double Function(dynamic, [double]) asDouble;
  const _TxRow({required this.tx, required this.asDouble});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSend = tx['type'] == 'send';
    final isSwap = tx['type'] == 'swap';
    final amount = asDouble(tx['amount']).abs();
    final asset = tx['asset'] as String? ?? '';
    final swapToAsset = tx['swapToAsset'] as String? ?? '';
    final swapToAmount = tx['receivedAmount'] ?? tx['swapToAmount'];
    final createdAt =
        DateTime.tryParse(tx['createdAt'] ?? '') ?? DateTime.now();
    final status = tx['status'] as String? ?? '';
    final accent = isSend
        ? DayFiColors.red
        : isSwap
        ? cs.primary
        : DayFiColors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSwap
                  ? Icons.swap_horiz_rounded
                  : isSend
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwap
                      ? 'Swap $asset → $swapToAsset'
                      : '${isSend ? 'Sent' : 'Received'} $asset',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.85),
                  ),
                ),
                Text(
                  status.toLowerCase() == 'confirmed'
                      ? DateFormat('MMM d, h:mm a').format(createdAt.toLocal())
                      : status,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Text(
            isSwap
                ? '${amount.toStringAsFixed(2)} $asset'
                : '${isSend ? '−' : '+'}${amount.toStringAsFixed(2)} $asset',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSend ? DayFiColors.red : cs.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insights card ──────────────────────────────────────────────────────────────

class _InsightsCard extends ConsumerWidget {
  final List<Map<String, dynamic>> invoices;
  final int overdueCount;
  final double paidThisMonth, totalExpensesThisMonth;
  const _InsightsCard({
    required this.invoices,
    required this.overdueCount,
    required this.paidThisMonth,
    required this.totalExpensesThisMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final totalInvoiced = invoices.fold<double>(
      0,
      (s, i) => s + ((i['totalAmount'] as num?)?.toDouble() ?? 0),
    );
    final collectionRate = totalInvoiced > 0
        ? (paidThisMonth / totalInvoiced) * 100
        : 0.0;

    final insights = <(String, String, Color)>[
      if (overdueCount > 0)
        (
          'Overdue invoices',
          '$overdueCount invoice${overdueCount > 1 ? 's are' : ' is'} overdue. Follow up to improve cash flow.',
          DayFiColors.red,
        ),
      if (collectionRate > 0)
        (
          'Collection rate',
          'You\'ve collected ${collectionRate.toStringAsFixed(0)}% of invoiced amounts this period.',
          collectionRate > 70 ? DayFiColors.green : const Color(0xFFE57745),
        ),
      (
        'Spending',
        totalExpensesThisMonth > 0
            ? 'Total expenses this month: ₦${(totalExpensesThisMonth / 1000).toStringAsFixed(0)}k'
            : 'No expenses recorded this month.',
        const Color(0xFF9C27B0),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 15,
                color: cs.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                'INSIGHTS',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: cs.onSurface.withOpacity(0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightTile(
                title: item.$1,
                body: item.$2,
                accent: item.$3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title, body;
  final Color accent;
  const _InsightTile({
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
              ],
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
  final double strokeWidth;
  const _SparklinePainter({
    required this.points,
    required this.color,
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

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < points.length; i++) {
      final p = pt(i - 1), c = pt(i);
      final cx = (p.dx + c.dx) / 2;
      path.cubicTo(cx, p.dy, cx, c.dy, c.dx, c.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter o) =>
      o.points != points || o.color != color;
}
