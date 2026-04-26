// lib/providers/inventory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  List<InventoryItem> get lowStockItems =>
      items.where((i) => i.isLowStock).toList();

  double get totalInventoryValue =>
      items.fold(0, (sum, i) => sum + (i.priceUsdc * i.stock));

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
  }) {
    return InventoryState(
      items:        items        ?? this.items,
      isLoading:    isLoading    ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error:        error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final raw = await apiService.getInventory();
      state = state.copyWith(
        isLoading: false,
        items: raw.map((e) => InventoryItem.fromMap(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

Future<void> setAbsoluteStock(String itemId, int value) async {
  final map = await apiService.updateStock(itemId, absolute: value);
  _replaceItem(InventoryItem.fromMap(map));
}

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final raw = await apiService.getInventory();
      state = state.copyWith(
        isRefreshing: false,
        items: raw.map((e) => InventoryItem.fromMap(e as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.toString());
    }
  }

  Future<void> addItem({
    required String name,
    required double priceUsdc,
    required int stock,
    int threshold = 5,
    String? sku,
    String? category,
  }) async {
    final map = await apiService.createInventoryItem(
      name: name,
      priceUsdc: priceUsdc,
      stock: stock,
      threshold: threshold,
      sku: sku,
      category: category,
    );
    final item = InventoryItem.fromMap(map);
    state = state.copyWith(items: [...state.items, item]);
  }

  Future<void> incrementStock(String itemId) async {
    _applyLocalDelta(itemId, 1);
    try {
      final map = await apiService.updateStock(itemId, delta: 1);
      _replaceItem(InventoryItem.fromMap(map));
    } catch (e) {
      _applyLocalDelta(itemId, -1); // rollback
      rethrow;
    }
  }

  Future<void> decrementStock(String itemId) async {
    _applyLocalDelta(itemId, -1);
    try {
      final map = await apiService.updateStock(itemId, delta: -1);
      _replaceItem(InventoryItem.fromMap(map));
    } catch (e) {
      _applyLocalDelta(itemId, 1); // rollback
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    await apiService.deleteInventoryItem(itemId);
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  // ─── Cart helpers ────────────────────────────────────────

  /// Deduct stock for all cart items after a confirmed payment
  Future<void> deductCartStock(Map<String, int> cart) async {
    for (final entry in cart.entries) {
      try {
        final map = await apiService.updateStock(entry.key, delta: -entry.value);
        _replaceItem(InventoryItem.fromMap(map));
      } catch (_) {}
    }
  }

  // ─── Private helpers ─────────────────────────────────────

  void _applyLocalDelta(String itemId, int delta) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id != itemId) return i;
        final newStock = (i.stock + delta).clamp(0, 999999);
        return i.copyWith(stock: newStock);
      }).toList(),
    );
  }

  void _replaceItem(InventoryItem updated) {
    state = state.copyWith(
      items: state.items.map((i) => i.id == updated.id ? updated : i).toList(),
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(),
);

final lowStockProvider = Provider<List<InventoryItem>>(
  (ref) => ref.watch(inventoryProvider).lowStockItems,
);