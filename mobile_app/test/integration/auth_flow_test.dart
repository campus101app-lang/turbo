// mobile_app/test/integration/auth_flow_test.dart
//
// Integration Tests for Authentication Flow
// Tests complete Nigerian business onboarding flow from email to dashboard
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart' as app;
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/wallet_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/secure_storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([ApiService, SecureStorageService])
import 'auth_flow_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockApiService mockApiService;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockApiService = MockApiService();
      mockSecureStorage = MockSecureStorageService();
    });

    testWidgets('complete new user onboarding flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on onboarding screen
      expect(find.text('Welcome to DayFi'), findsOneWidget);
      expect(find.text('Your Business Financial Command Center'), findsOneWidget);

      // Step 1: Navigate to email screen
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify email screen
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Step 2: Enter email and continue
      await tester.enterText(find.byType(TextFormField), 'newuser@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Verify OTP screen appears
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Step 4: Enter OTP and verify
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Step 5: Verify business onboarding screen appears
      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Account Type'), findsOneWidget);

      // Step 6: Select account type
      await tester.tap(find.text('Registered Business'));
      await tester.pumpAndSettle();

      // Step 7: Fill business information
      await tester.enterText(find.byKey(const Key('fullNameField')), 'Test Business Owner');
      await tester.enterText(find.byKey(const Key('businessNameField')), 'Test Business Ltd');
      await tester.enterText(find.byKey(const Key('phoneField')), '+2348012345678');
      await tester.enterText(find.byKey(const Key('bvnField')), '12345678901');
      await tester.enterText(find.byKey(const Key('businessAddressField')), '123 Business Street, Lagos');
      await tester.enterText(find.byKey(const Key('cacField')), 'RC123456789');
      await tester.enterText(find.byKey(const Key('tinField')), 'TIN123456789');
      await tester.pumpAndSettle();

      // Step 8: Accept terms and conditions
      await tester.tap(find.byKey(const Key('termsCheckbox')));
      await tester.pumpAndSettle();

      // Step 9: Submit business profile
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      // Step 10: Verify biometric screen appears
      expect(find.text('Enable Biometric Authentication'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Step 11: Skip biometric setup
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Step 12: Verify backup screen appears
      expect(find.text('Backup Your Wallet'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Step 13: Skip backup setup
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Step 14: Verify main shell/dashboard appears
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('existing user login flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to email screen
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Enter existing user email
      await tester.enterText(find.byType(TextFormField), 'existing@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter OTP
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Should go directly to main shell (skip onboarding)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('invalid OTP handling', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to OTP screen
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter invalid OTP
      await tester.enterText(find.byType(TextFormField), '000000');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Invalid verification code'), findsOneWidget);
    });

    testWidgets('email validation', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to email screen
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'valid@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should proceed to OTP screen
      expect(find.text('Enter Verification Code'), findsOneWidget);
    });

    testWidgets('BVN validation', (WidgetTester tester) async {
      // Launch app and navigate to business onboarding
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Business'));
      await tester.pumpAndSettle();

      // Enter invalid BVN (less than 11 digits)
      await tester.enterText(find.byKey(const Key('bvnField')), '123456789');
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('BVN must be 11 digits'), findsOneWidget);

      // Enter valid BVN
      await tester.enterText(find.byKey(const Key('bvnField')), '12345678901');
      await tester.pumpAndSettle();

      // Error should disappear
      expect(find.text('BVN must be 11 digits'), findsNothing);
    });

    testWidgets('phone number validation', (WidgetTester tester) async {
      // Launch app and navigate to business onboarding
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Business'));
      await tester.pumpAndSettle();

      // Enter invalid phone number
      await tester.enterText(find.byKey(const Key('phoneField')), '08012345678');
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Please enter a valid Nigerian phone number'), findsOneWidget);

      // Enter valid phone number
      await tester.enterText(find.byKey(const Key('phoneField')), '+2348012345678');
      await tester.pumpAndSettle();

      // Error should disappear
      expect(find.text('Please enter a valid Nigerian phone number'), findsNothing);
    });

    testWidgets('terms and conditions requirement', (WidgetTester tester) async {
      // Launch app and navigate to business onboarding
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registered Business'));
      await tester.pumpAndSettle();

      // Fill required fields but don't accept terms
      await tester.enterText(find.byKey(const Key('fullNameField')), 'Test User');
      await tester.enterText(find.byKey(const Key('businessNameField')), 'Test Business');
      await tester.enterText(find.byKey(const Key('phoneField')), '+2348012345678');
      await tester.enterText(find.byKey(const Key('bvnField')), '12345678901');
      await tester.pumpAndSettle();

      // Try to submit without accepting terms
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('You must accept the terms and conditions'), findsOneWidget);

      // Accept terms and submit
      await tester.tap(find.byKey(const Key('termsCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      // Should proceed to biometric screen
      expect(find.text('Enable Biometric Authentication'), findsOneWidget);
    });

    testWidgets('account type selection flow', (WidgetTester tester) async {
      // Launch app and navigate to business onboarding
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Test Individual account type
      await tester.tap(find.text('Individual'));
      await tester.pumpAndSettle();

      // Should show simplified form for Individual
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.byKey(const Key('businessNameField')), findsNothing);
      expect(find.byKey(const Key('cacField')), findsNothing);
      expect(find.byKey(const Key('tinField')), findsNothing);

      // Go back and test Other Entity
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other Entity'));
      await tester.pumpAndSettle();

      // Should show different form for Other Entity
      expect(find.text('Entity Information'), findsOneWidget);
      expect(find.byKey(const Key('businessNameField')), findsOneWidget);
      expect(find.byKey(const Key('cacField')), findsNothing); // Not required for Other Entity
    });

    testWidgets('session persistence', (WidgetTester tester) async {
      // Complete full onboarding flow
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'persist@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Individual'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fullNameField')), 'Persistent User');
      await tester.enterText(find.byKey(const Key('phoneField')), '+2348012345678');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('termsCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now')); // Skip biometric
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now')); // Skip backup
      await tester.pumpAndSettle();

      // Verify we're in main app
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Restart app
      app.main();
      await tester.pumpAndSettle();

      // Should go directly to main app (skip onboarding)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('logout functionality', (WidgetTester tester) async {
      // Complete onboarding and login
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'logout@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Individual'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fullNameField')), 'Logout User');
      await tester.enterText(find.byKey(const Key('phoneField')), '+2348012345678');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('termsCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Navigate to settings and logout
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Logout'),
        500,
      );
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout
      await tester.tap(find.text('Yes, Logout'));
      await tester.pumpAndSettle();

      // Should return to onboarding screen
      expect(find.text('Welcome to DayFi'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('network error handling', (WidgetTester tester) async {
      // This test would require mocking network failures
      // For now, we'll test the UI behavior when network is unavailable

      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Enter email and try to continue (simulate network error)
      await tester.enterText(find.byType(TextFormField), 'network@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // In a real implementation, this would show a network error dialog
      // For now, we'll verify the loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('form field accessibility', (WidgetTester tester) async {
      // Test that form fields have proper accessibility labels
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Check email field accessibility
      final emailField = find.byType(TextFormField);
      expect(emailField, findsOneWidget);
      
      final emailSemantics = tester.semantics(find.byType(TextFormField));
      expect(emailSemantics, includesSemantics('Email address field'));
    });

    testWidgets('back navigation', (WidgetTester tester) async {
      // Test back button functionality throughout the flow
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Test back button on email screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to DayFi'), findsOneWidget);

      // Navigate forward again
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'back@example.com');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Test back button on OTP screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
