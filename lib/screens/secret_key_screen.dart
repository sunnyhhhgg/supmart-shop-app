import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_key_info.dart';

/// API密钥管理
class SecretKeyScreen extends StatefulWidget {
  const SecretKeyScreen({super.key});

  @override
  State<SecretKeyScreen> createState() => _SecretKeyScreenState();
}

class _SecretKeyScreenState extends State<SecretKeyScreen> {
  ApiKeyInfo? _info;
  bool _loading = true;
  bool _showSecret = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _info = await ApiService.getApiKeyInfo();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _resetSecret() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('重置AppSecret后，旧的密钥将立即失效，确定要重置吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认重置')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _resetting = true);
    try {
      final result = await ApiService.resetAppSecret();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('重置成功', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[700],
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: $e')));
      }
    }
    setState(() => _resetting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('API密钥')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _info == null
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCard(
                        'AppID',
                        _info!.appId,
                        Icons.fingerprint,
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        'AppSecret',
                        _showSecret ? _info!.appSecret : '••••••' + _info!.appSecret.substring(
                          _info!.appSecret.length > 4 ? _info!.appSecret.length - 4 : 0
                        ),
                        Icons.key,
                        theme,
                        trailing: IconButton(
                          icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => _showSecret = !_showSecret),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCard(
                        'IP白名单',
                        _info!.ipWhitelist.isNotEmpty ? _info!.ipWhitelist.join(', ') : '未设置',
                        Icons.security,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: _resetting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          label: const Text('重置 AppSecret'),
                          onPressed: _resetting ? null : _resetSecret,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '重置后需要更新对接应用的密钥配置',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard(String label, String value, IconData icon, ThemeData theme, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_key, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text('暂无API密钥信息', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('刷新')),
        ],
      ),
    );
  }
}
