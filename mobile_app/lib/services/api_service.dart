// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://turbo-production-afee.up.railway.app';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String email) async =>
      (await _dio.post('/api/auth/send-otp', data: {'email': email})).data;

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async =>
      (await _dio.post(
        '/api/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      )).data;

  Future<Map<String, dynamic>> setupBusinessProfile({
    required String setupToken,
    required String fullName,
    required String businessName,
    required String businessCategory,
    String? businessEmail,
  }) async {
    final resp = await _dio.post(
      '/api/auth/setup-profile',
      data: {
        'setupToken': setupToken,
        'fullName': fullName,
        'businessName': businessName,
        'businessCategory': businessCategory,
        if (businessEmail != null) 'businessEmail': businessEmail,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── User ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async =>
      (await _dio.get('/api/user/me')).data;

  Future<void> registerDeviceToken(String token, String platform) async =>
      _dio.post(
        '/api/user/device-token',
        data: {'token': token, 'platform': platform},
      );

  // ─── Wallet ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getBalance() async =>
      (await _dio.get('/api/wallet/balance')).data;

  Future<Map<String, dynamic>> getAddress() async =>
      (await _dio.get('/api/wallet/address')).data;

  Future<Map<String, dynamic>> getNetworkConfig() async =>
      (await _dio.get('/api/wallet/networks')).data;

  Future<Map<String, dynamic>> sendFunds({
    required String to,
    required double amount,
    required String asset,
    String? memo,
  }) async =>
      (await _dio.post(
        '/api/wallet/send',
        data: {
          'to': to,
          'amount': amount,
          'asset': asset,
          if (memo != null) 'memo': memo,
        },
      )).data;

  Future<Map<String, dynamic>> resolveRecipient(String identifier) async =>
      (await _dio.get('/api/wallet/resolve/$identifier')).data;

  // ─── Transactions ─────────────────────────────────────────
  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? asset,
  }) async =>
      (await _dio.get(
        '/api/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
          if (asset != null) 'asset': asset,
        },
      )).data;

  // ─── SEP-38: Quotes ───────────────────────────────────────
  Future<Map<String, dynamic>> getQuote({
    required String sellAsset,
    required String buyAsset,
    double? sellAmount,
    double? buyAmount,
  }) async =>
      (await _dio.get(
        '/sep38/price',
        queryParameters: {
          'sell_asset': sellAsset,
          'buy_asset': buyAsset,
          if (sellAmount != null) 'sell_amount': sellAmount.toString(),
          if (buyAmount != null) 'buy_amount': buyAmount.toString(),
        },
      )).data;

  Future<Map<String, dynamic>> getPrices({
    required String sellAsset,
    required double sellAmount,
  }) async =>
      (await _dio.get(
        '/sep38/prices',
        queryParameters: {
          'sell_asset': sellAsset,
          'sell_amount': sellAmount.toString(),
        },
      )).data;

  // ─── SEP-24: Deposit / Withdraw ───────────────────────────
  Future<Map<String, dynamic>> initiateDeposit({
    required String assetCode,
    required String account,
    double? amount,
  }) async =>
      (await _dio.post(
        '/sep24/transactions/deposit/interactive',
        data: {
          'asset_code': assetCode,
          'account': account,
          if (amount != null) 'amount': amount.toString(),
        },
      )).data;

  Future<Map<String, dynamic>> initiateWithdraw({
    required String assetCode,
    required String account,
    double? amount,
  }) async =>
      (await _dio.post(
        '/sep24/transactions/withdraw/interactive',
        data: {
          'asset_code': assetCode,
          'account': account,
          if (amount != null) 'amount': amount.toString(),
        },
      )).data;

  Future<Map<String, dynamic>> getDepositStatus(String txId) async =>
      (await _dio.get(
        '/sep24/transaction',
        queryParameters: {'id': txId},
      )).data;

  // ─── Swap ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSwapQuote({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async =>
      (await _dio.get(
        '/api/wallet/swap-quote',
        queryParameters: {
          'from': fromAsset,
          'to': toAsset,
          'amount': amount.toString(),
        },
      )).data;

  Future<Map<String, dynamic>> executeSwap({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async =>
      (await _dio.post(
        '/api/wallet/swap',
        data: {'fromAsset': fromAsset, 'toAsset': toAsset, 'amount': amount},
      )).data;

  Future<void> markBackedUp() async =>
      await _dio.post('/api/auth/mark-backed-up');

  Future<List<String>> getMnemonic() async {
    final res = await _dio.get('/api/auth/mnemonic');
    final List<dynamic> words = res.data['words'] ?? [];
    return words.cast<String>();
  }

  Future<Map<String, dynamic>> syncTransactionsFromBlockchain() async =>
      (await _dio.post('/api/wallet/sync-transactions')).data;

  Future<Map<String, dynamic>> testFundWallet() async =>
      (await _dio.post('/api/wallet/test-funding')).data;

  // ─── Token ────────────────────────────────────────────────
  Future<void> saveToken(String t) async =>
      _storage.write(key: 'auth_token', value: t);
  Future<String?> getToken() async => _storage.read(key: 'auth_token');
  Future<void> clearToken() async => _storage.delete(key: 'auth_token');

  // ─── Virtual Account (NGN funding) ───────────────────────
  //
  // GET  /api/payments/virtual-account
  //   → { exists: false }
  //   → { exists: true, accountNumber, bankName, accountName }
  //
  // POST /api/payments/virtual-account  { bvn }
  //   → { accountNumber, bankName, accountName }

  /// Fetch the user's existing virtual account (if created).
  Future<Map<String, dynamic>> getVirtualAccount() async =>
      (await _dio.get('/api/payments/virtual-account')).data
          as Map<String, dynamic>;

  /// Create a virtual account for the first time (BVN required).
  Future<Map<String, dynamic>> createVirtualAccount({
    required String bvn,
  }) async =>
      (await _dio.post(
        '/api/payments/virtual-account',
        data: {'bvn': bvn},
      )).data as Map<String, dynamic>;

  // ─── Flutterwave (WebView deposit — kept for future use) ──

  Future<Map<String, dynamic>> initFlutterwaveDeposit({
    required double amount,
  }) async =>
      (await _dio.post(
        '/api/payments/flutterwave/init',
        data: {'amount': amount, 'currency': 'NGN'},
      )).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> verifyFlutterwaveDeposit({
    required String txRef,
  }) async =>
      (await _dio.post(
        '/api/payments/flutterwave/verify',
        data: {'txRef': txRef},
      )).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> withdrawToBank({
    required double ngntAmount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async =>
      (await _dio.post(
        '/api/payments/flutterwave/withdraw',
        data: {
          'ngntAmount': ngntAmount,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountName': accountName,
        },
      )).data as Map<String, dynamic>;

  // ─── Invoices ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getInvoices({
    int page = 1,
    int limit = 20,
    String? status,
  }) async =>
      (await _dio.get(
        '/api/invoices',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      )).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> createInvoice(
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.post('/api/invoices', data: payload)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateInvoice(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.put('/api/invoices/$id', data: payload)).data
          as Map<String, dynamic>;

  Future<void> deleteInvoice(String id) async =>
      _dio.delete('/api/invoices/$id');

  Future<Map<String, dynamic>> sendInvoice(String id) async =>
      (await _dio.post('/api/invoices/$id/send')).data as Map<String, dynamic>;

  // ─── Expenses ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int limit = 20,
    String? status,
  }) async =>
      (await _dio.get(
        '/api/expenses',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      )).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.post('/api/expenses', data: payload)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> approveExpense(String id) async =>
      (await _dio.put('/api/expenses/$id/approve')).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> rejectExpense(String id, String reason) async =>
      (await _dio.put(
        '/api/expenses/$id/reject',
        data: {'rejectionNote': reason},
      )).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> reimburseExpense(String id) async =>
      (await _dio.post('/api/expenses/$id/reimburse')).data
          as Map<String, dynamic>;

  // ─── Inventory ────────────────────────────────────────────
  Future<List<dynamic>> getInventory() async =>
      (await _dio.get('/api/inventory')).data['items'] as List<dynamic>;

  Future<Map<String, dynamic>> createInventoryItem({
    required String name,
    required double priceUsdc,
    required int stock,
    int threshold = 5,
    String? sku,
    String? category,
    String? imageUrl,
  }) async =>
      (await _dio.post(
        '/api/inventory',
        data: {
          'name': name,
          'priceUsdc': priceUsdc,
          'stock': stock,
          'threshold': threshold,
          if (sku != null) 'sku': sku,
          if (category != null) 'category': category,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      )).data['item'];

  Future<Map<String, dynamic>> rawGet(String url) async =>
      (await _dio.get(url)).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateStock(
    String itemId, {
    int? delta,
    int? absolute,
  }) async =>
      (await _dio.patch(
        '/api/inventory/$itemId/stock',
        data: {
          if (delta != null) 'delta': delta,
          if (absolute != null) 'absolute': absolute,
        },
      )).data['item'];

  Future<Map<String, dynamic>> updateInventoryItem(
    String itemId,
    Map<String, dynamic> data,
  ) async =>
      (await _dio.patch('/api/inventory/$itemId', data: data)).data['item'];

  Future<void> deleteInventoryItem(String itemId) async =>
      _dio.delete('/api/inventory/$itemId');

  Future<Map<String, dynamic>> getCheckoutUri({
    required List<Map<String, dynamic>> items,
    required double totalUsdc,
  }) async =>
      (await _dio.post(
        '/api/inventory/checkout/uri',
        data: {'items': items, 'totalUsdc': totalUsdc},
      )).data;

  // ─── Error parser ─────────────────────────────────────────
  String parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) return data['error'];
      if (data is Map && data['errors'] != null) {
        return (data['errors'] as List).map((e) => e['msg']).join(', ');
      }
      if (error.type == DioExceptionType.badResponse) {
        return 'Server error: ${error.response?.statusCode ?? 'Unknown'}';
      }
      return error.message ?? 'Network error';
    }
    final errStr = error.toString();
    if (errStr.contains('not a function')) {
      return 'Server processing error - please try again';
    }
    if (errStr.contains('Insufficient')) return errStr.split('\n')[0];
    return errStr.length > 100 ? '${errStr.substring(0, 97)}...' : errStr;
  }
}

final apiService = ApiService();