// mobile_app/test/unit/services/api_service_test.dart
//
// Unit Tests for API Service
// Tests HTTP requests, error handling, and response parsing
//

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app/services/api_service.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  group('API Service Tests', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService(dio: mockDio);
    });

    test('should initialize with correct base URL', () {
      expect(apiService.baseUrl, equals('https://api.dayfi.me'));
    });

    test('should send OTP successfully', () async {
      // Arrange
      final email = 'test@example.com';
      final mockResponse = Response(
        data: {
          'success': true,
          'isNewUser': true,
          'message': 'OTP sent successfully',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/send-otp'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.sendOtp(email);

      // Assert
      expect(result['success'], isTrue);
      expect(result['isNewUser'], isTrue);
      expect(result['message'], equals('OTP sent successfully'));

      verify(mockDio.post(
        '/api/auth/send-otp',
        data: {'email': email},
      )).called(1);
    });

    test('should handle OTP sending failure', () async {
      // Arrange
      final email = 'test@example.com';
      final mockError = DioException(
        requestOptions: RequestOptions(path: '/api/auth/send-otp'),
        error: DioErrorType.response,
        response: Response(
          data: {'error': 'Failed to send OTP'},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/api/auth/send-otp'),
        ),
      );

      when(mockDio.post(any, data: any))
          .thenThrow(mockError);

      // Act
      expect(() => apiService.sendOtp(email), throwsException);
    });

    test('should verify OTP successfully', () async {
      // Arrange
      final email = 'test@example.com';
      final otp = '123456';
      final mockResponse = Response(
        data: {
          'success': true,
          'token': 'jwt_token_123',
          'step': 'complete',
          'user': {
            'id': 'user_123',
            'email': email,
            'fullName': 'Test User',
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/verify-otp'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.verifyOtp(email, otp);

      // Assert
      expect(result['success'], isTrue);
      expect(result['token'], equals('jwt_token_123'));
      expect(result['step'], equals('complete'));
      expect(result['user']['email'], equals(email));

      verify(mockDio.post(
        '/api/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      )).called(1);
    });

    test('should create invoice successfully', () async {
      // Arrange
      final invoiceData = {
        'customerEmail': 'customer@example.com',
        'amount': '50000.00',
        'currency': 'NGN',
        'dueDate': '2024-01-15T00:00:00Z',
        'description': 'Test Invoice',
        'organizationId': 'org_123',
      };

      final mockResponse = Response(
        data: {
          'success': true,
          'invoice': {
            'id': 'inv_123',
            'invoiceNumber': 'INV-2024-001',
            'customerEmail': 'customer@example.com',
            'amount': '50000.00',
            'status': 'draft',
          },
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: '/api/invoices'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.createInvoice(invoiceData);

      // Assert
      expect(result['success'], isTrue);
      expect(result['invoice']['id'], equals('inv_123'));
      expect(result['invoice']['status'], equals('draft'));

      verify(mockDio.post(
        '/api/invoices',
        data: invoiceData,
      )).called(1);
    });

    test('should get invoices with pagination', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'success': true,
          'invoices': [
            {
              'id': 'inv_1',
              'invoiceNumber': 'INV-2024-001',
              'amount': '50000.00',
              'status': 'paid',
            },
            {
              'id': 'inv_2',
              'invoiceNumber': 'INV-2024-002',
              'amount': '75000.00',
              'status': 'pending',
            },
          ],
          'pagination': {
            'page': 1,
            'limit': 10,
            'total': 2,
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/invoices'),
      );

      when(mockDio.get(any, queryParameters: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.getInvoices(page: 1, limit: 10);

      // Assert
      expect(result['success'], isTrue);
      expect(result['invoices'], hasLength(2));
      expect(result['pagination']['page'], equals(1));
      expect(result['pagination']['total'], equals(2));

      verify(mockDio.get(
        '/api/invoices',
        queryParameters: {'page': 1, 'limit': 10},
      )).called(1);
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

      final mockResponse = Response(
        data: {
          'success': true,
          'payment': {
            'id': 'pay_123',
            'invoiceId': 'inv_123',
            'amount': '50000.00',
            'status': 'pending',
            'reference': 'PAY_123456',
          },
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: '/api/payments'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.createPayment(paymentData);

      // Assert
      expect(result['success'], isTrue);
      expect(result['payment']['id'], equals('pay_123'));
      expect(result['payment']['status'], equals('pending'));

      verify(mockDio.post(
        '/api/payments',
        data: paymentData,
      )).called(1);
    });

    test('should get balances successfully', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'success': true,
          'balances': [
            {'asset': 'XLM', 'balance': '1000.0000000'},
            {'asset': 'USDC', 'balance': '500.0000000'},
            {'asset': 'NGNT', 'balance': '100000.0000000'},
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/balances'),
      );

      when(mockDio.get(any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.getBalances();

      // Assert
      expect(result['success'], isTrue);
      expect(result['balances'], hasLength(3));
      expect(result['balances'][0]['asset'], equals('XLM'));
      expect(result['balances'][0]['balance'], equals('1000.0000000'));

      verify(mockDio.get('/api/balances')).called(1);
    });

    test('should handle network timeout', () async {
      // Arrange
      final mockError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.connectTimeout,
        message: 'Connection timeout',
      );

      when(mockDio.get(any))
          .thenThrow(mockError);

      // Act & Assert
      expect(() => apiService.getInvoices(), throwsException);
    });

    test('should handle server error', () async {
      // Arrange
      final mockError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.response,
        response: Response(
          data: {'error': 'Internal server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/api/invoices'),
        ),
      );

      when(mockDio.get(any))
          .thenThrow(mockError);

      // Act & Assert
      expect(() => apiService.getInvoices(), throwsException);
    });

    test('should validate token successfully', () async {
      // Arrange
      final token = 'valid_jwt_token';
      final mockResponse = Response(
        data: {'valid': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/validate'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.validateToken(token);

      // Assert
      expect(result, isTrue);

      verify(mockDio.post(
        '/api/auth/validate',
        data: {'token': token},
      )).called(1);
    });

    test('should handle invalid token', () async {
      // Arrange
      final token = 'invalid_jwt_token';
      final mockResponse = Response(
        data: {'valid': false},
        statusCode: 401,
        requestOptions: RequestOptions(path: '/api/auth/validate'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.validateToken(token);

      // Assert
      expect(result, isFalse);

      verify(mockDio.post(
        '/api/auth/validate',
        data: {'token': token},
      )).called(1);
    });

    test('should refresh token successfully', () async {
      // Arrange
      final oldToken = 'old_jwt_token';
      final newToken = 'new_jwt_token';
      final mockResponse = Response(
        data: {'token': newToken},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.refreshToken(oldToken);

      // Assert
      expect(result, equals(newToken));

      verify(mockDio.post(
        '/api/auth/refresh',
        data: {'token': oldToken},
      )).called(1);
    });

    test('should parse error messages correctly', () {
      // Test DioException with response data
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.response,
        response: Response(
          data: {'error': 'Validation failed', 'details': 'Invalid email format'},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/api/invoices'),
        ),
      );

      final errorMessage = apiService.parseError(dioError);
      expect(errorMessage, equals('Validation failed: Invalid email format'));

      // Test DioException without response data
      final networkError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.connectTimeout,
        message: 'Connection timeout',
      );

      final networkErrorMessage = apiService.parseError(networkError);
      expect(networkErrorMessage, equals('Connection timeout'));

      // Test generic Exception
      final genericError = Exception('Generic error');
      final genericErrorMessage = apiService.parseError(genericError);
      expect(genericErrorMessage, equals('Generic error'));
    });

    test('should handle request with headers', () async {
      // Arrange
      final token = 'jwt_token_123';
      final mockResponse = Response(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/user/profile'),
      );

      when(mockDio.get(any, options: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      await apiService.getUserProfile(token);

      // Assert
      verify(mockDio.get(
        '/api/user/profile',
        options: anyThat(
          predicate: (options) =>
              options.headers['Authorization'] == 'Bearer $token',
        ),
      )).called(1);
    });

    test('should handle file upload', () async {
      // Arrange
      final filePath = '/path/to/file.pdf';
      final mockResponse = Response(
        data: {
          'success': true,
          'fileUrl': 'https://example.com/files/file.pdf',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/upload'),
      );

      when(mockDio.post(any, data: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.uploadFile(filePath);

      // Assert
      expect(result['success'], isTrue);
      expect(result['fileUrl'], equals('https://example.com/files/file.pdf'));

      verify(mockDio.post(
        '/api/upload',
        data: anyThat(
          predicate: (data) => data is FormData,
        ),
      )).called(1);
    });

    test('should handle query parameters correctly', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'success': true,
          'data': [],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/reports'),
      );

      when(mockDio.get(any, queryParameters: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      await apiService.getReports(
        startDate: '2024-01-01',
        endDate: '2024-01-31',
        type: 'revenue',
      );

      // Assert
      verify(mockDio.get(
        '/api/reports',
        queryParameters: anyThat(
          predicate: (query) =>
              query['startDate'] == '2024-01-01' &&
              query['endDate'] == '2024-01-31' &&
              query['type'] == 'revenue',
        ),
      )).called(1);
    });

    test('should handle retry logic', () async {
      // Arrange
      final mockError1 = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.connectTimeout,
        message: 'Connection timeout',
      );

      final mockResponse = Response(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/invoices'),
      );

      when(mockDio.get(any))
          .thenThrow(mockError1)
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiService.getInvoices();

      // Assert
      expect(result['success'], isTrue);
      verify(mockDio.get('/api/invoices')).called(2); // First fails, second succeeds
    });

    test('should handle request timeout', () async {
      // Arrange
      apiService.setConnectionTimeout(5000); // 5 seconds
      final mockError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices'),
        error: DioErrorType.receiveTimeout,
        message: 'Receive timeout',
      );

      when(mockDio.get(any))
          .thenThrow(mockError);

      // Act & Assert
      expect(() => apiService.getInvoices(), throwsException);
    });

    test('should handle concurrent requests', () async {
      // Arrange
      final mockResponse = Response(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/invoices'),
      );

      when(mockDio.get(any))
          .thenAnswer((_) async => mockResponse);

      // Act
      final futures = [
        apiService.getInvoices(),
        apiService.getInvoices(),
        apiService.getInvoices(),
      ];

      final results = await Future.wait(futures);

      // Assert
      expect(results, hasLength(3));
      for (final result in results) {
        expect(result['success'], isTrue);
      }

      verify(mockDio.get('/api/invoices')).called(3);
    });

    test('should handle request cancellation', () async {
      // Arrange
      final cancelToken = CancelToken();
      final mockError = DioException(
        requestOptions: RequestOptions(path: '/api/invoices', cancelToken: cancelToken),
        error: DioErrorType.cancel,
        message: 'Request cancelled',
      );

      when(mockDio.get(any, cancelToken: any))
          .thenThrow(mockError);

      // Act
      cancelToken.cancel('User cancelled');
      expect(() => apiService.getInvoices(cancelToken: cancelToken), throwsException);
    });

    test('should handle response caching', () async {
      // Arrange
      final mockResponse = Response(
        data: {'success': true, 'cached': false},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/invoices'),
      );

      when(mockDio.get(any, options: any))
          .thenAnswer((_) async => mockResponse);

      // Act
      await apiService.getInvoices(enableCache: true);

      // Assert
      verify(mockDio.get(
        '/api/invoices',
        options: anyThat(
          predicate: (options) =>
              options.extra?['enableCache'] == true,
        ),
      )).called(1);
    });
  });
}
