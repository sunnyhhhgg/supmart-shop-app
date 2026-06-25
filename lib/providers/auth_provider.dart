import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  String _username = '';
  double _balance = 0;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _username;
  double get balance => _balance;

  /// 尝试自动登录（从本地存储恢复token）
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('auth_username') ?? '';
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
      _username = username;
      _isLoggedIn = true;
      notifyListeners();
      // 异步刷新余额
      refreshBalance();
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.login(username, password);
      if (result['code'] == 0 && result['data'] != null) {
        final data = result['data'];
        final token = data['token'] ?? data['access_token'] ?? '';
        if (token.isNotEmpty) {
          ApiService.setToken(token);
          _isLoggedIn = true;
          _username = username;
          _error = null;

          // 持久化token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('auth_username', username);

          _isLoading = false;
          notifyListeners();
          refreshBalance();
          return true;
        }
      }
      _error = result['message'] ?? '登录失败';
      _isLoggedIn = false;
    } catch (e) {
      _error = '网络错误: $e';
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 刷新余额
  Future<void> refreshBalance() async {
    if (!_isLoggedIn) return;
    try {
      _balance = await ApiService.getBalance();
      notifyListeners();
    } catch (_) {}
  }

  /// 退出
  Future<void> logout() async {
    ApiService.clearToken();
    _isLoggedIn = false;
    _username = '';
    _balance = 0;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
    notifyListeners();
  }
}
