// lib/providers/selected_product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';

final selectedProductProvider = StateProvider<InventoryItem?>((ref) => null);