// mobile_app/test/widget/balance_card_test.dart
//
// Widget Tests for Balance Card Component
// Tests balance display, formatting, and interactions
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/balance_card.dart';

void main() {
  group('Balance Card Widget Tests', () {
    testWidgets('displays balance correctly', (WidgetTester tester) async {
      // Arrange
      const balance = 50000.00;
      const currency = 'NGN';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: balance,
              currency: currency,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦50,000.00'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
    });

    testWidgets('formats different currencies correctly', (WidgetTester tester) async {
      // Test NGN
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 25000.50,
              currency: 'NGN',
            ),
          ),
        ),
      );
      expect(find.text('₦25,000.50'), findsOneWidget);

      // Test USDC
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 1000.25,
              currency: 'USDC',
            ),
          ),
        ),
      );
      expect(find.text('\$1,000.25'), findsOneWidget);

      // Test XLM
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 1500.1234567,
              currency: 'XLM',
            ),
          ),
        ),
      );
      expect(find.text('1,500.1234567 XLM'), findsOneWidget);
    });

    testWidgets('shows loading state correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 0,
              currency: 'NGN',
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading balance...'), findsOneWidget);
    });

    testWidgets('shows error state correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 0,
              currency: 'NGN',
              error: 'Failed to load balance',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Failed to load balance'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handles zero balance correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 0.0,
              currency: 'NGN',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦0.00'), findsOneWidget);
      expect(find.text('No balance available'), findsOneWidget);
    });

    testWidgets('shows last updated timestamp', (WidgetTester tester) async {
      // Arrange
      final lastUpdated = DateTime.now().subtract(const Duration(hours: 2));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 75000.00,
              currency: 'NGN',
              lastUpdated: lastUpdated,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Last updated'), findsOneWidget);
      expect(find.textContaining('2 hours ago'), findsOneWidget);
    });

    testWidgets('handles tap callback correctly', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(BalanceCard));

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('shows trend indicator correctly', (WidgetTester tester) async {
      // Test positive trend
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 75000.00,
              currency: 'NGN',
              trend: BalanceTrend.up,
              trendPercentage: 15.5,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('+15.5%'), findsOneWidget);

      // Test negative trend
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 75000.00,
              currency: 'NGN',
              trend: BalanceTrend.down,
              trendPercentage: 8.2,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('-8.2%'), findsOneWidget);
    });

    testWidgets('applies custom styling correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 100000.00,
              currency: 'NGN',
              backgroundColor: Colors.blue.shade50,
              textColor: Colors.blue.shade900,
              cardElevation: 8.0,
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(8.0));
      
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, equals(Colors.blue.shade50));
    });

    testWidgets('shows currency icon correctly', (WidgetTester tester) async {
      // Test NGN with icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              showCurrencyIcon: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      // Test USDC with icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 1000.00,
              currency: 'USDC',
              showCurrencyIcon: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.dollar_sign), findsOneWidget);
    });

    testWidgets('handles very large numbers correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 999999999.99,
              currency: 'NGN',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦999,999,999.99'), findsOneWidget);
    });

    testWidgets('shows compact variant correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 25000.00,
              currency: 'NGN',
              isCompact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦25,000.00'), findsOneWidget);
      expect(find.text('Available Balance'), findsNothing); // Compact variant doesn't show label
    });

    testWidgets('handles refresh functionality correctly', (WidgetTester tester) async {
      // Arrange
      bool wasRefreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              onRefresh: () async {
                wasRefreshed = true;
              },
              showRefreshButton: true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.refresh));

      // Assert
      expect(wasRefreshed, isTrue);
    });

    testWidgets('shows balance breakdown correctly', (WidgetTester tester) async {
      // Arrange
      final breakdown = [
        {'asset': 'NGN', 'amount': 25000.00, 'percentage': 50.0},
        {'asset': 'USDC', 'amount': 15000.00, 'percentage': 30.0},
        {'asset': 'XLM', 'amount': 10000.00, 'percentage': 20.0},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              breakdown: breakdown,
              showBreakdown: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Balance Breakdown'), findsOneWidget);
      expect(find.text('NGN: ₦25,000.00 (50%)'), findsOneWidget);
      expect(find.text('USDC: \$15,000.00 (30%)'), findsOneWidget);
      expect(find.text('XLM: 10,000.00 XLM (20%)'), findsOneWidget);
    });

    testWidgets('handles accessibility correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              semanticLabel: 'Current balance: 50,000 Nigerian Naira',
            ),
          ),
        ),
      );

      // Assert
      expect(
        tester.semantics(find.byType(BalanceCard)),
        includesSemantics('Current balance: 50,000 Nigerian Naira'),
      );
    });

    testWidgets('shows warning for low balance', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 500.00,
              currency: 'NGN',
              lowBalanceThreshold: 1000.00,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Low balance'), findsOneWidget);
    });

    testWidgets('handles animation correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 50000.00,
              currency: 'NGN',
              animateOnLoad: true,
            ),
          ),
        ),
      );

      // Act - pump animation frames
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert - animation should be complete
      expect(find.text('₦50,000.00'), findsOneWidget);
    });

    testWidgets('shows custom title correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 75000.00,
              currency: 'NGN',
              title: 'Total Assets',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Total Assets'), findsOneWidget);
      expect(find.text('Available Balance'), findsNothing);
    });

    testWidgets('handles decimal precision correctly', (WidgetTester tester) async {
      // Test 2 decimal places (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 12345.6789,
              currency: 'NGN',
            ),
          ),
        ),
      );
      expect(find.text('₦12,345.68'), findsOneWidget);

      // Test 4 decimal places
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              balance: 12345.6789,
              currency: 'XLM',
              decimalPlaces: 4,
            ),
          ),
        ),
      );
      expect(find.text('12,345.6789 XLM'), findsOneWidget);
    });
  });
}

// BalanceTrend enum for testing
enum BalanceTrend {
  up,
  down,
  neutral,
}
