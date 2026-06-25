/// 资金流水记录
class WalletRecord {
  final int id;
  final double amount;
  final double balanceAfter;
  final String type;
  final String typeText;
  final String remark;
  final String createdAt;

  WalletRecord({
    required this.id,
    this.amount = 0,
    this.balanceAfter = 0,
    this.type = '',
    this.typeText = '',
    this.remark = '',
    this.createdAt = '',
  });

  factory WalletRecord.fromJson(Map<String, dynamic> json) {
    return WalletRecord(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? json['balance'] ?? 0).toDouble(),
      type: json['type']?.toString() ?? '',
      typeText: json['type_text']?.toString() ?? _defaultTypeText(json['type']?.toString()),
      remark: json['remark']?.toString() ?? json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['create_time']?.toString() ?? '',
    );
  }

  static String _defaultTypeText(String? type) {
    switch (type) {
      case 'recharge': return '充值';
      case 'withdraw': return '提现';
      case 'buy': return '消费';
      case 'refund': return '退款';
      case 'commission': return '佣金';
      case 'admin_recharge': return '后台加款';
      case 'admin_deduct': return '后台扣款';
      case 'upgrade': return '升级';
      default: return type ?? '其他';
    }
  }
}

/// 充值记录
class RechargeRecord {
  final int id;
  final double amount;
  final String status;
  final String statusText;
  final String payType;
  final String createdAt;

  RechargeRecord({
    required this.id,
    this.amount = 0,
    this.status = '',
    this.statusText = '',
    this.payType = '',
    this.createdAt = '',
  });

  factory RechargeRecord.fromJson(Map<String, dynamic> json) {
    String s = (json['status'] ?? 0).toString();
    return RechargeRecord(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: s,
      statusText: s == '1' ? '已完成' : (s == '0' ? '待支付' : '已取消'),
      payType: json['pay_type']?.toString() ?? json['type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['create_time']?.toString() ?? '',
    );
  }
}

/// 提现记录
class WithdrawRecord {
  final int id;
  final double amount;
  final String status;
  final String statusText;
  final String account;
  final String remark;
  final String createdAt;

  WithdrawRecord({
    required this.id,
    this.amount = 0,
    this.status = '',
    this.statusText = '',
    this.account = '',
    this.remark = '',
    this.createdAt = '',
  });

  factory WithdrawRecord.fromJson(Map<String, dynamic> json) {
    String s = (json['status'] ?? 0).toString();
    String st;
    switch (s) {
      case '0': st = '待审核'; break;
      case '1': st = '已通过'; break;
      case '2': st = '已拒绝'; break;
      default: st = '未知';
    }
    return WithdrawRecord(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: s,
      statusText: st,
      account: json['account']?.toString() ?? json['withdraw_account']?.toString() ?? '',
      remark: json['remark']?.toString() ?? json['reason']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['create_time']?.toString() ?? '',
    );
  }
}
