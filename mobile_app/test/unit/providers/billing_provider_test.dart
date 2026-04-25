// mobile_app/test/unit/providers/billing_provider_test.dart
//
// Unit Tests for Billing Provider
// Tests invoice management, payment processing, and customer data
//

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile_app/providers/billing_provider.dart';
import 'package:mobile_app/services/api_service.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'billing_provider_test.mocks.dart';

void main() {
  group('Billing Provider Tests', () {
    late BillingProvider billingProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      billingProvider = BillingProvider(apiService: mockApiService);
    });

    test('should initialize with empty state', () {
      expect(billingProvider.invoices, isEmpty);
      expect(billingProvider.customers, isEmpty);
      expect(billingProvider.payments, isEmpty);
      expect(billingProvider.isLoading, isFalse);
      expect(billingProvider.error, isNull);
      expect(billingProvider.totalRevenue, equals(0.0));
    });

    test('should create invoice successfully', () async {
      // Arrange
      final invoiceData = {
        'customerEmail': 'customer@example.com',
        'amount': '50000.00',
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Professional Services',
        'organizationId': 'org_123',
      };

      final mockResponse = {
        'success': true,
        'invoice': {
          'id': 'inv_123',
          'invoiceNumber': 'INV-2024-001',
          'customerEmail': 'customer@example.com',
          'amount': '50000.00',
          'currency': 'NGN',
          'status': 'draft',
          'createdAt': '2024-01-01T00:00:00Z',
        },
      };

      when(mockApiService.createInvoice(invoiceData))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await billingProvider.createInvoice(invoiceData);

      // Assert
      expect(result['success'], isTrue);
      expect(result['invoice']['id'], equals('inv_123'));
      expect(result['invoice']['status'], equals('draft'));
      expect(billingProvider.invoices, hasLength(1));
      expect(billingProvider.invoices[0]['id'], equals('inv_123'));
      expect(billingProvider.isLoading, isFalse);

      verify(mockApiService.createInvoice(invoiceData)).called(1);
    });

    test('should handle invoice creation failure', () async {
      // Arrange
      final invoiceData = {
        'customerEmail': 'customer@example.com',
        'amount': '50000.00',
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Professional Services',
      };

      when(mockApiService.createInvoice(invoiceData))
          .thenThrow(Exception('Failed to create invoice'));

      // Act
      final result = await billingProvider.createInvoice(invoiceData);

      // Assert
      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
      expect(billingProvider.error, isNotNull);
      expect(billingProvider.error!.contains('Failed to create invoice'), isTrue);
    });

    test('should load invoices successfully', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'invoices': [
          {
            'id': 'inv_1',
            'invoiceNumber': 'INV-2024-001',
            'customerEmail': 'customer1@example.com',
            'amount': '50000.00',
            'currency': 'NGN',
            'status': 'paid',
            'createdAt': '2024-01-01T00:00:00Z',
          },
          {
            'id': 'inv_2',
            'invoiceNumber': 'INV-2024-002',
            'customerEmail': 'customer2@example.com',
            'amount': '75000.00',
            'currency': 'NGN',
            'status': 'pending',
            'createdAt': '2024-01-02T00:00:00Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 10,
          'total': 2,
        },
      };

      when(mockApiService.getInvoices(page: 1, limit: 10))
          .thenAnswer((_) async => mockResponse);

      // Act
      await billingProvider.loadInvoices(page: 1, limit: 10);

      // Assert
      expect(billingProvider.invoices, hasLength(2));
      expect(billingProvider.invoices[0]['invoiceNumber'], equals('INV-2024-001'));
      expect(billingProvider.invoices[1]['status'], equals('pending'));
      expect(billingProvider.totalRevenue, equals(125000.0)); // 50000 + 75000
      expect(billingProvider.isLoading, isFalse);

      verify(mockApiService.getInvoices(page: 1, limit: 10)).called(1);
    });

    test('should update invoice status successfully', () async {
      // Arrange
      final invoiceId = 'inv_123';
      final newStatus = 'sent';

      final mockResponse = {
        'success': true,
        'invoice': {
          'id': invoiceId,
          'status': newStatus,
          'sentAt': '2024-01-02T10:00:00Z',
        },
      };

      when(mockApiService.updateInvoiceStatus(invoiceId, newStatus))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await billingProvider.updateInvoiceStatus(invoiceId, newStatus);

      // Assert
      expect(result['success'], isTrue);
      expect(result['invoice']['status'], equals(newStatus));

      // Update local state
      billingProvider.invoices = [
        {'id': invoiceId, 'status': 'draft'},
      ];
      await billingProvider.updateInvoiceStatus(invoiceId, newStatus);

      expect(billingProvider.invoices[0]['status'], equals(newStatus));

      verify(mockApiService.updateInvoiceStatus(invoiceId, newStatus)).called(2);
    });

    test('should create payment successfully', () async {
      // Arrange
      final paymentData = {
        'invoiceId': 'inv_123',
        'amount': '50000.00',
        'currency': 'NGN',
        'paymentMethod': 'bank_transfer',
        'reference': 'PAY_123456',
      };

      final mockResponse = {
        'success': true,
        'payment': {
          'id': 'pay_123',
          'invoiceId': 'inv_123',
          'amount': '50000.00',
          'currency': 'NGN',
          'status': 'pending',
          'reference': 'PAY_123456',
          'createdAt': '2024-01-02T00:00:00Z',
        },
      };

      when(mockApiService.createPayment(paymentData))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await billingProvider.createPayment(paymentData);

      // Assert
      expect(result['success'], isTrue);
      expect(result['payment']['id'], equals('pay_123'));
      expect(result['payment']['status'], equals('pending'));
      expect(billingProvider.payments, hasLength(1));
      expect(billingProvider.payments[0]['id'], equals('pay_123'));

      verify(mockApiService.createPayment(paymentData)).called(1);
    });

    test('should load payments successfully', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'payments': [
          {
            'id': 'pay_1',
            'invoiceId': 'inv_1',
            'amount': '50000.00',
            'currency': 'NGN',
            'status': 'completed',
            'paymentMethod': 'bank_transfer',
            'createdAt': '2024-01-01T00:00:00Z',
          },
          {
            'id': 'pay_2',
            'invoiceId': 'inv_2',
            'amount': '25000.00',
            'currency': 'NGN',
            'status': 'pending',
            'paymentMethod': 'card',
            'createdAt': '2024-01-02T00:00:00Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 10,
          'total': 2,
        },
      };

      when(mockApiService.getPayments(page: 1, limit: 10))
          .thenAnswer((_) async => mockResponse);

      // Act
      await billingProvider.loadPayments(page: 1, limit: 10);

      // Assert
      expect(billingProvider.payments, hasLength(2));
      expect(billingProvider.payments[0]['status'], equals('completed'));
      expect(billingProvider.payments[1]['paymentMethod'], equals('card'));
      expect(billingProvider.isLoading, isFalse);

      verify(mockApiService.getPayments(page: 1, limit: 10)).called(1);
    });

    test('should create customer successfully', () async {
      // Arrange
      final customerData = {
        'email': 'newcustomer@example.com',
        'name': 'New Customer',
        'phone': '+2348012345678',
        'address': '123 Customer Street, Lagos, Nigeria',
        'businessType': 'INDIVIDUAL',
      };

      final mockResponse = {
        'success': true,
        'customer': {
          'id': 'cust_123',
          'email': 'newcustomer@example.com',
          'name': 'New Customer',
          'phone': '+2348012345678',
          'createdAt': '2024-01-01T00:00:00Z',
        },
      };

      when(mockApiService.createCustomer(customerData))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await billingProvider.createCustomer(customerData);

      // Assert
      expect(result['success'], isTrue);
      expect(result['customer']['id'], equals('cust_123'));
      expect(result['customer']['email'], equals('newcustomer@example.com'));
      expect(billingProvider.customers, hasLength(1));
      expect(billingProvider.customers[0]['id'], equals('cust_123'));

      verify(mockApiService.createCustomer(customerData)).called(1);
    });

    test('should load customers successfully', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'customers': [
          {
            'id': 'cust_1',
            'email': 'customer1@example.com',
            'name': 'Customer One',
            'phone': '+2348012345678',
            'totalInvoiced': '50000.00',
            'totalPaid': '50000.00',
            'outstandingBalance': '0.00',
          },
          {
            'id': 'cust_2',
            'email': 'customer2@example.com',
            'name': 'Customer Two',
            'phone': '+2348012345679',
            'totalInvoiced': '75000.00',
            'totalPaid': '25000.00',
            'outstandingBalance': '50000.00',
          },
        ],
      };

      when(mockApiService.getCustomers())
          .thenAnswer((_) async => mockResponse);

      // Act
      await billingProvider.loadCustomers();

      // Assert
      expect(billingProvider.customers, hasLength(2));
      expect(billingProvider.customers[0]['name'], equals('Customer One'));
      expect(billingProvider.customers[1]['outstandingBalance'], equals('50000.00'));
      expect(billingProvider.isLoading, isFalse);

      verify(mockApiService.getCustomers()).called(1);
    });

    test('should get customer payment history', () async {
      // Arrange
      final customerEmail = 'customer@example.com';
      final mockResponse = {
        'success': true,
        'payments': [
          {
            'id': 'pay_1',
            'amount': '25000.00',
            'currency': 'NGN',
            'status': 'completed',
            'paymentDate': '2024-01-01T00:00:00Z',
          },
          {
            'id': 'pay_2',
            'amount': '15000.00',
            'currency': 'NGN',
            'status': 'pending',
            'paymentDate': '2024-01-02T00:00:00Z',
          },
        ],
      };

      when(mockApiService.getCustomerPaymentHistory(customerEmail))
          .thenAnswer((_) async => mockResponse);

      // Act
      final history = await billingProvider.getCustomerPaymentHistory(customerEmail);

      // Assert
      expect(history['payments'], hasLength(2));
      expect(history['payments'][0]['amount'], equals('25000.00'));
      expect(history['payments'][1]['status'], equals('pending'));

      verify(mockApiService.getCustomerPaymentHistory(customerEmail)).called(1);
    });

    test('should calculate customer outstanding balance', () async {
      // Arrange
      final customerEmail = 'customer@example.com';
      final mockResponse = {
        'success': true,
        'outstandingBalance': '50000.00',
        'totalInvoiced': '100000.00',
        'totalPaid': '50000.00',
      };

      when(mockApiService.getCustomerBalance(customerEmail))
          .thenAnswer((_) async => mockResponse);

      // Act
      final balance = await billingProvider.getCustomerBalance(customerEmail);

      // Assert
      expect(balance['outstandingBalance'], equals('50000.00'));
      expect(balance['totalInvoiced'], equals('100000.00'));
      expect(balance['totalPaid'], equals('50000.00'));

      verify(mockApiService.getCustomerBalance(customerEmail)).called(1);
    });

    test('should generate revenue report', () async {
      // Arrange
      final startDate = '2024-01-01';
      final endDate = '2024-01-31';
      final mockResponse = {
        'success': true,
        'summary': {
          'totalInvoiced': '300000.00',
          'totalPaid': '250000.00',
          'outstanding': '50000.00',
          'totalInvoices': 15,
          'paidInvoices': 12,
          'pendingInvoices': 3,
        },
        'breakdown': [
          {
            'period': '2024-01-01',
            'invoiced': '100000.00',
            'paid': '80000.00',
          },
          {
            'period': '2024-01-15',
            'invoiced': '200000.00',
            'paid': '170000.00',
          },
        ],
      };

      when(mockApiService.getRevenueReport(startDate, endDate))
          .thenAnswer((_) async => mockResponse);

      // Act
      final report = await billingProvider.generateRevenueReport(startDate, endDate);

      // Assert
      expect(report['summary']['totalInvoiced'], equals('300000.00'));
      expect(report['summary']['outstanding'], equals('50000.00'));
      expect(report['breakdown'], hasLength(2));

      verify(mockApiService.getRevenueReport(startDate, endDate)).called(1);
    });

    test('should validate invoice data', () {
      // Test valid invoice data
      final validInvoice = {
        'customerEmail': 'customer@example.com',
        'amount': '50000.00',
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Test Invoice',
      };

      expect(billingProvider.validateInvoiceData(validInvoice), isTrue);

      // Test invalid invoice data
      final invalidInvoice1 = {
        'customerEmail': '', // Missing email
        'amount': '50000.00',
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Test Invoice',
      };

      expect(billingProvider.validateInvoiceData(invalidInvoice1), isFalse);

      final invalidInvoice2 = {
        'customerEmail': 'customer@example.com',
        'amount': '-100', // Negative amount
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Test Invoice',
      };

      expect(billingProvider.validateInvoiceData(invalidInvoice2), isFalse);
    });

    test('should validate payment data', () {
      // Test valid payment data
      final validPayment = {
        'invoiceId': 'inv_123',
        'amount': '25000.00',
        'currency': 'NGN',
        'paymentMethod': 'bank_transfer',
        'reference': 'PAY_123456',
      };

      expect(billingProvider.validatePaymentData(validPayment), isTrue);

      // Test invalid payment data
      final invalidPayment = {
        'invoiceId': '', // Missing invoice ID
        'amount': '25000.00',
        'currency': 'NGN',
        'paymentMethod': 'bank_transfer',
        'reference': 'PAY_123456',
      };

      expect(billingProvider.validatePaymentData(invalidPayment), isFalse);
    });

    test('should calculate invoice statistics', () {
      // Arrange
      billingProvider.invoices = [
        {
          'id': 'inv_1',
          'amount': '50000.00',
          'status': 'paid',
          'currency': 'NGN',
        },
        {
          'id': 'inv_2',
          'amount': '75000.00',
          'status': 'pending',
          'currency': 'NGN',
        },
        {
          'id': 'inv_3',
          'amount': '25000.00',
          'status': 'paid',
          'currency': 'NGN',
        },
      ];

      // Act
      final stats = billingProvider.calculateInvoiceStats();

      // Assert
      expect(stats['totalInvoices'], equals(3));
      expect(stats['paidInvoices'], equals(2));
      expect(stats['pendingInvoices'], equals(1));
      expect(stats['totalAmount'], equals(150000.0));
      expect(stats['paidAmount'], equals(75000.0));
      expect(stats['pendingAmount'], equals(75000.0));
      expect(stats['paidPercentage'], equals(50.0)); // 75000/150000 * 100
    });

    test('should filter invoices by status', () {
      // Arrange
      billingProvider.invoices = [
        {'id': 'inv_1', 'status': 'paid'},
        {'id': 'inv_2', 'status': 'pending'},
        {'id': 'inv_3', 'status': 'paid'},
        {'id': 'inv_4', 'status': 'overdue'},
      ];

      // Act
      final paidInvoices = billingProvider.filterInvoicesByStatus('paid');
      final pendingInvoices = billingProvider.filterInvoicesByStatus('pending');

      // Assert
      expect(paidInvoices, hasLength(2));
      expect(pendingInvoices, hasLength(1));
      expect(paidInvoices.every((inv) => inv['status'] == 'paid'), isTrue);
    });

    test('should handle loading states correctly', () {
      // Test initial state
      expect(billingProvider.isLoading, isFalse);

      // Test loading state
      billingProvider.setLoading(true);
      expect(billingProvider.isLoading, isTrue);

      billingProvider.setLoading(false);
      expect(billingProvider.isLoading, isFalse);
    });

    test('should handle error states correctly', () {
      // Test initial state
      expect(billingProvider.error, isNull);

      // Test error setting
      billingProvider.setError('Test error message');
      expect(billingProvider.error, equals('Test error message'));

      // Test error clearing
      billingProvider.clearError();
      expect(billingProvider.error, isNull);
    });

    test('should refresh billing data', () async {
      // Arrange
      final mockInvoicesResponse = {
        'success': true,
        'invoices': [
          {
            'id': 'inv_new',
            'amount': '100000.00',
            'status': 'paid',
            'currency': 'NGN',
          },
        ],
      };

      final mockPaymentsResponse = {
        'success': true,
        'payments': [
          {
            'id': 'pay_new',
            'amount': '50000.00',
            'status': 'completed',
            'currency': 'NGN',
          },
        ],
      };

      when(mockApiService.getInvoices())
          .thenAnswer((_) async => mockInvoicesResponse);
      when(mockApiService.getPayments())
          .thenAnswer((_) async => mockPaymentsResponse);

      // Act
      await billingProvider.refreshBillingData();

      // Assert
      expect(billingProvider.invoices, hasLength(1));
      expect(billingProvider.payments, hasLength(1));
      expect(billingProvider.invoices[0]['id'], equals('inv_new'));
      expect(billingProvider.isLoading, isFalse);

      verify(mockApiService.getInvoices()).called(1);
      verify(mockApiService.getPayments()).called(1);
    });
  });
}
