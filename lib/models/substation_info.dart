/// 分站信息模型
class SubstationInfo {
  final int id;
  final String name;
  final String domain;
  final String logo;
  final String qq;
  final String wx;
  final String phone;
  final String status;
  final String level;
  final String createdAt;

  SubstationInfo({
    this.id = 0,
    this.name = '',
    this.domain = '',
    this.logo = '',
    this.qq = '',
    this.wx = '',
    this.phone = '',
    this.status = '',
    this.level = '',
    this.createdAt = '',
  });

  bool get exists => id > 0;

  factory SubstationInfo.fromJson(Map<String, dynamic> json) {
    return SubstationInfo(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? json['site_name']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      qq: json['qq']?.toString() ?? '',
      wx: json['wx']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: (json['status'] ?? 0).toString(),
      level: json['level']?.toString() ?? json['vip_level']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['create_time']?.toString() ?? '',
    );
  }
}
