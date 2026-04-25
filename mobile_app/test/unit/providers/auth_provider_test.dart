// mobile_app/test/unit/providers/auth_provider_test.dart
//
// Unit Tests for Authentication Provider
// Tests Nigerian business authentication flow, OTP handling, and session management
//

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/secure_storage_service.dart';

// Generate mocks
@GenerateMocks([ApiService, SecureStorageService])
import 'auth_provider_test.mocks.dart';

void main() {
  group('Auth Provider Tests', () {
    late AuthProvider authProvider;
    late MockApiService mockApiService;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockApiService = MockApiService();
      mockSecureStorage = MockSecureStorageService();
      authProvider = AuthProvider(
        apiService: mockApiService,
        secureStorage: mockSecureStorage,
      );
    });

    test('should initialize with unauthenticated state', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.error, isNull);
      expect(authProvider.otpSent, isFalse);
    });

    test('should send OTP successfully', () async {
      // Arrange
      final email = 'test@example.com';
      final mockResponse = {
        'success': true,
        'isNewUser': true,
        'message': 'OTP sent successfully',
      };

      when(mockApiService.sendOtp(email))
          .thenAnswer((_) async => mockResponse);

      // Act
      await authProvider.sendOtp(email);

      // Assert
      expect(authProvider.otpSent, isTrue);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.error, isNull);
      expect(authProvider.isNewUser, isTrue);

      verify(mockApiService.sendOtp(email)).called(1);
    });

    test('should handle OTP sending failure', () async {
      // Arrange
      final email = 'test@example.com';

      when(mockApiService.sendOtp(email))
          .thenThrow(Exception('Failed to send OTP'));

      // Act
      await authProvider.sendOtp(email);

      // Assert
      expect(authProvider.otpSent, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error!.contains('Failed to send OTP'), isTrue);
    });

    test('should verify OTP and authenticate user', () async {
      // Arrange
      final email = 'test@example.com';
      final otp = '123456';
      final mockResponse = {
        'success': true,
        'token': 'jwt_token_12345',
        'step': 'complete',
        'user': {
          'id': 'user_123',
          'email': email,
          'fullName': 'Test User',
          'accountType': 'INDIVIDUAL',
        },
      };

      when(mockApiService.verifyOtp(email, otp))
          .thenAnswer((_) async => mockResponse);
      when(mockSecureStorage.saveToken('jwt_token_12345'))
          .thenAnswer((_) async {});

      // Act
      await authProvider.verifyOtp(email, otp);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, equals(email));
      expect(authProvider.user!.fullName, equals('Test User'));
      expect(authProvider.user!.accountType, equals('INDIVIDUAL'));
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.error, isNull);

      verify(mockApiService.verifyOtp(email, otp)).called(1);
      verify(mockSecureStorage.saveToken('jwt_token_12345')).called(1);
    });

    test('should handle OTP verification failure', () async {
      // Arrange
      final email = 'test@example.com';
      final otp = '000000';

      when(mockApiService.verifyOtp(email, otp))
          .thenThrow(Exception('Invalid OTP'));

      // Act
      await authProvider.verifyOtp(email, otp);

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error!.contains('Invalid OTP'), isTrue);
    });

    test('should handle new user routing to business onboarding', () async {
      // Arrange
      final email = 'newuser@example.com';
      final otp = '123456';
      final mockResponse = {
        'success': true,
        'token': 'jwt_token_new',
        'step': 'setup_username',
        'isNewUser': true,
        'destination': '/auth/business-onboarding',
      };

      when(mockApiService.verifyOtp(email, otp))
          .thenAnswer((_) async => mockResponse);
      when(mockSecureStorage.saveToken('jwt_token_new'))
          .thenAnswer((_) async {});

      // Act
      await authProvider.verifyOtp(email, otp);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isNewUser, isTrue);
      expect(authProvider.destination, equals('/auth/business-onboarding'));
    });

    test('should handle existing user routing to dashboard', () async {
      // Arrange
      final email = 'existing@example.com';
      final otp = '123456';
      final mockResponse = {
        'success': true,
        'token': 'jwt_token_existing',
        'step': 'complete',
        'isNewUser': false,
        'destination': '/dashboard',
      };

      when(mockApiService.verifyOtp(email, otp))
          .thenAnswer((_) async => mockResponse);
      when(mockSecureStorage.saveToken('jwt_token_existing'))
          .thenAnswer((_) async {});

      // Act
      await authProvider.verifyOtp(email, otp);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isNewUser, isFalse);
      expect(authProvider.destination, equals('/dashboard'));
    });

    test('should logout successfully', () async {
      // Arrange - user is authenticated
      authProvider.user = {
        'id': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
      };
      authProvider._isAuthenticated = true;

      when(mockSecureStorage.deleteToken())
          .thenAnswer((_) async {});

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.otpSent, isFalse);

      verify(mockSecureStorage.deleteToken()).called(1);
    });

    test('should check authentication status on initialization', () async {
      // Arrange
      final token = 'stored_jwt_token';
      final mockUser = {
        'id': 'user_456',
        'email': 'stored@example.com',
        'fullName': 'Stored User',
        'accountType': 'REGISTERED_BUSINESS',
      };

      when(mockSecureStorage.getToken())
          .thenAnswer((_) async => token);
      when(mockApiService.validateToken(token))
          .thenAnswer((_) async => true);
      when(mockApiService.getCurrentUser())
          .thenAnswer((_) async => mockUser);

      // Act
      await authProvider.checkAuthStatus();

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, equals('stored@example.com'));
      expect(authProvider.user!.accountType, equals('REGISTERED_BUSINESS'));

      verify(mockSecureStorage.getToken()).called(1);
      verify(mockApiService.validateToken(token)).called(1);
      verify(mockApiService.getCurrentUser()).called(1);
    });

    test('should handle invalid token on initialization', () async {
      // Arrange
      when(mockSecureStorage.getToken())
          .thenAnswer((_) async => 'invalid_token');
      when(mockApiService.validateToken('invalid_token'))
          .thenAnswer((_) async => false);
      when(mockSecureStorage.deleteToken())
          .thenAnswer((_) async {});

      // Act
      await authProvider.checkAuthStatus();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);

      verify(mockSecureStorage.deleteToken()).called(1);
    });

    test('should validate email format', () {
      // Test valid emails
      expect(authProvider.isValidEmail('test@example.com'), isTrue);
      expect(authProvider.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(authProvider.isValidEmail('user+tag@example.org'), isTrue);

      // Test invalid emails
      expect(authProvider.isValidEmail(''), isFalse);
      expect(authProvider.isValidEmail('invalid'), isFalse);
      expect(authProvider.isValidEmail('@example.com'), isFalse);
      expect(authProvider.isValidEmail('user@'), isFalse);
      expect(authProvider.isValidEmail('user@example'), isFalse);
    });

    test('should validate OTP format', () {
      // Test valid OTPs
      expect(authProvider.isValidOtp('123456'), isTrue);
      expect(authProvider.isValidOtp('000000'), isTrue);
      expect(authProvider.isValidOtp('999999'), isTrue);

      // Test invalid OTPs
      expect(authProvider.isValidOtp(''), isFalse);
      expect(authProvider.isValidOtp('12345'), isFalse); // Too short
      expect(authProvider.isValidOtp('1234567'), isFalse); // Too long
      expect(authProvider.isValidOtp('abcdef'), isFalse); // Non-numeric
      expect(authProvider.isValidOtp('12 456'), isFalse); // Contains space
    });

    test('should handle session timeout', () async {
      // Arrange - user is authenticated
      authProvider.user = {
        'id': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
      };
      authProvider._isAuthenticated = true;

      when(mockSecureStorage.deleteToken())
          .thenAnswer((_) async {});

      // Act
      authProvider.handleSessionTimeout();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error!.contains('Session expired'), isTrue);
    });

    test('should refresh token successfully', () async {
      // Arrange
      final oldToken = 'old_jwt_token';
      final newToken = 'new_jwt_token';

      when(mockSecureStorage.getToken())
          .thenAnswer((_) async => oldToken);
      when(mockApiService.refreshToken(oldToken))
          .thenAnswer((_) async => newToken);
      when(mockSecureStorage.saveToken(newToken))
          .thenAnswer((_) async {});

      // Act
      final result = await authProvider.refreshToken();

      // Assert
      expect(result, isTrue);

      verify(mockSecureStorage.getToken()).called(1);
      verify(mockApiService.refreshToken(oldToken)).called(1);
      verify(mockSecureStorage.saveToken(newToken)).called(1);
    });

    test('should handle token refresh failure', () async {
      // Arrange
      final oldToken = 'expired_jwt_token';

      when(mockSecureStorage.getToken())
          .thenAnswer((_) async => oldToken);
      when(mockApiService.refreshToken(oldToken))
          .thenThrow(Exception('Token expired'));
      when(mockSecureStorage.deleteToken())
          .thenAnswer((_) async {});

      // Act
      final result = await authProvider.refreshToken();

      // Assert
      expect(result, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);

      verify(mockSecureStorage.deleteToken()).called(1);
    });

    test('should handle biometric authentication', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'token': 'biometric_jwt_token',
        'user': {
          'id': 'user_789',
          'email': 'biometric@example.com',
          'fullName': 'Biometric User',
        },
      };

      when(mockApiService.authenticateWithBiometric())
          .thenAnswer((_) async => mockResponse);
      when(mockSecureStorage.saveToken('biometric_jwt_token'))
          .thenAnswer((_) async {});

      // Act
      await authProvider.authenticateWithBiometric();

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, equals('biometric@example.com'));

      verify(mockApiService.authenticateWithBiometric()).called(1);
      verify(mockSecureStorage.saveToken('biometric_jwt_token')).called(1);
    });

    test('should handle biometric authentication failure', () async {
      // Arrange
      when(mockApiService.authenticateWithBiometric())
          .thenThrow(Exception('Biometric authentication failed'));

      // Act
      await authProvider.authenticateWithBiometric();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.error, isNotNull);
      expect(authProvider.error!.contains('Biometric authentication failed'), isTrue);
    });

    test('should clear error state', () {
      // Arrange
      authProvider.setError('Test error message');
      expect(authProvider.error, isNotNull);

      // Act
      authProvider.clearError();

      // Assert
      expect(authProvider.error, isNull);
    });

    test('should handle loading states correctly', () {
      // Test initial state
      expect(authProvider.isLoading, isFalse);

      // Test loading state
      authProvider.setLoading(true);
      expect(authProvider.isLoading, isTrue);

      authProvider.setLoading(false);
      expect(authProvider.isLoading, isFalse);
    });

    test('should update user profile', () async {
      // Arrange - user is authenticated
      authProvider.user = {
        'id': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
      };
      authProvider._isAuthenticated = true;

      final updatedProfile = {
        'fullName': 'Updated Name',
        'phone': '+2348012345678',
        'businessName': 'Updated Business',
      };

      final mockResponse = {
        'success': true,
        'user': {
          'id': 'user_123',
          'email': 'test@example.com',
          'fullName': 'Updated Name',
          'phone': '+2348012345678',
          'businessName': 'Updated Business',
        },
      };

      when(mockApiService.updateUserProfile(updatedProfile))
          .thenAnswer((_) async => mockResponse);

      // Act
      await authProvider.updateProfile(updatedProfile);

      // Assert
      expect(authProvider.user!.fullName, equals('Updated Name'));
      expect(authProvider.user!.phone, equals('+2348012345678'));
      expect(authProvider.user!.businessName, equals('Updated Business'));

      verify(mockApiService.updateUserProfile(updatedProfile)).called(1);
    });
  });
}
