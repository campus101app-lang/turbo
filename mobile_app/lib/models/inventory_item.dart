// lib/models/inventory_item.dart

class InventoryItem {
  final String id;
  final String name;
  final String? sku;
  final double priceUsdc;
  final int stock;
  final int threshold;
  final String? barcode;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;

  const InventoryItem({
    required this.id,
    required this.name,
    this.sku,
    required this.priceUsdc,
    required this.stock,
    required this.threshold,
    this.barcode,
    this.imageUrl,
    this.category,
    this.createdAt,
  });

  bool get isLowStock => stock <= threshold;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id:         map['id'] as String,
      name:       map['name'] as String,
      sku:        map['sku'] as String?,
      priceUsdc:  (map['priceUsdc'] as num).toDouble(),
      stock:      (map['stock'] as num).toInt(),
      threshold:  (map['threshold'] as num?)?.toInt() ?? 5,
      barcode:    map['barcode'] as String?,
      imageUrl:   map['imageUrl'] as String?,
      category:   map['category'] as String?,
      createdAt:  map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  InventoryItem copyWith({
    String? name,
    String? sku,
    double? priceUsdc,
    int? stock,
    int? threshold,
    String? barcode,
    String? imageUrl,
    String? category,
  }) {
    return InventoryItem(
      id:        id,
      name:      name       ?? this.name,
      sku:       sku        ?? this.sku,
      priceUsdc: priceUsdc  ?? this.priceUsdc,
      stock:     stock      ?? this.stock,
      threshold: threshold  ?? this.threshold,
      barcode:   barcode    ?? this.barcode,
      imageUrl:  imageUrl   ?? this.imageUrl,
      category:  category   ?? this.category,
      createdAt: createdAt,
    );
  }
}