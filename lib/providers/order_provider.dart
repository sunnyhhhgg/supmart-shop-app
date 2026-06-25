import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _statusFilter = '';

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get statusFilter => _statusFilter;

  /// 加载订单
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _orders = [];
    }
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await ApiService.getOrders(
        status: _statusFilter.isEmpty ? null : _statusFilter,
        page: _page,
      );
      if (refresh) {
        _orders = list;
      } else {
        _orders.addAll(list);
      }
      _hasMore = list.length >= 20;
      _page++;
    } catch (e) {
      _error = '加载失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 设置状态筛选
  void setStatusFilter(String status) {
    _statusFilter = status;
    loadOrders(refresh: true);
  }
}
