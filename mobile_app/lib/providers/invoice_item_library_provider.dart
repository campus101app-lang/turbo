// lib/providers/invoice_item_library_provider.dart
// Local storage for invoice line item templates
// Persisted to device using SharedPreferences

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class InvoiceItemTemplate {
  final String id;
  final String description;
  final double price;
  final DateTime createdAt;

  InvoiceItemTemplate({
    required this.id,
    required this.description,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
  };

  factory InvoiceItemTemplate.fromJson(Map<String, dynamic> j) =>
      InvoiceItemTemplate(
        id: j['id'] as String,
        description: j['description'] as String,
        price: (j['price'] as num).toDouble(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class InvoiceItemLibraryState {
  final List<InvoiceItemTemplate> items;
  final bool isLoading;

  const InvoiceItemLibraryState({
    this.items = const [],
    this.isLoading = false,
  });

  InvoiceItemLibraryState copyWith({
    List<InvoiceItemTemplate>? items,
    bool? isLoading,
  }) {
    return InvoiceItemLibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InvoiceItemLibraryNotifier
    extends StateNotifier<InvoiceItemLibraryState> {
  InvoiceItemLibraryNotifier() : super(const InvoiceItemLibraryState()) {
    _init();
  }

  static const _storageKey = 'invoice_item_library';

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        final items = list
            .map((e) => InvoiceItemTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        // Initialize with default templates
        state = state.copyWith(
          items: _defaultTemplates(),
          isLoading: false,
        );
      }
    } catch (e) {
      print('Error loading invoice item library: $e');
      state = state.copyWith(items: _defaultTemplates(), isLoading: false);
    }
  }

  /// Default/hardcoded templates
  static List<InvoiceItemTemplate> _defaultTemplates() {
    return [
      InvoiceItemTemplate(
        id: 'tmpl_web_design',
        description: 'Web Design',
        price: 150000.0,
        createdAt: DateTime.now(),
      ),
      InvoiceItemTemplate(
        id: 'tmpl_logo_design',
        description: 'Logo Design',
        price: 75000.0,
        createdAt: DateTime.now(),
      ),
      InvoiceItemTemplate(
        id: 'tmpl_monthly_retainer',
        description: 'Monthly Retainer',
        price: 200000.0,
        createdAt: DateTime.now(),
      ),
      InvoiceItemTemplate(
        id: 'tmpl_seo_audit',
        description: 'SEO Audit',
        price: 50000.0,
        createdAt: DateTime.now(),
      ),
      InvoiceItemTemplate(
        id: 'tmpl_copywriting',
        description: 'Copywriting (per page)',
        price: 25000.0,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Add a new item to the library
  Future<void> addItem({
    required String description,
    required double price,
  }) async {
    final item = InvoiceItemTemplate(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      price: price,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(items: [...state.items, item]);
    await _save();
  }

  /// Remove an item from the library
  Future<void> removeItem(String id) async {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
    await _save();
  }

  /// Persist to device storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      print('Error saving invoice item library: $e');
    }
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────

final invoiceItemLibraryProvider = StateNotifierProvider<
    InvoiceItemLibraryNotifier,
    InvoiceItemLibraryState>((ref) {
  return InvoiceItemLibraryNotifier();
});
