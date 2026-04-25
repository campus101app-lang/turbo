// mobile_app/test/integration/organization_flow_test.dart
//
// Integration Tests for Organization Flow
// Tests complete multi-tenant team collaboration and workflow management
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart' as app;
import 'package:mobile_app/providers/organization_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'organization_flow_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Organization Flow Integration Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('complete organization setup and team management flow', (WidgetTester tester) async {
      // Launch app and navigate to organization
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      // Verify organization screen
      expect(find.text('Organization'), findsOneWidget);
      expect(find.text('Create Organization'), findsOneWidget);

      // Step 1: Create new organization
      await tester.tap(find.text('Create Organization'));
      await tester.pumpAndSettle();

      // Fill organization details
      await tester.enterText(
          find.byKey(const Key('organizationNameField')), 'Test Business Ltd');
      await tester.enterText(
          find.byKey(const Key('organizationDescriptionField')), 'Technology services company');
      await tester.tap(find.byKey(const Key('businessTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limited Liability'));
      await tester.pumpAndSettle();

      // Set organization settings
      await tester.tap(find.byKey(const Key('requireInvoiceApproval')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('requireExpenseApproval')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('maxInvoiceAmountField')), '1000000');
      await tester.enterText(
          find.byKey(const Key('maxExpenseAmountField')), '500000');
      await tester.pumpAndSettle();

      // Create organization
      await tester.tap(find.text('Create Organization'));
      await tester.pumpAndSettle();

      // Verify organization created
      expect(find.text('Organization Created'), findsOneWidget);
      expect(find.text('Test Business Ltd'), findsOneWidget);

      // Step 2: Navigate to team management
      await tester.tap(find.text('Team'));
      await tester.pumpAndSettle();

      // Verify team management screen
      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Invite Member'), findsOneWidget);
      expect(find.text('Roles & Permissions'), findsOneWidget);

      // Step 3: Invite team member
      await tester.tap(find.text('Invite Member'));
      await tester.pumpAndSettle();

      // Fill invitation details
      await tester.enterText(
          find.byKey(const Key('memberEmailField')), 'admin@test.com');
      await tester.tap(find.byKey(const Key('memberRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('invitationMessageField')), 'Join our team as administrator');
      await tester.pumpAndSettle();

      // Send invitation
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Verify invitation sent
      expect(find.text('Invitation Sent'), findsOneWidget);
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Step 4: Invite more team members
      await tester.tap(find.text('Invite Member'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('memberEmailField')), 'manager@test.com');
      await tester.tap(find.byKey(const Key('memberRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invite Member'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('memberEmailField')), 'staff@test.com');
      await tester.tap(find.byKey(const Key('memberRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      // Step 5: Accept invitations (simulate)
      await tester.tap(find.text('Team'));
      await tester.pumpAndSettle();
      
      // Verify team members
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('manager@test.com'), findsOneWidget);
      expect(find.text('staff@test.com'), findsOneWidget);

      // Step 6: Test role-based permissions
      await tester.tap(find.text('Roles & Permissions'));
      await tester.pumpAndSettle();

      // Verify roles
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);

      // View Admin permissions
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Manage Invoices'), findsOneWidget);
      expect(find.text('Manage Expenses'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);
      expect(find.text('Manage Members'), findsOneWidget);

      // View Manager permissions
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager'));
      await tester.pumpAndSettle();
      expect(find.text('Create Invoices'), findsOneWidget);
      expect(find.text('Create Expenses'), findsOneWidget);
      expect(find.text('View Team Reports'), findsOneWidget);
      expect(find.text('Manage Members'), findsNothing); // Not available for Manager

      // View Staff permissions
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      expect(find.text('View Own Data'), findsOneWidget);
      expect(find.text('Create Expenses'), findsOneWidget);
      expect(find.text('View Team Reports'), findsNothing); // Not available for Staff
    });

    testWidgets('workflow management and approval process', (WidgetTester tester) async {
      // Launch app and navigate to organization
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      // Navigate to workflows
      await tester.tap(find.text('Workflows'));
      await tester.pumpAndSettle();

      // Verify workflows screen
      expect(find.text('Workflows'), findsOneWidget);
      expect(find.text('Create Workflow'), findsOneWidget);

      // Step 1: Create invoice approval workflow
      await tester.tap(find.text('Create Workflow'));
      await tester.pumpAndSettle();

      // Fill workflow details
      await tester.enterText(
          find.byKey(const Key('workflowNameField')), 'Invoice Approval Workflow');
      await tester.enterText(
          find.byKey(const Key('workflowDescriptionField')), 'Multi-level approval for high-value invoices');
      await tester.tap(find.byKey(const Key('workflowTriggerField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invoice Created'));
      await tester.pumpAndSettle();

      // Set conditions
      await tester.tap(find.byKey(const Key('addCondition')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conditionField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amount'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conditionOperator')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Greater Than'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('conditionValueField')), '100000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();

      // Add approval steps
      await tester.tap(find.text('Add Step'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approval'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('stepTimeoutField')), '72');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Step'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Step'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approval'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('stepTimeoutField')), '48');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Step'));
      await tester.pumpAndSettle();

      // Create workflow
      await tester.tap(find.text('Create Workflow'));
      await tester.pumpAndSettle();

      // Verify workflow created
      expect(find.text('Workflow Created'), findsOneWidget);
      expect(find.text('Invoice Approval Workflow'), findsOneWidget);

      // Step 2: Test workflow trigger
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Create high-value invoice to trigger workflow
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'client@example.com');
      await tester.enterText(
          find.byKey(const Key('amountField')), '150000'); // Above 100000 threshold
      await tester.enterText(
          find.byKey(const Key('descriptionField')), 'Enterprise Software License');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify workflow triggered
      expect(find.text('Workflow Triggered'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Invoice Approval Workflow'), findsOneWidget);

      // Step 3: Process workflow approvals
      await tester.tap(find.text('View Workflow'));
      await tester.pumpAndSettle();

      // Verify workflow steps
      expect(find.text('Step 1: Manager Approval'), findsOneWidget);
      expect(find.text('Step 2: Admin Approval'), findsOneWidget);

      // Manager approval
      await tester.tap(find.text('Approve (Manager)'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('approvalCommentsField')), 'Approved for enterprise client');
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      // Verify first step completed
      expect(find.text('Manager Approved'), findsOneWidget);
      expect(find.text('Step 2: Admin Approval'), findsOneWidget);

      // Admin approval
      await tester.tap(find.text('Approve (Admin)'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('approvalCommentsField')), 'Final approval confirmed');
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      // Verify workflow completed
      expect(find.text('Workflow Completed'), findsOneWidget);
      expect(find.text('All Steps Approved'), findsOneWidget);
      expect(find.text('Invoice Sent'), findsOneWidget);
    });

    testWidgets('team collaboration and permissions testing', (WidgetTester tester) async {
      // Launch app and navigate to organization
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      // Navigate to team
      await tester.tap(find.text('Team'));
      await tester.pumpAndSettle();

      // Test Admin role capabilities
      await tester.tap(find.text('admin@test.com'));
      await tester.pumpAndSettle();

      // Admin can manage team members
      expect(find.text('Change Role'), findsOneWidget);
      expect(find.text('Remove Member'), findsOneWidget);
      expect(find.text('View Permissions'), findsOneWidget);

      // Test Manager role capabilities
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('manager@test.com'));
      await tester.pumpAndSettle();

      // Manager has limited capabilities
      expect(find.text('Change Role'), findsNothing); // Cannot change roles
      expect(find.text('Remove Member'), findsNothing); // Cannot remove members
      expect(find.text('View Permissions'), findsOneWidget);

      // Test Staff role capabilities
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('staff@test.com'));
      await tester.pumpAndSettle();

      // Staff has minimal capabilities
      expect(find.text('Change Role'), findsNothing);
      expect(find.text('Remove Member'), findsNothing);
      expect(find.text('View Permissions'), findsOneWidget);

      // Test role change (as Admin)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('admin@test.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newRoleField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Senior Admin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Role'));
      await tester.pumpAndSettle();

      // Verify role updated
      expect(find.text('Senior Admin'), findsOneWidget);
    });

    testWidgets('organization analytics and reporting', (WidgetTester tester) async {
      // Launch app and navigate to organization
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      // Navigate to analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Verify analytics dashboard
      expect(find.text('Organization Analytics'), findsOneWidget);
      expect(find.text('Team Overview'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
      expect(find.text('Financial Summary'), findsOneWidget);

      // View team overview
      expect(find.text('Total Members'), findsOneWidget);
      expect(find.text('Active Users'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      // Select date range
      await tester.tap(find.byKey(const Key('dateRangeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      // View performance metrics
      await tester.tap(find.text('Performance Metrics'));
      await tester.pumpAndSettle();

      // Verify metrics
      expect(find.text('Invoices Created'), findsOneWidget);
      expect(find.text('Expenses Submitted'), findsOneWidget);
      expect(find.text('Approvals Processed'), findsOneWidget);
      expect(find.text('Average Response Time'), findsOneWidget);

      // View financial summary
      await tester.tap(find.text('Financial Summary'));
      await tester.pumpAndSettle();

      // Verify financial data
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('Net Profit'), findsOneWidget);
      expect(find.text('Profit Margin'), findsOneWidget);

      // Generate team performance report
      await tester.tap(find.text('Generate Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team Performance Report'));
      await tester.pumpAndSettle();

      // Export report
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // Verify export initiated
      expect(find.text('Exporting...'), findsOneWidget);
    });

    testWidgets('organization settings and configuration', (WidgetTester tester) async {
      // Launch app and navigate to organization
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify settings screen
      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Approval Settings'), findsOneWidget);
      expect(find.text('Security Settings'), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);

      // Update approval settings
      await tester.tap(find.text('Approval Settings'));
      await tester.pumpAndSettle();

      // Modify invoice approval settings
      await tester.tap(find.byKey(const Key('requireInvoiceApproval')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('maxInvoiceAmountField')), '2000000');
      await tester.pumpAndSettle();

      // Modify expense approval settings
      await tester.tap(find.byKey(const Key('requireExpenseApproval')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('maxExpenseAmountField')), '750000');
      await tester.pumpAndSettle();

      // Save settings
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      // Verify settings saved
      expect(find.text('Settings Saved'), findsOneWidget);

      // Update security settings
      await tester.tap(find.text('Security Settings'));
      await tester.pumpAndSettle();

      // Enable two-factor authentication
      await tester.tap(find.byKey(const Key('enableTwoFactor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sessionTimeoutField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sessionTimeoutField')), '30');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      // Verify security settings saved
      expect(find.text('Security Settings Updated'), findsOneWidget);

      // Update notification settings
      await tester.tap(find.text('Notification Settings'));
      await tester.pumpAndSettle();

      // Configure email notifications
      await tester.tap(find.byKey(const Key('emailNotifications')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('approvalNotifications')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('paymentNotifications')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      // Verify notification settings saved
      expect(find.text('Notification Settings Updated'), findsOneWidget);
    });

    testWidgets('cross-tab integration with organization workflows', (WidgetTester tester) async {
      // Launch app and navigate to billing
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Create invoice that requires approval
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'client@example.com');
      await tester.enterText(
          find.byKey(const Key('amountField')), '500000'); // High amount
      await tester.enterText(
          find.byKey(const Key('descriptionField')), 'Enterprise Services');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify workflow triggered
      expect(find.text('Pending Approval'), findsOneWidget);

      // Navigate to organization to approve
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workflows'));
      await tester.pumpAndSettle();

      // Approve invoice
      await tester.tap(find.text('Pending Approvals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('approvalCommentsField')), 'Approved for processing');
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      // Navigate back to billing to verify
      await tester.tap(find.text('Billing'));
      await tester.pumpAndSettle();

      // Verify invoice approved
      expect(find.text('Approved'), findsOneWidget);

      // Test expense workflow integration
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Expense'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('expenseAmountField')), '300000');
      await tester.enterText(
          find.byKey(const Key('expenseCategoryField')), 'Office Rent');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Expense'));
      await tester.pumpAndSettle();

      // Verify expense workflow triggered
      expect(find.text('Pending Approval'), findsOneWidget);

      // Navigate to organization to approve
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workflows'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending Approvals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('approvalCommentsField')), 'Monthly rent approved');
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      // Navigate back to expenses to verify
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      // Verify expense approved
      expect(find.text('Approved'), findsOneWidget);
    });
  });
}
