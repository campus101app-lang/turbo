// lib/providers/billing_provider.dart
//
// Billing Provider for DayFi
// Manages billing state and operations
//

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> payments;
  final double totalRevenue;
  final double pendingAmount;
  final bool isLoading;
  final String? error;

  BillingState({
    this.invoices = const [],
    this.payments = const [],
    this.totalRevenue = 0.0,
    this.pendingAmount = 0.0,
    this.isLoading = false,
    this.error,
  });

  BillingState copyWith({
    List<Map<String, dynamic>>? invoices,
    List<Map<String, dynamic>>? payments,
    double? totalRevenue,
    double? pendingAmount,
    bool? isLoading,
    String? error,
  }) {
    return BillingState(
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BillingProvider extends StateNotifier<BillingState> {
  BillingProvider() : super(BillingState());

  Future<void> loadBillingData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final invoices = [
        {
          'id': '1',
          'number': 'INV-2024-001',
          'amount': 50000.0,
          'currency': 'NGN',
          'status': 'paid',
          'createdAt': '2024-01-15',
          'dueDate': '2024-02-15',
          'customer': 'Customer A',
        },
        {
          'id': '2',
          'number': 'INV-2024-002',
          'amount': 75000.0,
          'currency': 'NGN',
          'status': 'pending',
          'createdAt': '2024-01-20',
          'dueDate': '2024-02-20',
          'customer': 'Customer B',
        },
      ];

      final payments = [
        {
          'id': '1',
          'amount': 50000.0,
          'currency': 'NGN',
          'method': 'bank_transfer',
          'date': '2024-01-16',
          'status': 'completed',
          'invoiceId': '1',
        },
      ];

      final totalRevenue = payments
          .where((p) => p['status'] == 'completed')
          .fold(0.0, (sum, p) => sum + (p['amount'] as double));

      final pendingAmount = invoices
          .where((i) => i['status'] != 'paid')
          .fold(0.0, (sum, i) => sum + (i['amount'] as double));

      state = state.copyWith(
        invoices: invoices,
        payments: payments,
        totalRevenue: totalRevenue,
        pendingAmount: pendingAmount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final newInvoice = {
        ...invoiceData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'number': 'INV-${DateTime.now().year}-${(state.invoices.length + 1).toString().padLeft(3, '0')}',
        'createdAt': DateTime.now().toIso8601String().split('T')[0],
      };

      state = state.copyWith(
        invoices: [...state.invoices, newInvoice],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markInvoiceAsPaid(String invoiceId) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final updatedInvoices = state.invoices.map((invoice) {
        if (invoice['id'] == invoiceId) {
          return {...invoice, 'status': 'paid'};
        }
        return invoice;
      }).toList();

      state = state.copyWith(
        invoices: updatedInvoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final billingProvider = StateNotifierProvider<BillingProvider, BillingState>(
  (ref) => BillingProvider(),
);
