// mobile_app/test/widget/transaction_item_test.dart
//
// Widget Tests for Transaction Item Component
// Tests transaction display, status indicators, and interactions
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/transaction_item.dart';

void main() {
  group('Transaction Item Widget Tests', () {
    testWidgets('displays transaction information correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_123',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'description': 'Invoice payment',
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦50,000.00'), findsOneWidget);
      expect(find.text('customer@example.com'), findsOneWidget);
      expect(find.text('Invoice payment'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows different transaction types correctly', (WidgetTester tester) async {
      // Test payment transaction
      final paymentTransaction = {
        'id': 'tx_payment',
        'type': 'payment',
        'amount': '25000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'sender@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: paymentTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Payment Received'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.text('₦25,000.00'), findsOneWidget);

      // Test send transaction
      final sendTransaction = {
        'id': 'tx_send',
        'type': 'send',
        'amount': '15000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'recipient@example.com',
        'timestamp': '2024-01-15T11:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: sendTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Payment Sent'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text('₦15,000.00'), findsOneWidget);

      // Test swap transaction
      final swapTransaction = {
        'id': 'tx_swap',
        'type': 'swap',
        'amount': '1000.00',
        'currency': 'USDC',
        'status': 'completed',
        'counterparty': 'Dex Exchange',
        'timestamp': '2024-01-15T12:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: swapTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Swap'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.text('\$1,000.00'), findsOneWidget);
    });

    testWidgets('shows different status indicators correctly', (WidgetTester tester) async {
      // Test completed status
      final completedTransaction = {
        'id': 'tx_completed',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: completedTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Test pending status
      final pendingTransaction = {
        'id': 'tx_pending',
        'type': 'payment',
        'amount': '25000.00',
        'currency': 'NGN',
        'status': 'pending',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: pendingTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);

      // Test failed status
      final failedTransaction = {
        'id': 'tx_failed',
        'type': 'payment',
        'amount': '10000.00',
        'currency': 'NGN',
        'status': 'failed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: failedTransaction,
            ),
          ),
        ),
      );

      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('formats timestamp correctly', (WidgetTester tester) async {
      // Test recent transaction
      final recentTransaction = {
        'id': 'tx_recent',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: recentTransaction,
            ),
          ),
        ),
      );

      expect(find.textContaining('minutes ago'), findsOneWidget);

      // Test older transaction
      final oldTransaction = {
        'id': 'tx_old',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: oldTransaction,
            ),
          ),
        ),
      );

      expect(find.textContaining('days ago'), findsOneWidget);
    });

    testWidgets('handles tap callback correctly', (WidgetTester tester) async {
      // Arrange
      TransactionItem? tappedTransaction;
      final transaction = {
        'id': 'tx_123',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
              onTap: (tx) => tappedTransaction = tx,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(TransactionItem));

      // Assert
      expect(tappedTransaction, isNotNull);
      expect(tappedTransaction!['id'], equals('tx_123'));
    });

    testWidgets('shows compact variant correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_compact',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
              isCompact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('₦50,000.00'), findsOneWidget);
      expect(find.text('customer@example.com'), findsOneWidget);
      // Compact variant might not show description or full timestamp
    });

    testWidgets('shows different currencies correctly', (WidgetTester tester) async {
      // Test NGN
      final ngnTransaction = {
        'id': 'tx_ngn',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: ngnTransaction,
            ),
          ),
        ),
      );

      expect(find.text('₦50,000.00'), findsOneWidget);

      // Test USDC
      final usdcTransaction = {
        'id': 'tx_usdc',
        'type': 'payment',
        'amount': '1000.00',
        'currency': 'USDC',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: usdcTransaction,
            ),
          ),
        ),
      );

      expect(find.text('\$1,000.00'), findsOneWidget);

      // Test XLM
      final xlmTransaction = {
        'id': 'tx_xlm',
        'type': 'payment',
        'amount': '1500.1234567',
        'currency': 'XLM',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: xlmTransaction,
            ),
          ),
        ),
      );

      expect(find.text('1,500.1234567 XLM'), findsOneWidget);
    });

    testWidgets('shows transaction hash correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_123',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'transactionHash': '0x1234567890abcdef1234567890abcdef12345678',
        'showTransactionHash': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('0x1234...5678'), findsOneWidget);
    });

    testWidgets('handles long counterparty names correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_long_name',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'very.long.email.address.that.is.too.long.for.display@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert - should truncate long names
      expect(find.textContaining('very.long.email.address...'), findsOneWidget);
    });

    testWidgets('shows fee information correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_with_fee',
        'type': 'send',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'recipient@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'fee': '0.50',
        'showFee: true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Fee: ₦0.50'), findsOneWidget);
    });

    testWidgets('applies custom styling correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_styled',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
              backgroundColor: Colors.blue.shade50,
              textColor: Colors.blue.shade900,
              cardElevation: 4.0,
            ),
          ),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(4.0));
    });

    testWidgets('handles accessibility correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_accessibility',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'semanticLabel': 'Payment of 50,000 Nigerian Naira from customer@example.com',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(
        tester.semantics(find.byType(TransactionItem)),
        includesSemantics('Payment of 50,000 Nigerian Naira from customer@example.com'),
      );
    });

    testWidgets('shows loading state correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_loading',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'pending',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'isLoading': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_error',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'failed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'error': 'Transaction failed: Insufficient funds',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Transaction failed: Insufficient funds'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('handles swipe actions correctly', (WidgetTester tester) async {
      // Arrange
      bool wasSwiped = false;
      final transaction = {
        'id': 'tx_swipe',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'enableSwipeActions': true,
        'onSwipe: () => wasSwiped = true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Act
      await tester.drag(find.byType(TransactionItem), const Offset(-200, 0));

      // Assert
      expect(wasSwiped, isTrue);
    });

    testWidgets('shows memo/description correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_memo',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'NGN',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'memo': 'Monthly subscription payment',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Monthly subscription payment'), findsOneWidget);
    });

    testWidgets('shows block explorer link correctly', (WidgetTester tester) async {
      // Arrange
      final transaction = {
        'id': 'tx_explorer',
        'type': 'payment',
        'amount': '50000.00',
        'currency': 'XLM',
        'status': 'completed',
        'counterparty': 'customer@example.com',
        'timestamp': '2024-01-15T10:30:00Z',
        'transactionHash': '0x1234567890abcdef1234567890abcdef12345678',
        'showExplorerLink': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionItem(
              transaction: transaction,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('View on Explorer'), findsOneWidget);
    });
  });
}
