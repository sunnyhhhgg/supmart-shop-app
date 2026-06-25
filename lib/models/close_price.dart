/// 成交价/密价模型
class ClosePrice {
  final int id;
  final int productId;
  final String productName;
  final double originalPrice;
  final double closePrice;
  final int markupType;
  final double markupValue;

  ClosePrice({
    required this.id,
    this.productId = 0,
    this.productName = '',
    this.originalPrice = 0,
    this.closePrice = 0,
    this.markupType = 0,
    this.markupValue = 0,
  });

  factory ClosePrice.fromJson(Map<String, dynamic> json) {
    return ClosePrice(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? json['goods_id'] ?? 0,
      productName: json['product_name']?.toString() ?? json['goods_name']?.toString() ?? '',
      originalPrice: (json['original_price'] ?? json['price'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? json['our_price'] ?? 0).toDouble(),
      markupType: json['markup_type'] ?? 0,
      markupValue: (json['markup_value'] ?? 0).toDouble(),
    );
  }
}
