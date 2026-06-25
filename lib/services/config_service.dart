import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_pack_config.dart';

/// 启动时加载APP动态配置
class ConfigService {
  static const String _defaultHost = 'https://3003.online';
  static const String _openApiPath = '/openapi/app-pack/config/0';

  static AppPackConfig? _config;
  static String _baseUrl = _defaultHost;

  static AppPackConfig? get config => _config;
  static String get baseUrl => _baseUrl;
  static String get apiBase => '$_baseUrl/api/v2';
  static String get appName => _config?.appName ?? 'SUPMART';
  static String get primaryColor => _config?.primaryColor ?? '#5E6AD2';

  /// 从公开API加载配置
  static Future<bool> loadConfig({String? host}) async {
    if (host != null && host.isNotEmpty) {
      _baseUrl = host;
    }
    try {
      final uri = Uri.parse('$_baseUrl$_openApiPath');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['code'] == 0 && json['data'] != null) {
          _config = AppPackConfig.fromJson(json['data']);
          if (_config!.domain.isNotEmpty) {
            _baseUrl = _config!.domain;
          }
          return true;
        }
      }
    } catch (e) {
      // 静默失败，使用默认值
    }
    return false;
  }
}
