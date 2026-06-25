import 'dart:convert';

/// 商品模型
class Product {
  final int id;
  final String name;
  final String image;
  final double price;
  final double? originalPrice;
  final int stock;
  final int minBuy;
  final int maxBuy;
  final String description;
  final int categoryId;
  final String categoryName;
  final int salesCount;
  final bool isOpen;
  final String unit;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.stock,
    this.minBuy = 1,
    this.maxBuy = 999,
    this.description = '',
    this.categoryId = 0,
    this.categoryName = '',
    this.salesCount = 0,
    this.isOpen = true,
    this.unit = '个',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: _parseImage(json),
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      stock: json['stock'] ?? 0,
      minBuy: json['min_buy'] ?? json['min'] ?? 1,
      maxBuy: json['max_buy'] ?? json['max'] ?? 999,
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      salesCount: json['sales_count'] ?? json['total_sales'] ?? 0,
      isOpen: json['is_open'] ?? json['is_close'] != 1,
      unit: json['unit'] ?? '个',
    );
  }

  static String _parseImage(Map<String, dynamic> json) {
    var img = json['image'] ?? '';
    if (img is List && img.isNotEmpty) img = img[0];
    if (img is String && img.startsWith('[')) {
      try {
        final list = jsonDecode(img.toString()) as List;
        if (list.isNotEmpty) return list[0].toString();
      } catch (_) {}
    }
    return img.toString();
  }
}
