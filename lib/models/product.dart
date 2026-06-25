import 'dart:convert';

/// 商品购买参数项 — 与PC端 buy_params 结构一致
class BuyParam {
  final String name;
  final String key;
  final int type;
  final String description;
  final String? typeConfig;
  final Map<String, dynamic>? verify;
  final String? defaultValue;
  final bool required;

  BuyParam({
    required this.name,
    required this.key,
    required this.type,
    this.description = '',
    this.typeConfig,
    this.verify,
    this.defaultValue,
    this.required = false,
  });

  factory BuyParam.fromJson(Map<String, dynamic> json) {
    return BuyParam(
      name: json['name'] ?? '参数',
      key: json['key'] ?? json['name'] ?? '',
      type: json['type'] ?? 1,
      description: json['description'] ?? '',
      typeConfig: json['type_config']?.toString(),
      verify: json['verify'] is Map ? json['verify'] as Map<String, dynamic> : null,
      defaultValue: json['default']?.toString(),
      required: json['required'] == true || json['required'] == 1,
    );
  }
}

/// 商品模型 — 完整覆盖后端返回字段
class Product {
  final int id;
  final String name;
  final String image;
  final double price;
  final double? originalPrice;
  final double? ourPrice;
  final double? marketPrice;
  final int stock;
  final int minBuy;
  final int maxBuy;
  final int buyRate;
  final String description;
  final String? particulars;
  final int categoryId;
  final String categoryName;
  final int salesCount;
  final bool isOpen;
  final bool isCardCode;
  final String unit;
  final double? commissionRate;
  final double? avgCompletionHours;
  final List<String> imageUrls;
  final List<BuyParam> buyParams;
  final String? tag;
  final String? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    this.ourPrice,
    this.marketPrice,
    required this.stock,
    this.minBuy = 1,
    this.maxBuy = 999,
    this.buyRate = 1,
    this.description = '',
    this.particulars,
    this.categoryId = 0,
    this.categoryName = '',
    this.salesCount = 0,
    this.isOpen = true,
    this.isCardCode = false,
    this.unit = '个',
    this.commissionRate,
    this.avgCompletionHours,
    this.imageUrls = const [],
    this.buyParams = const [],
    this.tag,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 解析图片URLs
    final imgUrls = _parseImageUrls(json);

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: imgUrls.isNotEmpty ? imgUrls.first : '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      ourPrice: json['our_price']?.toDouble(),
      marketPrice: json['market_price']?.toDouble(),
      stock: json['stock'] ?? 0,
      minBuy: json['buy_min_limit'] ?? json['min_buy'] ?? json['min'] ?? 1,
      maxBuy: json['buy_max_limit'] ?? json['max_buy'] ?? json['max'] ?? 999,
      buyRate: json['buy_rate'] ?? 1,
      description: json['description'] ?? '',
      particulars: json['particulars']?.toString(),
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      salesCount: json['sales'] ?? json['sales_count'] ?? json['total_sales'] ?? 0,
      isOpen: json['is_close'] != 1,
      isCardCode: json['is_card_code'] == 1,
      unit: json['unit'] ?? '个',
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      avgCompletionHours: (json['avg_completion_hours'] ?? 0).toDouble(),
      imageUrls: imgUrls,
      buyParams: _parseBuyParams(json),
      tag: json['tag']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  /// 获取显示用的价格（优先市场价，次之我们的价，最后是基础价）
  double get displayPrice => marketPrice ?? ourPrice ?? price;

  /// 获取价格文本（移除多余小数位）
  String get priceText {
    final p = displayPrice;
    if (p == 0) return '0';
    return p.toStringAsFixed(7).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// 获取原始价格文本
  String get originalPriceText {
    if (price > 0 && displayPrice > 0 && displayPrice < price) {
      return price.toStringAsFixed(7).replaceAll(RegExp(r'\.?0+$'), '');
    }
    return '';
  }

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    // 优先使用 image_urls 数组
    final urls = json['image_urls'];
    if (urls is List && urls.isNotEmpty) {
      return urls.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    // 其次是 image 字段（可能包含JSON数组字符串或单个URL）
    final img = json['image'] ?? '';
    if (img is String) {
      if (img.startsWith('[')) {
        try {
          final list = jsonDecode(img) as List;
          return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        } catch (_) {}
      }
      if (img.isNotEmpty) return [img];
    }
    return [];
  }

  static List<BuyParam> _parseBuyParams(Map<String, dynamic> json) {
    final params = json['buy_params'];
    if (params is List && params.isNotEmpty) {
      return params.map((e) => BuyParam.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
