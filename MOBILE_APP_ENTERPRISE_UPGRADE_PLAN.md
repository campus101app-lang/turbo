# DayFi Mobile App Enterprise Upgrade Plan
## Transform to Production-Grade Business Financial Command Center

---

## Executive Summary

**Current State**: Good foundation with basic functionality  
**Target State**: Enterprise-grade mobile app with premium UI/UX, comprehensive testing, and business intelligence  
**Timeline**: 4-6 weeks  
**Priority**: HIGH - Critical for beta launch success

---

## Phase 1: Mobile App Testing Framework (Week 1)

### 1.1 Comprehensive Testing Infrastructure

#### Flutter Testing Setup
```yaml
# mobile_app/pubspec.yaml - Add testing dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  golden_toolkit: ^0.15.0
  network_image_mock: ^2.1.1
  fake_cloud_firestore: ^2.4.2
```

#### Test Structure
```
mobile_app/test/
├── unit/
│   ├── providers/
│   │   ├── wallet_provider_test.dart
│   │   ├── auth_provider_test.dart
│   │   └── billing_provider_test.dart
│   ├── services/
│   │   ├── api_service_test.dart
│   │   └── encryption_service_test.dart
│   └── widgets/
│       ├── balance_card_test.dart
│       └── transaction_item_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   ├── billing_flow_test.dart
│   ├── shop_flow_test.dart
│   └── organization_flow_test.dart
├── widget/
│   ├── home_screen_test.dart
│   ├── billing_screen_test.dart
│   └── shop_screen_test.dart
└── performance/
    ├── app_startup_test.dart
    └── tab_switching_test.dart
```

### 1.2 Critical Test Implementation

#### Authentication Flow Tests
```dart
// mobile_app/test/integration/auth_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    testWidgets('complete new user onboarding flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Verify welcome screen
      expect(find.text('Welcome to DayFi'), findsOneWidget);
      
      // Enter email
      await tester.enterText(find.byKey(Key('email-field')), 'test@business.com');
      await tester.tap(find.byKey(Key('continue-button')));
      await tester.pumpAndSettle();

      // Verify OTP screen
      expect(find.text('Enter verification code'), findsOneWidget);
      
      // Enter OTP
      await tester.enterText(find.byKey(Key('otp-field')), '123456');
      await tester.tap(find.byKey(Key('verify-button')));
      await tester.pumpAndSettle();

      // Verify business onboarding
      expect(find.text('Business Information'), findsOneWidget);
      
      // Fill business details
      await tester.enterText(find.byKey(Key('business-name')), 'Test Business');
      await tester.tap(find.byKey(Key('business-type-dropdown')));
      await tester.tap(find.text('REGISTERED_BUSINESS'));
      await tester.enterText(find.byKey(Key('bvn-field')), '12345678901');
      await tester.tap(find.byKey(Key('complete-onboarding')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.textContaining('USDC Balance'), findsOneWidget);
    });

    testWidgets('existing user login flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter existing user email
      await tester.enterText(find.byKey(Key('email-field')), 'existing@business.com');
      await tester.tap(find.byKey(Key('continue-button')));
      await tester.pumpAndSettle();

      // Enter OTP
      await tester.enterText(find.byKey(Key('otp-field')), '123456');
      await tester.tap(find.byKey(Key('verify-button')));
      await tester.pumpAndSettle();

      // Should go directly to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

#### Billing Tab Tests
```dart
// mobile_app/test/integration/billing_flow_test.dart
group('Billing Tab Tests', () {
  testWidgets('complete invoice lifecycle', (WidgetTester tester) async {
    await loginAndNavigateToBilling(tester);

    // Create new invoice
    await tester.tap(find.byKey(Key('create-invoice-button')));
    await tester.pumpAndSettle();

    // Fill invoice details
    await tester.enterText(find.byKey(Key('customer-email')), 'customer@example.com');
    await tester.enterText(find.byKey(Key('invoice-amount')), '1000');
    await tester.tap(find.byKey(Key('currency-dropdown')));
    await tester.tap(find.text('USDC'));
    await tester.enterText(find.byKey(Key('invoice-description')), 'Professional Services');
    await tester.tap(find.byKey(Key('create-invoice')));
    await tester.pumpAndSettle();

    // Verify invoice created
    expect(find.text('Invoice Created Successfully'), findsOneWidget);
    expect(find.textContaining('INV-'), findsOneWidget);

    // Send invoice
    await tester.tap(find.byKey(Key('send-invoice')));
    await tester.pumpAndSettle();

    // Verify sent status
    expect(find.text('Sent'), findsOneWidget);
  });

  testWidgets('payment request processing', (WidgetTester tester) async {
    await loginAndNavigateToBilling(tester);

    // Switch to requests tab
    await tester.tap(find.text('Payment Requests'));
    await tester.pumpAndSettle();

    // Create payment request
    await tester.tap(find.byKey(Key('create-request-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('request-amount')), '500');
    await tester.enterText(find.byKey(Key('request-description')), 'Project payment');
    await tester.tap(find.byKey(Key('create-request')));
    await tester.pumpAndSettle();

    // Verify request created
    expect(find.text('Payment Request Created'), findsOneWidget);
    
    // Share request
    await tester.tap(find.byKey(Key('share-request')));
    await tester.pumpAndSettle();

    // Verify share options
    expect(find.text('Share Payment Request'), findsOneWidget);
  });
});
```

#### Shop Tab Tests
```dart
// mobile_app/test/integration/shop_flow_test.dart
group('Shop Tab Tests', () {
  testWidgets('complete product management flow', (WidgetTester tester) async {
    await loginAndNavigateToShop(tester);

    // Add new product
    await tester.tap(find.byKey(Key('add-product-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('product-name')), 'Premium Widget');
    await tester.enterText(find.byKey(Key('product-price')), '150');
    await tester.enterText(find.byKey(Key('product-stock')), '50');
    await tester.enterText(find.byKey(Key('product-category')), 'Electronics');
    await tester.tap(find.byKey(Key('save-product')));
    await tester.pumpAndSettle();

    // Verify product added
    expect(find.text('Product Added Successfully'), findsOneWidget);
    expect(find.text('Premium Widget'), findsOneWidget);

    // Edit product
    await tester.tap(find.byKey(Key('edit-product-0')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('product-price')), '175');
    await tester.tap(find.byKey(Key('save-product')));
    await tester.pumpAndSettle();

    // Verify price updated
    expect(find.text('\$175.00'), findsOneWidget);

    // Manage inventory
    await tester.tap(find.byKey(Key('inventory-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('increment-stock-0')));
    await tester.pumpAndSettle();

    // Verify stock updated
    expect(find.text('51 units'), findsOneWidget);
  });

  testWidgets('customer checkout flow', (WidgetTester tester) async {
    await loginAndNavigateToShop(tester);

    // View products
    expect(find.byType(ProductCard), findsWidgets);

    // Add to cart
    await tester.tap(find.byKey(Key('add-to-cart-0')));
    await tester.pumpAndSettle();

    // View cart
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();

    // Verify cart contents
    expect(find.text('Shopping Cart'), findsOneWidget);
    expect(find.textContaining('1 item'), findsOneWidget);

    // Checkout
    await tester.tap(find.byKey(Key('checkout-button')));
    await tester.pumpAndSettle();

    // Select payment method
    await tester.tap(find.byKey(Key('payment-method-stellar')));
    await tester.pumpAndSettle();

    // Confirm order
    await tester.tap(find.byKey(Key('confirm-order')));
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify order completion
    expect(find.text('Order Completed Successfully'), findsOneWidget);
    expect(find.textContaining('Order #'), findsOneWidget);
  });
});
```

### 1.3 Performance Testing
```dart
// mobile_app/test/performance/app_startup_test.dart
void main() {
  group('App Performance Tests', () {
    testWidgets('app startup time under 3 seconds', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should load within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('tab switching under 500ms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final tabs = ['Billing', 'Shop', 'Organization', 'Transactions', 'Home'];

      for (final tab in tabs) {
        final stopwatch = Stopwatch()..start();
        
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Each tab switch should be under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      }
    });

    testWidgets('large data handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      // Verify performance with 1000+ transactions
      final stopwatch = Stopwatch()..start();
      
      // Scroll through entire list
      await tester.fling(find.byType(ListView), Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Should handle large lists smoothly
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
```

---

## Phase 2: Enterprise UI/UX Upgrade (Week 2-3)

### 2.1 Design System Enhancement

#### Premium Theme System
```dart
// mobile_app/lib/theme/enterprise_theme.dart
class EnterpriseTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E40AF), // Premium blue
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
      ),
      // ... dark theme configuration
    );
  }
}
```

### 2.2 Enhanced Screen Components

#### Premium Home Dashboard
```dart
// mobile_app/lib/screens/home/enterprise_home_screen.dart
class EnterpriseHomeScreen extends ConsumerStatefulWidget {
  const EnterpriseHomeScreen({super.key});

  @override
  ConsumerState<EnterpriseHomeScreen> createState() => _EnterpriseHomeScreenState();
}

class _EnterpriseHomeScreenState extends ConsumerState<EnterpriseHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Business Dashboard'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: _buildQuickStats(),
              ),
            ),
          ),
          
          // Business Overview Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOverviewCard(index),
                childCount: 4,
              ),
            ),
          ),
          
          // Recent Activity
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildRecentActivity(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final walletState = ref.watch(walletProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              title: 'USDC Balance',
              value: '\$${walletState.usdcBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              title: 'NGNT Balance',
              value: '₦${(walletState.ngntBalance * (walletState.ngnRate ?? 1350)).toStringAsFixed(0)}',
              icon: Icons.currency_exchange,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(int index) {
    final cards = [
      {'title': 'Revenue', 'value': '\$12,450', 'change': '+12%', 'icon': Icons.trending_up},
      {'title': 'Expenses', 'value': '\$8,230', 'change': '+5%', 'icon': Icons.trending_down},
      {'title': 'Transactions', 'value': '147', 'change': '+18%', 'icon': Icons.receipt_long},
      {'title': 'Active Users', 'value': '23', 'change': '+8%', 'icon': Icons.people},
    ];

    final card = cards[index];
    final isPositive = card['change']!.toString().startsWith('+');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card['icon'] as IconData, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card['change'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPositive ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              card['title'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card['value'] as String,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _ActivityTile(
                icon: Icons.arrow_downward,
                title: 'Payment Received',
                subtitle: 'From customer@example.com',
                amount: '+\$500.00',
                color: Colors.green,
              ),
              const Divider(height: 1),
              _ActivityTile(
                icon: Icons.arrow_upward,
                title: 'Payment Sent',
                subtitle: 'To supplier@vendor.com',
                amount: '-\$250.00',
                color: Colors.red,
              ),
              const Divider(height: 1),
              _ActivityTile(
                icon: Icons.receipt_long,
                title: 'Invoice Created',
                subtitle: 'INV-2024-001',
                amount: '\$1,000.00',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
```

#### Enhanced Billing Screen
```dart
// mobile_app/lib/screens/billing/enterprise_billing_screen.dart
class EnterpriseBillingScreen extends ConsumerStatefulWidget {
  const EnterpriseBillingScreen({super.key});

  @override
  ConsumerState<EnterpriseBillingScreen> createState() => _EnterpriseBillingScreenState();
}

class _EnterpriseBillingScreenState extends ConsumerState<EnterpriseBillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Payment Requests'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showBillingAnalytics(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoicesTab(),
          _buildPaymentRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Invoiced',
                  value: '\$45,230',
                  change: '+12%',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Outstanding',
                  value: '\$12,450',
                  change: '-5%',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        
        // Invoice List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            itemBuilder: (context, index) => _InvoiceCard(
              invoice: _mockInvoices[index],
              onTap: () => _viewInvoice(_mockInvoices[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRequestsTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Requested',
                  value: '\$8,450',
                  change: '+8%',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Pending',
                  value: '\$3,200',
                  change: '+15%',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        
        // Payment Request List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            itemBuilder: (context, index) => _PaymentRequestCard(
              request: _mockPaymentRequests[index],
              onTap: () => _viewPaymentRequest(_mockPaymentRequests[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _InvoiceCard({required Invoice invoice, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(invoice.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    invoice.amount,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                invoice.customerName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                invoice.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'INV-${invoice.number.toString().padLeft(6, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Phase 3: Business Intelligence Integration (Week 3-4)

### 3.1 Analytics Dashboard
```dart
// mobile_app/lib/screens/analytics/business_intelligence_screen.dart
class BusinessIntelligenceScreen extends ConsumerStatefulWidget {
  const BusinessIntelligenceScreen({super.key});

  @override
  ConsumerState<BusinessIntelligenceScreen> createState() => _BusinessIntelligenceScreenState();
}

class _BusinessIntelligenceScreenState extends ConsumerState<BusinessIntelligenceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Overview
            _buildKPIOverview(),
            const SizedBox(height: 24),
            
            // Revenue Chart
            _buildRevenueChart(),
            const SizedBox(height: 24),
            
            // Expense Breakdown
            _buildExpenseBreakdown(),
            const SizedBox(height: 24),
            
            // Business Insights
            _buildBusinessInsights(),
            const SizedBox(height: 24),
            
            // Performance Metrics
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Performance Indicators',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _KPICard(
                  title: 'Total Revenue',
                  value: '\$45,230',
                  change: '+12.5%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _KPICard(
                  title: 'Total Expenses',
                  value: '\$28,450',
                  change: '+5.2%',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
                _KPICard(
                  title: 'Net Profit',
                  value: '\$16,780',
                  change: '+23.8%',
                  icon: Icons.account_balance,
                  color: Colors.blue,
                ),
                _KPICard(
                  title: 'Profit Margin',
                  value: '37.1%',
                  change: '+8.3%',
                  icon: Icons.percent,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 30),
                        FlSpot(1, 35),
                        FlSpot(2, 32),
                        FlSpot(3, 38),
                        FlSpot(4, 42),
                        FlSpot(5, 45),
                        FlSpot(6, 48),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titles: _buildChartTitles(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ..._insights.map((insight) => _InsightCard(insight: insight)),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Phase 4: Performance & Security Enhancements (Week 4-5)

### 4.1 Performance Optimization
```dart
// mobile_app/lib/services/performance_service.dart
class PerformanceService {
  static void initialize() {
    // Enable performance monitoring
    FlutterError.onError = (FlutterErrorDetails details) {
      // Report to crashlytics
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Monitor app lifecycle
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  static Future<void> optimizeAppStartup() async {
    // Preload critical data
    await Future.wait([
      _preloadUserPreferences(),
      _preloadCachedData(),
      _preloadThemeData(),
    ]);
  }

  static Future<void> _preloadUserPreferences() async {
    // Preload user settings
    await ref.read(settingsProvider.future);
  }

  static Future<void> _preloadCachedData() async {
    // Preload cached financial data
    await ref.read(walletProvider.future);
  }

  static Future<void> _preloadThemeData() async {
    // Preload theme configuration
    await ref.read(themeProvider.future);
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Refresh data when app resumes
        _refreshCriticalData();
        break;
      case AppLifecycleState.paused:
        // Save current state
        _saveCurrentState();
        break;
      default:
        break;
    }
  }

  void _refreshCriticalData() {
    // Refresh wallet data
    ref.read(walletProvider.notifier).refresh();
  }

  void _saveCurrentState() {
    // Save current app state
    // Implementation for state persistence
  }
}
```

### 4.2 Security Enhancements
```dart
// mobile_app/lib/services/security_service.dart
class SecurityService {
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();
      
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) return false;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to access your financial data',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  static Future<void> secureStorage() async {
    // Initialize secure storage
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );

    // Store sensitive data securely
    await storage.write(key: 'auth_token', value: 'encrypted_token');
    await storage.write(key: 'user_credentials', value: 'encrypted_credentials');
  }

  static Future<void> enableAppProtection() async {
    // Enable app protection features
    await Future.wait([
      _enableScreenSecurity(),
      _enableRootDetection(),
      _enableTamperDetection(),
    ]);
  }

  static Future<void> _enableScreenSecurity() async {
    // Prevent screenshots in sensitive screens
    FlutterWindow.instance.addPostFrameCallback((_) {
      // Implementation for screen security
    });
  }

  static Future<void> _enableRootDetection() async {
    // Detect if device is rooted
    final bool isRooted = await TrustDevice.isRooted;
    if (isRooted) {
      // Handle rooted device
      _handleRootedDevice();
    }
  }

  static Future<void> _enableTamperDetection() async {
    // Detect app tampering
    final bool isTampered = await TrustDevice.isAppTampered;
    if (isTampered) {
      // Handle tampered app
      _handleTamperedApp();
    }
  }

  static void _handleRootedDevice() {
    // Take appropriate action for rooted devices
    throw SecurityException('Device is rooted - access denied');
  }

  static void _handleTamperedApp() {
    // Take appropriate action for tampered apps
    throw SecurityException('App integrity compromised - access denied');
  }
}
```

---

## Phase 5: Deployment & CI/CD (Week 5-6)

### 5.1 Build Configuration
```yaml
# mobile_app/.github/workflows/build.yml
name: Build and Test Mobile App

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run unit tests
      run: flutter test --coverage
      
    - name: Run integration tests
      run: flutter test integration_test/
      
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Build APK
      run: flutter build apk --release
      
    - name: Build iOS
      run: flutter build ios --release
      
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-artifacts
        path: build/
```

### 5.2 Release Management
```dart
// mobile_app/lib/services/update_service.dart
class UpdateService {
  static Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Check latest version from API
      final latestVersion = await _getLatestVersion();
      
      if (_isNewerVersion(currentVersion, latestVersion)) {
        _showUpdateDialog(latestVersion);
      }
    } catch (e) {
      // Handle error
    }
  }

  static Future<String> _getLatestVersion() async {
    final response = await http.get(
      Uri.parse('https://api.dayfi.me/version/latest'),
    );
    
    final data = jsonDecode(response.body);
    return data['version'];
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    return false;
  }

  static void _showUpdateDialog(String latestVersion) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('Version $latestVersion is available. Update now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => _openAppStore(),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static void _openAppStore() {
    // Open app store for update
    launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.dayfi.app'));
  }
}
```

---

## Implementation Timeline

| Week | Focus | Deliverables |
|------|-------|-------------|
| 1 | Testing Framework | Unit tests, Integration tests, Performance tests |
| 2-3 | UI/UX Upgrade | Premium theme, Enhanced screens, Better navigation |
| 3-4 | Business Intelligence | Analytics dashboard, KPI tracking, Insights |
| 4-5 | Performance & Security | Optimization, Security enhancements |
| 5-6 | Deployment | CI/CD pipeline, Release management |

---

## Success Metrics

### Quality Metrics
- **Test Coverage**: >85% unit, >75% integration
- **Performance**: <3s startup, <500ms tab switching
- **Crash Rate**: <0.1%
- **User Satisfaction**: >4.5/5 rating

### Business Metrics
- **User Engagement**: +30% session duration
- **Feature Adoption**: +50% BI dashboard usage
- **Transaction Volume**: +25% with improved UX
- **Support Tickets**: -40% with better UI

---

## Next Steps

1. **Immediate**: Start with testing framework implementation
2. **Week 1**: Set up comprehensive test suite
3. **Week 2**: Begin UI/UX enhancements
4. **Week 3**: Implement business intelligence features
5. **Week 4**: Optimize performance and security
6. **Week 5**: Set up deployment pipeline
7. **Week 6**: Beta launch preparation

This comprehensive upgrade plan transforms the mobile app into an enterprise-grade business financial command center ready for beta launch and production deployment.
