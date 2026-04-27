// lib/providers/shell_navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellDest {
  // ── 8 main tabs (indices 0-7) ──────────────────────────────
  billing,       // 0
  expenses,      // 1
  shop,          // 2
  transactions,  // 3
  home,          // 4
  accounts,      // 5
  cards,         // 6
  workflows,     // 7
  // ── Sub-screens (8+) ────────────────────────────────────────
  send,          // 8
  receive,       // 9
  swap,          // 10
  settings,      // 11
  security,      // 12
  // ── Merchant sub-screens (13+) ──────────────────────────────
  checkout,      // 13
  addProduct,    // 14
  editProduct,   // 15
  productDetail, invoices, merchant, // 16
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

  bool get isSubScreen => state.index >= ShellDest.send.index;
  bool get isMerchantSubScreen => state.index >= ShellDest.checkout.index;
}

final shellNavProvider =
    NotifierProvider<ShellNavNotifier, ShellDest>(ShellNavNotifier.new);