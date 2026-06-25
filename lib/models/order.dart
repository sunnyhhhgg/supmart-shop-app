/// 订单模型
class Order {
  final int id;
  final String orderNo;
  final int productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double totalAmount;
  final String status;
  final String statusText;
  final String cardInfo;
  final String buyer;
  final String buyerContact;
  final int createdAt;
  final int updatedAt;
  final double refundAmount;
  final int refundQuantity;

  Order({
    required this.id,
    required this.orderNo,
    required this.productId,
    required this.productName,
    this.productImage = '',
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.statusText,
    this.cardInfo = '',
    this.buyer = '',
    this.buyerContact = '',
    required this.createdAt,
    required this.updatedAt,
    this.refundAmount = 0,
    this.refundQuantity = 0,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNo: json['order_no'] ?? json['order_sn'] ?? '',
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      totalAmount: (json['total_amount'] ?? json['total'] ?? 0).toDouble(),
      status: (json['status'] ?? '').toString(),
      statusText: _statusText((json['status'] ?? '').toString()),
      cardInfo: json['card_info'] ?? json['card_code'] ?? '',
      buyer: json['buyer'] ?? json['customer_name'] ?? '',
      buyerContact: json['buyer_contact'] ?? json['customer_contact'] ?? '',
      createdAt: _parseTime(json['created_at'] ?? json['create_time'] ?? 0),
      updatedAt: _parseTime(json['updated_at'] ?? json['update_time'] ?? 0),
      refundAmount: (json['refund_amount'] ?? 0).toDouble(),
      refundQuantity: json['refund_quantity'] ?? 0,
    );
  }

  static String _statusText(String status) {
    switch (status) {
      case '0': return '待处理';
      case '1': return '处理中';
      case '2': return '已完成';
      case '3': return '交易完成';
      case '-1': return '已退款';
      case '-2': return '已取消';
      default: return status;
    }
  }

  static int _parseTime(dynamic t) {
    if (t is int) return t;
    if (t is String) {
      try {
        return DateTime.parse(t).millisecondsSinceEpoch ~/ 1000;
      } catch (_) {}
    }
    return 0;
  }
}
