/// APP一键打包配置 — 从 /openapi/app-pack/config/:stationId 获取
class AppPackConfig {
  final int id;
  final int stationId;
  final String appName;
  final String domain;
  final String splashImage;
  final String appIcon;
  final String primaryColor;
  final String version;
  final String downloadUrl;
  final bool androidEnabled;
  final bool iosEnabled;
  final String updateLog;
  final String description;
  final int createdAt;
  final int updatedAt;

  AppPackConfig({
    required this.id,
    required this.stationId,
    required this.appName,
    required this.domain,
    required this.splashImage,
    required this.appIcon,
    required this.primaryColor,
    required this.version,
    required this.downloadUrl,
    required this.androidEnabled,
    required this.iosEnabled,
    required this.updateLog,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppPackConfig.fromJson(Map<String, dynamic> json) {
    return AppPackConfig(
      id: json['id'] ?? 0,
      stationId: json['station_id'] ?? 0,
      appName: json['app_name'] ?? 'SUPMART',
      domain: json['domain'] ?? '',
      splashImage: json['splash_image'] ?? '',
      appIcon: json['app_icon'] ?? '',
      primaryColor: json['primary_color'] ?? '#5E6AD2',
      version: json['version'] ?? '1.0.0',
      downloadUrl: json['download_url'] ?? '',
      androidEnabled: json['android_enabled'] ?? true,
      iosEnabled: json['ios_enabled'] ?? true,
      updateLog: json['update_log'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }
}
