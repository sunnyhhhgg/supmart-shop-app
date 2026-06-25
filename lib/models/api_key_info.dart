/// API密钥信息
class ApiKeyInfo {
  final String appId;
  final String appSecret;
  final List<String> ipWhitelist;
  final String? createdAt;

  ApiKeyInfo({
    this.appId = '',
    this.appSecret = '',
    this.ipWhitelist = const [],
    this.createdAt,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) {
    List<String> whitelist = [];
    if (json['ip_whitelist'] != null) {
      if (json['ip_whitelist'] is List) {
        whitelist = (json['ip_whitelist'] as List).map((e) => e.toString()).toList();
      } else if (json['ip_whitelist'] is String && json['ip_whitelist'].toString().isNotEmpty) {
        whitelist = json['ip_whitelist'].toString().split(',');
      }
    }
    return ApiKeyInfo(
      appId: json['app_id']?.toString() ?? '',
      appSecret: json['app_secret']?.toString() ?? '',
      ipWhitelist: whitelist,
      createdAt: json['created_at']?.toString(),
    );
  }
}
