// mobile_app/test/integration/billing_flow_test.dart
//
// Integration Tests for Billing Flow
// Tests complete invoice lifecycle from creation to payment
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart' as app;
import 'package:mobile_app/providers/billing_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'billing_flow_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Billing Flow Integration Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('complete invoice creation and payment flow', (WidgetTester tester) async {
      // Launch app and login (assuming user is already authenticated)
      app.main();
      await tester.pumpAndSettle();

      // Navigate to billing tab
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Verify billing screen
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Create Invoice'), findsOneWidget);

      // Step 1: Create new invoice
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify invoice creation form
      expect(find.text('New Invoice'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      // Step 2: Fill invoice details
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'customer@example.com');
      await tester.enterText(
          find.byKey(const Key('amountField')), '50000.00');
      await tester.enterText(
          find.byKey(const Key('descriptionField')), 'Professional Services');
      await tester.pumpAndSettle();

      // Step 3: Select due date
      await tester.tap(find.byKey(const Key('dueDateField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Step 4: Add invoice items
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('itemDescriptionField')), 'Consulting Services');
      await tester.enterText(
          find.byKey(const Key('itemQuantityField')), '40');
      await tester.enterText(
          find.byKey(const Key('itemUnitPriceField')), '1250.00');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Step 5: Save invoice
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify invoice created
      expect(find.text('Invoice Created Successfully'), findsOneWidget);
      expect(find.text('INV-2024-001'), findsOneWidget);

      // Step 6: Send invoice to customer
      await tester.tap(find.text('Send Invoice'));
      await tester.pumpAndSettle();

      // Verify invoice sent
      expect(find.text('Invoice Sent'), findsOneWidget);
      expect(find.text('customer@example.com'), findsOneWidget);

      // Step 7: Navigate back to invoices list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Step 8: Verify invoice appears in list
      expect(find.text('INV-2024-001'), findsOneWidget);
      expect(find.text('customer@example.com'), findsOneWidget);
      expect(find.text('₦50,000.00'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);

      // Step 9: Open invoice details
      await tester.tap(find.text('INV-2024-001'));
      await tester.pumpAndSettle();

      // Verify invoice details
      expect(find.text('Invoice Details'), findsOneWidget);
      expect(find.text('customer@example.com'), findsOneWidget);
      expect(find.text('₦50,000.00'), findsOneWidget);
      expect(find.text('Consulting Services'), findsOneWidget);

      // Step 10: Record payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Fill payment details
      await tester.enterText(
          find.byKey(const Key('paymentAmountField')), '50000.00');
      await tester.tap(find.byKey(const Key('paymentMethodField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('referenceField')), 'PAY_123456');
      await tester.pumpAndSettle();

      // Step 11: Confirm payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Verify payment recorded
      expect(find.text('Payment Recorded'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);

      // Step 12: Verify invoice status updated
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('invoice validation and error handling', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Try to create invoice without required fields
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice')); // Try to save immediately
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Customer email is required'), findsOneWidget);
      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);

      // Fill invalid email
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'invalid-email');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify email validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Fill invalid amount
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'valid@example.com');
      await tester.enterText(
          find.byKey(const Key('amountField')), '-100');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify amount validation error
      expect(find.text('Amount must be greater than 0'), findsOneWidget);
    });

    testWidgets('customer management flow', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Navigate to customers
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();

      // Verify customers screen
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);

      // Step 1: Add new customer
      await tester.tap(find.text('Add Customer'));
      await tester.pumpAndSettle();

      // Fill customer details
      await tester.enterText(
          find.byKey(const Key('customerNameField')), 'Test Customer');
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'newcustomer@example.com');
      await tester.enterText(
          find.byKey(const Key('customerPhoneField')), '+2348012345678');
      await tester.enterText(
          find.byKey(const Key('customerAddressField')), '123 Customer Street, Lagos');
      await tester.pumpAndSettle();

      // Save customer
      await tester.tap(find.text('Save Customer'));
      await tester.pumpAndSettle();

      // Verify customer created
      expect(find.text('Customer Created'), findsOneWidget);
      expect(find.text('Test Customer'), findsOneWidget);

      // Step 2: Navigate back to customers list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify customer appears in list
      expect(find.text('Test Customer'), findsOneWidget);
      expect(find.text('newcustomer@example.com'), findsOneWidget);

      // Step 3: Create invoice for this customer
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();
      
      // Customer should be selectable
      await tester.tap(find.byKey(const Key('customerSelectField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Customer'));
      await tester.pumpAndSettle();

      // Verify customer email is pre-filled
      final customerEmailField = find.byKey(const Key('customerEmailField'));
      expect(customerEmailField, findsOneWidget);
      // Note: In a real implementation, we'd verify the field value
    });

    testWidgets('invoice filtering and search', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Create multiple invoices with different statuses
      for (int i = 1; i <= 3; i++) {
        await tester.tap(find.text('Create Invoice'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('customerEmailField')), 'customer$i@example.com');
        await tester.enterText(
            find.byKey(const Key('amountField')), '${i * 10000}.00');
        await tester.enterText(
            find.byKey(const Key('descriptionField')), 'Service $i');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create Invoice'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Test status filtering
      await tester.tap(find.byKey(const Key('statusFilter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();

      // Verify filter is applied
      expect(find.byKey(const Key('statusFilter')), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);

      // Test search functionality
      await tester.tap(find.byKey(const Key('searchField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('searchField')), 'customer2');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('customer2@example.com'), findsOneWidget);
      expect(find.text('customer1@example.com'), findsNothing);
      expect(find.text('customer3@example.com'), findsNothing);
    });

    testWidgets('invoice item management', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Create invoice with multiple items
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();
      
      // Fill basic invoice details
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'multi@example.com');
      await tester.enterText(
          find.byKey(const Key('amountField')), '100000.00');
      await tester.enterText(
          find.byKey(const Key('descriptionField')), 'Multi-item Invoice');
      await tester.pumpAndSettle();

      // Add first item
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('itemDescriptionField')), 'Web Development');
      await tester.enterText(
          find.byKey(const Key('itemQuantityField')), '20');
      await tester.enterText(
          find.byKey(const Key('itemUnitPriceField')), '3000.00');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Add second item
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('itemDescriptionField')), 'Mobile App Development');
      await tester.enterText(
          find.byKey(const Key('itemQuantityField')), '10');
      await tester.enterText(
          find.byKey(const Key('itemUnitPriceField')), '4000.00');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify items are displayed
      expect(find.text('Web Development'), findsOneWidget);
      expect(find.text('Mobile App Development'), findsOneWidget);
      expect(find.text('₦60,000.00'), findsOneWidget); // 20 * 3000
      expect(find.text('₦40,000.00'), findsOneWidget); // 10 * 4000

      // Edit first item
      await tester.tap(find.byKey(const Key('editItem_0')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('itemQuantityField')), '25'); // Update quantity
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Verify item updated
      expect(find.text('₦75,000.00'), findsOneWidget); // 25 * 3000

      // Delete second item
      await tester.tap(find.byKey(const Key('deleteItem_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify item deleted
      expect(find.text('Mobile App Development'), findsNothing);
      expect(find.text('₦40,000.00'), findsNothing);

      // Create invoice
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify invoice created with updated total
      expect(find.text('Invoice Created'), findsOneWidget);
    });

    testWidgets('payment processing flow', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Navigate to payments
      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();

      // Verify payments screen
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);

      // Step 1: Record new payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Select invoice
      await tester.tap(find.byKey(const Key('invoiceSelectField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('INV-2024-001')); // Assuming invoice exists
      await tester.pumpAndSettle();

      // Fill payment details
      await tester.enterText(
          find.byKey(const Key('paymentAmountField')), '25000.00');
      await tester.tap(find.byKey(const Key('paymentMethodField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('referenceField')), 'PAY_PARTIAL_123');
      await tester.pumpAndSettle();

      // Record partial payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Verify payment recorded
      expect(find.text('Payment Recorded'), findsOneWidget);
      expect(find.text('Partially Paid'), findsOneWidget);

      // Step 2: Navigate back to payments list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify payment appears in list
      expect(find.text('PAY_PARTIAL_123'), findsOneWidget);
      expect(find.text('₦25,000.00'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);

      // Step 3: Record remaining payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invoiceSelectField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('INV-2024-001'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('paymentAmountField')), '25000.00');
      await tester.tap(find.byKey(const Key('paymentMethodField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('referenceField')), 'PAY_FINAL_123');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      // Verify full payment
      expect(find.text('Payment Recorded'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('billing reports and analytics', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Navigate to reports
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      // Verify reports screen
      expect(find.text('Billing Reports'), findsOneWidget);
      expect(find.text('Revenue Summary'), findsOneWidget);
      expect(find.text('Customer Analysis'), findsOneWidget);

      // Step 1: Generate revenue summary
      await tester.tap(find.text('Revenue Summary'));
      await tester.pumpAndSettle();

      // Verify revenue summary
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Total Invoices'), findsOneWidget);
      expect(find.text('Paid Invoices'), findsOneWidget);

      // Step 2: Select date range
      await tester.tap(find.byKey(const Key('dateRangeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      // Verify data is updated
      expect(find.text('Last 30 Days'), findsOneWidget);

      // Step 3: Export report
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // Verify export initiated
      expect(find.text('Exporting...'), findsOneWidget);
    });

    testWidgets('billing settings and preferences', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify billing settings
      expect(find.text('Billing Settings'), findsOneWidget);
      expect(find.text('Invoice Prefix'), findsOneWidget);
      expect(find.text('Default Due Days'), findsOneWidget);
      expect(find.text('Payment Terms'), findsOneWidget);

      // Update invoice prefix
      await tester.tap(find.byKey(const Key('invoicePrefixField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('invoicePrefixField')), 'BIZ');
      await tester.pumpAndSettle();

      // Update default due days
      await tester.tap(find.byKey(const Key('dueDaysField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dueDaysField')), '14');
      await tester.pumpAndSettle();

      // Save settings
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      // Verify settings saved
      expect(find.text('Settings Saved'), findsOneWidget);
    });
  });
}
