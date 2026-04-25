// lib/providers/shop_provider.dart
//
// Shop Provider for DayFi
// Manages shop/e-commerce state and operations
//

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShopState {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? cart;
  final bool isLoading;
  final String? error;

  ShopState({
    this.products = const [],
    this.orders = const [],
    this.categories = const [],
    this.cart,
    this.isLoading = false,
    this.error,
  });

  ShopState copyWith({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? orders,
    List<Map<String, dynamic>>? categories,
    Map<String, dynamic>? cart,
    bool? isLoading,
    String? error,
  }) {
    return ShopState(
      products: products ?? this.products,
      orders: orders ?? this.orders,
      categories: categories ?? this.categories,
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ShopProvider extends StateNotifier<ShopState> {
  ShopProvider() : super(ShopState());

  Future<void> loadShopData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final products = [
        {
          'id': '1',
          'name': 'Professional Accounting Software',
          'description': 'Complete accounting solution for Nigerian businesses',
          'price': 50000.0,
          'currency': 'NGN',
          'category': 'Software',
          'stock': 100,
          'image': 'assets/images/product1.jpg',
          'rating': 4.5,
          'reviews': 23,
          'isActive': true,
        },
        {
          'id': '2',
          'name': 'Business Compliance Package',
          'description': 'Full Nigerian business compliance tools',
          'price': 75000.0,
          'currency': 'NGN',
          'category': 'Services',
          'stock': 50,
          'image': 'assets/images/product2.jpg',
          'rating': 4.8,
          'reviews': 45,
          'isActive': true,
        },
      ];

      final categories = [
        {
          'id': '1',
          'name': 'Software',
          'description': 'Business software solutions',
          'productCount': 15,
        },
        {
          'id': '2',
          'name': 'Services',
          'description': 'Professional services',
          'productCount': 8,
        },
        {
          'id': '3',
          'name': 'Hardware',
          'description': 'Business equipment',
          'productCount': 12,
        },
      ];

      final orders = [
        {
          'id': '1',
          'orderNumber': 'ORD-2024-001',
          'items': [
            {'productId': '1', 'quantity': 2, 'price': 50000.0},
          ],
          'totalAmount': 100000.0,
          'currency': 'NGN',
          'status': 'delivered',
          'orderDate': '2024-01-15',
          'deliveryDate': '2024-01-17',
          'customer': {
            'name': 'Customer A',
            'email': 'customer@example.com',
            'phone': '+234-123-456-7890',
          },
        },
      ];

      state = state.copyWith(
        products: products,
        categories: categories,
        orders: orders,
        cart: {'items': [], 'total': 0.0},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final product = state.products.firstWhere((p) => p['id'] == productId);
      
      final currentCart = state.cart ?? {'items': [], 'total': 0.0};
      final items = List<Map<String, dynamic>>.from(currentCart['items']);
      
      final existingItemIndex = items.indexWhere((item) => item['productId'] == productId);
      
      if (existingItemIndex >= 0) {
        items[existingItemIndex]['quantity'] += quantity;
      } else {
        items.add({
          'productId': productId,
          'name': product['name'],
          'price': product['price'],
          'quantity': quantity,
        });
      }

      final total = items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

      state = state.copyWith(
        cart: {'items': items, 'total': total},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeFromCart(String productId) async {
    final currentCart = state.cart ?? {'items': [], 'total': 0.0};
    final items = currentCart['items'].where((item) => item['productId'] != productId).toList();
    
    final total = items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

    state = state.copyWith(
      cart: {'items': items, 'total': total},
    );
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final newOrder = {
        ...orderData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'orderNumber': 'ORD-${DateTime.now().year}-${(state.orders.length + 1).toString().padLeft(3, '0')}',
        'orderDate': DateTime.now().toIso8601String().split('T')[0],
        'status': 'processing',
      };

      state = state.copyWith(
        orders: [...state.orders, newOrder],
        cart: {'items': [], 'total': 0.0},
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
final shopProvider = StateNotifierProvider<ShopProvider, ShopState>(
  (ref) => ShopProvider(),
);
