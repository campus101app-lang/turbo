// mobile_app/test/integration/shop_flow_test.dart
//
// Integration Tests for Shop Flow
// Tests complete e-commerce flow from product creation to order fulfillment
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/main.dart' as app;
import 'package:mobile_app/providers/shop_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'shop_flow_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shop Flow Integration Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('complete product to order flow', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Verify shop screen
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);

      // Step 1: Create new product
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();

      // Verify product creation form
      expect(find.text('New Product'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      // Step 2: Fill product details
      await tester.enterText(
          find.byKey(const Key('productNameField')), 'Premium Laptop');
      await tester.enterText(
          find.byKey(const Key('productDescriptionField')), 'High-performance laptop for professionals');
      await tester.enterText(
          find.byKey(const Key('productSkuField')), 'LAPTOP-001');
      await tester.enterText(
          find.byKey(const Key('productPriceField')), '250000.00');
      await tester.pumpAndSettle();

      // Step 3: Select category
      await tester.tap(find.byKey(const Key('productCategoryField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      // Step 4: Set inventory
      await tester.enterText(
          find.byKey(const Key('inventoryQuantityField')), '50');
      await tester.enterText(
          find.byKey(const Key('reorderLevelField')), '10');
      await tester.pumpAndSettle();

      // Step 5: Add product images
      await tester.tap(find.text('Add Images'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Step 6: Save product
      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      // Verify product created
      expect(find.text('Product Created Successfully'), findsOneWidget);
      expect(find.text('Premium Laptop'), findsOneWidget);

      // Step 7: Navigate back to products list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Step 8: Verify product appears in list
      expect(find.text('Premium Laptop'), findsOneWidget);
      expect(find.text('₦250,000.00'), findsOneWidget);
      expect(find.text('In Stock: 50'), findsOneWidget);

      // Step 9: View product details
      await tester.tap(find.text('Premium Laptop'));
      await tester.pumpAndSettle();

      // Verify product details
      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('High-performance laptop for professionals'), findsOneWidget);
      expect(find.text('₦250,000.00'), findsOneWidget);
      expect(find.text('SKU: LAPTOP-001'), findsOneWidget);
      expect(find.text('In Stock: 50'), findsOneWidget);

      // Step 10: Create order for this product
      await tester.tap(find.text('Create Order'));
      await tester.pumpAndSettle();

      // Fill order details
      await tester.enterText(
          find.byKey(const Key('customerEmailField')), 'shopper@example.com');
      await tester.enterText(
          find.byKey(const Key('customerNameField')), 'Test Shopper');
      await tester.pumpAndSettle();

      // Set quantity
      await tester.enterText(
          find.byKey(const Key('quantityField')), '2');
      await tester.pumpAndSettle();

      // Add shipping address
      await tester.enterText(
          find.byKey(const Key('shippingStreetField')), '123 Shopper Street');
      await tester.enterText(
          find.byKey(const Key('shippingCityField')), 'Lagos');
      await tester.enterText(
          find.byKey(const Key('shippingStateField')), 'Lagos');
      await tester.enterText(
          find.byKey(const Key('shippingPostalCodeField')), '100001');
      await tester.pumpAndSettle();

      // Select payment method
      await tester.tap(find.byKey(const Key('paymentMethodField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();

      // Step 11: Create order
      await tester.tap(find.text('Create Order'));
      await tester.pumpAndSettle();

      // Verify order created
      expect(find.text('Order Created'), findsOneWidget);
      expect(find.text('Order #ORD-2024-001'), findsOneWidget);
      expect(find.text('₦500,000.00'), findsOneWidget); // 2 * 250000

      // Step 12: Navigate to orders
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Verify order appears
      expect(find.text('ORD-2024-001'), findsOneWidget);
      expect(find.text('shopper@example.com'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Step 13: Process order
      await tester.tap(find.text('ORD-2024-001'));
      await tester.pumpAndSettle();

      // Confirm order
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Verify order confirmed
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      // Step 14: Update inventory
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium Laptop'));
      await tester.pumpAndSettle();

      // Verify inventory updated
      expect(find.text('In Stock: 48'), findsOneWidget); // 50 - 2
    });

    testWidgets('product variants management', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Create product with variants
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
          find.byKey(const Key('productNameField')), 'T-Shirt');
      await tester.enterText(
          find.byKey(const Key('productDescriptionField')), 'Comfortable cotton t-shirt');
      await tester.enterText(
          find.byKey(const Key('productSkuField')), 'TSHIRT-001');
      await tester.enterText(
          find.byKey(const Key('productPriceField')), '5000.00');
      await tester.pumpAndSettle();

      // Enable variants
      await tester.tap(find.byKey(const Key('enableVariants')));
      await tester.pumpAndSettle();

      // Add size variant
      await tester.tap(find.text('Add Variant'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('variantNameField')), 'T-Shirt - Small');
      await tester.enterText(
          find.byKey(const Key('variantSkuField')), 'TSHIRT-S-RED');
      await tester.enterText(
          find.byKey(const Key('variantPriceField')), '5000.00');
      await tester.tap(find.byKey(const Key('variantSizeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('variantColorField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Red'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('variantQuantityField')), '20');
      await tester.tap(find.text('Add Variant'));
      await tester.pumpAndSettle();

      // Add second variant
      await tester.tap(find.text('Add Variant'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('variantNameField')), 'T-Shirt - Medium');
      await tester.enterText(
          find.byKey(const Key('variantSkuField')), 'TSHIRT-M-BLU');
      await tester.enterText(
          find.byKey(const Key('variantPriceField')), '5000.00');
      await tester.tap(find.byKey(const Key('variantSizeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('variantColorField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('variantQuantityField')), '15');
      await tester.tap(find.text('Add Variant'));
      await tester.pumpAndSettle();

      // Save product
      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      // Verify variants created
      expect(find.text('T-Shirt - Small'), findsOneWidget);
      expect(find.text('T-Shirt - Medium'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
    });

    testWidgets('inventory management flow', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      // Verify inventory screen
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Low Stock Alerts'), findsOneWidget);
      expect(find.text('Stock Levels'), findsOneWidget);

      // Create product with low stock
      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('productNameField')), 'Low Stock Product');
      await tester.enterText(
          find.byKey(const Key('productPriceField')), '10000.00');
      await tester.enterText(
          find.byKey(const Key('inventoryQuantityField')), '5'); // Low quantity
      await tester.enterText(
          find.byKey(const Key('reorderLevelField')), '10'); // Higher than quantity
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      // Navigate back to inventory
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      // Verify low stock alert
      expect(find.text('Low Stock Alert'), findsOneWidget);
      expect(find.text('Low Stock Product'), findsOneWidget);
      expect(find.text('5 in stock'), findsOneWidget);

      // Update inventory
      await tester.tap(find.text('Low Stock Product'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update Stock'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('newQuantityField')), '25');
      await tester.enterText(
          find.byKey(const Key('updateReasonField')), 'Stock replenishment');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Verify stock updated
      expect(find.text('Stock Updated'), findsOneWidget);
      expect(find.text('25 in stock'), findsOneWidget);
      expect(find.text('Low Stock Alert'), findsNothing); // Alert should disappear
    });

    testWidgets('customer shopping experience', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Switch to customer view
      await tester.tap(find.byKey(const Key('viewToggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customer View'));
      await tester.pumpAndSettle();

      // Verify customer shop interface
      expect(find.text('Browse Products'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      // Browse products by category
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      // Verify electronics products
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.byType(GridList), findsOneWidget);

      // Search for product
      await tester.tap(find.byKey(const Key('searchField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('searchField')), 'Laptop');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Laptop'), findsOneWidget);

      // View product details
      await tester.tap(find.text('Premium Laptop'));
      await tester.pumpAndSettle();

      // Verify product details for customer
      expect(find.text('Premium Laptop'), findsOneWidget);
      expect(find.text('₦250,000.00'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);

      // Add to cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Verify added to cart
      expect(find.text('Added to Cart'), findsOneWidget);
      expect(find.text('View Cart (1)'), findsOneWidget);

      // View cart
      await tester.tap(find.text('View Cart'));
      await tester.pumpAndSettle();

      // Verify cart contents
      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.text('Premium Laptop'), findsOneWidget);
      expect(find.text('₦250,000.00'), findsOneWidget);
      expect(find.text('Quantity: 1'), findsOneWidget);
      expect(find.text('Total: ₦250,000.00'), findsOneWidget);

      // Update quantity
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Quantity: 2'), findsOneWidget);
      expect(find.text('Total: ₦500,000.00'), findsOneWidget);

      // Checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();

      // Fill checkout information
      await tester.enterText(
          find.byKey(const Key('checkoutNameField')), 'Test Customer');
      await tester.enterText(
          find.byKey(const Key('checkoutEmailField')), 'customer@example.com');
      await tester.enterText(
          find.byKey(const Key('checkoutPhoneField')), '+2348012345678');
      await tester.pumpAndSettle();

      // Add shipping address
      await tester.enterText(
          find.byKey(const Key('checkoutStreetField')), '123 Customer Street');
      await tester.enterText(
          find.byKey(const Key('checkoutCityField')), 'Lagos');
      await tester.enterText(
          find.byKey(const Key('checkoutStateField')), 'Lagos');
      await tester.pumpAndSettle();

      // Select payment method
      await tester.tap(find.byKey(const Key('paymentMethodField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay with Card'));
      await tester.pumpAndSettle();

      // Place order
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Verify order placed
      expect(find.text('Order Placed Successfully'), findsOneWidget);
      expect(find.text('Order #CUST-2024-001'), findsOneWidget);
      expect(find.text('₦500,000.00'), findsOneWidget);
    });

    testWidgets('shop analytics and reporting', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Navigate to analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Verify analytics dashboard
      expect(find.text('Shop Analytics'), findsOneWidget);
      expect(find.text('Sales Overview'), findsOneWidget);
      expect(find.text('Top Products'), findsOneWidget);
      expect(find.text('Customer Insights'), findsOneWidget);

      // View sales overview
      expect(find.text('Total Sales'), findsOneWidget);
      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('Average Order Value'), findsOneWidget);

      // Select date range
      await tester.tap(find.byKey(const Key('dateRangeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      // Verify date range updated
      expect(find.text('Last 7 Days'), findsOneWidget);

      // View top products
      await tester.tap(find.text('Top Products'));
      await tester.pumpAndSettle();

      // Verify top products list
      expect(find.text('Premium Laptop'), findsOneWidget);
      expect(find.text('T-Shirt'), findsOneWidget);

      // Generate sales report
      await tester.tap(find.text('Generate Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sales Report'));
      await tester.pumpAndSettle();

      // Export report
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excel'));
      await tester.pumpAndSettle();

      // Verify export initiated
      expect(find.text('Exporting...'), findsOneWidget);
    });

    testWidgets('product search and filtering', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Create multiple products
      final products = [
        {'name': 'Laptop', 'category': 'Electronics', 'price': '250000.00'},
        {'name': 'Mouse', 'category': 'Electronics', 'price': '5000.00'},
        {'name': 'T-Shirt', 'category': 'Clothing', 'price': '5000.00'},
        {'name': 'Jeans', 'category': 'Clothing', 'price': '15000.00'},
      ];

      for (final product in products) {
        await tester.tap(find.text('Add Product'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('productNameField')), product['name'] as String);
        await tester.enterText(
            find.byKey(const Key('productPriceField')), product['price'] as String);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('productCategoryField')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(product['category'] as String));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create Product'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Test category filtering
      await tester.tap(find.byKey(const Key('categoryFilter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('T-Shirt'), findsNothing);
      expect(find.text('Jeans'), findsNothing);

      // Test price filtering
      await tester.tap(find.byKey(const Key('priceFilter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('minPriceField')), '10000');
      await tester.enterText(find.byKey(const Key('maxPriceField')), '100000'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify price filtered results
      expect(find.text('Laptop'), findsOneWidget); // 250000 > 100000, should not appear
      expect(find.text('Mouse'), findsNothing); // 5000 < 10000, should not appear

      // Test search
      await tester.tap(find.byKey(const Key('searchField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('searchField')), 'T-Shirt');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('T-Shirt'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Mouse'), findsNothing);
    });

    testWidgets('order fulfillment workflow', (WidgetTester tester) async {
      // Launch app and navigate to shop
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Navigate to orders
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Create test order (assuming it exists)
      await tester.tap(find.text('ORD-2024-001'));
      await tester.pumpAndSettle();

      // Verify order details
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Process order
      await tester.tap(find.text('Process Order'));
      await tester.pumpAndSettle();

      // Add tracking information
      await tester.enterText(
          find.byKey(const Key('trackingNumberField')), 'TRK123456789');
      await tester.tap(find.byKey(const Key('carrierField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DHL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Shipped'));
      await tester.pumpAndSettle();

      // Verify order shipped
      expect(find.text('Order Shipped'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('TRK123456789'), findsOneWidget);
      expect(find.text('DHL'), findsOneWidget);

      // Complete order
      await tester.tap(find.text('Mark as Delivered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Delivery'));
      await tester.pumpAndSettle();

      // Verify order completed
      expect(find.text('Order Completed'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });
}
