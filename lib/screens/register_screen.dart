import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// 用户注册
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showMsg('请填写账号和密码');
      return;
    }
    if (username.length < 3) {
      _showMsg('账号至少3个字符');
      return;
    }
    if (password.length < 6) {
      _showMsg('密码至少6个字符');
      return;
    }
    if (password != confirm) {
      _showMsg('两次密码不一致');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.register(
        username: username,
        password: password,
        phone: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text.trim() : null,
        inviteCode: _inviteCtrl.text.isNotEmpty ? _inviteCtrl.text.trim() : null,
      );
      if (result['code'] == 0) {
        _showMsg('注册成功，请登录', isError: false);
        Navigator.pop(context);
      } else {
        _showMsg(result['message'] ?? '注册失败');
      }
    } catch (e) {
      _showMsg('注册失败: $e');
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
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.person_add, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePwd,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认密码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '手机号（选填）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _inviteCtrl,
              decoration: const InputDecoration(
                labelText: '邀请码（选填）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('注册', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('已有账号？立即登录'),
            ),
          ],
        ),
      ),
    );
  }
}
