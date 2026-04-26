// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://turbo-production-afee.up.railway.app', // Your Railway URL
  );

  // Make baseUrl accessible for debugging
  static String get getBaseUrl => baseUrl;

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
          print('API Request: ${options.method} ${options.path}');
          final token = await _storage.read(key: 'auth_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          print(
            'API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
          );
          print('API Error Details: ${error.response?.data}');
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> uploadProductImage(
    String itemId,
    File imageFile,
  ) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });
    return (await _dio.post(
          '/api/shop/products/$itemId/image',
          data: formData,
        )).data
        as Map<String, dynamic>;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

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
      '/api/auth/setup-profile', // ← was setup-business-profile, wrong
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

  Future<void> markBackedUp() async =>
      await _dio.post('/api/auth/mark-backed-up');

  Future<List<String>> getMnemonic() async {
    final res = await _dio.get('/api/auth/mnemonic');
    final List<dynamic> words = res.data['words'] ?? [];
    return words.cast<String>();
  }

  Future<Map<String, dynamic>> setupBusinessOnboarding(
    Map<String, dynamic> data,
  ) async =>
      (await _dio.post('/api/auth/setup-onboarding', data: data)).data
          as Map<String, dynamic>;

  // ─── User ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMe() async =>
      (await _dio.get('/api/user/me')).data;

  Future<void> registerDeviceToken(String token, String platform) async =>
      _dio.post(
        '/api/user/device-token',
        data: {'token': token, 'platform': platform},
      );

  // ─── Token ────────────────────────────────────────────────────────────────

  Future<void> saveToken(String t) async =>
      _storage.write(key: 'auth_token', value: t);
  Future<String?> getToken() async => _storage.read(key: 'auth_token');
  Future<void> clearToken() async => _storage.delete(key: 'auth_token');

  // ─── Wallet ───────────────────────────────────────────────────────────────

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
  }) async => (await _dio.post(
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

  Future<Map<String, dynamic>> getSwapQuote({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async => (await _dio.get(
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
  }) async => (await _dio.post(
    '/api/wallet/swap',
    data: {'fromAsset': fromAsset, 'toAsset': toAsset, 'amount': amount},
  )).data;

  Future<Map<String, dynamic>> syncTransactionsFromBlockchain() async =>
      (await _dio.post('/api/wallet/sync-transactions')).data;

  Future<Map<String, dynamic>> testFundWallet() async =>
      (await _dio.post('/api/wallet/test-funding')).data;

  // ─── SEP-38: Quotes ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getQuote({
    required String sellAsset,
    required String buyAsset,
    double? sellAmount,
    double? buyAmount,
  }) async => (await _dio.get(
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
  }) async => (await _dio.get(
    '/sep38/prices',
    queryParameters: {
      'sell_asset': sellAsset,
      'sell_amount': sellAmount.toString(),
    },
  )).data;

  // ─── SEP-24: Deposit / Withdraw ───────────────────────────────────────────

  Future<Map<String, dynamic>> initiateDeposit({
    required String assetCode,
    required String account,
    double? amount,
  }) async => (await _dio.post(
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
  }) async => (await _dio.post(
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

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? asset,
  }) async => (await _dio.get(
    '/api/transactions',
    queryParameters: {
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (asset != null) 'asset': asset,
    },
  )).data;

  // ─── Virtual Account (NGN) ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVirtualAccount() async =>
      (await _dio.get('/api/payments/virtual-account')).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> createVirtualAccount({
    required String bvn,
  }) async =>
      (await _dio.post(
            '/api/payments/virtual-account',
            data: {'bvn': bvn},
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> initFlutterwaveDeposit({
    required double amount,
  }) async =>
      (await _dio.post(
            '/api/payments/flutterwave/init',
            data: {'amount': amount, 'currency': 'NGN'},
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> verifyFlutterwaveDeposit({
    required String txRef,
  }) async =>
      (await _dio.post(
            '/api/payments/flutterwave/verify',
            data: {'txRef': txRef},
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> withdrawToBank({
    required double ngntAmount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    String? idempotencyKey,
  }) async =>
      (await _dio.post(
            '/api/payments/flutterwave/withdraw',
            data: {
              'ngntAmount': ngntAmount,
              'bankCode': bankCode,
              'accountNumber': accountNumber,
              'accountName': accountName,
              if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
            },
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getNigeriaBanks() async =>
      (await _dio.get('/api/payments/flutterwave/banks')).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> resolveBankAccount({
    required String bankCode,
    required String accountNumber,
  }) async =>
      (await _dio.post(
            '/api/payments/flutterwave/resolve-account',
            data: {'bankCode': bankCode, 'accountNumber': accountNumber},
          )).data
          as Map<String, dynamic>;

  // ─── Workflows ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWorkflows({
    int page = 1,
    int limit = 20,
    String? status,
  }) async =>
      (await _dio.get(
            '/api/workflows',
            queryParameters: {
              'page': page,
              'limit': limit,
              if (status != null) 'status': status,
            },
          )).data
          as Map<String, dynamic>;

  // ─── Organization ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOrganization() async =>
      (await _dio.get('/api/organization')).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> createOrganization(
    Map<String, dynamic> data,
  ) async =>
      (await _dio.post('/api/organization', data: data)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateOrganization(
    String id,
    Map<String, dynamic> data,
  ) async =>
      (await _dio.put('/api/organization/$id', data: data)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> inviteOrganizationMember(
    Map<String, dynamic> data,
  ) async =>
      (await _dio.post('/api/organization/invite', data: data)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateOrganizationMember(
    String organizationId,
    String memberId,
    Map<String, dynamic> data,
  ) async =>
      (await _dio.put(
            '/api/organization/$organizationId/members/$memberId',
            data: data,
          )).data
          as Map<String, dynamic>;

  Future<void> removeOrganizationMember(
    String organizationId,
    String memberId,
  ) async =>
      await _dio.delete('/api/organization/$organizationId/members/$memberId');

  Future<Map<String, dynamic>> getOrganizationFinancialDashboard(
    String period,
  ) async =>
      (await _dio.get(
            '/api/organization/financial-dashboard',
            queryParameters: {'period': period},
          )).data
          as Map<String, dynamic>;

  // ─── Invoices ─────────────────────────────────────────────────────────────

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
          )).data
          as Map<String, dynamic>;

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

  Future<Map<String, dynamic>> markInvoicePaid(String id) async =>
      (await _dio.post('/api/invoices/$id/mark-paid')).data
          as Map<String, dynamic>;

  // ─── Expenses ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
  }) async =>
      (await _dio.get(
            '/api/expenses',
            queryParameters: {
              'page': page,
              'limit': limit,
              if (status != null) 'status': status,
              if (category != null) 'category': category,
            },
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> getExpense(String id) async =>
      (await _dio.get('/api/expenses/$id')).data as Map<String, dynamic>;

  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.post('/api/expenses', data: payload)).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.put('/api/expenses/$id', data: payload)).data
          as Map<String, dynamic>;

  Future<void> deleteExpense(String id) async =>
      _dio.delete('/api/expenses/$id');

  Future<Map<String, dynamic>> approveExpense(String id) async =>
      (await _dio.post('/api/expenses/$id/approve')).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> rejectExpense(
    String id,
    String rejectionNote,
  ) async =>
      (await _dio.post(
            '/api/expenses/$id/reject',
            data: {'rejectionNote': rejectionNote},
          )).data
          as Map<String, dynamic>;

  // ─── Cards ────────────────────────────────────────────────────────────────

  /// GET /api/cards — list all non-cancelled cards
  Future<Map<String, dynamic>> getCards() async =>
      (await _dio.get('/api/cards')).data as Map<String, dynamic>;

  /// GET /api/cards/:id — single card
  Future<Map<String, dynamic>> getCard(String id) async =>
      (await _dio.get('/api/cards/$id')).data as Map<String, dynamic>;

  /// POST /api/cards — create virtual card
  /// payload: { cardholderName, currency, label?, color?, spendingLimit? }
  /// Returns: { card, cvv } — cvv shown once only
  Future<Map<String, dynamic>> createCard(Map<String, dynamic> payload) async =>
      (await _dio.post('/api/cards', data: payload)).data
          as Map<String, dynamic>;

  /// PATCH /api/cards/:id — update label / color / spending limit
  Future<Map<String, dynamic>> updateCard(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.patch('/api/cards/$id', data: payload)).data
          as Map<String, dynamic>;

  /// POST /api/cards/:id/freeze
  Future<Map<String, dynamic>> freezeCard(String id) async =>
      (await _dio.post('/api/cards/$id/freeze')).data as Map<String, dynamic>;

  /// POST /api/cards/:id/unfreeze
  Future<Map<String, dynamic>> unfreezeCard(String id) async =>
      (await _dio.post('/api/cards/$id/unfreeze')).data as Map<String, dynamic>;

  /// DELETE /api/cards/:id — cancel card permanently
  Future<Map<String, dynamic>> cancelCard(String id) async =>
      (await _dio.delete('/api/cards/$id')).data as Map<String, dynamic>;

  // ─── Workflows ────────────────────────────────────────────────────────────

  /// GET /api/workflows/:id
  Future<Map<String, dynamic>> getWorkflow(String id) async =>
      (await _dio.get('/api/workflows/$id')).data as Map<String, dynamic>;

  /// POST /api/workflows
  /// payload: { name, description?, triggerType, triggerConfig, actionType, actionConfig }
  Future<Map<String, dynamic>> createWorkflow(
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.post('/api/workflows', data: payload)).data
          as Map<String, dynamic>;

  /// PUT /api/workflows/:id — update workflow
  Future<Map<String, dynamic>> updateWorkflow(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.put('/api/workflows/$id', data: payload)).data
          as Map<String, dynamic>;

  /// DELETE /api/workflows/:id — soft-delete (archives)
  Future<Map<String, dynamic>> deleteWorkflow(String id) async =>
      (await _dio.delete('/api/workflows/$id')).data as Map<String, dynamic>;

  /// POST /api/workflows/:id/pause
  Future<Map<String, dynamic>> pauseWorkflow(String id) async =>
      (await _dio.post('/api/workflows/$id/pause')).data
          as Map<String, dynamic>;

  /// POST /api/workflows/:id/resume
  Future<Map<String, dynamic>> resumeWorkflow(String id) async =>
      (await _dio.post('/api/workflows/$id/resume')).data
          as Map<String, dynamic>;

  /// POST /api/workflows/:id/run — manual trigger
  Future<Map<String, dynamic>> runWorkflow(String id) async =>
      (await _dio.post('/api/workflows/$id/run')).data as Map<String, dynamic>;

  // ─── Payment Requests ─────────────────────────────────────────────────────

  /// GET /api/requests — list payment requests
  Future<Map<String, dynamic>> getRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async =>
      (await _dio.get(
            '/api/requests',
            queryParameters: {
              'page': page,
              'limit': limit,
              if (status != null) 'status': status,
            },
          )).data
          as Map<String, dynamic>;

  /// GET /api/requests/:id
  Future<Map<String, dynamic>> getRequest(String id) async =>
      (await _dio.get('/api/requests/$id')).data as Map<String, dynamic>;

  /// POST /api/requests — create payment request
  /// payload: { amount, asset, note?, payerName?, payerEmail?, expiresAt? }
  /// Returns: { request } with paymentLink already generated
  Future<Map<String, dynamic>> createRequest(
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.post('/api/requests', data: payload)).data
          as Map<String, dynamic>;

  /// DELETE /api/requests/:id — cancel pending request
  Future<Map<String, dynamic>> cancelRequest(String id) async =>
      (await _dio.delete('/api/requests/$id')).data as Map<String, dynamic>;

  /// PUT /api/requests/:id — edit pending request
  Future<Map<String, dynamic>> updateRequest(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      (await _dio.put('/api/requests/$id', data: payload)).data
          as Map<String, dynamic>;

  /// POST /api/requests/:id/mark-paid — manually mark as paid
  Future<Map<String, dynamic>> markRequestPaid(String id) async =>
      (await _dio.post('/api/requests/$id/mark-paid')).data
          as Map<String, dynamic>;

  /// GET /api/requests/pay/:requestNumber — public, no auth
  Future<Map<String, dynamic>> getPublicRequest(String requestNumber) async =>
      (await _dio.get('/api/requests/pay/$requestNumber')).data
          as Map<String, dynamic>;

  // ─── Inventory ────────────────────────────────────────────────────────────

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
  }) async => (await _dio.post(
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

  Future<Map<String, dynamic>> updateStock(
    String itemId, {
    int? delta,
    int? absolute,
  }) async => (await _dio.patch(
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
  }) async => (await _dio.post(
    '/api/inventory/checkout/uri',
    data: {'items': items, 'totalUsdc': totalUsdc},
  )).data;

  Future<Map<String, dynamic>> rawGet(String url) async =>
      (await _dio.get(url)).data as Map<String, dynamic>;

  // ─── Error parser ─────────────────────────────────────────────────────────

  String parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'];
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
    if (errStr.contains('not a function'))
      return 'Server processing error - please try again';
    if (errStr.contains('Insufficient')) return errStr.split('\n')[0];
    return errStr.length > 100 ? '${errStr.substring(0, 97)}...' : errStr;
  }
}

final apiService = ApiService();
