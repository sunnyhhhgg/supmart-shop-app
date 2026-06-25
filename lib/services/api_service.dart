import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import 'config_service.dart';

/// SUPMART 开放API调用层
class ApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 通用请求头
  static Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  /// API基础地址
  static String get _base => ConfigService.apiBase;

  // ==================== 登录 ====================

  /// 用户登录
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sign = md5.convert(utf8.encode('$username$password$ts')).toString();
    final resp = await http.post(
      Uri.parse('$_base/openapi/customer/Login'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'timestamp': ts,
        'sign': sign,
      }),
    ).timeout(const Duration(seconds: 15));
    return jsonDecode(resp.body);
  }

  // ==================== 商品 ====================

  /// 获取商品分类
  static Future<List<Category>> getCategories() async {
    final resp = await http.get(
      Uri.parse('$_base/openapi/customer/Goods/CategoryList'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data'] as List;
      return list.map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  /// 获取商品列表
  static Future<List<Product>> getProducts({int? categoryId, String? keyword, int page = 1, int pageSize = 50}) async {
    final body = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null && categoryId > 0) body['category_id'] = categoryId;
    if (keyword != null && keyword.isNotEmpty) body['keyword'] = keyword;

    final resp = await http.post(
      Uri.parse('$_base/openapi/customer/Goods/List'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data'] is List ? json['data'] as List : (json['data']['list'] ?? []) as List;
      return list.map((e) => Product.fromJson(e)).toList();
    }
    return [];
  }

  /// 商品详情
  static Future<Product?> getProductDetail(int productId) async {
    final resp = await http.post(
      Uri.parse('$_base/openapi/customer/Goods/Show'),
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

  /// 提交订单
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
      Uri.parse('$_base/openapi/customer/Goods/Buy'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(resp.body);
  }

  // ==================== 订单 ====================

  /// 获取订单列表
  static Future<List<Order>> getOrders({String? status, int page = 1, int pageSize = 20}) async {
    final body = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) body['status'] = status;

    final resp = await http.post(
      Uri.parse('$_base/openapi/customer/Order/List'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data'] is List ? json['data'] as List : (json['data']['list'] ?? []) as List;
      return list.map((e) => Order.fromJson(e)).toList();
    }
    return [];
  }

  /// 订单详情
  static Future<Order?> getOrderDetail(String orderNo) async {
    final resp = await http.post(
      Uri.parse('$_base/openapi/customer/Order/Show'),
      headers: _headers(),
      body: jsonEncode({'order_no': orderNo}),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return Order.fromJson(json['data']);
    }
    return null;
  }

  // ==================== 账户 ====================

  /// 获取账户余额
  static Future<double> getBalance() async {
    final resp = await http.get(
      Uri.parse('$_base/openapi/customer/CustomerAccount/Show'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return (json['data']['balance'] ?? 0).toDouble();
    }
    return 0;
  }
}
