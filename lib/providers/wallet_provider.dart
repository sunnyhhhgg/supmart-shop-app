import 'package:flutter/material.dart';
import '../models/wallet_record.dart';
import '../services/api_service.dart';

/// 钱包状态管理
class WalletProvider extends ChangeNotifier {
  List<WalletRecord> _capitalFlows = [];
  List<RechargeRecord> _rechargeRecords = [];
  List<WithdrawRecord> _withdrawRecords = [];
  bool _isLoading = false;
  String? _error;
  int _capitalPage = 1;
  int _rechargePage = 1;
  int _withdrawPage = 1;
  bool _hasMoreCapital = true;
  bool _hasMoreRecharge = true;
  bool _hasMoreWithdraw = true;

  List<WalletRecord> get capitalFlows => _capitalFlows;
  List<RechargeRecord> get rechargeRecords => _rechargeRecords;
  List<WithdrawRecord> get withdrawRecords => _withdrawRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreCapital => _hasMoreCapital;
  bool get hasMoreRecharge => _hasMoreRecharge;
  bool get hasMoreWithdraw => _hasMoreWithdraw;

  /// 加载资金流水
  Future<void> loadCapitalFlow({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _capitalPage = 1;
      _hasMoreCapital = true;
    }
    if (!_hasMoreCapital) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getCapitalFlow(page: _capitalPage);
      final list = result['list'] as List<WalletRecord>;
      final total = result['total'] as int;
      if (refresh) {
        _capitalFlows = list;
      } else {
        _capitalFlows.addAll(list);
      }
      _hasMoreCapital = _capitalFlows.length < total;
      _capitalPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载充值记录
  Future<void> loadRechargeRecords({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _rechargePage = 1;
      _hasMoreRecharge = true;
    }
    if (!_hasMoreRecharge) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getRechargeRecords(page: _rechargePage);
      final list = result['list'] as List<RechargeRecord>;
      final total = result['total'] as int;
      if (refresh) {
        _rechargeRecords = list;
      } else {
        _rechargeRecords.addAll(list);
      }
      _hasMoreRecharge = _rechargeRecords.length < total;
      _rechargePage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载提现记录
  Future<void> loadWithdrawRecords({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _withdrawPage = 1;
      _hasMoreWithdraw = true;
    }
    if (!_hasMoreWithdraw) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getWithdrawRecords(page: _withdrawPage);
      final list = result['list'] as List<WithdrawRecord>;
      final total = result['total'] as int;
      if (refresh) {
        _withdrawRecords = list;
      } else {
        _withdrawRecords.addAll(list);
      }
      _hasMoreWithdraw = _withdrawRecords.length < total;
      _withdrawPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 刷新所有数据
  Future<void> refreshAll() async {
    _capitalPage = 1;
    _rechargePage = 1;
    _withdrawPage = 1;
    _hasMoreCapital = true;
    _hasMoreRecharge = true;
    _hasMoreWithdraw = true;
    await Future.wait([
      loadCapitalFlow(refresh: true),
      loadRechargeRecords(refresh: true),
      loadWithdrawRecords(refresh: true),
    ]);
  }
}
