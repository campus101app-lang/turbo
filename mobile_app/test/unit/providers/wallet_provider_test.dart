// mobile_app/test/unit/providers/wallet_provider_test.dart
//
// Unit Tests for Wallet Provider
// Tests wallet creation, transaction processing, and balance management
//

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile_app/providers/wallet_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/stellar_service.dart';

// Generate mocks
@GenerateMocks([ApiService, StellarService])
import 'wallet_provider_test.mocks.dart';

void main() {
  group('Wallet Provider Tests', () {
    late WalletProvider walletProvider;
    late MockApiService mockApiService;
    late MockStellarService mockStellarService;

    setUp(() {
      mockApiService = MockApiService();
      mockStellarService = MockStellarService();
      walletProvider = WalletProvider(
        apiService: mockApiService,
        stellarService: mockStellarService,
      );
    });

    test('should initialize with empty wallet state', () {
      expect(walletProvider.wallet, isNull);
      expect(walletProvider.balances, isEmpty);
      expect(walletProvider.isLoading, isFalse);
      expect(walletProvider.error, isNull);
    });

    test('should create wallet successfully', () async {
      // Arrange
      final mockWallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        'encryptedMnemonic': 'encrypted_mnemonic_data',
      };

      when(mockStellarService.createWallet()).thenAnswer((_) async => mockWallet);

      // Act
      await walletProvider.createWallet();

      // Assert
      expect(walletProvider.wallet, isNotNull);
      expect(walletProvider.wallet!['publicKey'], equals('GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q'));
      expect(walletProvider.isLoading, isFalse);
      expect(walletProvider.error, isNull);

      verify(mockStellarService.createWallet()).called(1);
    });

    test('should handle wallet creation failure', () async {
      // Arrange
      when(mockStellarService.createWallet())
          .thenThrow(Exception('Failed to create wallet'));

      // Act
      await walletProvider.createWallet();

      // Assert
      expect(walletProvider.wallet, isNull);
      expect(walletProvider.isLoading, isFalse);
      expect(walletProvider.error, isNotNull);
      expect(walletProvider.error!.contains('Failed to create wallet'), isTrue);
    });

    test('should load balances successfully', () async {
      // Arrange
      final mockBalances = [
        {'asset': 'XLM', 'balance': '1000.0000000'},
        {'asset': 'USDC', 'balance': '500.0000000'},
        {'asset': 'NGNT', 'balance': '100000.0000000'},
      ];

      // Set up wallet first
      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.getBalances(any))
          .thenAnswer((_) async => mockBalances);

      // Act
      await walletProvider.loadBalances();

      // Assert
      expect(walletProvider.balances, hasLength(3));
      expect(walletProvider.balances[0]['asset'], equals('XLM'));
      expect(walletProvider.balances[0]['balance'], equals('1000.0000000'));
      expect(walletProvider.balances[1]['asset'], equals('USDC'));
      expect(walletProvider.balances[1]['balance'], equals('500.0000000'));
      expect(walletProvider.balances[2]['asset'], equals('NGNT'));
      expect(walletProvider.balances[2]['balance'], equals('100000.0000000'));
      expect(walletProvider.isLoading, isFalse);

      verify(mockStellarService.getBalances(any)).called(1);
    });

    test('should send transaction successfully', () async {
      // Arrange
      final mockTransaction = {
        'success': true,
        'transactionId': 'tx_123456',
        'transactionHash': 'hash_789',
      };

      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.sendPayment(
        any,
        'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        '100.50',
        'USDC',
      )).thenAnswer((_) async => mockTransaction);

      // Act
      final result = await walletProvider.sendTransaction(
        recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        amount: '100.50',
        asset: 'USDC',
      );

      // Assert
      expect(result['success'], isTrue);
      expect(result['transactionId'], equals('tx_123456'));
      expect(walletProvider.isLoading, isFalse);
      expect(walletProvider.error, isNull);

      verify(mockStellarService.sendPayment(
        any,
        'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        '100.50',
        'USDC',
      )).called(1);
    });

    test('should handle transaction failure', () async {
      // Arrange
      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.sendPayment(
        any,
        'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        '100.50',
        'USDC',
      )).thenThrow(Exception('Insufficient balance'));

      // Act
      final result = await walletProvider.sendTransaction(
        recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        amount: '100.50',
        asset: 'USDC',
      );

      // Assert
      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
      expect(walletProvider.error, isNotNull);
      expect(walletProvider.error!.contains('Insufficient balance'), isTrue);
    });

    test('should create trustline successfully', () async {
      // Arrange
      final mockTrustline = {
        'success': true,
        'transactionId': 'trustline_123',
      };

      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.createTrustline(
        any,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
      )).thenAnswer((_) async => mockTrustline);

      // Act
      final result = await walletProvider.createTrustline(
        asset: 'USDC',
        issuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
      );

      // Assert
      expect(result['success'], isTrue);
      expect(result['transactionId'], equals('trustline_123'));
      expect(walletProvider.isLoading, isFalse);

      verify(mockStellarService.createTrustline(
        any,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
      )).called(1);
    });

    test('should get transaction history', () async {
      // Arrange
      final mockHistory = {
        'transactions': [
          {
            'id': 'tx_1',
            'type': 'payment',
            'amount': '100.00',
            'asset': 'USDC',
            'timestamp': '2024-01-01T12:00:00Z',
          },
          {
            'id': 'tx_2',
            'type': 'payment',
            'amount': '50.00',
            'asset': 'NGNT',
            'timestamp': '2024-01-02T14:30:00Z',
          },
        ],
      };

      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.getTransactionHistory(any))
          .thenAnswer((_) async => mockHistory);

      // Act
      final history = await walletProvider.getTransactionHistory();

      // Assert
      expect(history['transactions'], hasLength(2));
      expect(history['transactions'][0]['id'], equals('tx_1'));
      expect(history['transactions'][0]['amount'], equals('100.00'));
      expect(history['transactions'][1]['id'], equals('tx_2'));
      expect(history['transactions'][1]['amount'], equals('50.00'));

      verify(mockStellarService.getTransactionHistory(any)).called(1);
    });

    test('should validate recipient address', () {
      // Test valid addresses
      expect(
        walletProvider.isValidAddress('GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q'),
        isTrue,
      );
      expect(
        walletProvider.isValidAddress('GB5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q'),
        isTrue,
      );

      // Test invalid addresses
      expect(walletProvider.isValidAddress(''), isFalse);
      expect(walletProvider.isValidAddress('invalid'), isFalse);
      expect(walletProvider.isValidAddress('GD5QJZQJQ5'), isFalse); // Too short
      expect(walletProvider.isValidAddress('GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5X'), isFalse); // Invalid character
    });

    test('should validate amount format', () {
      // Test valid amounts
      expect(walletProvider.isValidAmount('100.50'), isTrue);
      expect(walletProvider.isValidAmount('1000'), isTrue);
      expect(walletProvider.isValidAmount('0.01'), isTrue);

      // Test invalid amounts
      expect(walletProvider.isValidAmount(''), isFalse);
      expect(walletProvider.isValidAmount('abc'), isFalse);
      expect(walletProvider.isValidAmount('-100'), isFalse);
      expect(walletProvider.isValidAmount('0'), isFalse);
    });

    test('should calculate transaction fees', () {
      // Test fee calculation for different assets
      expect(walletProvider.calculateTransactionFee('XLM'), equals('0.00001'));
      expect(walletProvider.calculateTransactionFee('USDC'), equals('0.00'));
      expect(walletProvider.calculateTransactionFee('NGNT'), equals('0.00'));
    });

    test('should handle loading states correctly', () {
      // Test initial state
      expect(walletProvider.isLoading, isFalse);

      // Test loading state during operations
      walletProvider.setLoading(true);
      expect(walletProvider.isLoading, isTrue);

      walletProvider.setLoading(false);
      expect(walletProvider.isLoading, isFalse);
    });

    test('should handle error states correctly', () {
      // Test initial state
      expect(walletProvider.error, isNull);

      // Test error setting
      walletProvider.setError('Test error message');
      expect(walletProvider.error, equals('Test error message'));

      // Test error clearing
      walletProvider.clearError();
      expect(walletProvider.error, isNull);
    });

    test('should refresh wallet data', () async {
      // Arrange
      final mockBalances = [
        {'asset': 'XLM', 'balance': '2000.0000000'},
        {'asset': 'USDC', 'balance': '750.0000000'},
      ];

      final mockHistory = {
        'transactions': [
          {
            'id': 'tx_new',
            'type': 'payment',
            'amount': '250.00',
            'asset': 'USDC',
            'timestamp': '2024-01-03T10:00:00Z',
          },
        ],
      };

      walletProvider.wallet = {
        'publicKey': 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
      };

      when(mockStellarService.getBalances(any))
          .thenAnswer((_) async => mockBalances);
      when(mockStellarService.getTransactionHistory(any))
          .thenAnswer((_) async => mockHistory);

      // Act
      await walletProvider.refreshWalletData();

      // Assert
      expect(walletProvider.balances, hasLength(2));
      expect(walletProvider.balances[0]['balance'], equals('2000.0000000'));
      expect(walletProvider.isLoading, isFalse);

      verify(mockStellarService.getBalances(any)).called(1);
      verify(mockStellarService.getTransactionHistory(any)).called(1);
    });
  });
}
