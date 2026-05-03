// lib/providers/shell_navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellDest {
  // ── 10 main tabs (indices 0-9) ─────────────────────────────
  home,         // 0
  accounts,     // 1
  cards,        // 2
  send,         // 3  (Payments tab)
  transactions, // 4
  billing,      // 5  (Invoices)
  expenses,     // 6
  shop,         // 7
  reports,      // 8
  workflows,    // 9
  // ── Sub-screens (10+) ──────────────────────────────────────
  receive,      // 10
  swap,         // 11
  settings,     // 12
  security,     // 13
  checkout,     // 14
  addProduct,   // 15
  editProduct,  // 16
  productDetail,// 17
  invoices,     // 18  (alias)
  merchant,     // 19  (alias)
  createInvoice,   // 20
  invoiceDetail,   // 21
  createExpense,   // 22
  expenseDetail,   // 23
  createCard,      // 24
  cardDetail,      // 25
  createWorkflow,  // 26
  workflowDetail,  // 27
}

class ShellNavNotifier extends Notifier<ShellDest> {
  ShellDest _previous = ShellDest.home;

  @override
  ShellDest build() => ShellDest.home;

  ShellDest get previous => _previous;

  void goTo(ShellDest dest) {
    _previous = state;
    state = dest;
  }

  void goBack() {
    final temp = _previous;
    _previous = state;
    state = temp;
  }

  bool get isSubScreen => state.index >= ShellDest.receive.index;
  bool get isMerchantSubScreen => state.index >= ShellDest.checkout.index;
}

final shellNavProvider = NotifierProvider<ShellNavNotifier, ShellDest>(
  ShellNavNotifier.new,
);