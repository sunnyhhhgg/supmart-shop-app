import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import 'config_service.dart';

/// SUPMART Shop API调用层
class ApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  static String get _base => ConfigService.apiBase;

  // ==================== 登录 ====================

  /// 用户登录 (POST /api/v2/shop/login)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/login'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));
    return jsonDecode(resp.body);
  }

  // ==================== 商品 ====================

  /// 获取商品分类 (POST /api/v2/shop/categories)
  static Future<List<Category>> getCategories() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/categories'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data'] as List;
      return list.map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  /// 获取商品列表 (POST /api/v2/shop/goods-list)
  static Future<List<Product>> getProducts({int? categoryId, String? keyword, int page = 1, int pageSize = 50}) async {
    final body = <String, dynamic>{
      'page': page,
      'list_rows': pageSize,
    };
    if (categoryId != null && categoryId > 0) body['goods_category_id'] = categoryId;
    if (keyword != null && keyword.isNotEmpty) body['goods_name'] = keyword;

    final resp = await http.post(
      Uri.parse('$_base/shop/goods-list'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? json['data'] as List;
      return (list as List).map((e) => Product.fromJson(e)).toList();
    }
    return [];
  }

  /// 商品详情 (POST /api/v2/shop/goods-detail)
  static Future<Product?> getProductDetail(int productId) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/goods-detail'),
      headers: _headers(),
      body: jsonEncode({'id': productId}),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return Product.fromJson(json['data']);
    }
    return null;
  }

  // ==================== 下单 ====================

  /// 提交订单 (POST /api/v2/shop/buy)
  static Future<Map<String, dynamic>> placeOrder({
    required int productId,
    required int quantity,
    String? contact,
    String? buyer,
  }) async {
    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
    if (contact != null) body['contact'] = contact;
    if (buyer != null) body['buyer'] = buyer;

    final resp = await http.post(
      Uri.parse('$_base/shop/buy'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(resp.body);
  }

  // ==================== 订单 ====================

  /// 获取订单列表 (POST /api/v2/shop/order-paging)
  static Future<List<Order>> getOrders({String? status, int page = 1, int pageSize = 20}) async {
    final body = <String, dynamic>{
      'page': page,
      'list_rows': pageSize,
    };
    if (status != null && status.isNotEmpty) {
      body['status'] = int.tryParse(status) ?? 0;
    }

    final resp = await http.post(
      Uri.parse('$_base/shop/order-paging'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? json['data'] as List;
      return (list as List).map((e) => Order.fromJson(e)).toList();
    }
    return [];
  }

  /// 订单详情 (POST /api/v2/shop/order-paging with order_id)
  static Future<Order?> getOrderDetail(String orderNo) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/order-paging'),
      headers: _headers(),
      body: jsonEncode({'order_no': orderNo, 'page': 1, 'list_rows': 1}),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? json['data'] as List;
      if ((list as List).isNotEmpty) {
        return Order.fromJson(list[0]);
      }
    }
    return null;
  }

  // ==================== 账户 ====================

  /// 获取账户余额 (POST /api/v2/shop/profile)
  static Future<double> getBalance() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/profile'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return (json['data']['balance'] ?? 0).toDouble();
    }
    return 0;
  }
}
