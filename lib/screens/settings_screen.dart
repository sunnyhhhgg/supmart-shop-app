import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// 账号设置（修改密码、个人信息）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPwd = _oldPwdCtrl.text;
    final newPwd = _newPwdCtrl.text;
    final confirm = _confirmPwdCtrl.text;

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      _showMsg('请填写密码');
      return;
    }
    if (newPwd.length < 6) {
      _showMsg('新密码至少6个字符');
      return;
    }
    if (newPwd != confirm) {
      _showMsg('两次密码不一致');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.post('/shop/settings/password', {
        'old_password': oldPwd,
        'new_password': newPwd,
      });
      if (result['code'] == 0) {
        _showMsg('密码修改成功', isError: false);
        _oldPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
      } else {
        _showMsg(result['message'] ?? '修改失败');
      }
    } catch (e) {
      _showMsg('修改失败: $e');
    }
    setState(() => _loading = false);
  }

  void _showMsg(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[800] : Colors.green[800],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('账号设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    (auth.username.isNotEmpty ? auth.username[0] : 'U').toUpperCase(),
                    style: TextStyle(fontSize: 24, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('余额: ¥${auth.balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('修改密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _oldPwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '当前密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '确认新密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存修改', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
