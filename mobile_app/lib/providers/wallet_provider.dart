// lib/providers/wallet_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

// ─── Wallet State ─────────────────────────────────────────────────────────────

class WalletState {
  final double usdcBalance;
  final double xlmBalance;
  final double ngntBalance; // 1 NGNT = 1 NGN
  final double xlmReserved; // XLM locked by master wallet
  final double xlmPriceUSD;
  final double? ngntPriceUSD; // USD value of 1 NGN  (e.g. 0.00059)
  final double? ngnRate; // NGN per 1 USD        (e.g. 1700)
  final String? stellarAddress;
  final String? dayfiUsername;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final bool hasError;
  final bool isOffline;
  final double? lastKnownTotal;

  const WalletState({
    this.usdcBalance = 0.0,
    this.xlmBalance = 0.0,
    this.ngntBalance = 0.0,
    this.xlmReserved = 0.0,
    this.xlmPriceUSD = 0.169,
    this.ngntPriceUSD,
    this.ngnRate,
    this.stellarAddress,
    this.dayfiUsername,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.hasError = false,
    this.isOffline = false,
    this.lastKnownTotal,
  });

  // Total USD value across all assets
  double get totalUSD => usdcBalance + (ngntBalance * (ngntPriceUSD ?? 0));

  // Available XLM = total balance - reserved (all reserved XLM is locked)
  double get availableXLM => (xlmBalance - xlmReserved).clamp(0, double.infinity);
  double get availableXLMUSD => availableXLM * xlmPriceUSD;

  // NGN display value of NGNT (1:1)
  double get ngntNGN => ngntBalance;

  WalletState copyWith({
    double? usdcBalance,
    double? xlmBalance,
    double? ngntBalance,
    double? xlmReserved,
    double? xlmPriceUSD,
    double? ngntPriceUSD,
    double? ngnRate,
    String? stellarAddress,
    String? dayfiUsername,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    bool? hasError,
    bool? isOffline,
    double? lastKnownTotal,
  }) {
    return WalletState(
      usdcBalance: usdcBalance ?? this.usdcBalance,
      xlmBalance: xlmBalance ?? this.xlmBalance,
      ngntBalance: ngntBalance ?? this.ngntBalance,
      xlmReserved: xlmReserved ?? this.xlmReserved,
      xlmPriceUSD: xlmPriceUSD ?? this.xlmPriceUSD,
      ngntPriceUSD: ngntPriceUSD ?? this.ngntPriceUSD,
      ngnRate: ngnRate ?? this.ngnRate,
      stellarAddress: stellarAddress ?? this.stellarAddress,
      dayfiUsername: dayfiUsername ?? this.dayfiUsername,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error, // nullable — always overwrite
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasError: hasError ?? this.hasError,
      isOffline: isOffline ?? this.isOffline,
      lastKnownTotal: lastKnownTotal ?? this.lastKnownTotal,
    );
  }
}

// ─── Wallet Notifier ──────────────────────────────────────────────────────────

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState(isLoading: true)) {
    load();
  }

  // ─── Price fetchers ──────────────────────────────────────

  Future<double> _fetchXlmPrice() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/simple/price'
              '?ids=stellar&vs_currencies=usd',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['stellar']['usd'] as num).toDouble();
      }
    } catch (_) {}
    return state.xlmPriceUSD;
  }

  /// Returns (ngntPriceUSD, ngnPerUSD)
  /// CoinGecko: price of 1 USD in NGN → invert to get USD per NGN.
  /// Since 1 NGNT = 1 NGN, ngntPriceUSD = 1 / ngnPerUSD.
  Future<(double, double)> _fetchNgnRate() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/simple/price'
              '?ids=usd&vs_currencies=ngn',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final ngnPerUsd = (data['usd']['ngn'] as num).toDouble();
        if (ngnPerUsd > 0) {
          return (1.0 / ngnPerUsd, ngnPerUsd);
        }
      }
    } catch (_) {}
    // Fallback: ₦1700 per USD
    const fallbackRate = 1354.92;
    return (1.0 / fallbackRate, fallbackRate);
  }

  // ─── Helpers ────────────────────────────────────────────

  double? _computeLastKnown({
    required double usdcBalance,
    required double xlmBalance,
    required double ngntBalance,
    required double xlmPrice,
    required double ngntPriceUsd,
  }) {
    final live =
        usdcBalance + (xlmBalance * xlmPrice) + (ngntBalance * ngntPriceUsd);
    return live > 0 ? live : state.lastKnownTotal;
  }

  bool _isNetworkError(Object e) {
    return e is SocketException ||
        e is TimeoutException ||
        e.toString().contains('SocketException') ||
        e.toString().contains('TimeoutException') ||
        e.toString().contains('Failed host lookup') ||
        e.toString().contains('Network is unreachable') ||
        e.toString().contains('Connection refused');
  }

  // ─── Initial load ────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      isOffline: false,
      error: null,
    );

    try {
      final results = await Future.wait([
        apiService.getBalance(),
        apiService.getAddress(),
        _fetchXlmPrice(),
        _fetchNgnRate(),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final addressData = results[1] as Map<String, dynamic>;
      final xlmPrice = results[2] as double;
      final (ngntPriceUsd, ngnPerUsd) = results[3] as (double, double);

      final balances = balanceData['balances'] as Map<String, dynamic>? ?? {};
      final usdc = (balances['USDC'] as num?)?.toDouble() ?? 0.0;
      final xlm = (balances['XLM'] as num?)?.toDouble() ?? 0.0;
      final ngnt = (balances['NGNT'] as num?)?.toDouble() ?? 0.0;
      final xlmReserved = (balanceData['xlmReserved'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        usdcBalance: usdc,
        xlmBalance: xlm,
        ngntBalance: ngnt,
        xlmReserved: xlmReserved,
        xlmPriceUSD: xlmPrice,
        ngntPriceUSD: ngntPriceUsd,
        ngnRate: ngnPerUsd,
        stellarAddress: addressData['stellarAddress'] as String?,
        dayfiUsername: addressData['dayfiUsername'] as String?,
        isLoading: false,
        hasError: false,
        isOffline: false,
        lastKnownTotal: _computeLastKnown(
          usdcBalance: usdc,
          xlmBalance: xlm,
          ngntBalance: ngnt,
          xlmPrice: xlmPrice,
          ngntPriceUsd: ngntPriceUsd,
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      final offline = _isNetworkError(e);
      state = state.copyWith(
        isLoading: false,
        hasError: !offline,
        isOffline: offline,
        error: e.toString(),
      );
    }
  }

  // ─── Pull-to-refresh ─────────────────────────────────────

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    final previousTotal = state.totalUSD > 0
        ? state.totalUSD
        : state.lastKnownTotal;

    state = state.copyWith(
      isRefreshing: true,
      hasError: false,
      isOffline: false,
      error: null,
    );

    try {
      final results = await Future.wait([
        apiService.getBalance(),
        _fetchXlmPrice(),
        _fetchNgnRate(),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final xlmPrice = results[1] as double;
      final (ngntPriceUsd, ngnPerUsd) = results[2] as (double, double);

      final balances = balanceData['balances'] as Map<String, dynamic>? ?? {};
      final usdc = (balances['USDC'] as num?)?.toDouble() ?? 0.0;
      final xlm = (balances['XLM'] as num?)?.toDouble() ?? 0.0;
      final ngnt = (balances['NGNT'] as num?)?.toDouble() ?? 0.0;
      final xlmReserved = (balanceData['xlmReserved'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        usdcBalance: usdc,
        xlmBalance: xlm,
        ngntBalance: ngnt,
        xlmReserved: xlmReserved,
        xlmPriceUSD: xlmPrice,
        ngntPriceUSD: ngntPriceUsd,
        ngnRate: ngnPerUsd,
        isRefreshing: false,
        hasError: false,
        isOffline: false,
        lastKnownTotal: _computeLastKnown(
          usdcBalance: usdc,
          xlmBalance: xlm,
          ngntBalance: ngnt,
          xlmPrice: xlmPrice,
          ngntPriceUsd: ngntPriceUsd,
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      final offline = _isNetworkError(e);
      state = state.copyWith(
        isRefreshing: false,
        hasError: !offline,
        isOffline: offline,
        error: e.toString(),
        usdcBalance: state.usdcBalance,
        xlmBalance: state.xlmBalance,
        ngntBalance: state.ngntBalance,
        lastKnownTotal: previousTotal,
      );
    }
  }

  // ─── Send ────────────────────────────────────────────────

  Future<Map<String, dynamic>> send({
    required String to,
    required double amount,
    required String asset,
    String? memo,
  }) async {
    final result = await apiService.sendFunds(
      to: to,
      amount: amount,
      asset: asset,
      memo: memo,
    );
    await refresh();
    return result;
  }

  // ─── Resolve recipient ───────────────────────────────────

  Future<Map<String, dynamic>?> resolveRecipient(String identifier) async {
    if (identifier.length < 3) return null;
    if (_isStellarAddress(identifier)) {
      return {
        'stellarAddress': identifier,
        'dayfiUsername': null,
        'displayName': identifier,
      };
    }
    try {
      return await apiService.resolveRecipient(identifier);
    } catch (_) {
      return null;
    }
  }

  bool _isStellarAddress(String input) {
    return input.length == 56 &&
        input.startsWith('G') &&
        RegExp(r'^[A-Z2-7]+$').hasMatch(input);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  return WalletNotifier();
});

final usdcBalanceProvider = Provider<double>(
  (ref) => ref.watch(walletProvider).usdcBalance,
);

final xlmBalanceProvider = Provider<double>(
  (ref) => ref.watch(walletProvider).xlmBalance,
);

final ngntBalanceProvider = Provider<double>(
  (ref) => ref.watch(walletProvider).ngntBalance,
);

final xlmPriceProvider = Provider<double>(
  (ref) => ref.watch(walletProvider).xlmPriceUSD,
);

/// USD value of 1 NGN (e.g. ~0.00059)
final ngntPriceUSDProvider = Provider<double?>(
  (ref) => ref.watch(walletProvider).ngntPriceUSD,
);

/// NGN per 1 USD (e.g. ~1700)
final ngnRateProvider = Provider<double?>(
  (ref) => ref.watch(walletProvider).ngnRate,
);

final walletAddressProvider = Provider<String?>(
  (ref) => ref.watch(walletProvider).stellarAddress,
);

final dayfiUsernameProvider = Provider<String?>(
  (ref) => ref.watch(walletProvider).dayfiUsername,
);
