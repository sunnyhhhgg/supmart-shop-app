import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/announcement.dart';
import '../models/banner.dart';
import '../models/wallet_record.dart';
import '../models/close_price.dart';
import '../models/api_key_info.dart';
import '../models/substation_info.dart';
import 'config_service.dart';

/// SUPMART Shop API调用层 — 完整覆盖PC端所有shop接口
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

  static final Duration _timeout = const Duration(seconds: 15);

  static String get _base => ConfigService.apiBase;

  /// 解析API响应，自动处理错误码
  static Map<String, dynamic> _parseResponse(http.Response resp) {
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception(json['message'] ?? '请求失败');
    }
    return json;
  }

  // ==================== 认证 ====================

  /// 用户登录 (POST /api/v2/shop/login)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/login'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    return json;
  }

  /// 用户注册 (POST /api/v2/shop/register)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? phone,
    String? inviteCode,
  }) async {
    final body = <String, dynamic>{'username': username, 'password': password};
    if (phone != null) body['phone'] = phone;
    if (inviteCode != null) body['invite_code'] = inviteCode;
    final resp = await http.post(
      Uri.parse('$_base/shop/register'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  // ==================== 初始化 ====================

  /// 获取系统配置 (POST /api/v2/shop/init-config)
  static Future<Map<String, dynamic>> initConfig() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/init-config'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  /// 获取商城样式 (POST /api/v2/shop/style)
  static Future<Map<String, dynamic>> getStyle() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/style'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  // ==================== 商品 ====================

  /// 获取商品分类 (POST /api/v2/shop/categories)
  static Future<List<Category>> getCategories() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/categories'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data'] as List;
      return list.map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  /// 获取商品列表 (POST /api/v2/shop/goods-list)
  static Future<Map<String, dynamic>> getProducts({
    int? categoryId,
    String? keyword,
    int page = 1,
    int pageSize = 50,
  }) async {
    final body = <String, dynamic>{'page': page, 'list_rows': pageSize};
    if (categoryId != null && categoryId > 0) body['goods_category_id'] = categoryId;
    if (keyword != null && keyword.isNotEmpty) body['goods_name'] = keyword;
    final resp = await http.post(
      Uri.parse('$_base/shop/goods-list'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final data = json['data'];
      final list = (data['list'] ?? data as List) as List;
      return {
        'list': list.map((e) => Product.fromJson(e)).toList(),
        'total': data['total'] ?? list.length,
      };
    }
    return {'list': <Product>[], 'total': 0};
  }

  /// 商品详情 (POST /api/v2/shop/goods-detail)
  static Future<Product?> getProductDetail(int productId) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/goods-detail'),
      headers: _headers(),
      body: jsonEncode({'id': productId}),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return Product.fromJson(json['data']);
    }
    return null;
  }

  /// 解析链接 (POST /api/v2/shop/resolve-link)
  static Future<String?> resolveLink(int goodsId, String url) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/resolve-link'),
      headers: _headers(),
      body: jsonEncode({'goods_id': goodsId, 'url': url}),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data']?['url'];
  }

  // ==================== 下单 ====================

  /// 提交订单 (POST /api/v2/shop/buy)
  static Future<Map<String, dynamic>> placeOrder({
    required int productId,
    required int quantity,
    String? contact,
    String? buyer,
    Map<String, dynamic>? buyParams,
  }) async {
    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
    if (contact != null) body['contact'] = contact;
    if (buyer != null) body['buyer'] = buyer;
    if (buyParams != null && buyParams.isNotEmpty) body['buy_params'] = buyParams;

    final resp = await http.post(
      Uri.parse('$_base/shop/buy'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(resp.body);
  }

  // ==================== 订单 ====================

  /// 获取订单列表 (POST /api/v2/shop/order-paging)
  static Future<Map<String, dynamic>> getOrders({
    int? status,
    int? goodsId,
    String? goodsName,
    int page = 1,
    int pageSize = 20,
  }) async {
    final body = <String, dynamic>{'page': page, 'list_rows': pageSize};
    if (status != null) body['status'] = status;
    if (goodsId != null) body['goods_id'] = goodsId;
    if (goodsName != null && goodsName.isNotEmpty) body['goods_name'] = goodsName;

    final resp = await http.post(
      Uri.parse('$_base/shop/order-paging'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final data = json['data'];
      final list = (data['list'] ?? data as List) as List;
      return {
        'list': list.map((e) => Order.fromJson(e)).toList(),
        'total': data['total'] ?? list.length,
      };
    }
    return {'list': <Order>[], 'total': 0};
  }

  // ==================== 账户/个人中心 ====================

  /// 获取用户信息 (POST /api/v2/shop/profile)
  static Future<Map<String, dynamic>> getProfile() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/profile'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return json['data'] as Map<String, dynamic>;
    }
    return {};
  }

  /// 获取用户信息(扩展版) (GET /api/v2/shop/user-info?Switch=4)
  static Future<Map<String, dynamic>> getUserInfo(String switchVal) async {
    final resp = await http.get(
      Uri.parse('$_base/shop/user-info?Switch=$switchVal'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  // ==================== 公告 ====================

  /// 获取公告列表 (GET /api/v2/shop/announcements)
  static Future<List<Announcement>> getAnnouncements() async {
    final resp = await http.get(
      Uri.parse('$_base/shop/announcements'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? [];
      return (list as List).map((e) => Announcement.fromJson(e)).toList();
    }
    return [];
  }

  /// 获取未读通知数 (GET /api/v2/shop/notice-red)
  static Future<int> getUnreadNoticeCount() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/shop/notice-red'),
        headers: _headers(),
      ).timeout(_timeout);
      final json = jsonDecode(resp.body);
      if (json['code'] == 0 && json['data'] != null) {
        return json['data']['count'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // ==================== 轮播图 ====================

  /// 获取轮播图 (GET /api/v2/shop/banners)
  static Future<List<BannerItem>> getBanners() async {
    final resp = await http.get(
      Uri.parse('$_base/shop/banners'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? [];
      return (list as List).map((e) => BannerItem.fromJson(e)).toList();
    }
    return [];
  }

  // ==================== 钱包 ====================

  /// 资金流水 (POST /api/v2/shop/wallet/capital-flow)
  static Future<Map<String, dynamic>> getCapitalFlow({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    final body = <String, dynamic>{'page': page, 'list_rows': pageSize};
    if (type != null && type.isNotEmpty) body['type'] = type;
    final resp = await http.post(
      Uri.parse('$_base/shop/wallet/capital-flow'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final data = json['data'];
      final list = (data['list'] ?? data as List) as List;
      return {
        'list': list.map((e) => WalletRecord.fromJson(e)).toList(),
        'total': data['total'] ?? list.length,
      };
    }
    return {'list': <WalletRecord>[], 'total': 0};
  }

  /// 充值记录 (POST /api/v2/shop/wallet/recharge-record)
  static Future<Map<String, dynamic>> getRechargeRecords({
    int page = 1,
    int pageSize = 20,
    int? status,
  }) async {
    final body = <String, dynamic>{'page': page, 'list_rows': pageSize};
    if (status != null) body['status'] = status;
    final resp = await http.post(
      Uri.parse('$_base/shop/wallet/recharge-record'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final data = json['data'];
      final list = (data['list'] ?? data as List) as List;
      return {
        'list': list.map((e) => RechargeRecord.fromJson(e)).toList(),
        'total': data['total'] ?? list.length,
      };
    }
    return {'list': <RechargeRecord>[], 'total': 0};
  }

  /// 提现记录 (POST /api/v2/shop/wallet/withdraw-record)
  static Future<Map<String, dynamic>> getWithdrawRecords({
    int page = 1,
    int pageSize = 20,
    int? status,
  }) async {
    final body = <String, dynamic>{'page': page, 'list_rows': pageSize};
    if (status != null) body['status'] = status;
    final resp = await http.post(
      Uri.parse('$_base/shop/wallet/withdraw-record'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final data = json['data'];
      final list = (data['list'] ?? data as List) as List;
      return {
        'list': list.map((e) => WithdrawRecord.fromJson(e)).toList(),
        'total': data['total'] ?? list.length,
      };
    }
    return {'list': <WithdrawRecord>[], 'total': 0};
  }

  /// 发起提现 (POST /api/v2/shop/wallet/withdraw)
  static Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String account,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/wallet/withdraw'),
      headers: _headers(),
      body: jsonEncode({'amount': amount, 'account': account}),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 创建支付订单 (POST /api/v2/shop/create-payment)
  static Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String payType,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/create-payment'),
      headers: _headers(),
      body: jsonEncode({'amount': amount, 'pay_type': payType}),
    ).timeout(const Duration(seconds: 30));
    final json = jsonDecode(resp.body);
    return json; // 含 pay_url, order_no, amount
  }

  // ==================== API密钥 ====================

  /// 获取API密钥信息 (POST /api/v2/shop/token/open-api-info)
  static Future<ApiKeyInfo?> getApiKeyInfo() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/token/open-api-info'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return ApiKeyInfo.fromJson(json['data']);
    }
    return null;
  }

  /// 重置AppSecret (POST /api/v2/shop/token/reset-app-secret)
  static Future<Map<String, dynamic>> resetAppSecret() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/token/reset-app-secret'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  /// 更新IP白名单 (PUT /api/v2/shop/token/whitelist)
  static Future<List<String>> updateWhitelist(List<String> ips) async {
    final resp = await http.put(
      Uri.parse('$_base/shop/token/whitelist'),
      headers: _headers(),
      body: jsonEncode({'ip_whitelist': ips}),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return List<String>.from(json['data']?['ip_whitelist'] ?? []);
  }

  // ==================== 成交价(密价) ====================

  /// 获取成交价列表 (POST /api/v2/shop/close-price/list)
  static Future<List<ClosePrice>> getClosePriceList({int? goodsId}) async {
    final body = <String, dynamic>{};
    if (goodsId != null) body['goods_id'] = goodsId;
    final resp = await http.post(
      Uri.parse('$_base/shop/close-price/list'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? [];
      return (list as List).map((e) => ClosePrice.fromJson(e)).toList();
    }
    return [];
  }

  // ==================== 分站 ====================

  /// 获取用户分站信息 (POST /api/v2/shop/substation)
  static Future<SubstationInfo?> getSubstation() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/substation'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      return SubstationInfo.fromJson(json['data']);
    }
    return null;
  }

  /// 购买分站 (POST /api/v2/shop/buy-substation)
  static Future<Map<String, dynamic>> buySubstation() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/buy-substation'),
      headers: _headers(),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 购买/升级分站(带配置) (POST /api/v2/shop/buy-fz)
  static Future<Map<String, dynamic>> buyFz({
    int? level,
    String? logo,
    String? siteName,
    String? url,
    String? qq,
    String? wx,
    String? domainPrefix,
    int? mainDomainId,
  }) async {
    final body = <String, dynamic>{};
    if (level != null) body['level'] = level;
    if (logo != null) body['logo'] = logo;
    if (siteName != null) body['site_name'] = siteName;
    if (url != null) body['url'] = url;
    if (qq != null) body['qq'] = qq;
    if (wx != null) body['wx'] = wx;
    if (domainPrefix != null) body['domain_prefix'] = domainPrefix;
    if (mainDomainId != null) body['main_domain_id'] = mainDomainId;
    final resp = await http.post(
      Uri.parse('$_base/shop/buy-fz'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 分站授权列表 (POST /api/v2/shop/fz-auth-list)
  static Future<Map<String, dynamic>> getFzAuthList() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/fz-auth-list'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0) {
      return json['data'] ?? {};
    }
    return {};
  }

  /// 分站域名列表 (POST /api/v2/shop/url-list)
  static Future<List<Map<String, dynamic>>> getShopUrlList() async {
    final resp = await http.post(
      Uri.parse('$_base/shop/url-list'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? [];
      return (list as List).map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// 分站详情 (GET /api/v2/shop/fz-info?Switch=1)
  static Future<Map<String, dynamic>> getFzInfo(String switchVal, {String? startTime, String? endTime}) async {
    String url = '$_base/shop/fz-info?Switch=$switchVal';
    if (startTime != null) url += '&StartTime=$startTime';
    if (endTime != null) url += '&EndTime=$endTime';
    final resp = await http.get(
      Uri.parse(url),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  // ==================== VIP/会员 ====================

  /// 获取VIP等级价格 (GET /api/v2/shop/vip-money)
  static Future<Map<String, dynamic>> getVipMoney({String? type}) async {
    String url = '$_base/shop/vip-money';
    if (type != null) url += '?type=$type';
    final resp = await http.get(
      Uri.parse(url),
      headers: _headers(),
    ).timeout(_timeout);
    final json = _parseResponse(resp);
    return json['data'] ?? {};
  }

  /// 升级会员等级 (POST /api/v2/shop/upgrade-level)
  static Future<Map<String, dynamic>> upgradeLevel(String targetLevel) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/upgrade-level'),
      headers: _headers(),
      body: jsonEncode({'target_level': targetLevel}),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 购买会员 (POST /api/v2/shop/buy-membership)
  static Future<Map<String, dynamic>> buyMembership(String targetLevel) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/buy-membership'),
      headers: _headers(),
      body: jsonEncode({'target_level': targetLevel}),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 续费会员 (POST /api/v2/shop/renew-membership)
  static Future<Map<String, dynamic>> renewMembership(String targetLevel) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/renew-membership'),
      headers: _headers(),
      body: jsonEncode({'target_level': targetLevel}),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  // ==================== 通知 ====================

  /// 登录记录 (POST /api/v2/shop/login-records)
  static Future<Map<String, dynamic>> getLoginRecords({
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/shop/login-records'),
      headers: _headers(),
      body: jsonEncode({'page': page, 'list_rows': pageSize}),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    return json;
  }

  // ==================== 在线客服 ====================

  /// 发送消息并获取自动回复 (POST /api/v2/admin/cs/auto-reply)
  /// shop_token 也可调用此admin接口
  static Future<Map<String, dynamic>> sendChatMessage({
    required String content,
    int convId = 0,
    int userId = 0,
    String userName = '',
    String msgType = 'text',
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/admin/cs/auto-reply'),
      headers: _headers(),
      body: jsonEncode({
        'conv_id': convId,
        'user_id': userId,
        'user_name': userName,
        'content': content,
        'msg_type': msgType,
      }),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 获取聊天消息列表 (GET /api/v2/admin/cs/messages?conv_id=X)
  static Future<List<Map<String, dynamic>>> getChatMessages(int convId) async {
    final resp = await http.get(
      Uri.parse('$_base/admin/cs/messages?conv_id=$convId'),
      headers: _headers(),
    ).timeout(_timeout);
    final json = jsonDecode(resp.body);
    if (json['code'] == 0 && json['data'] != null) {
      final list = json['data']['list'] ?? [];
      return (list as List).map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // ==================== 辅助方法 ====================

  /// 通用POST请求（用于扩展未覆盖的API）
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }

  /// 通用GET请求
  static Future<Map<String, dynamic>> get(String path) async {
    final resp = await http.get(
      Uri.parse('$_base$path'),
      headers: _headers(),
    ).timeout(_timeout);
    return jsonDecode(resp.body);
  }
}
